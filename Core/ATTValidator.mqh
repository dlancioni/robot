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
      string ValidateExpired();
      string ValidateAmount(double);
      string ValidatePointsToTrade(double);
      string ValidateStops(double, double, double);
      string ValidateDailyLimits(double, double);
   public:
      string ValidateParameters(double, double, double, double, double, double, double, double, double);   

};

//+------------------------------------------------------------------+
//| Validate all input parameter                                     |
//+------------------------------------------------------------------+
string ATTValidator::ValidateParameters(double amount, double pointsToTrade, double pointsLoss, double pointsProfit, double trailingLoss, double tralingProfit, double tralingProfitStep, double dailyLoss, double dailyProfit) {
   
   string value = "";

   // Validate the ammount
   if (value == "")
      value = ATTValidator::ValidateExpired();
   
   // Validate the ammount
   if (value == "")
      value = ATTValidator::ValidateAmount(amount);

   // Validate the ammount
   if (value == "")   
      value = ATTValidator::ValidatePointsToTrade(pointsToTrade);
  
   // Validate the stops
   if (value == "")   
      value = ATTValidator::ValidateStops(trailingLoss, tralingProfit, tralingProfitStep);

   // Validate daily limits
   if (value == "")         
      value = ValidateDailyLimits(dailyLoss, dailyProfit);      
   
   return value;
}

//+------------------------------------------------------------------+
//| Validate the amount                                              |
//+------------------------------------------------------------------+
string ATTValidator::ValidateExpired() {

   string value = "";
   MqlDateTime time;
   TimeCurrent(time);
   
   if (time.mon == 1) {
      value = "This version of Atom has expired at 12/31/19. Get latest version at github.com/dlancioni/atom";
   }   

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
string ATTValidator::ValidateStops(double trailingLoss, double tralingProfit, double tralingProfitStep) {

   string value = "";
      
   if (trailingLoss < 0) {
      value = "Points stop loss is mandatory";
   }

   if (tralingProfit > 0) {
      if (tralingProfitStep <= 0) {
         value = "TakeProfit is mandatory";
      }      
   }
   
   if (tralingProfitStep > tralingProfit)    {
         value = "Trailing profit step cannot be greater than trailing stop";   
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