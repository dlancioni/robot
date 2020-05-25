
//+------------------------------------------------------------------+
//|                                                     ATTBalance.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Balance related methods (PnL, Margin, Balance, etc)              |
//+------------------------------------------------------------------+
class ATTBalance {
   private:

   public:
       double GetBalance();      // Total account balance
       double GetProfit();       // PnL for current opened position
       double GetEquity();       // Account balance plus current PnL
       double GetMargin();       // Used margin       
       double GetDailyPnl();     // Sum of history profit
       bool IsResultOverLimits(double, double); // Risk Control - limit profit or loss
};

//+------------------------------------------------------------------+
//| Open or close position at market price                           |
//+------------------------------------------------------------------+
double ATTBalance::GetBalance() {
   return AccountInfoDouble(ACCOUNT_BALANCE);
}

double ATTBalance::GetProfit() {
   return AccountInfoDouble(ACCOUNT_PROFIT);
}

double ATTBalance::GetEquity() {
   return AccountInfoDouble(ACCOUNT_EQUITY);
}

double ATTBalance::GetMargin() {
   return AccountInfoDouble(ACCOUNT_MARGIN);
}

double ATTBalance::GetDailyPnl() {
   
    // General Declaration
    ulong ticket = 0;
    datetime time;
    string symbol = "";
    double profit = 0;
    double pnl = 0;
    uint total = 0;
    string dt = "";
    datetime from;
    datetime to;
    MqlDateTime today;
    TimeToStruct(TimeLocal(), today);

    // Get today's trades    
    dt = IntegerToString(today.year) + "." + IntegerToString(today.mon) + "." + IntegerToString(today.day);
    from = StringToTime(dt + " " + "00:00:00");
    to = StringToTime(dt + " " + "23:59:00");

   // Select deals form history
    HistorySelect(from, to);
    total = HistoryDealsTotal();
   
    // Iterate over daily history   
    for (uint i=0; i<total; i++) {
        if((ticket = HistoryDealGetTicket(i)) > 0) {            
            symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
            profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            time  = (datetime) HistoryDealGetInteger(ticket,DEAL_TIME);            
	         profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            pnl += profit;
        }
    }

   return pnl;
}

bool ATTBalance::IsResultOverLimits(double limitLoss, double limitProfit) {

   bool flag = false;
   double pnl = 0;
   
   // Get daily PnL
   pnl = ATTBalance::GetDailyPnl();   

   // Profit limit
   if (pnl >= limitProfit) {
       flag = true;
       Print("Profit limited achieved, no more trades today: ", pnl);
   }

   // Loss limit (must negative it)
   if (pnl <= limitLoss*-1) {
       flag = true;
       Print("Loss limited achieved, no more trades today: ", pnl);
   }   

   // Touched the limits, stop expert
   return flag; 
}






















/*

   printf("ACCOUNT_BALANCE =  %G",AccountInfoDouble(ACCOUNT_BALANCE));
   printf("ACCOUNT_CREDIT =  %G",AccountInfoDouble(ACCOUNT_CREDIT));
   printf("ACCOUNT_PROFIT =  %G",AccountInfoDouble(ACCOUNT_PROFIT));
   printf("ACCOUNT_EQUITY =  %G",AccountInfoDouble(ACCOUNT_EQUITY));
   printf("ACCOUNT_MARGIN =  %G",AccountInfoDouble(ACCOUNT_MARGIN));
   printf("ACCOUNT_FREEMARGIN =  %G",AccountInfoDouble(ACCOUNT_FREEMARGIN));
   printf("ACCOUNT_MARGIN_LEVEL =  %G",AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
   printf("ACCOUNT_MARGIN_SO_CALL = %G",AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL));
   printf("ACCOUNT_MARGIN_SO_SO = %G",AccountInfoDouble(ACCOUNT_MARGIN_SO_SO));
   
   */