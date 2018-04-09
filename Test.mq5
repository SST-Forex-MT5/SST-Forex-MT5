//+------------------------------------------------------------------+
//|                                                           EA.mq5 |
//|                                         Copyright 2018, SST Team |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, SST Team"
#property link      "https://www.mql5.com"
#property version   "1.00"
input int      longMAPeriod=60;   //długi okres średniej kroczącej
input int      shortMAPeriod=10;  //krótki okres średniej kroczącej
input double   takeProfit=1000.0; //poziom take profit
input double   stopLoss=300.0;    //poziom stop loss
input double   lot=500;           //wolumen w lotach
input ulong   dev=5;           //dopuszczalne odchylenie wartości transakcji

#define MODE_TRADES 0
#define SELECT_BY_POS 0
#define SELECT_BY_TICKET 1
#define EXPERT_MAGIC 6969666

int CROSSED_UP = 1;               //zmienna pomocnicza do określania kierunku przecięcia
int CROSSED_DOWN = 2;             //zmienna pomocnicza do określania kierunku przecięcia

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   double startingBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   Print("Poczatkowy stan konta:", + startingBalance); 
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   if(validate()) {
      int crossingDirection = calculateAveragesAndCheckDirection();
      closePositions();        //zamknięcie pozycji spełniającej warunki strategii
      openPositions(crossingDirection);
   }
}

bool validate() {
   if(Bars(_Symbol,_Period)<100){     //Bars-liczba wszystkich słupków na wykresie
      Print("Liczba słupków mniejsza niż 100");
      return(false); //błąd
   }
   if(stopLoss<100){ //stop loss
      Print("StopLoss mniejszy niż 100");
      return(false);//błąd 
   }
   return(true);
}


int calculateAveragesAndCheckDirection() {
   double previousLongMA, previousShortMA, currentLongMA, currentShortMA;
   
   //długa pozycja
   previousLongMA = iMAMQL4(NULL,0,longMAPeriod,0,MODE_SMA,PRICE_CLOSE,2);
   currentLongMA = iMAMQL4(NULL,0,longMAPeriod,0,MODE_SMA,PRICE_CLOSE,1);
   
   //krótka pozycja
   previousShortMA = iMAMQL4(NULL,0,shortMAPeriod,0,MODE_SMA,PRICE_CLOSE,2);
   currentShortMA = iMAMQL4(NULL,0,shortMAPeriod,0,MODE_SMA,PRICE_CLOSE,1);
   
   if((previousLongMA>=previousShortMA) && (currentLongMA<currentShortMA)){
      return (CROSSED_UP);
   }
   else if((previousLongMA<=previousShortMA) && (currentLongMA>currentShortMA)){
      return(CROSSED_DOWN);
   }
   else return(0);
}

//+------------------------------------------------------------------+
//| OTWARCIE POZYCJI                                                 |
//+------------------------------------------------------------------+
void openPositions(int direction){
   int total = OrdersTotal();    //łączna kwota obrotu i zleceń oczekujących
   if(total==0){
      if(direction==CROSSED_UP){   //otwarcie pozycji kupna
         openBuyPosition();
      }
      if(direction==CROSSED_DOWN){ //otwarcie pozycji sprzedaży
         openSellPosition();
      }
   }
}
  
//+------------------------------------------------------------------+
//| OTWARCIE POZYCJI (kupna)                                         |
//|      Kupno przy zachwowaniu warunków zgodnych ze strategią       |
//|      Bid-kurs kupna                                              |
//|      Ask-kurs sprzedaży                                          |
//+------------------------------------------------------------------+
void openBuyPosition(){
   MqlTradeRequest request={0};
   MqlTradeResult  result={0};
//--- parameters of request
   request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
   request.symbol   =Symbol();                              // symbol
   request.volume   =lot;                                   // volume of 0.1 lot
   request.type     =ORDER_TYPE_BUY;                        // order type
   request.price    =SymbolInfoDouble(Symbol(),SYMBOL_ASK); // price for opening
   request.deviation=dev;                                   // allowed deviation from the price
   request.magic    =EXPERT_MAGIC;                          // MagicNumber of the order
   
   if(!OrderSend(request,result))
      PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
//--- information about the operation
   PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);

}

//+------------------------------------------------------------------+
//| OTWARCIE POZYCJI (sprzedaży)                                     |
//|      Point-próg rentowności                                      |
//|      Bid-kurs kupna                                              |
//|      Ask-kurs sprzedaży                                          |
//+------------------------------------------------------------------+
void openSellPosition(){
   MqlTradeRequest request={0};
   MqlTradeResult  result={0};
//--- parameters of request
   request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
   request.symbol   =Symbol();                              // symbol
   request.volume   =lot;                                   // volume of 0.1 lot
   request.type     =ORDER_TYPE_SELL;                       // order type
   request.price    =SymbolInfoDouble(Symbol(),SYMBOL_BID); // price for opening
   request.deviation=dev;                                   // allowed deviation from the price
   request.magic    =EXPERT_MAGIC;                          // MagicNumber of the order
//--- send the request
   if(!OrderSend(request,result))
      PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
//--- information about the operation
   PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);

}

