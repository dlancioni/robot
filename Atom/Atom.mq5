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
input double _dailyProfit = 0;              // Daily profit limit
input double _dailyLoss = 0;                // Daily loss limit
input string TradeInfo = "----------";      // Trade Info 
input ENUM_TIMEFRAMES _chartTime = 1;       // Chart time
input double _contracts = 0;                // Number of Contracts
input double _pointsTrade = 0;              // Points after current price to open trade
input double _pointsLoss = 0;               // Points stop loss
input double _pointsProfit = 0;             // Points take profit
input double _tralingProfit = 0;            // Points to trigger dinamic stop profit
input double _tralingProfitStep = 0;        // Points to trail take profit
input double _trailingLoss = 0;             // Points to trail stop loss
input string CrossoverInfo = "----------";  // Crossover setup
input int _mavgShort = 0;                   // Short moving avarage
input int _mavgLong = 0;                    // Long moving avarage
input double _tradingLevel = 0;             // Minimum level to open positions

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
double initialBalance = 0.0;     // Used to limit profit and loss in daily basis

//
// Init the values
//
int OnInit() {

   string msg = "";

   // Used to limit profit and loss in daily basis
   initialBalance = __ATTBalance.GetBalance();
   
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
                                           _mavgShort,
                                           _mavgLong,
                                           _tradingLevel);
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
   double mid = 0.0;         // Avarage price to compare against avarages
  
   // Get prices   
   bid = __ATTSymbol.Bid();
   ask = __ATTSymbol.Ask();

   // If no price, no deal (markets closed, or off-line)
   if (bid > 0 && ask > 0) {
      if (!__ATTBalance.IsResultOverLimits(initialBalance, _dailyLoss, _dailyProfit)) {
         tradeCrossoverStrategy();
      } else {
         Print("Daily limits exceeded");
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
   ulong orderId = 0;
   bool buy = false;
   bool sell = false;   
   double priceDeal = 0;
   double priceLoss = 0.0;
   double priceProfit = 0.0;
   double mavgDiff = 0.0;
   double mavgShort = 0;     // Short moving avarage
   double mavgLong = 0;      // Long moving avarage
   double level = 0;         // Current support and resistence level (using wpr)   

   // Get avgs and calculate difference
   mavgShort = __ATTIndicator.CalculateMovingAvarage(Symbol(), _chartTime, _mavgShort);
   mavgLong = __ATTIndicator.CalculateMovingAvarage(Symbol(), _chartTime, _mavgLong);
   mavgDiff = MathAbs(__ATTMath.Subtract(mavgLong, mavgShort));
   
   // Log current level:
   Comment("Level: ", mavgDiff, "  ", "Last Cross: ", lastCross);
   
   // Trade on support and resistence crossover
   if ((mavgShort > mavgLong) && (mavgDiff > _tradingLevel)) {
      cross = UP;
      buy = true;
      sell = false;
   }  
   if ((mavgShort < mavgLong) && (mavgDiff > _tradingLevel)) {      
      cross = DN;
      buy = false;
      sell = true;
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
         priceDeal = __ATTPrice.Sum(__ATTSymbol.Ask(), _pointsTrade);
         priceLoss = __ATTPrice.Subtract(priceDeal, _pointsLoss);
         priceProfit = __ATTPrice.Sum(priceDeal, _pointsProfit);
         orderId = __ATTOrder.Buy(_ORDER_TYPE::MARKET, Symbol(), _contracts, priceDeal, priceLoss, priceProfit);
      }
      if (sell) {
         priceDeal = __ATTPrice.Subtract(__ATTSymbol.Bid(), _pointsTrade);
         priceLoss = __ATTPrice.Sum(priceDeal, _pointsLoss);
         priceProfit = __ATTPrice.Subtract(priceDeal, _pointsProfit);
         orderId = __ATTOrder.Sell(_ORDER_TYPE::MARKET, Symbol(), _contracts, priceDeal, priceLoss, priceProfit);
      }
   } else {
       __ATTPosition.TrailStop(_pointsLoss, _trailingLoss, _tralingProfit, _tralingProfitStep);
   }
}
