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
   public:
       double Sum(double value, double pts);
       double Subtract(double value, double pts);
       double GetPoints(double price1, double price2);
       double GetAverage(double price1, double price2);
};

//+------------------------------------------------------------------+
//| Calculate loss or profits                                        |
//+------------------------------------------------------------------+
double ATTPrice::Sum(double price=0.0, double pts=0.0) {

   // General declaration   
   double value = 0.0;
   double points = 0.0;
   double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   ulong digits = SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
   
   // Calculate the points
   if (digits == 0) {
      points = pts * Point();
   } else {
      points = pts / Digits();
   }
   
   // Calculate value based on given points
   value = NormalizeDouble(price + points, Digits());

   // Normalize the final value according to the tick size   
   if (digits == 0) {
      while (MathMod(value, tickSize) > 0) {
         value = NormalizeDouble(value + Point(), Digits());
      }              
   }  
   
   // Just return
   return value;
}

double ATTPrice::Subtract(double price=0.0, double pts=0.0) {

   // General declaration   
   double value = 0.0;
   double points = 0.0;
   double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   ulong digits = SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);   

   // Calculate the points
   if (digits == 0) {
      points = pts * Point();
   } else {
      points = pts / Digits();
   }

   // Calculate value based on given points
   value = NormalizeDouble(price - points, Digits());

   // Normalize the final value according to the tick size   
   if (digits == 0) {
      while (MathMod(value, tickSize) > 0) {
         value = NormalizeDouble(value - Point(), Digits());
      }
   }
   
   // Just return
   return value;
}

double ATTPrice::GetPoints(double price1, double price2) {

   // General declaration   
   double value = 0.0;
   ulong digits = SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);

   // Normalize the final value according to the tick size   
   if (digits == 0) {
      value = MathAbs(price1 - price2) * Point();
   }
   
   if (digits == 5) {
      value = MathAbs(price1 - price2) / Point();
   }   
   
   value = NormalizeDouble(value, Digits());
   
   // Just return
   return value;
}

double ATTPrice::GetAverage(double price1, double price2) {
   double value = 0.0;
   value = (price1 + price2) / 2;  
   value = NormalizeDouble(value, Digits());   
   return value;
}