//+------------------------------------------------------------------+
//| ZAMKNIĘCIE WSZYSTKICH POZYCJI                                               |
//+------------------------------------------------------------------+
void closePositions(){
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total=PositionsTotal(); // number of open positions   
//--- iterate over all open positions
   for(int i=total-1; i>=0; i--)
     {
      //--- parameters of the order
      ulong  position_ticket=PositionGetTicket(i);                                      // ticket of the position
      string position_symbol=PositionGetString(POSITION_SYMBOL);                        // symbol 
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);              // number of decimal places
      ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber of the position
      double volume=PositionGetDouble(POSITION_VOLUME);                                 // volume of the position
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // type of the position
      //--- output information about the position
      PrintFormat("#%I64u %s  %s  %.2f  %s [%I64d]",
                  position_ticket,
                  position_symbol,
                  EnumToString(type),
                  volume,
                  DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                  magic);
      //--- if the MagicNumber matches
      if(magic==EXPERT_MAGIC)
        {
         //--- zeroing the request and result values
         ZeroMemory(request);
         ZeroMemory(result);
         //--- setting the operation parameters
         request.action   =TRADE_ACTION_DEAL;        // type of trade operation
         request.position =position_ticket;          // ticket of the position
         request.symbol   =position_symbol;          // symbol 
         request.volume   =volume;                   // volume of the position
         request.deviation=5;                        // allowed deviation from the price
         request.magic    =EXPERT_MAGIC;             // MagicNumber of the position
         //--- set the price and order type depending on the position type
         if(type==POSITION_TYPE_BUY)
           {
            request.price=SymbolInfoDouble(position_symbol,SYMBOL_BID);
            request.type =ORDER_TYPE_SELL;
           }
         else
           {
            request.price=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
            request.type =ORDER_TYPE_BUY;
           }
         //--- output information about the closure
         PrintFormat("Close #%I64d %s %s",position_ticket,position_symbol,EnumToString(type));
         //--- send the request
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
         //--- information about the operation   
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
         //---
        }
     }
}


ENUM_TIMEFRAMES TFMigrate(int tf)
  {
   switch(tf)
     {
      case 0: return(PERIOD_CURRENT);
      case 1: return(PERIOD_M1);
      case 5: return(PERIOD_M5);
      case 15: return(PERIOD_M15);
      case 30: return(PERIOD_M30);
      case 60: return(PERIOD_H1);
      case 240: return(PERIOD_H4);
      case 1440: return(PERIOD_D1);
      case 10080: return(PERIOD_W1);
      case 43200: return(PERIOD_MN1);
      
      case 2: return(PERIOD_M2);
      case 3: return(PERIOD_M3);
      case 4: return(PERIOD_M4);      
      case 6: return(PERIOD_M6);
      case 10: return(PERIOD_M10);
      case 12: return(PERIOD_M12);
      case 16385: return(PERIOD_H1);
      case 16386: return(PERIOD_H2);
      case 16387: return(PERIOD_H3);
      case 16388: return(PERIOD_H4);
      case 16390: return(PERIOD_H6);
      case 16392: return(PERIOD_H8);
      case 16396: return(PERIOD_H12);
      case 16408: return(PERIOD_D1);
      case 32769: return(PERIOD_W1);
      case 49153: return(PERIOD_MN1);      
      default: return(PERIOD_CURRENT);
     }
  }
  
ENUM_MA_METHOD MethodMigrate(int method)
  {
   switch(method)
     {
      case 0: return(MODE_SMA);
      case 1: return(MODE_EMA);
      case 2: return(MODE_SMMA);
      case 3: return(MODE_LWMA);
      default: return(MODE_SMA);
     }
  }
ENUM_APPLIED_PRICE PriceMigrate(int price)
  {
   switch(price)
     {
      case 1: return(PRICE_CLOSE);
      case 2: return(PRICE_OPEN);
      case 3: return(PRICE_HIGH);
      case 4: return(PRICE_LOW);
      case 5: return(PRICE_MEDIAN);
      case 6: return(PRICE_TYPICAL);
      case 7: return(PRICE_WEIGHTED);
      default: return(PRICE_CLOSE);
     }
  }
ENUM_STO_PRICE StoFieldMigrate(int field)
  {
   switch(field)
     {
      case 0: return(STO_LOWHIGH);
      case 1: return(STO_CLOSECLOSE);
      default: return(STO_LOWHIGH);
     }
  }
//+------------------------------------------------------------------+

double CopyBufferMQL4(int handle,int index,int shift)
  {
   double buf[];
   switch(index)
     {
      case 0: if(CopyBuffer(handle,0,shift,1,buf)>0)
         return(buf[0]); break;
      case 1: if(CopyBuffer(handle,1,shift,1,buf)>0)
         return(buf[0]); break;
      case 2: if(CopyBuffer(handle,2,shift,1,buf)>0)
         return(buf[0]); break;
      case 3: if(CopyBuffer(handle,3,shift,1,buf)>0)
         return(buf[0]); break;
      case 4: if(CopyBuffer(handle,4,shift,1,buf)>0)
         return(buf[0]); break;
      default: break;
     }
   return(EMPTY_VALUE);
  }

double iMAMQL4(string symbol,
               int tf,
               int period,
               int ma_shift,
               int method,
               int price,
               int shift)
  {
   ENUM_TIMEFRAMES timeframe=TFMigrate(tf);
   ENUM_MA_METHOD ma_method=MethodMigrate(method);
   ENUM_APPLIED_PRICE applied_price=PriceMigrate(price);
   int handle=iMA(symbol,timeframe,period,ma_shift,
                  ma_method,applied_price);
   if(handle<0)
     {
      Print("The iMA object is not created: Error",GetLastError());
      return(-1);
     }
   else
      return(CopyBufferMQL4(handle,0,shift));
  }
