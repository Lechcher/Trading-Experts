//+------------------------------------------------------------------+
//|                                           Lib_MQL4_To_MQL5.mqh   |
//|                        Compatibility Library                     |
//+------------------------------------------------------------------+
#property strict

// --- Standard Constants ---
#define OP_BUY 0
#define OP_SELL 1
#define OP_BUYLIMIT 2
#define OP_SELLLIMIT 3
#define OP_BUYSTOP 4
#define OP_SELLSTOP 5
#define MODE_OPEN 0
#define MODE_LOW 1
#define MODE_HIGH 2
#define MODE_CLOSE 3
#define MODE_VOLUME 4
#define MODE_TIME 5
#define MODE_BID 9
#define MODE_ASK 10
#define MODE_POINT 11
#define MODE_DIGITS 12
#define MODE_SPREAD 13
#define MODE_STOPLEVEL 14
#define MODE_LOTSIZE 15
#define MODE_TICKVALUE 16
#define MODE_TICKSIZE 17
#define MODE_SWAPLONG 18
#define MODE_SWAPSHORT 19
#define MODE_STARTING 20
#define MODE_EXPIRATION 21
#define MODE_TRADEALLOWED 22
#define MODE_MINLOT 23
#define MODE_LOTSTEP 24
#define MODE_MAXLOT 25
#define MODE_SWAPTYPE 26
#define MODE_PROFITCALCMODE 27
#define MODE_MARGINCALCMODE 28
#define MODE_MARGININIT 29
#define MODE_MARGINMAINTENANCE 30
#define MODE_MARGINHEDGED 31
#define MODE_MARGINREQUIRED 32
#define MODE_FREEZELEVEL 33

#define SELECT_BY_POS 0
#define SELECT_BY_TICKET 1
#define MODE_TRADES 0
#define MODE_HISTORY 1

// --- Global Variables for compatibility ---
#define Digits _Digits
#define Point _Point

// --- Imports ---

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>
#include <Trade/HistoryOrderInfo.mqh>
#include <Trade/DealInfo.mqh>

CTrade trade;
CPositionInfo PositionInfo;
COrderInfo OrderInfo;
CHistoryOrderInfo m_HistoryOrderInfo; // Renamed to avoid potential conflict
CDealInfo m_DealInfo;

// --- RefreshRates Wrapper ---
bool RefreshRates() {
   MqlTick tick;
   return SymbolInfoTick(_Symbol, tick);
}

// --- Time Wrappers ---
// TimeLocal and TimeGMT are built-in MQL5 functions, removing overrides.

// OrderCloseTime
datetime OrderCloseTime() {
   if (_order_cache_type == CACHE_HISTORY) return (datetime)m_HistoryOrderInfo.TimeDone();
   if (_order_cache_type == CACHE_DEAL) return (datetime)m_DealInfo.Time();
   return 0;
}

// --- MarketInfo Wrapper ---
double MarketInfo(string symbol, int types)
  {
   switch(types)
     {
      case MODE_BID: return(SymbolInfoDouble(symbol,SYMBOL_BID));
      case MODE_ASK: return(SymbolInfoDouble(symbol,SYMBOL_ASK));
      case MODE_POINT: return(SymbolInfoDouble(symbol,SYMBOL_POINT));
      case MODE_DIGITS: return((double)SymbolInfoInteger(symbol,SYMBOL_DIGITS));
      case MODE_SPREAD: return((double)SymbolInfoInteger(symbol,SYMBOL_SPREAD));
      case MODE_STOPLEVEL: return((double)SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL));
      case MODE_LOTSIZE: return(SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE));
      case MODE_TICKVALUE: return(SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE));
      case MODE_TICKSIZE: return(SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE));
      case MODE_MINLOT: return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN));
      case MODE_LOTSTEP: return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP));
      case MODE_MAXLOT: return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX));
      case MODE_FREEZELEVEL: return((double)SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL));
      case MODE_SWAPLONG: return(SymbolInfoDouble(symbol,SYMBOL_SWAP_LONG));
      case MODE_SWAPSHORT: return(SymbolInfoDouble(symbol,SYMBOL_SWAP_SHORT));
      case MODE_TRADEALLOWED: return((double)MQLInfoInteger(MQL_TRADE_ALLOWED));
      default: return(0.0);
     }
  }

