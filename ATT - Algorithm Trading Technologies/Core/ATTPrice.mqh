//+------------------------------------------------------------------+
//|                                                     ATTPrice.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Pricing related methods (bid/ask, gain/loss, etc                 |
//+------------------------------------------------------------------+
class ATTPrice {
   private:
       double GetPrice(const string symbol, const string bidOrAsk);
   public:
       double GetBid(const string symbol);
       double GetAsk(const string symbol);
       double GetStopLoss(double price, double points);
       double GetTakeProfit(double price, double points);
};

//+------------------------------------------------------------------+
//| Open or close position at market price                           |
//+------------------------------------------------------------------+
double ATTPrice::GetBid(const string symbol) {
   return ATTPrice::GetPrice(symbol, "BID");
}
double ATTPrice::GetAsk(const string symbol) {
   return ATTPrice::GetPrice(symbol, "ASK");
}
double ATTPrice::GetStopLoss(double price, double points) {
   return NormalizeDouble(price-(points*_Point), _Digits);
}
double ATTPrice::GetTakeProfit(double price, double points) {
   return NormalizeDouble(price+(points*_Point), _Digits);
}

//+------------------------------------------------------------------+
//| Core logic to open and close positions at market price           |
//+------------------------------------------------------------------+
double ATTPrice::GetPrice(const string symbol, const string bidOrAsk) {

   // General Declaration
   double price = 0.0;
   
   // Trade when 1(buy) or 2(Sell), otherwise reteurn zero  
   if (bidOrAsk=="BID" || bidOrAsk=="ASK") {
   
       if (bidOrAsk == "BID") {
           price = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_BID), _Digits);
       } else {
           price = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_ASK), _Digits);
       }
   }
   
   // Return current price
   return price;
}

