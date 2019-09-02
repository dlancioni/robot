#include "..\Core\ATTTrade.mqh"
#include "..\Core\ATTPrice.mqh"
#include "..\Core\ATTIndicator.mqh"
#include "..\Core\ATTBalance.mqh"

//+------------------------------------------------------------------------------------------------------+
//| algo1.mq5                                                                                            |
//| Copyright 2019, MetaQuotes Software Corp.                                                            |
//| https://www.mql5.com                                                                                 |
//| Crossing up: If price is 100000, open a buy order at 100100, with loss on 100000 and gain on 100600  |
//| Crossing dn: If price is 100000, open a sell order at 99900, with loss on 100000 and gain on 99400   |
//| If there is a cross but no order is executed, existing order must be reverted                        |
//+------------------------------------------------------------------------------------------------------+
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
input double factor = 100;             // Points used to open future price order
input double pointsLoss = 100;          // Default stop loss
input double pointsProfit = 500;       // Default stop gain
input double dailyLoss = 200;          // Daily loss limit (per contract)
input double dailyProfit = 100;        // Daily profit limit (per contract)

//
// General Declaration
//
ATTTrade _ATTTrade;
ATTPrice _ATTPrice;
ATTIndicator _ATTIndicator;
ATTBalance _ATTBalance;

ulong orderIdBuy = 0;             // Current open ticket
ulong orderIdSell = 0;            // Current open ticket
double priceBid = 0.0;           // Current bid price
double priceAsk = 0.0;           // Current ask price
double shortMovingAvarage = 0;   // Short moving avarage 
double longMovingAvarage = 0;    // Long moving avarage
double priceLoss = 0.0;          // Stop loss for current trade
double priceProfit = 0.0;        // Profit value for current trade
double initialBalance = 0.0;     // Used to limit profit and loss in daily basis

//
// Start and finish events
//
int OnInit() {

    // Used to limit profit and loss in daily basis
    initialBalance = _ATTBalance.GetBalance();

    // Go ahead
    return(INIT_SUCCEEDED);
}

//
// Something went wrong, lets stop everything
//
void OnDeinit(const int reason) {
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
      //ExpertRemove();
      //Alert("No price available for ", assetCode, ". Exiting program");
   }

   // if result touch the limits - stop everything  
   if (_ATTBalance.IsResultOverLimits(initialBalance, dailyLoss, dailyProfit)) {
       //ExpertRemove();
       //Alert("Daily limits were achieved");
   }

   // Calculate EMA for short and long period
   shortMovingAvarage = _ATTIndicator.CalculateMovingAvarage(assetCode, chartTime, shortPeriod);
   longMovingAvarage = _ATTIndicator.CalculateMovingAvarage(assetCode, chartTime, longPeriod);
   
   // Crossing up
   if ((shortMovingAvarage) > longMovingAvarage) {

      orderIdSell = _ATTTrade.DeleteOrder(orderIdSell);      
      if (orderIdBuy == 0) {
         priceAsk = priceAsk + factor;
         priceLoss = _ATTPrice.GetStopLoss(priceAsk, pointsLoss);
         priceProfit = _ATTPrice.GetTakeProfit(priceBid, pointsProfit);
         orderIdBuy = _ATTTrade.Buy(assetCode, contracts, priceAsk, priceLoss, priceProfit);
      }
   } 

   // Handle crossing down
   if (((shortMovingAvarage)) < longMovingAvarage) {
   
      _ATTTrade.DeleteOrder(orderIdBuy);      
      if (orderIdSell == 0) {      
         priceBid = priceBid - factor;
         priceLoss = _ATTPrice.GetStopLoss(priceBid, pointsLoss);
         priceProfit = _ATTPrice.GetTakeProfit(priceAsk, pointsProfit);
         orderIdSell = _ATTTrade.Sell(assetCode, contracts, priceBid, priceLoss, priceProfit);
      }
   }

}

