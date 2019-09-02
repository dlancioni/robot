//+------------------------------------------------------------------+
//|                                                     ATTIndicator.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Pricing related methods (bid/ask, gain/loss, etc                 |
//+------------------------------------------------------------------+
class ATTIndicator {
   private:

   public:
       double CalculateMovingAvarage
       (
           const string symbol,              // EURUSD, WDOQ19, etc
           ENUM_TIMEFRAMES timeFrame,        // M1, M5, M15, etc
           int periods,                      // Number of periods/candles (1, 2, 10, 50 etc)
           int period,                       // MAVG at specific period/candle from right to left
           ENUM_MA_METHOD method,            // Simple, Exponential, etc
           ENUM_APPLIED_PRICE appliedPrice   // Open Price, Close Price (default), etc
       );
};

//+------------------------------------------------------------------+
//| Core logic to open and close positions at market price           |
//+------------------------------------------------------------------+
double ATTIndicator::CalculateMovingAvarage(const string symbol,
                                            ENUM_TIMEFRAMES timeFrame,
                                            int periods,
                                            int period=1, // most recent candle
                                            ENUM_MA_METHOD method = MODE_EMA,
                                            ENUM_APPLIED_PRICE appliedPrice = PRICE_CLOSE) {

   // General Declaration
   double movingAvarage[];
   double value = 0.0;
   int startingPeriod = 0;

   // Get MA definition
   int movingAvarageDefinition = iMA(symbol, timeFrame, periods, startingPeriod, method, appliedPrice);      
   
   // Set the ma for each candle
   CopyBuffer(movingAvarageDefinition, 0, startingPeriod, periods, movingAvarage);
              
   // Get the final result
   value = NormalizeDouble(movingAvarage[periods-period], _Digits);

   // Return current price
   return value;
}

