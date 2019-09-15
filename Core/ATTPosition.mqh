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
      ulong trailingTicket;
      double trailingPrice;
      double trailingPoints;
      void CloseAllPositions();
      void TrailStop(_TRAIL_STOP trailStop);
};

//+------------------------------------------------------------------+
//| Constructor/Destructor                                        |
//+------------------------------------------------------------------+
ATTPosition::ATTPosition() {
   ATTPosition::trailingTicket = 0;
   ATTPosition::trailingPrice = 0.0;
   ATTPosition::trailingPoints = 0.0;
}
ATTPosition::~ATTPosition() {
   ATTPosition::trailingTicket = 0;
   ATTPosition::trailingPrice = 0.0;
   ATTPosition::trailingPoints = 0.0;
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
void ATTPosition::TrailStop(_TRAIL_STOP trailStop) {

   // General Declaration
   double bid = 0.0;
   double ask = 0.0;
   ulong ticketId = 0;
   double priceDeal = 0.0;
   double stopLoss = 0.0;
   double takeProfit = 0.0;
   ulong dealType = 0.0;
   double pointsLoss = 0.0;
   double pointsProfit = 0.0;   
   double contracts = 0.0;
   double points = 0.0;
   double priceStep = 0.0;
   double priceStop = 0.0;
      
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
            bid = _ATTSymbol.Bid();
            ask = _ATTSymbol.Ask();

            // Dinamic stop loss
            if (trailStop == _TRAIL_STOP::LOSS || trailStop == _TRAIL_STOP::BOTH) {
            
               // Define points to trail stop loss
               pointsLoss = MathAbs(_ATTPrice.GetPoints(stopLoss, priceDeal));
               points = (pointsLoss / 4);
            
               if (dealType == ENUM_POSITION_TYPE::POSITION_TYPE_BUY) {
                  if (stopLoss < priceDeal) {
                     if (bid > _ATTPrice.Sum(stopLoss, (pointsLoss + points))) {
                        ATTPosition::ModifyPosition(ticketId, _ATTPrice.Sum(stopLoss, points), takeProfit);
                     }
                  }
               } else {
                  if (stopLoss > priceDeal) {
                     if (_ATTSymbol.Ask() < _ATTPrice.Subtract(stopLoss, (pointsLoss + points))) {
                        ATTPosition::ModifyPosition(ticketId, _ATTPrice.Subtract(stopLoss, points), takeProfit);
                     }
                  }
               }
            }

            // Define points to trail stop loss
            if (trailStop == _TRAIL_STOP::PROFIT || trailStop == _TRAIL_STOP::BOTH) {

               // When bid is 150% greater than price, put a close order            
               pointsProfit = MathAbs(ATTPosition::trailingPoints/2);
               points = MathAbs((pointsProfit / 2));
               
               if (dealType == ENUM_POSITION_TYPE::POSITION_TYPE_BUY) {
               
                  priceStep = _ATTPrice.Sum(ATTPosition::trailingPrice, (pointsProfit + points));
                  priceStop = _ATTPrice.Sum(ATTPosition::trailingPrice, pointsProfit);

                  if (bid > priceStep) {
                     if (ATTPosition::trailingTicket == 0) {
                        ATTPosition::trailingTicket = _ATTOrder.Sell(_ORDER_TYPE::LIMIT, Symbol(), contracts, priceStop, bid, 0);
                     } else {
                        _ATTOrder.AmmendOrder(ATTPosition::trailingTicket, priceStop, bid, 0);
                     }
                     
                     ATTPosition::trailingPrice = bid;
                  }

               } else {
               
                  priceStep = _ATTPrice.Subtract(ATTPosition::trailingPrice, (pointsProfit - points));
                  priceStop = _ATTPrice.Subtract(ATTPosition::trailingPrice, pointsProfit);

                  if (ask < priceStep) {
                     if (ATTPosition::trailingTicket == 0) {
                        ATTPosition::trailingTicket = _ATTOrder.Buy(_ORDER_TYPE::LIMIT, Symbol(), contracts, priceStop, ask, 0);
                     } else {
                        _ATTOrder.AmmendOrder(ATTPosition::trailingTicket, priceStop, ask, 0);
                     }
                     
                     ATTPosition::trailingPrice = ask;
                  }
               }            
            }  
         }
      }
   }
}