// --- Time Wrappers ---
int Year()         { MqlDateTime tm; TimeCurrent(tm); return(tm.year); }
int Month()        { MqlDateTime tm; TimeCurrent(tm); return(tm.mon); }
int Day()          { MqlDateTime tm; TimeCurrent(tm); return(tm.day); }
int Hour()         { MqlDateTime tm; TimeCurrent(tm); return(tm.hour); }
int Minute()       { MqlDateTime tm; TimeCurrent(tm); return(tm.min); }
int Seconds()      { MqlDateTime tm; TimeCurrent(tm); return(tm.sec); }
int DayOfWeek()    { MqlDateTime tm; TimeCurrent(tm); return(tm.day_of_week); }
int DayOfYear()    { MqlDateTime tm; TimeCurrent(tm); return(tm.day_of_year); }

// --- Account Wrapper ---
string AccountName() { return(AccountInfoString(ACCOUNT_NAME)); }
int AccountNumber() { return((int)AccountInfoInteger(ACCOUNT_LOGIN)); }
double AccountBalance() { return(AccountInfoDouble(ACCOUNT_BALANCE)); }
double AccountEquity() { return(AccountInfoDouble(ACCOUNT_EQUITY)); }
double AccountFreeMargin() { return(AccountInfoDouble(ACCOUNT_MARGIN_FREE)); }
string AccountCurrency() { return(AccountInfoString(ACCOUNT_CURRENCY)); }

double AccountFreeMarginCheck(string symbol, int cmd, double volume)
{
   double margin_required = 0.0;
   ENUM_ORDER_TYPE order_type = ORDER_TYPE_BUY;
   if(cmd == OP_SELL) order_type = ORDER_TYPE_SELL;
   
   if(!OrderCalcMargin(order_type, symbol, volume, SymbolInfoDouble(symbol, SYMBOL_ASK), margin_required))
      return AccountFreeMargin(); // Fallback
      
   return AccountFreeMargin() - margin_required;
}

// --- Order System Wrapper ---

enum OrderCacheType {
   CACHE_NONE,
   CACHE_POSITION,
   CACHE_ORDER,
   CACHE_HISTORY,
   CACHE_DEAL
};

OrderCacheType _order_cache_type = CACHE_NONE;

// HistoryTotal wrapper (Deals)
int HistoryTotal() {
    HistorySelect(0, TimeCurrent()); // Load all history
    return HistoryDealsTotal();
}

int OrdersTotalMQL4() {
    return PositionsTotal() + ::OrdersTotal();
}
#define OrdersTotal OrdersTotalMQL4

bool OrderSelect(ulong tkt_param, int select, int pool=MODE_TRADES) {
    _order_cache_type = CACHE_NONE;
    if (pool == MODE_TRADES) {
        if (select == SELECT_BY_POS) {
            if (tkt_param < (ulong)PositionsTotal()) {
                if (PositionInfo.SelectByIndex((int)tkt_param)) {
                    _order_cache_type = CACHE_POSITION;
                    return true;
                }
            } else {
                if (OrderInfo.SelectByIndex((int)tkt_param - PositionsTotal())) {
                    _order_cache_type = CACHE_ORDER;
                    return true;
                }
            }
        } else if (select == SELECT_BY_TICKET) {
            if (PositionInfo.SelectByTicket(tkt_param)) {
                _order_cache_type = CACHE_POSITION;
                return true;
            }
            if (OrderInfo.Select(tkt_param)) {
                _order_cache_type = CACHE_ORDER;
                return true;
            }
        }
    } else if (pool == MODE_HISTORY) {
        if (select == SELECT_BY_POS) {
            // Prioritize Deals for history iteration (MQL4 style closed orders)
            if (m_DealInfo.SelectByIndex((int)tkt_param)) {
                _order_cache_type = CACHE_DEAL;
                return true;
            }
            if (m_HistoryOrderInfo.SelectByIndex((int)tkt_param)) {
                _order_cache_type = CACHE_HISTORY;
                return true;
            }
        } else if (select == SELECT_BY_TICKET) {
            // Try selecting deal by ticket directly
            if (HistoryDealSelect(tkt_param)) { 
                m_DealInfo.Ticket(tkt_param); 
                _order_cache_type = CACHE_DEAL;
                return true;
            }
            // For HistoryOrder
            if (HistoryOrderSelect(tkt_param)) {
                 m_HistoryOrderInfo.Ticket(tkt_param);
                 _order_cache_type = CACHE_HISTORY;
                 return true;
            }
        }
    }
    return false;
}

