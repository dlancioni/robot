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
       double GetBidOrAsk(const string symbol, const string bidOrAsk);
   public:
       double GetBid(const string symbol);
       double GetAsk(const string symbol);
       double GetPrice(const string buyOrSell, double price, double pts);
};

//+------------------------------------------------------------------+
//| Get online prices                           |
//+------------------------------------------------------------------+
double ATTPrice::GetBid(const string symbol) {
   return ATTPrice::GetBidOrAsk(symbol, "BID");
}
double ATTPrice::GetAsk(const string symbol) {
   return ATTPrice::GetBidOrAsk(symbol, "ASK");
}

//+------------------------------------------------------------------+
//| Core logic to open and close positions at market price           |
//+------------------------------------------------------------------+
double ATTPrice::GetBidOrAsk(const string symbol, const string bidOrAsk) {

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

//+------------------------------------------------------------------+
//| Calculate loss or profits                                        |
//+------------------------------------------------------------------+
double ATTPrice::GetPrice(const string buyOrSell="", double price=0.0, double pts=0.0) {

   double value = 0.0;
      
   if (buyOrSell == "B") {
      value=NormalizeDouble(price+(pts*_Point), _Digits);
   } else {
      value=NormalizeDouble(price-(pts*_Point), _Digits);   
   }
   
   return value;
}