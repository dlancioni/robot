
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
       double GetBalance(); // Total account balance
       double GetPnL();     // PnL for current opened position
       double GetEquity();  // Account balance plus current PnL
       double GetMargin();  // Used margin       
       double IsResultOverLimits(double loss, double profit); // Risk Control - limit profit or loss
};

//+------------------------------------------------------------------+
//| Open or close position at market price                           |
//+------------------------------------------------------------------+
double ATTBalance::GetBalance() {
   return AccountInfoDouble(ACCOUNT_BALANCE);
}

double ATTBalance::GetPnL() {
   return AccountInfoDouble(ACCOUNT_PROFIT);
}

double ATTBalance::GetEquity() {
   return AccountInfoDouble(ACCOUNT_EQUITY);
}

double ATTBalance::GetMargin() {
   return AccountInfoDouble(ACCOUNT_MARGIN);
}

double ATTBalance::IsResultOverLimits(double loss, double profit) {

   bool flag = false;
   double result = MathAbs((ATTBalance::GetBalance() - ATTBalance::GetBalance()));
   
   if (result<=loss || result>=profit) {
       flag = true;
   } else {
       flag = false;   
   }
      
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