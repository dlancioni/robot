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
input double _pointsLoss = 0;               // Points stop sloss
input double _pointsProfit = 0;             // Points take profit
input string Trailing = "----------";       // Trailing info
input double _checkpoints = 0;              // Points to accummulate over price deal
input double _points = 0;                   // Points to calculate stops


//
// General Declaration
//
ATTOrder ATOrder;
ATTPrice ATPrice;
ATTSymbol ATSymbol;
ATTBalance ATBalance;
ATTPosition ATPosition;
ATTIndicator ATIndicator;  
ATTValidator ATValidator;
ATTMath ATMath;
string cross = "";
string lastCross = "";
double slb = 0;         // Stop loss buy
double sls = 0;         // Stop loss sell
double dailyPnL = 0;
//
// Init the values
//
int OnInit() {

   string msg = "";
   
   // Validate input parameters related to trade and abort program if something is wrong
   msg = ATValidator.ValidateParameters(_dailyLoss, 
                                        _dailyProfit,
                                        _contracts, 
                                        _pointsLoss,
                                        _pointsProfit, 
                                        _checkpoints, 
                                        _shortAvg,
                                        _longAvg,
                                        _diffAvg);
   if (msg != "") {
      Print(msg);
      Alert(msg);
      ExpertRemove();
   }
   
   // Load current PnL (very important if services go down)
   dailyPnL = ATBalance.GetDailyPnl();

   // Go ahead
   return(INIT_SUCCEEDED);
}


//
// Reload risk information after change on trading related (order, deal, etc)
//
void OnTrade() {
   dailyPnL = ATBalance.GetDailyPnl();
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

    string symbol = Symbol();
    double bid = 0.0;         // Current bid price 
    double ask = 0.0;         // Current ask price
    double shortAvg = 0; 
    double longAvg = 0;
    
    // Get prices   
    bid = ATSymbol.Bid();
    ask = ATSymbol.Ask();
   
    // Get avgs and calculate difference
    shortAvg = ATIndicator.CalculateMovingAvarage(symbol, _chartTime, _shortAvg);
    longAvg = ATIndicator.CalculateMovingAvarage(symbol, _chartTime, _longAvg);   

    // If no price, no deal (markets closed, or off-line)
    if (!ATBalance.IsResultOverLimits(dailyPnL, _dailyLoss, _dailyProfit)) {
        if (bid > 0 && ask > 0) {
            if (shortAvg > 0 && longAvg > 0) {
                tradeCrossoverStrategy(symbol, bid, ask, shortAvg, longAvg );
            } else {
                Print("No moving avarage available");
            }
        } else {
            Print("No price available");
        }
    }
}

//
// Open position as indicators are attended
//
void tradeCrossoverStrategy(string symbol, double bid = 0, double ask = 0, double shortAvg = 0, double longAvg = 0) {

    // General declaration
    const string UP = "UP";
    const string DN = "DN";
    
    ulong orderId = 0;
    double diffAvg = 0;
    double tpb = 0;
    double tps = 0;
    bool buy = false;
    bool sell = false;    
      
    // Calculate avarage difference
    diffAvg = MathAbs(ATMath.Subtract(longAvg, shortAvg));
   
    // Ajust according to digits
    switch (Digits()) {
    case 3:
        diffAvg = diffAvg * 10;
        break;
    case 5:
        diffAvg = diffAvg * 100000;
        break;
    }
   
    Comment("Diff: ", diffAvg, " Cross: ", lastCross, " PnL: ", dailyPnL);
    
    // Keep prices
    bid = ATSymbol.Bid();
    ask = ATSymbol.Ask();

    // Calculate profit & loss
    tpb = ATPrice.Sum(ask, _pointsProfit);
    tps = ATPrice.Subtract(bid, _pointsProfit);    
    slb = ATPrice.Subtract(ask, _pointsLoss);
    sls = ATPrice.Sum(bid, _pointsLoss);    
    
    // Crossover logic
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
        ATOrder.CloseAllOrders();
        ATPosition.CloseAllPositions();        
    } else {
        buy = false;
        sell = false;
    }

    // Just trade
    if (PositionsTotal() == 0) {    
        if (buy) {        
            orderId = ATOrder.Buy(_ORDER_TYPE::MARKET, symbol, _contracts, ask, slb, tpb);
        }        
        if (sell) {
            orderId = ATOrder.Sell(_ORDER_TYPE::MARKET, symbol, _contracts, bid, sls, tps);
        }        
        ATPosition.SetTrailStopLoss(_checkpoints, _points);
    } else {
       ATPosition.TrailStop();
    }
   
}




