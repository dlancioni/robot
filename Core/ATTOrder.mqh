#include <Trade\Trade.mqh>
#include "ATTDef.mqh"

// https://www.mql5.com/pt/docs/standardlibrary/tradeclasses/ctrade

//+------------------------------------------------------------------+
//|                                                     ATTOrder.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Provide methods do open and close deals                          |
//+------------------------------------------------------------------+
class ATTOrder : public CTrade {
   private:
       ulong Order(_ORDER_TYPE type, string, string, double, double, double, double, ENUM_ORDER_TYPE_TIME, datetime);
     
   public:  
       ulong Buy(_ORDER_TYPE , string, double, double, double, double, ENUM_ORDER_TYPE_TIME, datetime);
       ulong Sell(_ORDER_TYPE , string, double, double, double, double, ENUM_ORDER_TYPE_TIME, datetime);
       bool AmmendOrder(ulong , double, double, double);

       ulong CloseAllOrders();
       ulong OrderCount(string);
};

//+------------------------------------------------------------------+
//| Open or close position at market price                           |
//+------------------------------------------------------------------+
ulong ATTOrder::Buy(_ORDER_TYPE type, const string symbol=NULL, double qtt=0.0, double price=0.0, double sl=0.0, double tp=0.0, ENUM_ORDER_TYPE_TIME expireType=ORDER_TIME_GTC, datetime expireTime=0) {
   return ATTOrder::Order(type, "BUY", symbol, qtt, price, sl, tp, expireType, expireTime);
}
ulong ATTOrder::Sell(_ORDER_TYPE type, const string symbol=NULL, double qtt=0.0, double price=0.0, double sl=0.0, double tp=0.0, ENUM_ORDER_TYPE_TIME expireType=ORDER_TIME_GTC, datetime expireTime=0) {
   return ATTOrder::Order(type, "SELL", symbol, qtt, price, sl, tp, expireType, expireTime);
}

//+------------------------------------------------------------------+
//| Core logic to open and close positions at market price           |
//+------------------------------------------------------------------+
ulong ATTOrder::Order(_ORDER_TYPE type, const string bs, const string symbol=NULL, double qtt=0.0, double price=0.0, double sl=0.0, double tp=0.0, ENUM_ORDER_TYPE_TIME expireType=ORDER_TIME_GTC, datetime expireTime=0) {

   // General Declaration
   bool result = false;
   ulong tid = 0;
   string comment = "";
   CTrade trade;
   
   // Trade when 1(buy) or 2(Sell), otherwise reteurn zero  
   if (bs=="BUY" || bs=="SELL") {   
   
      
      ATTOrder::SetTypeFilling(ENUM_ORDER_TYPE_FILLING::ORDER_FILLING_FOK);
   
      switch (type) {
      
         case _ORDER_TYPE::STOP:         
         
            if (bs=="BUY") {
               result = ATTOrder::BuyStop(qtt, price, symbol, sl, tp, expireType, expireTime, comment);
            } else {
               result = ATTOrder::SellStop(qtt, price, symbol, sl, tp, expireType, expireTime, comment);
            }
            break;
         
         case _ORDER_TYPE::LIMIT:         
         
            if (bs=="BUY") {
               result = ATTOrder::BuyLimit(qtt, price, symbol, sl, tp, expireType, expireTime, comment);
            } else {
               result = ATTOrder::SellLimit(qtt, price, symbol, sl, tp, expireType, expireTime, comment);
            }
            break;
         
         case _ORDER_TYPE::MARKET:
         
            if (bs=="BUY") {
               result = trade.Buy(qtt, symbol, price, sl, tp, comment);
            } else {
               result = trade.Sell(qtt, symbol, price, sl, tp, comment);
            }
            break;         
      }


      // Check trading action
      if (result) {
         if (ATTOrder::ResultRetcode() == TRADE_RETCODE_DONE) {   
            tid = ATTOrder::ResultOrder();
         }
      }
   }
   
   // Return ticket id or zeros
   return tid;
}

//+------------------------------------------------------------------+
//| Modify existing order                                            |
//+------------------------------------------------------------------+
bool ATTOrder::AmmendOrder(ulong ticket, double price, double sl, double tp) {
   CTrade trade;
   return trade.OrderModify(ticket, price, sl, tp, 0, 0, 0);
}

//+------------------------------------------------------------------+
//| Close all open orders                                            |
//+------------------------------------------------------------------+
ulong ATTOrder::CloseAllOrders() {

    // General Declaration
    CTrade trade;
    ulong tid = 0;

    // Close open positions
     for (int i=OrdersTotal()-1; i>=0; i--) {     
	     tid = OrderGetTicket(i);	     
        if (OrderSelect(tid)) {        
           if (OrderGetString(ORDER_SYMBOL) == Symbol()) {
   	         trade.OrderDelete(tid);
  	        }  	        
        }
     }
     
     return 0;   
}

//+------------------------------------------------------------------+
//| Close all open orders                                            |
//+------------------------------------------------------------------+
ulong ATTOrder::OrderCount(string _symbol) {

    // General Declaration
    CTrade trade;
    ulong tid = 0;
    ulong count = 0;

    // Close open positions
     for (int i=OrdersTotal()-1; i>=0; i--) {     
	     tid = OrderGetTicket(i);	     
        if (OrderSelect(tid)) { 
           if (_symbol == "") {
               count++;
           } else {
              if (OrderGetString(ORDER_SYMBOL) == _symbol) {
      	         count++;
     	        }
  	        }
        }
     }
     return count;
}