long OrderTicket() {
    if (_order_cache_type == CACHE_POSITION) return PositionInfo.Ticket();
    if (_order_cache_type == CACHE_ORDER) return OrderInfo.Ticket();
    if (_order_cache_type == CACHE_HISTORY) return m_HistoryOrderInfo.Ticket();
    if (_order_cache_type == CACHE_DEAL) return m_DealInfo.Ticket();
    return 0;
}

int OrderType() {
    if (_order_cache_type == CACHE_POSITION) return (int)PositionInfo.PositionType();
    if (_order_cache_type == CACHE_ORDER) return (int)OrderInfo.OrderType();
    if (_order_cache_type == CACHE_HISTORY) return (int)m_HistoryOrderInfo.OrderType();
    if (_order_cache_type == CACHE_DEAL) return (int)m_DealInfo.DealType();
    return 0;
}

double OrderOpenPrice() {
    if (_order_cache_type == CACHE_POSITION) return PositionInfo.PriceOpen();
    if (_order_cache_type == CACHE_ORDER) return OrderInfo.PriceOpen();
    if (_order_cache_type == CACHE_HISTORY) return m_HistoryOrderInfo.PriceOpen();
    if (_order_cache_type == CACHE_DEAL) return m_DealInfo.Price();
    return 0.0;
}

double OrderClosePrice() {
    if (_order_cache_type == CACHE_POSITION) return PositionInfo.PriceCurrent(); // Approximation
    if (_order_cache_type == CACHE_DEAL) return m_DealInfo.Price(); // Deal price is execution price
    if (_order_cache_type == CACHE_HISTORY) return 0.0;
    return 0.0;
}

double OrderLots() {
    if (_order_cache_type == CACHE_POSITION) return PositionInfo.Volume();
    if (_order_cache_type == CACHE_ORDER) return OrderInfo.VolumeInitial();
    if (_order_cache_type == CACHE_HISTORY) return m_HistoryOrderInfo.VolumeInitial();
    if (_order_cache_type == CACHE_DEAL) return m_DealInfo.Volume();
    return 0.0;
}

double OrderStopLoss() {
    if (_order_cache_type == CACHE_POSITION) return PositionInfo.StopLoss();
    if (_order_cache_type == CACHE_ORDER) return OrderInfo.StopLoss();
    if (_order_cache_type == CACHE_HISTORY) return m_HistoryOrderInfo.StopLoss();
    return 0.0;
}

double OrderTakeProfit() {
    if (_order_cache_type == CACHE_POSITION) return PositionInfo.TakeProfit();
    if (_order_cache_type == CACHE_ORDER) return OrderInfo.TakeProfit();
    if (_order_cache_type == CACHE_HISTORY) return m_HistoryOrderInfo.TakeProfit();
    return 0.0;
}

datetime OrderOpenTime() {
    if (_order_cache_type == CACHE_POSITION) return (datetime)PositionInfo.Time();
    if (_order_cache_type == CACHE_ORDER) return (datetime)OrderInfo.TimeSetup();
    if (_order_cache_type == CACHE_HISTORY) return (datetime)m_HistoryOrderInfo.TimeSetup();
    if (_order_cache_type == CACHE_DEAL) return (datetime)m_DealInfo.Time();
    return 0;
}

string OrderComment() {
    if (_order_cache_type == CACHE_POSITION) return PositionInfo.Comment();
    if (_order_cache_type == CACHE_ORDER) return OrderInfo.Comment();
    if (_order_cache_type == CACHE_HISTORY) return m_HistoryOrderInfo.Comment();
    if (_order_cache_type == CACHE_DEAL) return m_DealInfo.Comment();
    return "";
}

long OrderMagicNumber() {
    if (_order_cache_type == CACHE_POSITION) return PositionInfo.Magic();
    if (_order_cache_type == CACHE_ORDER) return OrderInfo.Magic();
    if (_order_cache_type == CACHE_HISTORY) return m_HistoryOrderInfo.Magic();
    if (_order_cache_type == CACHE_DEAL) return m_DealInfo.Magic();
    return 0;
}

