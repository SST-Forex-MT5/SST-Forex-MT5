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
input double   lot=0.1;           //wolumen w lotach

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   if(Bars(_Symbol,_Period)<100){     //Bars-liczba wszystkich słupków na wykresie
      Print("Liczba słupków mniejsza niż 100");
      return(false); //błąd
   }
   if(stopLoss<100){ //stop loss
      Print("StopLoss mniejszy niż 100");
      return(false);//błąd 
   }
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
   double previousLongMA, previousShortMA, currentLongMA, currentShortMA;
   
   //długa pozycja
   previousLongMA = iMA(NULL,0,longMAPeriod,0,MODE_SMA,PRICE_CLOSE,2);
   currentLongMA = iMA(NULL,0,longMAPeriod,0,MODE_SMA,PRICE_CLOSE,1);
   
   //krótka pozycja
   previousShortMA = iMA(NULL,0,shortMAPeriod,0,MODE_SMA,PRICE_CLOSE,2);
   currentShortMA = iMA(NULL,0,shortMAPeriod,0,MODE_SMA,PRICE_CLOSE,1);
   
   if((previousLongMA>=previousShortMA) && (currentLongMA<currentShortMA)){
      closePositions();        //zamknięcie pozycji spełniającej warunki strategii
      openPositions();
   }
}

//+------------------------------------------------------------------+
//| OTWARCIE POZYCJI                                                 |
//+------------------------------------------------------------------+
void openPositions(){
   int total = OrdersTotal();    //łączna kwota obrotu i zleceń oczekujących
   if(total==0){
      openBuyPosition();
   }
}
  
//+------------------------------------------------------------------+
//| OTWARCIE POZYCJI (kupna)                                         |
//|      Kupno przy zachwowaniu warunków zgodnych ze strategią       |
//|      Bid-kurs kupna                                              |
//|      Ask-kurs sprzedaży                                          |
//+------------------------------------------------------------------+
void openBuyPosition(){
   int position = OP_BUY;
   double volume = lot;
   MqlTick last_tick;
   SymbolInfoTick(_Symbol,last_tick);
   double price = last_tick.ask; //kurs sprzedaży
   double sl = last_tick.bid - stopLoss*_Point; 
   double tp = 0;
   if(takeProfit>0){
      tp = last_tick.ask + takeProfit*_Point;
   }  
   color clr = Green;
   sendRequest(position,volume,price,sl,tp,clr);
}

//+------------------------------------------------------------------+
//| ZAMKNIĘCIE POZYCJI                                               |
//+------------------------------------------------------------------+
void closePositions(){
   int position;
   int total = OrdersTotal(); //łączna kwota obrotu i zleceń oczekujących
   if(total>0){
      for(position=0; position<total; position++){
         OrderSelect(position,SELECT_BY_POS,MODE_TRADES); //wybór zlecenia do przetworzenia
         if((OrderType()<=OP_SELL) && (OrderSymbol()==Symbol())){
            closeSellPosition(); //wysłanie żądania zamknięcia zlecenia
         }
      }
   }
}

//+------------------------------------------------------------------+
//| WYSŁANIE ŻĄDANIA ZAMKNIĘCIA POZYCJI (kupna)                      |
//+------------------------------------------------------------------+
void closeBuyPosition(){
   MqlTick last_tick;
   SymbolInfoTick(_Symbol,last_tick);
   OrderClose(OrderTicket(),OrderLots(),last_tick.bid,3,Violet);
}

//+------------------------------------------------------------------+
//| WYSŁANIE ŻĄDANIA ZAMKNIĘCIA POZYCJI (sprzedaży)                  |
//+------------------------------------------------------------------+
void closeSellPosition(){
   MqlTick last_tick;
   SymbolInfoTick(_Symbol,last_tick);
   OrderClose(OrderTicket(),OrderLots(),last_tick.ask,3,Violet);
}

//+------------------------------------------------------------------+
//| WYSŁANIE ZLECENIA NA RYNEK                                       |
//+------------------------------------------------------------------+
void sendRequest(int position, double volume, double price, double sl, double tp, color clr){
   int ticket = OrderSend(Symbol(),position,volume,price,3,sl,tp,"Program",12345,0,clr); //numer zlecenia lub błąd 
   if(ticket>0){ //jeżeli pobrano numer zlecenia to...
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)){ //wybór zlecnia zakończony sukcesem
         Print("Pozycja otwarta:",OrderOpenPrice()); //wartrość aktualnego zlecenia
      }
      else Print("Blad otwarcia pozycji", GetLastError()); //rodzaj błędu
   }
}
//+------------------------------------------------------------------+