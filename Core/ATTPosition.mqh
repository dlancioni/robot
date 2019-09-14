#include <Trade\Trade.mqh>
#include "ATTPrice.mqh"
#include "ATTSymbol.mqh"
#include "ATTOrder.mqh"
#include "ATTDef.mqh"
// https://www.mql5.com/pt/docs/standardlibrary/tradeclasses/ctrade
// https://www.youtube.com/watch?v=VL1_NGaAOaU

//+------------------------------------------------------------------+
//|                                                     ATTTrade.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Provide methods do open and close deals                          |
//+------------------------------------------------------------------+
class ATTPosition : public CPositionInfo {
   private:
      bool ModifyPosition(ulong orderId, double sl, double tp);    
   public:
      ATTPosition();
      ~ATTPosition();
      ulong ticketTrailing;   
      void CloseAllPositions();
      void TrailStop(bool trailStopLoss, bool trailStopProfit);
};

//+------------------------------------------------------------------+
//| Constructor/Destructor                                        |
//+------------------------------------------------------------------+
ATTPosition::ATTPosition() {
   ATTPosition::ticketTrailing = 0;
}
ATTPosition::~ATTPosition() {
   ATTPosition::ticketTrailing = 0;
}

//+------------------------------------------------------------------+
//| Delete all pending orders                                        |
//+------------------------------------------------------------------+
void ATTPosition::CloseAllPositions() {

    // General Declaration
    CTrade trade;   
    ulong id = 0;

    // Close open positions
     for (int i=PositionsTotal()-1; i>=0; i--) {
	      id = PositionGetTicket(i);
	      trade.PositionClose(id);
     }
}

//+------------------------------------------------------------------+
//| Modify existing order                                            |
//+------------------------------------------------------------------+
bool ATTPosition::ModifyPosition(ulong id=0, double sl=0.0, double tp=0.0) {
    CTrade trade;
    bool status = false;    
    status = trade.PositionModify(id, sl, tp);
    return status;
}

//+------------------------------------------------------------------+
//| Handle dinamic stops                                             |
//+------------------------------------------------------------------+
void ATTPosition::TrailStop(bool trailStopLoss, bool trailStopProfit) {

   // General Declaration
   ulong ticketId = 0;
   double priceDeal = 0.0;
   double stopLoss = 0.0;
   double takeProfit = 0.0;
   ulong dealType = 0.0;
   double pointsLoss = 0.0;
   double contracts = 0.0;
   double trailingPointsLoss = 0.0;
      
   ATTSymbol _ATTSymbol;
   ATTPrice _ATTPrice;
   ATTOrder _ATTOrder;
   
   // Close open positions
   for (int i=PositionsTotal()-1; i>=0; i--) {   

      // Get current deal
      if (SelectByIndex(i)) {
   
         // Make sure we are at same symbol as chart
         if (PositionGetSymbol(i) == Symbol()) {

            // Get deal info
            ticketId = PositionGetInteger(POSITION_TICKET);
            priceDeal = PositionGetDouble(POSITION_PRICE_OPEN);
            stopLoss = PositionGetDouble(POSITION_SL);
            takeProfit = PositionGetDouble(POSITION_TP);
            dealType = PositionGetInteger(POSITION_TYPE);
            contracts = PositionGetDouble(POSITION_VOLUME);

            // Set default checkpoint value
            pointsLoss = MathAbs(_ATTPrice.GetPoints(stopLoss, priceDeal));

            // Move the stops higher or lowers
            if (dealType == ENUM_POSITION_TYPE::POSITION_TYPE_BUY) {

               if (trailStopLoss) {
                  if (stopLoss < priceDeal) {
                     if (_ATTSymbol.Bid() > _ATTPrice.Sum(stopLoss, (pointsLoss + trailingPointsLoss))) {
                        ATTPosition::ModifyPosition(ticketId, _ATTPrice.Sum(stopLoss, trailingPointsLoss), takeProfit);
                     }
                  }
               }
               
               if (trailStopProfit) {
               
               }

            } else {
                        
               if (trailStopProfit) {
                  if (stopLoss > priceDeal) {
                     if (_ATTSymbol.Ask() < _ATTPrice.Subtract(stopLoss, (pointsLoss + trailingPointsLoss))) {
                        ATTPosition::ModifyPosition(ticketId, _ATTPrice.Subtract(stopLoss, trailingPointsLoss), takeProfit);
                     }
                  }
               }
               
               if (trailStopProfit) {
               
               }               
               
            }
         }
      }
   }
}      




/*
               
               // Decrease profit after 50% profit
               if (_ATTSymbol.Ask() < _ATTPrice.Subtract(takeProfit/2, trailingPoints)) {
                  if (ATTPosition::ticketTrailing == 0) {
                     ATTPosition::ticketTrailing = _ATTOrder.Buy(_ORDER_TYPE::LIMIT, Symbol(), contracts, _ATTSymbol.Ask(), 0, 0);
                  } else {
                     if (!_ATTOrder.AmmendOrder(ATTPosition::ticketTrailing, _ATTSymbol.Ask(), 0, 0)) {
                        ATTPosition::CloseAllPositions();
                     }
                  }
               }
*/               