string OrderSymbol() {
    if (_order_cache_type == CACHE_POSITION) return PositionInfo.Symbol();
    if (_order_cache_type == CACHE_ORDER) return OrderInfo.Symbol();
    if (_order_cache_type == CACHE_HISTORY) return m_HistoryOrderInfo.Symbol();
    if (_order_cache_type == CACHE_DEAL) return m_DealInfo.Symbol();
    return "";
}

double OrderProfit() {
    if (_order_cache_type == CACHE_POSITION) return PositionInfo.Profit();
    if (_order_cache_type == CACHE_DEAL) return m_DealInfo.Profit();
    return 0.0;
}

double OrderSwap() {
    if (_order_cache_type == CACHE_POSITION) return PositionInfo.Swap();
    if (_order_cache_type == CACHE_DEAL) return m_DealInfo.Swap();
    return 0.0;
}

double OrderCommission() {
    if (_order_cache_type == CACHE_POSITION) return PositionInfo.Commission();
    if (_order_cache_type == CACHE_DEAL) return m_DealInfo.Commission();
    return 0.0;
}

datetime OrderExpiration() {
    if (_order_cache_type == CACHE_ORDER) return (datetime)OrderInfo.TimeExpiration();
    return 0;
}

// Time functions
int TimeHour(datetime date) {
    MqlDateTime tm;
    TimeToStruct(date, tm);
    return tm.hour;
}

int TimeMinute(datetime date) {
    MqlDateTime tm;
    TimeToStruct(date, tm);
    return tm.min;
}

int TimeDayOfWeek(datetime date) {
    MqlDateTime tm;
    TimeToStruct(date, tm);
    return tm.day_of_week;
}

int TimeDay(datetime date) {
    MqlDateTime tm;
    TimeToStruct(date, tm);
    return tm.day;
}

int TimeMonth(datetime date) {
    MqlDateTime tm;
    TimeToStruct(date, tm);
    return tm.mon;
}

int TimeYear(datetime date) {
    MqlDateTime tm;
    TimeToStruct(date, tm);
    return tm.year;
}

bool OrderDelete(ulong ticket, color color_param=clrNONE) {
    return trade.OrderDelete(ticket);
}

bool OrderClose(ulong ticket, double lots, double price, int slippage, color color_param=clrNONE) {
    // Try to close position first
    if(PositionInfo.SelectByTicket(ticket)) {
        return trade.PositionClose(ticket, slippage);
    }
    // If it's a pending order, delete it (though OrderClose is usually for positions in MQL4)
    if(OrderInfo.Select(ticket)) {
        return trade.OrderDelete(ticket);
    }
    return false;
}

bool OrderModify(ulong ticket, double price, double stoploss, double takeprofit, datetime expiration, color arrow_color=clrNONE) {
    if(PositionInfo.SelectByTicket(ticket)) {
        // It's a position, modify SL/TP
        return trade.PositionModify(ticket, stoploss, takeprofit);
    }
    if(OrderInfo.Select(ticket)) {
        // It's a pending order, modify Price, SL, TP, Expiration
        return trade.OrderModify(ticket, price, stoploss, takeprofit, ORDER_TIME_GTC, expiration);
    }
    return false;
}

// OrderSend Wrapper
int OrderSend(string symbol, int cmd, double volume, double price, int slippage, double stoploss, double takeprofit, string comment="", int magic=0, datetime expiration=0, color arrow_color=clrNONE)
  {
   trade.SetExpertMagicNumber(magic);
   trade.SetDeviationInPoints(slippage);
   
   if(cmd == OP_BUY)
     {
      if(trade.Buy(volume, symbol, price, stoploss, takeprofit, comment)) return((int)trade.ResultOrder());
     }
   else if(cmd == OP_SELL)
     {
      if(trade.Sell(volume, symbol, price, stoploss, takeprofit, comment)) return((int)trade.ResultOrder());
     }
   else if(cmd == OP_BUYLIMIT)
     {
      if(trade.BuyLimit(volume, price, symbol, stoploss, takeprofit, ORDER_TIME_GTC, expiration, comment)) return((int)trade.ResultOrder());
     }
   else if(cmd == OP_SELLLIMIT)
     {
      if(trade.SellLimit(volume, price, symbol, stoploss, takeprofit, ORDER_TIME_GTC, expiration, comment)) return((int)trade.ResultOrder());
     }
   else if(cmd == OP_BUYSTOP)
     {
      if(trade.BuyStop(volume, price, symbol, stoploss, takeprofit, ORDER_TIME_GTC, expiration, comment)) return((int)trade.ResultOrder());
     }
   else if(cmd == OP_SELLSTOP)
     {
      if(trade.SellStop(volume, price, symbol, stoploss, takeprofit, ORDER_TIME_GTC, expiration, comment)) return((int)trade.ResultOrder());
     }
     
   return(-1);
  }

