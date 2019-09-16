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
      double trailingPrice;
      void CloseAllPositions();
      void TrailStop(double, double, double);
};

//+------------------------------------------------------------------+
//| Constructor/Destructor                                        |
//+------------------------------------------------------------------+
ATTPosition::ATTPosition() {
}
ATTPosition::~ATTPosition() {
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
void ATTPosition::TrailStop(double trailingLoss, double trailingProfit, double tralingProfitStep) {

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

            // Dinamic stop loss, zero means no trailing
            if (trailingLoss > 0) {
            
               // Define points to trail stop loss
               pointsLoss = trailingLoss;
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

            // Define points to trail stop profit, zero means no trailing
            if (trailingProfit > 0 && tralingProfitStep > 0) {
               if (dealType == ENUM_POSITION_TYPE::POSITION_TYPE_BUY) {
                  if (bid > trailingPrice) {
                     trailingPrice = bid;
                  }
               } else {
                  if (ask < trailingPrice) {
                     trailingPrice = bid;
                  }
               }
            }
         //
         }
      }
   }
}