//+------------------------------------------------------------------+
//|                                                     ATTOrder.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Provide methods do open and close deals                          |
//+------------------------------------------------------------------+
enum _ORDER_TYPE {
   MARKET,
   STOP,
   LIMIT
};

enum _ORDER_POSITION {
   BUY,
   SELL
};
