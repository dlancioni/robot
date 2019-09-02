#include "..\Core\ATTTrade.mqh"
#include "..\Core\ATTPrice.mqh"
#include "..\Core\ATTIndicator.mqh"
#include "..\Core\ATTBalance.mqh"

//+------------------------------------------------------------------+
//|                                                        algo1.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//
// Define input parameters (comments are labels)
//
input string assetCode = "WINV19";     // Asset Code
input double contracts = 1;            // Number of Contracts
input int shortPeriod = 1;             // Moving Avarage - Short
input int longPeriod = 5;              // Moving Avarage - Long
input ENUM_TIMEFRAMES chartTime = 5;   // Chart Time (M1, M5, M15)
input double factor = 50;              // Trigger trades when (short avarage + factor) crosses the longer avarage. 
input double pointsLoss = 50;          // Default stop loss
input double pointsProfit = 150;       // Default stop gain
input double dailyLoss = 200;          // Daily loss limit (per contract)
input double dailyProfit = 100;        // Daily profit limit (per contract)

//
// General Declaration
//
double priceBid = 0.0;           // Current bid price
double priceAsk = 0.0;           // Current ask price
bool buyPositionIsOpen = false;  // Control if we have open bought position
bool sellPositionIsOpen = false; // Control if we have open sold position
double shortMovingAvarage = 0;   // Short moving avarage 
double longMovingAvarage = 0;    // Long moving avarage
double priceLoss = 0.0;           // Stop loss for current trade
double priceProfit = 0.0;         // Profit value for current trade

ATTTrade _ATTTrade;
ATTPrice _ATTPrice;
ATTIndicator _ATTIndicator;
ATTBalance _ATTBalance;

//
// Start and finish events
//
int OnInit() 
{   
    return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
    Print(TimeCurrent(),": " ,__FUNCTION__," Reason code = ", reason); 
}

//
// Main loop
//
void OnTick()
{
   // Get current prices
   priceBid = _ATTPrice.GetBid(assetCode);
   priceAsk = _ATTPrice.GetAsk(assetCode);
   
   // If no price, something is wrong - stop everything
   if (priceBid==0.0 || priceAsk==0.0) {
      ExpertRemove();
      Alert("No price available for ", assetCode, ". Exiting program");
   }
   
   // if result touch the limits - stop everything
   if (_ATTBalance.IsResultOverLimits(dailyLoss, dailyProfit)) {
      ExpertRemove();
      Alert("Daily limits were achieved");
   }

   // Calculate EMA for short and long period
   shortMovingAvarage = _ATTIndicator.CalculateMovingAvarage(assetCode, chartTime, shortPeriod);
   longMovingAvarage = _ATTIndicator.CalculateMovingAvarage(assetCode, chartTime, longPeriod);
   
   // Handle crossing up
   if ((shortMovingAvarage+factor) > longMovingAvarage) {
   
      // Close current position
      if (sellPositionIsOpen == true) {
         _ATTTrade.CloseAllPositions();
         sellPositionIsOpen = false;
      }
      
      // Open long position
      if (buyPositionIsOpen == false) {
      
         priceLoss = _ATTPrice.GetStopLoss(priceAsk, pointsLoss);
         priceProfit = _ATTPrice.GetTakeProfit(priceBid, pointsProfit);
               
         _ATTTrade.Buy(assetCode, contracts, priceLoss, priceProfit);
         buyPositionIsOpen = true;
      }      
   } 
   
   // Handle crossing down
   if (((shortMovingAvarage+factor)) < longMovingAvarage) {
   
      // Close current position
      if (buyPositionIsOpen == true) {
         _ATTTrade.CloseAllPositions();
         buyPositionIsOpen = false;
      }

      // Open long position
      if (sellPositionIsOpen == false) {     
      
         priceLoss = _ATTPrice.GetStopLoss(priceBid, pointsLoss);
         priceProfit = _ATTPrice.GetTakeProfit(priceAsk, pointsProfit);
      
         _ATTTrade.Sell(assetCode, contracts, priceLoss, priceProfit);
         sellPositionIsOpen = true;
      }
   }

}

