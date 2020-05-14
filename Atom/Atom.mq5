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
input string RiskInfo = "----------";       // Risk Info
input double _dailyProfit = 1000;           // Daily profit limit
input double _dailyLoss = 1000;             // Daily loss limit
input string TradeInfo = "----------";      // Trade Info 
input ENUM_TIMEFRAMES _chartTime = 1;       // Chart time
input double _contracts = 5;                // Number of Contracts
input double _pointsTrade = 10;             // Points after current price to open trade
input double _pointsLoss = 500;             // Points stop loss
input double _pointsProfit = 100;           // Points take profit
input double _tralingProfit = 0;            // Points to trigger dinamic stop profit
input double _tralingProfitStep = 0;        // Points to trail take profit
input double _trailingLoss = 0;             // Points to trail stop loss
input string CrossoverInfo = "----------";  // Crossover setup
input int _mavgShort = 7;                   // Short moving avarage
input int _mavgLong = 21;                   // Long moving avarage
input double _mavgDiffAvoid = 10;           // Avoid open position in this level

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
   msg = __ATTValidator.ValidateParameters(_contracts, 
                                           _pointsTrade, 
                                           _pointsLoss, 
                                           _pointsProfit, 
                                           _trailingLoss, 
                                           _tralingProfit, 
                                           _tralingProfitStep, 
                                           _dailyLoss, 
                                           _dailyProfit);
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
   
   double mavgShort = 0;     // Short moving avarage
   double mavgLong = 0;      // Long moving avarage
   double level = 0;         // Current support and resistence level (using wpr)

   // if result touch the limits - stop everything  
   __ATTBalance.IsResultOverLimits(initialBalance, _dailyLoss, _dailyProfit);
   
   // Get prices   
   bid = __ATTSymbol.Bid();
   ask = __ATTSymbol.Ask();

   // If no price, no deal (markets closed, or off-line)
   if (bid > 0 && ask > 0) {

      // Calculate indicators - EMAS
      if ((_mavgShort > 0) && (_mavgLong > 0)) {
         mavgShort = __ATTIndicator.CalculateMovingAvarage(Symbol(), _chartTime, _mavgShort);
         mavgLong = __ATTIndicator.CalculateMovingAvarage(Symbol(), _chartTime, _mavgLong);
      }

      // Open trades according to indicators
      Trade(bid, ask, mavgShort, mavgLong);

   } else {
       Print("No price available");
   }
}

//
// Open position as indicators are attended
//
void Trade(double bid, double ask, double mavgShort, double mavgLong) {

   // General declaration
   string cross = "";
   const string UP = "UP";
   const string DN = "DN";   
   ulong orderId = 0;
   bool buy = false;
   bool sell = false;   
   double priceDeal = 0;
   double priceLoss = 0.0;
   double priceProfit = 0.0;
   double mavgDiff = 0.0;

   // Keep the difference of mavgs
   mavgDiff = MathAbs(__ATTMath.Subtract(mavgLong, mavgShort));
   
   // Log current level:
   Comment("moving Avg: ", mavgDiff, "  ", "lastCross: ", lastCross);

   // Trade on support and resistence crossover
   if (mavgDiff > _mavgDiffAvoid) {
      if (mavgShort < mavgLong) {
            buy = false;
            sell = true;
            cross = DN;
      }
      if (mavgShort > mavgLong) {      
         buy = true;
         sell = false;
         cross = UP;
      }
   }
   
   // If cross changed, rever position   
   if (cross != lastCross) {
      // Keep current cross
      lastCross = cross;      
      // MAVG diff is tight, do not trade SR
      if (_mavgDiffAvoid > 0) {
         if (mavgDiff <= _mavgDiffAvoid) {
            buy = false;
            sell = false;
         }
      }      
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
         priceDeal = __ATTPrice.Sum(ask, _pointsTrade);
         priceLoss = __ATTPrice.Subtract(priceDeal, _pointsLoss);
         priceProfit = __ATTPrice.Sum(priceDeal, _pointsProfit);
         orderId = __ATTOrder.Buy(_ORDER_TYPE::STOP, Symbol(), _contracts, priceDeal, priceLoss, priceProfit);
      }
      if (sell) {
         priceDeal = __ATTPrice.Subtract(bid, _pointsTrade);
         priceLoss = __ATTPrice.Sum(priceDeal, _pointsLoss);
         priceProfit = __ATTPrice.Subtract(priceDeal, _pointsProfit);
         orderId = __ATTOrder.Sell(_ORDER_TYPE::STOP, Symbol(), _contracts, priceDeal, priceLoss, priceProfit);
      }
   } else {
       __ATTPosition.TrailStop(_pointsLoss, _trailingLoss, _tralingProfit, _tralingProfitStep);
   }
}
