#include "..\Core\ATTTrade.mqh"
#include "..\Core\ATTPrice.mqh"
#include "..\Core\ATTIndicator.mqh"

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
input int shortPeriod = 13;             // Moving Avarage - Short
input int longPeriod = 26;              // Moving Avarage - Long
input ENUM_TIMEFRAMES chartTime = 5;   // Chart Time (M1, M5, M15)
input double factor = 1.01;            // Avoid crossing all time 

//
// General Declaration
//
double priceBid = 0.0;           // Current bid price
double priceAsk = 0.0;           // Current ask price
bool buyPositionIsOpen = false;  // Control if we have open bought position
bool sellPositionIsOpen = false; // Control if we have open sold position
double shortMovingAvarage = 0;   // Short moving avarage 
double longMovingAvarage = 0;    // Long moving avarage
double stopLoss = 0.0;           // Stop loss for current trade
double takeProfit = 0.0;         // Profit value for current trade
int pointsLoss = 5;              // Default stop loss
int pointsGain = 50;             // Default stop gain

ATTTrade _ATTTrade;
ATTPrice _ATTPrice;
ATTIndicator _ATTIndicator;

//
// Start and finish events
//
int OnInit() 
{   
    return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
}

//
// Main loop
//
void OnTick()
{
   // Calculate current prices
   priceBid = _ATTPrice.GetBid(assetCode);
   priceAsk = _ATTPrice.GetAsk(assetCode);
   
   if (priceBid==0.0 || priceAsk==0.0) {
      Alert("No price available for ", assetCode, ". Exiting program");
      return;
   }

   // Calculate EMA for short and long period
   shortMovingAvarage = _ATTIndicator.CalculateMovingAvarage(assetCode, chartTime, shortPeriod);
   longMovingAvarage = _ATTIndicator.CalculateMovingAvarage(assetCode, chartTime, longPeriod);
   
   // Handle crossing up
   if ((shortMovingAvarage*factor) > longMovingAvarage) {
   
      // Close current position
      if (sellPositionIsOpen == true) {
         _ATTTrade.CloseAllPositions();
         sellPositionIsOpen = false;
      }
      
      // Open long position
      if (buyPositionIsOpen == false) {
      
         //stopLoss = _ATTPrice.GetStopLoss(priceAsk, pointsLoss);
         //takeProfit = _ATTPrice.GetTakeProfit(priceBid, pointsGain);      
               
         _ATTTrade.Buy(assetCode, contracts, 0.0, 0.0);
         buyPositionIsOpen = true;
      }      
   } 
   
   // Handle crossing down
   if (((shortMovingAvarage*factor)) < longMovingAvarage) {
   
      // Close current position
      if (buyPositionIsOpen == true) {
         _ATTTrade.CloseAllPositions();
         buyPositionIsOpen = false;
      }

      // Open long position
      if (sellPositionIsOpen == false) {     
      
         //stopLoss = _ATTPrice.GetStopLoss(priceBid, pointsLoss);
         //takeProfit = _ATTPrice.GetTakeProfit(priceAsk, pointsGain);            
      
         _ATTTrade.Sell(assetCode, contracts, 0.0, 0.0);
         sellPositionIsOpen = true;
      }
   }

}

