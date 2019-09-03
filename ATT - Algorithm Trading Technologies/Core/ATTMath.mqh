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
class ATTMath {
   private:

   public:
       double Sum(double value1, double value2);
       double Subtract(double value1, double value2);

};

//+------------------------------------------------------------------+
//| Calculate and round decimal points                               |
//+------------------------------------------------------------------+
double ATTMath::Sum(double value1, double value2) {
   return NormalizeDouble(value1 + value2, _Digits);
}

double ATTMath::Subtract(double value1, double value2) {
   return NormalizeDouble(value1 - value2, _Digits);
}


