//+------------------------------------------------------------------+
//|                                                        Test5.mq5 |
//|                                               Copyright SST Team |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "SST Team"
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>

#property script_show_inputs
//--- input parameters
input int Periods=5;  // Period for MA indicator                              ////////////////////////
input int SL=999999;       // Stop Loss
input int TP=999999;       // Take Profit
input int PERIOD_QUANITITY=5;
input double lot=0.5;           //wolumen w lotach
input ulong dev=1;           //dopuszczalne odchylenie wartości transakcji
#define MAGIC 6969666;   // MAGIC number


CTrade trade;


MqlTradeRequest trReq;
MqlTradeResult trRez;
int smallAverage;
int bigAverage;
double smallAverageBuffer[]; //krótka średnia
double bigAverageBuffer[];  //długa średnia
double actualPrice;    // aktualna cena

int transakcjaS=0;  //zmienna określająca zawarcie transakcji sprzedzazy
int transakcjaB=0;  // zmienna okreslajaca zawarcie transakcji kupna

int sl; // stopLoss
int tp; //takeProfit
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   ZeroMemory(trReq);
   ZeroMemory(trRez);
//---- set default vaules for all new order requests
   trReq.action=TRADE_ACTION_DEAL;
   trReq.magic=MAGIC;
   trReq.symbol=Symbol();                 // Trade symbol
   trReq.volume=lot;                      // Requested volume for a deal in lots
   trReq.deviation=dev;                     // Maximal possible deviation from the requested price
   trReq.type_filling=ORDER_FILLING_FOK;  // Order execution type
   trReq.type_time=ORDER_TIME_GTC;        // Order execution time
   trReq.comment="MA Sample";

//---- Create handle for 2 MA indicators
   smallAverage=iMA(Symbol(),PERIOD_CURRENT,Periods,0,MODE_EMA,PRICE_CLOSE);   //obliczanie krótkiej średniej
   bigAverage=iMA(Symbol(),PERIOD_CURRENT,Periods*PERIOD_QUANITITY,0,MODE_EMA,PRICE_CLOSE); //obliczanie długiej średniej

//---- input parameters are ReadOnly
   tp=TP;
   sl=SL;

//---- Suppoprt for acount with 5 decimals
   if(_Digits==5)
     {
      sl*=10;
      tp*=10;
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   MqlTick tick; //variable for tick info
   if(!SymbolInfoTick(Symbol(),tick)) {
      Print("Failed to get Symbol info!");
      return;
     }

//---- Copy latest MA indicator values into a buffer
   int copied=CopyBuffer(smallAverage,0,0,4,smallAverageBuffer);
   Print(smallAverage);
   if(copied>0) {
      copied=CopyBuffer(bigAverage,0,0,4,bigAverageBuffer);
      Print(bigAverage);
    }
   
   
   actualPrice=tick.ask; //przypisanie aktualnej ceny
   //transakcja=PositionsTotal();
   
 /*  if(actualPrice<=bigAverageBuffer[1] || actualPrice<=smallAverageBuffer[1])
   {
      tp=30;
   } else { 
      tp = TP;
   }*/                             // <-------------------------------- a po co to? (Marcin S.)
   
   if(copied>0) {
      // warunek sprawdzający czy aktualna cena przewyższa obie średnie
      if(actualPrice>bigAverageBuffer[1] && actualPrice>smallAverageBuffer[1] && transakcjaB==0) {
         trReq.price=tick.ask;                   // SymbolInfoDouble(NULL,SYMBOL_ASK);
         trReq.sl=tick.ask-_Point*sl;            // Stop Loss level of the order
         trReq.tp=tick.ask+_Point*tp;            // Take Profit level of the order
         trReq.type=ORDER_TYPE_BUY;  // Order type        
         OrderSend(trReq,trRez);  //zawieramy transakcje kupna
         transakcjaB =1;
        }
      //warunek sprawdzajcy czy aktualna cena jest nizsza niż obie średnie
      else if((actualPrice<bigAverageBuffer[1] && actualPrice<smallAverageBuffer[1])&& (transakcjaS==0)) {
         trReq.price=tick.bid;
         trReq.sl=tick.bid+_Point*sl;            // Stop Loss level of the order
         trReq.tp=tick.bid-_Point*tp;            // Take Profit level of the order
         trReq.type=ORDER_TYPE_SELL;             // Order type
        OrderSend(trReq,trRez);  //zawieramy transkacje sprzedaży
        
          transakcjaS =1;  
        }
        // w przypadku zejścia poniżej jakiejkolwiek średniej zamykamy transakcje kupna (nie działa to jeszcze tak jak powinno
        //poprawię do 31.05 (Marcin C.)
      else if((actualPrice<bigAverageBuffer[1] || actualPrice<smallAverageBuffer[1])&&(transakcjaB==1)) { 
      trade.PositionClose(Symbol());
      transakcjaB =0;
      }
         // w przypadku zejścia powyżej jakiejkolwiek średniej zamykamy transakcje sprzedaży (nie działa to jeszcze tak jak powinnno
        //poprawię do 31.05 (Marcin C.)
     else if((actualPrice>bigAverageBuffer[1] || actualPrice>smallAverageBuffer[1])&&(transakcjaS==1)) {
      trade.PositionClose(Symbol());
        transakcjaS =0; 
     }
     }
     
  }
//+------------------------------------------------------------------+
