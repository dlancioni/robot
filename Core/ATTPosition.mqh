#include <Trade\Trade.mqh>
#include "ATTPrice.mqh"
#include "ATTSymbol.mqh"
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
      double checkpoint;   
      void CloseAllPositions();
      void TrailingStop();
};

//+------------------------------------------------------------------+
//| Constructor/Destructor                                        |
//+------------------------------------------------------------------+
ATTPosition::ATTPosition() {
   ATTPosition::checkpoint = 0.0;
}
ATTPosition::~ATTPosition() {
   ATTPosition::checkpoint = 0.0;
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
void ATTPosition::TrailingStop() {

   // General Declaration
   ulong ticketId = 0;
   double priceDeal = 0.0;
   double stopLoss = 0.0;
   double takeProfit = 0.0;
   ulong dealType = 0.0;
   double pointsStep = 0.0;
   double pointsTrade = 0.0;
      
   ATTSymbol _ATTSymbol;
   ATTPrice _ATTPrice;
   
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

            // Set default checkpoint value
            pointsTrade = MathAbs(_ATTPrice.GetPoints(stopLoss, priceDeal));
            pointsStep = MathAbs(pointsTrade / 5);

            // Move the stops higher or lowers
            if (dealType == ENUM_POSITION_TYPE::POSITION_TYPE_BUY) {
            
               // Decrease stop loss
               if (stopLoss < priceDeal) {
                  if (_ATTSymbol.Bid() > _ATTPrice.Sum(stopLoss, (pointsTrade + pointsStep))) {
                     ATTPosition::ModifyPosition(ticketId, _ATTPrice.Sum(stopLoss, pointsStep), takeProfit);
                  }
               }
               
               // Increase take profit (not used yet)
               if (_ATTSymbol.Bid() > _ATTPrice.Sum(takeProfit, pointsStep)) {
                  ATTPosition::checkpoint = _ATTSymbol.Bid();
               }
               
            } else {
                        
               // Decrease stop loss            
               if (stopLoss > priceDeal) {
                  if (_ATTSymbol.Ask() < _ATTPrice.Subtract(stopLoss, (pointsTrade + pointsStep))) {
                     ATTPosition::ModifyPosition(ticketId,  _ATTPrice.Subtract(stopLoss, pointsStep), takeProfit);
                  }               
               }
               
               // Increase take profit (not used yet)
               if (_ATTSymbol.Ask() < _ATTPrice.Subtract(takeProfit, pointsStep)) {
                  ATTPosition::checkpoint = _ATTSymbol.Bid();
               }
            }
         }
      }
   }
}      