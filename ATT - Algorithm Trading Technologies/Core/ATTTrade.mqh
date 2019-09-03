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
       ulong TradeAtMarketPrice(const string bs, const string symbol, double qtt, double price, double sl, double tp);
     
   public:
       ulong Buy(const string symbol, double qtt, double price, double sl, double tp);       
       ulong Sell(const string symbol, double qtt, double price, double sl, double tp);       
       
       void CloseAllPositions();
       ulong DeleteOrder(ulong tid);
       void CloseAllOrders();
       bool GetAccountType();
};

//+------------------------------------------------------------------+
//| Open or close position at market price                           |
//+------------------------------------------------------------------+
ulong ATTTrade::Buy(const string symbol=NULL, double qtt=0.0, double price=0.0, double sl=0.0, double tp=0.0) {
   return ATTTrade::TradeAtMarketPrice("BUY", symbol, qtt, price, sl, tp);
}
ulong ATTTrade::Sell(const string symbol=NULL, double qtt=0.0, double price=0.0, double sl=0.0, double tp=0.0) {
   return ATTTrade::TradeAtMarketPrice("SELL", symbol, qtt, price, sl, tp);
}

//+------------------------------------------------------------------+
//| Core logic to open and close positions at market price           |
//+------------------------------------------------------------------+
ulong ATTTrade::TradeAtMarketPrice(const string bs, const string symbol=NULL, double qtt=0.0, double price=0.0, double sl=0.0, double tp=0.0) {

   // General Declaration
   CTrade trade;   
   bool result = false;
   ulong tid = 0;
   string comment = "";
   
   // Trade when 1(buy) or 2(Sell), otherwise reteurn zero  
   if (bs=="BUY" || bs=="SELL") {
   
      // Buy or sell according
      if (bs=="BUY") {
         result = trade.BuyStop(qtt, price, symbol, sl, tp, ORDER_TIME_GTC);
      } else {
         result = trade.SellStop(qtt, price, symbol, sl, tp, ORDER_TIME_GTC);
      }

      // Check trading action
      if (result) {
         if (trade.ResultRetcode()==TRADE_RETCODE_DONE) {   
            tid = trade.ResultOrder();
         }
      }
   }
   
   // Return ticket id or zeros
   return tid;
}


//+------------------------------------------------------------------+
//| Close all open positions at market price                         |
//+------------------------------------------------------------------+
ulong ATTTrade::DeleteOrder(ulong tid) {
    CTrade trade;
    trade.OrderDelete(tid);
    return 0;
}

//+------------------------------------------------------------------+
//| Delete all pending orders                                        |
//+------------------------------------------------------------------+
void ATTTrade::CloseAllPositions() {

    // General Declaration
    CTrade trade;   
    ulong id = 0;

    // Close open positions
     for (int i=PositionsTotal()-1; i>=0; i--) {
	      id = PositionGetTicket(i);
	      trade.PositionClose(id);
     }   
}

//+------------------------------------------------------------------+
//| Close all open orders                                            |
//+------------------------------------------------------------------+
void ATTTrade::CloseAllOrders() {

    // General Declaration
    CTrade trade;   
    ulong id = 0;

    // Close open positions
     for (int i=OrdersTotal()-1; i>=0; i--) {
	      id = OrderGetTicket(i);
	      trade.OrderDelete(id);
     }   
}

bool ATTTrade::GetAccountType() {

    ENUM_ACCOUNT_TRADE_MODE tradeMode=(ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE); 

    //--- Find out the account type 
    switch(tradeMode) { 
       case(ACCOUNT_TRADE_MODE_DEMO): 
           Print("This is a demo account"); 
           break; 
       case(ACCOUNT_TRADE_MODE_CONTEST): 
           Print("This is a competition account"); 
           break; 
       default:
           Print("This is a real account!"); 
    } 
    
    return true;

}



