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
input double contracts = 1;            // Number of Contracts
input int shortPeriod = 1;             // Moving Avarage - Short
input int longPeriod = 2;              // Moving Avarage - Long
input ENUM_TIMEFRAMES chartTime = 5;   // Chart Time (M1, M5, M15)
input double points = 100;             // Default stop loss and trail unit. Price=1000, sl=900, tp=1100, 1200...
input double dailyLoss = 0;            // Daily loss limit (per contract) - zero for no limit
input double dailyProfit = 0;          // Daily profit limit (per contract) - zero for no limit

//
// General Declaration
//
ATTTrade _ATTTrade;
ATTPrice _ATTPrice;
ATTIndicator _ATTIndicator;
ATTBalance _ATTBalance;
ATTMath _ATTMath;

ulong orderIdBuy = 0;               // Current open ticket
ulong orderIdSell = 0;              // Current open ticket
double initialBalance = 0.0;        // Used to limit profit and loss in daily basis
string assetCode = "";              // Current asset on chart
string lastCross = "";              // Used to avoid calling trades on every cross
double priceDeal = 0;               // Current trade price   
double priceLoss = 0.0;             // Stop loss for current trade
double priceProfit = 0.0;           // Not used as trading checkpoints on profit

//
// Start and finish events
//
int OnInit() {

   // Current asset on chart
   assetCode = Symbol();

   // Used to limit profit and loss in daily basis
   initialBalance = _ATTBalance.GetBalance();

   // Go ahead
   return(INIT_SUCCEEDED);
}

//
// Something went wrong, lets stop everything
//
void OnDeinit(const int reason) {
    Alert(TimeCurrent(),": " ,__FUNCTION__," Reason code = ", reason); 
}

//
// Main loop
//
void OnTick() {

   double shortMovingAvarage = 0;   // Short moving avarage 
   double longMovingAvarage = 0;    // Long moving avarage
   double priceBid = 0.0;           // Current bid price
   double priceAsk = 0.0;           // Current ask price   


   // if result touch the limits - stop everything  
   if (_ATTBalance.IsResultOverLimits(initialBalance, dailyLoss, dailyProfit) == false) {

      // Get current prices
      priceBid = _ATTPrice.GetBid(assetCode);
      priceAsk = _ATTPrice.GetAsk(assetCode);

      // If no price, no deal (markets closed, or off-line)
      if (priceBid>0.0 || priceAsk>0.0) {
            
         // Calculate EMA for short and long period
         shortMovingAvarage = _ATTIndicator.CalculateMovingAvarage(assetCode, chartTime, shortPeriod);
         longMovingAvarage = _ATTIndicator.CalculateMovingAvarage(assetCode, chartTime, longPeriod);
         
         Print("Bid/Ask: ", priceBid, "/", priceAsk, " Avg S/L: ", shortMovingAvarage, "/ ", longMovingAvarage);
         
         // Strategy 1: open long positions after crossing
         TradeOnMovingAvarageCross(priceBid, priceAsk, shortMovingAvarage, longMovingAvarage);

      } else {
          Print("No price available");
      }
   } else {
       Print("Out of daily limits, please check pnl on history tab");
   }
}

//
// Open a position in favor of tendence and wait for the boom
//
void TradeOnMovingAvarageCross(double priceBid, double priceAsk, double shortMovingAvarage, double longMovingAvarage) {

   // General declaration
   bool crossUp = false;            // Start openning a position on current tendence
   bool crossDn = false;            // Start openning a position on current tendence
   double DINAMIC_PROFIT = 0;       // Profit is as great as the markets goes
   
   // Do not open more than one position at a time
   if (PositionsTotal() == 0) {
         
      // Control last cross   
      if ((shortMovingAvarage) > longMovingAvarage) {
         if (lastCross!="S") {
            crossUp=true;
            crossDn=false;
            lastCross="S";
            orderIdSell = _ATTTrade.CloseAllOrders();
         } 
      } else {
         if (lastCross!="L") {
            crossUp=false;
            crossDn=true;
            lastCross="L";
            orderIdBuy = _ATTTrade.CloseAllOrders();
         }
      }
     
      // Make sure we have only one order at a time
      if (OrdersTotal() == 0) {
      
         // Cross up, must cancel short orders and open long orders   
         if (crossUp) {
         
            if (orderIdSell == 0) {
               priceProfit = 0.0;
               priceDeal = _ATTPrice.Sum(priceAsk, points);
               priceLoss = _ATTPrice.Subtract(priceAsk, points);
               priceProfit = _ATTPrice.Sum(priceDeal, points);
               orderIdBuy = _ATTTrade.Buy(assetCode, contracts, priceDeal, priceLoss, DINAMIC_PROFIT);
            }
         }
      
         // Cross down, must cancel long orders and open short orders   
         if (crossDn) {      
            if (orderIdBuy == 0) {        
               priceProfit = 0.0;         
               priceDeal = _ATTPrice.Subtract(priceBid, points);
               priceLoss = _ATTPrice.Sum(priceBid, points);
               priceProfit = _ATTPrice.Subtract(priceDeal, points);
               orderIdSell = _ATTTrade.Sell(assetCode, contracts, priceDeal, priceLoss, DINAMIC_PROFIT);
            }
         }      
      }      
            
   } else {
      
      // Set take profit as stop loss (duplicate the target)      
      if (orderIdBuy>0) {            
         if (priceBid > priceProfit) {
            priceLoss = priceProfit;
            _ATTTrade.ModifyPosition(orderIdBuy, priceLoss, DINAMIC_PROFIT);
            priceProfit = _ATTPrice.Sum(priceProfit, points);
         }
      }

      if (orderIdSell>0) {
         if (priceAsk < priceProfit) {
            priceLoss = priceProfit;
            _ATTTrade.ModifyPosition(orderIdBuy, priceLoss, DINAMIC_PROFIT);
            priceProfit = _ATTPrice.Subtract(priceProfit, points);
         }      
      }
   }

}
