//+------------------------------------------------------------------+
//|                                                    SST-Final.mq5 |
//|                                         Copyright 2018, SST Team |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, SST Team"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>


MqlTradeRequest trReq;
MqlTradeResult trRez;
MqlRates cwel[];
CPositionInfo position;
CTrade trade;


//trade.LogLevel(LOG_LEVEL_ALL);
//trade.SetExpertMagicNumber(69696660);
//trade.SetDeviationInPoints(1000);
//trade.SetTypeFilling(ORDER_FILLING_IOC);
//trade.SetTypeFillingBySymbol
 
 
int shortPeriods=5;
int longPeriods=25;



int smallAverage;
int bigAverage;
double smallAverageBuffer[]; //krótka średnia
double bigAverageBuffer[];  //długa średnia
double actualPrice;    // aktualna cena
double actualPriceBid;


int k=0;
int sl=200; // stopLoss
int tp=100; //takeProfit
int MAGIC=6969666;
int transakcjaS=0;  //zmienna określająca zawarcie transakcji sprzedzazy
int transakcjaB=0;  // zmienna okreslajaca zawarcie transakcji kupna
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   smallAverage=iMA(Symbol(),PERIOD_M15,shortPeriods,0,MODE_LWMA,PRICE_WEIGHTED);   //obliczanie krótkiej średniej
   bigAverage=iMA(Symbol(),PERIOD_M15,longPeriods,0,MODE_LWMA,PRICE_WEIGHTED); //obliczanie długiej średniej
   trade.LogLevel(LOG_LEVEL_ALL);
   ZeroMemory(trReq);
   ZeroMemory(trRez);
//---- set default vaules for all new order requests
   trReq.action=TRADE_ACTION_DEAL;
   trReq.magic=MAGIC;
   trReq.symbol=Symbol();                 // Trade symbol
   trReq.volume=0.3;                      // Requested volume for a deal in lots
   trReq.deviation=100;                     // Maximal possible deviation from the requested price
   
  

//--- create timer
  // EventSetTimer(60);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   MqlTick tick;
   
      ArraySetAsSeries(cwel,true);
   int chuj=CopyRates(Symbol(),PERIOD_M15,0,Bars(Symbol(),Period()),cwel); // Copied all datas
   double pr0_close= cwel[0].close;
   double pr1_close= cwel[1].close;        // cwel[1].high,cwel[1].open for high
   datetime t1 = cwel[1].time;
   
   if(!SymbolInfoTick(Symbol(),tick)) {
      Print("Failed to get Symbol info!");
      return;
     }
   
   int copied=CopyBuffer(smallAverage,0,0,shortPeriods,smallAverageBuffer);
   Print(smallAverage);
   if(copied>0) {
      copied=CopyBuffer(bigAverage,0,0,longPeriods,bigAverageBuffer);
      Print(bigAverage);
    }
   
   if(k==500) {
      actualPrice=pr0_close; //przypisanie aktualnej ceny
      actualPriceBid=pr0_close;
      k=0;
   } k++;
   
   
   if(actualPrice>bigAverageBuffer[0] && actualPrice>smallAverageBuffer[0] && transakcjaB==0 && PositionsTotal()==0) {
         trReq.price=tick.ask;
         trReq.sl=tick.ask-_Point*sl;
         trReq.tp=tick.ask+_Point*tp;
         trReq.type=ORDER_TYPE_BUY;
         trade.OrderSend(trReq,trRez);
         for(int i=PositionsTotal()-1;i>=0;i--)
            if(position.SelectByIndex(i))
               if(position.Symbol()==Symbol())
                  trade.PositionModify(Symbol(),0,0);
         transakcjaB=1;
         
   } else if(actualPrice<bigAverageBuffer[0] && actualPrice<smallAverageBuffer[0] && transakcjaS==0 && PositionsTotal()==0) {
         trReq.price=tick.bid;
         trReq.sl=tick.bid+_Point*sl;
         trReq.tp=tick.bid-_Point*tp;
         trReq.type=ORDER_TYPE_SELL;
         trade.OrderSend(trReq,trRez);
         for(int i=PositionsTotal()-1;i>=0;i--)
            if(position.SelectByIndex(i))
               if(position.Symbol()==Symbol())
                  trade.PositionModify(Symbol(),0,0);
         transakcjaS=1;
          
   } else if((actualPriceBid<bigAverageBuffer[0] || actualPriceBid<smallAverageBuffer[0])&&(transakcjaB==1)) { 
         for(int i=PositionsTotal()-1;i>=0;i--)
            if(position.SelectByIndex(i))
               if(position.Symbol()==Symbol())
                  trade.PositionClose(position.Ticket(),-1);
         transakcjaB =0;
   } else if((actualPrice>bigAverageBuffer[0] || actualPrice>smallAverageBuffer[0])&&(transakcjaS==1)) {
         for(int i=PositionsTotal()-1;i>=0;i--)
            if(position.SelectByIndex(i))
               if(position.Symbol()==Symbol())
                  trade.PositionClose(position.Ticket(),-1);
         transakcjaS =0;
      }
     
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
 
   
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| TesterInit function                                              |
//+------------------------------------------------------------------+
void OnTesterInit()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| TesterPass function                                              |
//+------------------------------------------------------------------+
void OnTesterPass()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| TesterDeinit function                                            |
//+------------------------------------------------------------------+
void OnTesterDeinit()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
//---
   
  }
//+------------------------------------------------------------------+
