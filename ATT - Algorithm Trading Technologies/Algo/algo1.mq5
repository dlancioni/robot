#include "..\Core\ATTTrade.mqh"
#include "..\Core\ATTPrice.mqh"
#include "..\Core\ATTIndicator.mqh"
#include "..\Core\ATTBalance.mqh"
#include "..\Core\ATTMath.mqh"

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
input double dailyLoss = 200;          // Daily loss limit (per contract)
input double dailyProfit = 100;        // Daily profit limit (per contract)

//
// General Declaration
//
ATTTrade _ATTTrade;
ATTPrice _ATTPrice;
ATTIndicator _ATTIndicator;
ATTBalance _ATTBalance;
ATTMath _ATTMath;

ulong orderIdBuy = 0;             // Current open ticket
ulong orderIdSell = 0;            // Current open ticket
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

   double shortMovingAvarage = 0;   // Short moving avarage 
   double longMovingAvarage = 0;    // Long moving avarage
   double priceBid = 0.0;           // Current bid price
   double priceAsk = 0.0;           // Current ask price   

   // Get current prices
   priceBid = _ATTPrice.GetBid(assetCode);
   priceAsk = _ATTPrice.GetAsk(assetCode);
   
   // If no price, something is wrong - stop everything
   if (priceBid==0.0 || priceAsk==0.0) {
      ExpertRemove();
      Alert("No price available for ", assetCode, ". Exiting program");
   }

   // if result touch the limits - stop everything  
   if (_ATTBalance.IsResultOverLimits(initialBalance, dailyLoss, dailyProfit) == false) {

      // Do not open more than one position at a time
      if (PositionsTotal() == 0) {
         
         // Calculate EMA for short and long period
         shortMovingAvarage = _ATTIndicator.CalculateMovingAvarage(assetCode, chartTime, shortPeriod);
         longMovingAvarage = _ATTIndicator.CalculateMovingAvarage(assetCode, chartTime, longPeriod);
         
         // Strategy 1: open long positions after crossing
         TradeOnCrossing(priceBid, priceAsk, shortMovingAvarage, longMovingAvarage);     
      }
   }
   
}

void TradeOnCrossing(double priceBid, double priceAsk, double shortMovingAvarage, double longMovingAvarage) {

   // General declaration
   double price = 0;
   double priceLoss = 0.0;          // Stop loss for current trade
   double priceProfit = 0.0;        // Profit value for current trade

   // Crossing up
   if ((shortMovingAvarage) > longMovingAvarage) {

      orderIdSell = _ATTTrade.DeleteOrder(orderIdSell);      
      if (orderIdBuy == 0 && orderIdSell == 0) {
         price = _ATTMath.Sum(priceAsk, factor*2);
         priceLoss = _ATTMath.Subtract(priceBid, factor*1);
         priceProfit = _ATTMath.Sum(priceBid, factor*3);
         orderIdBuy = _ATTTrade.Buy(assetCode, contracts, price, priceLoss, priceProfit);
      }
   } 

   // Handle crossing down
   if (((shortMovingAvarage)) < longMovingAvarage) {
   
      _ATTTrade.DeleteOrder(orderIdBuy);      
      if (orderIdBuy == 0 && orderIdSell == 0) {            
         price = _ATTMath.Subtract(priceBid, factor*2);
         priceLoss = _ATTMath.Sum(priceAsk, factor*1);
         priceProfit = _ATTMath.Subtract(priceAsk, factor*3);
         orderIdSell = _ATTTrade.Sell(assetCode, contracts, price, priceLoss, priceProfit);
      }
   }
}
