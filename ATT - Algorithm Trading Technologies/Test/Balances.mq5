
void OnTick()
  {
   double balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double pnl=AccountInfoDouble(ACCOUNT_PROFIT);
   
   Comment("Balance: ", balance, " Equity: ", equity, " PnL: ", pnl);
   
   // https://www.mql5.com/pt/articles/113
   
  }