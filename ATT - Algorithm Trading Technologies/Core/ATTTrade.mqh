#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//|                                                     ATTTrade.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Provide methods do open and close deals                          |
//+------------------------------------------------------------------+
class ATTTrade {
   private:
     ulong TradeAtMarketPrice(int bs, const string symbol, double qtt, double stopLoss, double takeProfit);
     
   public:
     ulong Buy(const string symbol, double qtt, double stopLoss, double takeProfit);
     ulong Sell(const string symbol, double qtt, double stopLoss, double takeProfit);
};

//+------------------------------------------------------------------+
//| Open or close position at market price                           |
//+------------------------------------------------------------------+
ulong ATTTrade::Buy(const string symbol=NULL, double qtt=0.0, double stopLoss=0.0, double takeProfit=0.0) {
   return ATTTrade::TradeAtMarketPrice(1, symbol, qtt, stopLoss, takeProfit);
}
ulong ATTTrade::Sell(const string symbol=NULL, double qtt=0.0, double stopLoss=0.0, double takeProfit=0.0) {
   return ATTTrade::TradeAtMarketPrice(2, symbol, qtt, stopLoss, takeProfit);
}

//+------------------------------------------------------------------+
//| Core logic to open and close positions at market price           |
//+------------------------------------------------------------------+
ulong ATTTrade::TradeAtMarketPrice(int bs=0, const string symbol=NULL, double qtt=0.0, double stopLoss=0.0, double takeProfit=0.0) {

   // General Declaration
   CTrade trade;   
   bool result = false;
   ulong ticketId = 0;
   string comment = "Pending comment yet";    
   
   // Trade when 1(buy) or 2(Sell), otherwise reteurn zero  
   if (bs == 1 || bs == 2) {
   
      // Buy or sell according
      if (bs == 1) {
         result = trade.Buy(qtt, symbol, 0.0, stopLoss, takeProfit, comment);
      } else {
         result = trade.Sell(qtt, symbol, 0.0, stopLoss, takeProfit, comment);   
      }
   
      // Check trading action
      if (result) {
         if (trade.ResultRetcode() == TRADE_RETCODE_DONE) {   
            ticketId = trade.ResultDeal();
         }
      }
   }
   
   // Return ticket id or zero
   return ticketId;
}

