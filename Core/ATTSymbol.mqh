#include <Trade\Trade.mqh>

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
class ATTSymbol {
   private:
   public:
      double Bid();
      double Ask();   
};

double ATTSymbol::Bid(void) {
   return SymbolInfoDouble(Symbol(),SYMBOL_BID);
}

double ATTSymbol::Ask(void) {
   return SymbolInfoDouble(Symbol(),SYMBOL_ASK);
}