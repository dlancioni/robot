#include <Trade\Trade.mqh>
#include "ATTPrice.mqh"
#include "ATTSymbol.mqh"
// https://www.mql5.com/pt/docs/standardlibrary/tradeclasses/ctrade

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
      void CloseAllPositions();
      void DinamicStop(ulong ticketId, double pointsLoss, double pointsStep, double priceProfit);
};

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
void ATTPosition::DinamicStop(ulong _ticketId, double _pointsLoss, double _pointsStep, double _priceProfit) {

   double sl = 0.0;
   double tp = 0.0;
   double priceTarget = 0.0;
   ATTSymbol __ATTSymbol;
   ATTPrice __ATTPrice;

   // Query the position
   if (ATTPosition::SelectByTicket(_ticketId)) {   
   
      // Ajust stop loss as price moves
      if (ATTPosition::PositionType() == ENUM_POSITION_TYPE::POSITION_TYPE_BUY) {
      
         priceTarget = __ATTPrice.Sum(ATTPosition::StopLoss(), _pointsLoss + _pointsStep);
         
         if (__ATTSymbol.Bid() > priceTarget) {
            sl = priceTarget;
            tp = _priceProfit; 
         }
         
      } else {

         priceTarget = __ATTPrice.Subtract(ATTPosition::StopLoss(), _pointsLoss - _pointsStep);
         
         if (__ATTSymbol.Ask() < priceTarget) {
            sl = priceTarget;
            tp = _priceProfit; 
         }      
      }
      
      ATTPosition::ModifyPosition(_ticketId, sl, tp);
   }
}      