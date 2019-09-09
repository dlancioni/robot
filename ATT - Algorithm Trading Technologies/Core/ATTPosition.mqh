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
      void CloseAllPositions();
      void TrailingStop();
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
void ATTPosition::TrailingStop() {

   // General Declaration
   ulong tid = 0;
   string symbol = "";
   double price = 0.0;
   double po = 0.0;
   double sl = 0.0;
   double tp = 0.0;
   double bid = 0.0;
   double ask = 0.0;
   double pts = 0.0;
   ulong type = 0.0;
   double step = 0.0;
      
   ATTSymbol __ATTSymbol;
   ATTPrice __ATTPrice;
   
   // Close open positions
   for (int i=PositionsTotal()-1; i>=0; i--) {   
   
      // Make sure we are at same symbol as chart
      if (PositionGetSymbol(i) == Symbol()) {

         // Get deal info         
         tid = PositionGetInteger(POSITION_TICKET);
         po = PositionGetDouble(POSITION_PRICE_OPEN);
         sl = PositionGetDouble(POSITION_SL);
         tp = PositionGetDouble(POSITION_TP);
         type = PositionGetInteger(POSITION_TYPE);
         bid = __ATTSymbol.Bid();
         ask = __ATTSymbol.Ask();
         
         // Set default checkpoint value
         pts = MathAbs(((tp - po) * Point()));
         step = MathAbs(pts/4);

         // Move the stops higher or lowers
         if (type == ENUM_POSITION_TYPE::POSITION_TYPE_BUY) {
            price = __ATTPrice.Sum(sl+pts,step);
            if (bid > price) {
               sl = __ATTPrice.Sum(sl, step);
               tp = __ATTPrice.Sum(tp, step);
               ATTPosition::ModifyPosition(tid, sl, tp);
            }
         } else {        
            price = __ATTPrice.Subtract(sl-pts, step);
            if (ask < price) {
               sl = __ATTPrice.Subtract(sl, step);
               tp = __ATTPrice.Subtract(tp, step);            
               ATTPosition::ModifyPosition(tid, sl, tp);
            }      
         }        
      }
   }   

}      