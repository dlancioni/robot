#include <Trade\Trade.mqh>
#include "ATTDef.mqh"

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
class ATTValidator {
   private:
      string ValidateAmount(double);
      string ValidatePointsToTrade(double);
      string ValidateStops(_TRAIL_STOP, double, double);
      string ValidateDailyLimits(double, double);      
   public:
      string ValidateParameters(double, double, double, double, _TRAIL_STOP, double, double);   

};

//+------------------------------------------------------------------+
//| Validate all input parameter                                     |
//+------------------------------------------------------------------+
string ATTValidator::ValidateParameters(double amount, double pointsToTrade, double pointsLoss, double pointsProfit, _TRAIL_STOP trailStop, double loss, double profit) {
   
   string value = "";
   
   // Validate the ammount
   value = ATTValidator::ValidateAmount(amount);

   // Validate the ammount
   value = ATTValidator::ValidatePointsToTrade(pointsToTrade);
  
   // Validate the stops
   value = ATTValidator::ValidateStops(trailStop, pointsLoss, pointsProfit);
   
   return value;
}

//+------------------------------------------------------------------+
//| Validate the amount                                              |
//+------------------------------------------------------------------+
string ATTValidator::ValidateAmount(double amount) {

   string value = "";
   
   if (amount > 1)
      value = "This service is free for small investments, to trade unlimited contracts consider support this project. Email dlancioni@gmail.com for details ";
      
   if (amount <= 0)
      value = "Must inform number of contracts (amount)";

   return value;
}

//+------------------------------------------------------------------+
//| Validate the amount                                              |
//+------------------------------------------------------------------+
string ATTValidator::ValidatePointsToTrade(double pointsToTrade) {

   string value = "";
      
   if (pointsToTrade < 0)
      value = "Points to trade cannot be negative";

   return value;
}

//+------------------------------------------------------------------+
//| Validate the stops                                               |
//+------------------------------------------------------------------+
string ATTValidator::ValidateStops(_TRAIL_STOP trailStop, double pointsLoss, double pointsProfit) {

   string value = "";
      
   if (pointsLoss <= 0)
      value = "StopLoss is mandatory";
      
   if (pointsProfit < 0)
      value = "TakeProfit is mandatory";
      
   if (trailStop == _TRAIL_STOP::PROFIT || trailStop == _TRAIL_STOP::BOTH) {
      if (pointsProfit > 0) {
         if (pointsProfit < (pointsLoss * 3)) {
            value = "Trailing stop profit is selected, points profit must be at least 3 x greater than points loss or zero for unlimited profit";
         }
      }
   }

   return value;
}

//+------------------------------------------------------------------+
//| Validate the stops                                               |
//+------------------------------------------------------------------+
string ATTValidator::ValidateDailyLimits(double loss, double profit) {

   string value = "";
      
   if (loss <= 0)
      value = "Daily loss value is mandatory";
      
   if (profit <= 0)
      value = "Daily profit value is mandatory";

   return value;
}