// --- Status Wrappers ---
bool IsDemo() { return(AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO); }
bool IsTesting() { return(MQLInfoInteger(MQL_TESTER) != 0); }
bool IsOptimization() { return(MQLInfoInteger(MQL_OPTIMIZATION) != 0); }
bool IsVisualMode() { return(MQLInfoInteger(MQL_VISUAL_MODE) != 0); }

// --- String Wrappers ---
// StringToLower MQL4 returns string, MQL5 returns bool/void inplace.
string StringToLowerMQL4(string &text)
{
   StringToLower(text);
   return text;
}
#define StringToLower StringToLowerMQL4

// --- Indicator Wrappers ---

// iBars
int iBars(string symbol, int timeframe) {
   return Bars(symbol, (ENUM_TIMEFRAMES)timeframe);
}

datetime iTime(string symbol, int timeframe, int shift)
{
   datetime times[];
   ArraySetAsSeries(times, true);
   int copied = CopyTime(symbol, (ENUM_TIMEFRAMES)timeframe, shift, 1, times);
   if(copied > 0) return times[0];
   return 0;
}

double iOpen(string symbol, int timeframe, int shift)
{
   double open[];
   ArraySetAsSeries(open, true);
   int copied = CopyOpen(symbol, (ENUM_TIMEFRAMES)timeframe, shift, 1, open);
   if(copied > 0) return open[0];
   return 0.0;
}

double iClose(string symbol, int timeframe, int shift)
{
   double close[];
   ArraySetAsSeries(close, true);
   int copied = CopyClose(symbol, (ENUM_TIMEFRAMES)timeframe, shift, 1, close);
   if(copied > 0) return close[0];
   return 0.0;
}

double iHigh(string symbol, int timeframe, int shift)
{
   double high[];
   ArraySetAsSeries(high, true);
   int copied = CopyHigh(symbol, (ENUM_TIMEFRAMES)timeframe, shift, 1, high);
   if(copied > 0) return high[0];
   return 0.0;
}

double iLow(string symbol, int timeframe, int shift)
{
   double low[];
   ArraySetAsSeries(low, true);
   int copied = CopyLow(symbol, (ENUM_TIMEFRAMES)timeframe, shift, 1, low);
   if(copied > 0) return low[0];
   return 0.0;
}

// Fractals
double iFractals(string symbol, int timeframe, int mode, int shift)
{
   int handle = iFractals(symbol, (ENUM_TIMEFRAMES)timeframe);
   if(handle == INVALID_HANDLE) return 0.0;
   
   double buf[];
   ArraySetAsSeries(buf, true);
   int buffer_num = (mode == 1) ? 0 : 1;
   
   if(CopyBuffer(handle, buffer_num, shift, 1, buf) > 0)
   {
       if(buf[0] == EMPTY_VALUE || buf[0] == DBL_MAX) return 0.0;
       return buf[0];
   }
   return 0.0;
}

// Moving Average
double iMA(string symbol, int timeframe, int period, int ma_shift, int ma_method, int applied_price, int shift)
{
   int handle = iMA(symbol, (ENUM_TIMEFRAMES)timeframe, period, ma_shift, (ENUM_MA_METHOD)ma_method, (ENUM_APPLIED_PRICE)applied_price);
   if(handle == INVALID_HANDLE) return 0.0;
   
   double buf[];
   ArraySetAsSeries(buf, true);
   if(CopyBuffer(handle, 0, shift, 1, buf) > 0)
      return buf[0];
   return 0.0;
}
