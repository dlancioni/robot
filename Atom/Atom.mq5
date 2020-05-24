#include "..\Core\ATTOrder.mqh"
#include "..\Core\ATTPrice.mqh"
#include "..\Core\ATTIndicator.mqh"
#include "..\Core\ATTBalance.mqh"
#include "..\Core\ATTMath.mqh"
#include "..\Core\ATTDef.mqh"
#include "..\Core\ATTPosition.mqh"
#include "..\Core\ATTSymbol.mqh"
#include "..\Core\ATTValidator.mqh"

//+------------------------------------------------------------------------------------------------------+
//| atom.mq5                                                                                             |
//| Author David Lancioni 05/2020                                                                        |
//| https://www.mql5.com                                                                                 |
//| Crossover strategy                                                                                   |
//+------------------------------------------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//
// Define input parameters (comments are labels)
//
input string RiskInfo = "----------";       // Risk Info
input double _dailyLoss = 0;                // Daily loss limit
input double _dailyProfit = 0;              // Daily profit limit
input string ChartInfo = "----------";      // Strategy setup for crossover
input ENUM_TIMEFRAMES _chartTime = 1;       // Chart time
input int _shortAvg = 0;                    // Short moving avarage
input int _longAvg = 0;                     // Long moving avarage
input double _diffAvg = 0;                  // Averages difference to open position
input string TradeInfo = "----------";      // Trade Info 
input double _contracts = 0;                // Number of Contracts
input double _pointsLoss = 0;               // Points stop loss (zero close on cross)
input double _pointsProfit = 0;             // Points take profit
input double _pointsTrade = 0;              // Points after current price to open trade
input string Trailing = "----------";       // Trailing info 
input double _trailingLoss = 0;             // Points to trail stop loss
input double _tralingProfit = 0;            // Points to trigger dinamic stop profit
input double _tralingProfitStep = 0;        // Points to trail take profit


//
// General Declaration
//
ATTOrder __ATTOrder;
ATTPrice __ATTPrice;
ATTSymbol __ATTSymbol;
ATTBalance __ATTBalance;
ATTPosition __ATTPosition;
ATTIndicator __ATTIndicator;  
ATTValidator __ATTValidator;
ATTMath __ATTMath;
string cross = "";
string lastCross = "";

//
// Init the values
//
int OnInit() {

   string msg = "";
   
   // Validate input parameters related to trade and abort program if something is wrong
   msg = __ATTValidator.ValidateParameters(_dailyLoss, 
                                           _dailyProfit,
                                           _contracts, 
                                           _pointsTrade, 
                                           _pointsLoss,
                                           _pointsProfit, 
                                           _trailingLoss, 
                                           _tralingProfit, 
                                           _tralingProfitStep,
                                           _shortAvg,
                                           _longAvg,
                                           _diffAvg);
   if (msg != "") {
      Print(msg);
      Alert(msg);
      ExpertRemove();
   }  

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
void OnTick() {

   double bid = 0.0;         // Current bid price 
   double ask = 0.0;         // Current ask price
  
   // Get prices   
   bid = __ATTSymbol.Bid();
   ask = __ATTSymbol.Ask();

   // If no price, no deal (markets closed, or off-line)
   if (bid > 0 && ask > 0) {
      if (!__ATTBalance.IsResultOverLimits(_dailyLoss, _dailyProfit)) {
         tradeCrossoverStrategy();
      }
   } else {
       Print("No price available");
   }
}

//
// Open position as indicators are attended
//
void tradeCrossoverStrategy() {

   // General declaration
   const string UP = "UP";
   const string DN = "DN";
   
   bool buy = false;
   bool sell = false;   
   ulong orderId = 0;
   double price = 0;
   double sl = 0;
   double tp = 0;
   double shortAvg = 0;
   double longAvg = 0;
   double diffAvg = 0;
   
   // Get avgs and calculate difference
   shortAvg = __ATTIndicator.CalculateMovingAvarage(Symbol(), _chartTime, _shortAvg);
   longAvg = __ATTIndicator.CalculateMovingAvarage(Symbol(), _chartTime, _longAvg);
   diffAvg = MathAbs(__ATTMath.Subtract(longAvg, shortAvg));
   
   // Log current level:
   Comment("Diff: ", diffAvg, "  ", "Cross: ", lastCross);
   
   // Trade on support and resistence crossover
   if (shortAvg > longAvg) {
       if (diffAvg > _diffAvg) {
           cross = UP;
           buy = true;
           sell = false;
       }
   }  
   if (shortAvg < longAvg) {      
       if (diffAvg > _diffAvg) {
          cross = DN;
          buy = false;
          sell = true;
       }
   }

   // Trade on cross only
   if (lastCross != cross) {
      lastCross = cross;
   } else {
      buy = false;
      sell = false;   
   }

   // True indicates a trade signal was identified
   if (buy || sell) {
      __ATTOrder.CloseAllOrders();
      __ATTPosition.CloseAllPositions();
   } else {
      buy = false;
      sell = false;
   }

   // Do not open more than one position at a time
   if (PositionsTotal() == 0) {
      if (buy) {
         price = __ATTPrice.Sum(__ATTSymbol.Ask(), _pointsTrade);
         sl = __ATTPrice.Subtract(price, _pointsLoss);
         tp = __ATTPrice.Sum(price, _pointsProfit);
         orderId = __ATTOrder.Buy(_ORDER_TYPE::MARKET, Symbol(), _contracts, price, sl, tp);
      }
      if (sell) {
         price = __ATTPrice.Subtract(__ATTSymbol.Bid(), _pointsTrade);
         sl = __ATTPrice.Sum(price, _pointsLoss);
         tp = __ATTPrice.Subtract(price, _pointsProfit);
         orderId = __ATTOrder.Sell(_ORDER_TYPE::MARKET, Symbol(), _contracts, price, sl, tp);
      }
   } else {
       __ATTPosition.TrailStop(_pointsLoss, _trailingLoss, _tralingProfit, _tralingProfitStep);
   }
}
