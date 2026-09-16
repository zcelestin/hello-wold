//+------------------------------------------------------------------+
//|                                       FVG_Trading_Strategy_EA.mq5 |
//|                                                                   |
//| D1 bias -> H4 confirm -> M30 entry                                |
//| Impulse -> FVG below 50% -> price returns -> 3-candle reaction    |
//|                                                                   |
//| The setup is armed once and then watched over the following bars, |
//| because the reaction is not expected on the bar that finds it.    |
//+------------------------------------------------------------------+
#property copyright "Celestin Zongo"
#property version   "3.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
// INPUT PARAMETERS
//+------------------------------------------------------------------+

input group "=== Risk Management ===";
input double RiskPercentage            = 1.0;    // Risk per trade (% of balance)
input double MinRiskRewardRatio        = 2.0;    // Minimum Risk/Reward ratio
input int    MaxOpenTrades             = 1;      // Max simultaneous trades + orders
input int    MagicNumber               = 123456; // Magic number

input group "=== Structure / Impulse ===";
input int    BiasLookbackBars          = 120;    // Bars scanned for swing structure
input int    EntryLookbackBars         = 200;    // M30 bars scanned for impulse/FVG
input int    ImpulseMinBars            = 4;      // Minimum bars in the impulse leg
input double MinImpulsePips            = 15.0;   // Minimum impulse size (pips)

input group "=== Retracement / FVG ===";
input double FibonacciRetracementLevel = 0.5;    // FVG must sit beyond this level
input double FVGMinPips                = 2.0;    // Minimum FVG size (pips)
input int    SetupMaxBars              = 40;     // Bars an armed setup stays valid

input group "=== Candle Confirmation ===";
input bool   RequireRejectionCandle     = true;  // Candle 1: rejection inside FVG
input bool   RequireIndecisionCandle    = true;  // Candle 2: indecision
input bool   RequireConfirmationCandle  = true;  // Candle 3: strong close
input bool   RequireVolumeConfirmation  = false; // Candle 3 volume > candles 1 & 2
input double MaxIndecisionBodyPercent   = 50.0;  // Max body size for indecision (%)
input double MinConfirmationBodyPercent = 55.0;  // Min body size for confirmation (%)

input group "=== Execution ===";
input int    MaxSpreadPoints    = 50;   // Max spread allowed (points, 0 = off)
input int    SlippagePoints     = 20;   // Max deviation (points)
input int    SLBufferPoints     = 20;   // Extra distance beyond invalidation

input group "=== Trading Hours (server time) ===";
input int    StartHour = 0;             // Start trading at (0-23)
input int    EndHour   = 0;             // Stop trading at (0-23, equal = 24h)

input group "=== EA Settings ===";
input bool   ShowDebugInfo        = true;   // Log setup progress
input bool   UseTrailingStop      = false;  // Use trailing stop
input int    TrailingStopPoints   = 500;    // Trailing distance (points)

//+------------------------------------------------------------------+
// TYPES & GLOBALS
//+------------------------------------------------------------------+

CTrade        trade;
CPositionInfo posInfo;

enum BiasDirection {
    BIAS_NEUTRAL =  0,
    BIAS_BULLISH =  1,
    BIAS_BEARISH = -1
};

struct SwingPoint {
    double price;
    int    shift;
};

struct ArmedSetup {
    bool          active;
    BiasDirection direction;
    double        fvgHigh;
    double        fvgLow;
    double        impulseHigh;
    double        impulseLow;
    bool          priceReturned;
    int           age;
};

// Counts how many bars clear each gate, printed at shutdown. With no trades on
// a run, this is what says which gate is responsible.
struct Funnel {
    long bars;
    long timeOK;
    long spreadOK;
    long slotOK;
    long aligned;
    long impulse;
    long fvgFound;
    long armed;
    long returned;
    long reaction;
    long targetsOK;
    long lotsOK;
    long orders;
};

ArmedSetup g_setup;
Funnel     g_funnel;
datetime   g_lastBarTime = 0;

//+------------------------------------------------------------------+
// HELPERS
//+------------------------------------------------------------------+

double PipSize() {
    return (_Digits == 3 || _Digits == 5) ? _Point * 10.0 : _Point;
}

int VolumeDigits(double step) {
    int d = 0;
    while (step < 1.0 && d < 8) { step *= 10.0; d++; }
    return d;
}

double MinStopDistance() {
    long level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    if (level <= 0) level = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * 2;
    return level * _Point;
}

void Debug(string msg) {
    if (ShowDebugInfo) Print("[FVG] ", msg);
}

string BiasName(BiasDirection b) {
    if (b == BIAS_BULLISH) return "BULL";
    if (b == BIAS_BEARISH) return "BEAR";
    return "FLAT";
}

// AS_SERIES is reasserted after the copy: setting it beforehand alone is not
// reliable across builds, and a silently reversed buffer breaks every index.
int LoadRates(ENUM_TIMEFRAMES timeframe, int count, MqlRates &rates[]) {
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(_Symbol, timeframe, 0, count, rates);
    if (copied > 0) ArraySetAsSeries(rates, true);
    return copied;
}

bool IsNewBar() {
    datetime t = iTime(_Symbol, PERIOD_M30, 0);
    if (t == 0 || t == g_lastBarTime) return false;
    g_lastBarTime = t;
    return true;
}

bool IsTradingTime() {
    if (StartHour == EndHour) return true;
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    if (StartHour < EndHour) return (dt.hour >= StartHour && dt.hour < EndHour);
    return (dt.hour >= StartHour || dt.hour < EndHour);
}

bool SpreadOK() {
    if (MaxSpreadPoints <= 0) return true;
    return SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) <= MaxSpreadPoints;
}

//+------------------------------------------------------------------+
// SWING DETECTION
//+------------------------------------------------------------------+

// Fractal swing: extreme against the two bars either side. Scanning starts at
// shift 3 so bar 0 (still forming) never takes part in confirming a swing.
int FindSwings(const MqlRates &rates[], int total, bool findHighs, SwingPoint &out[]) {
    ArrayResize(out, 0);
    int found = 0;

    for (int i = 3; i <= total - 3; i++) {
        bool isSwing;
        if (findHighs) {
            double v = rates[i].high;
            isSwing = (v > rates[i-1].high && v > rates[i-2].high &&
                       v > rates[i+1].high && v > rates[i+2].high);
        } else {
            double v = rates[i].low;
            isSwing = (v < rates[i-1].low && v < rates[i-2].low &&
                       v < rates[i+1].low && v < rates[i+2].low);
        }

        if (isSwing) {
            ArrayResize(out, found + 1);
            out[found].price = findHighs ? rates[i].high : rates[i].low;
            out[found].shift = i;
            found++;
        }
    }
    return found;   // out[0] is the most recent swing
}

//+------------------------------------------------------------------+
// BIAS ANALYSIS (HH/HL vs LH/LL)
//+------------------------------------------------------------------+

BiasDirection AnalyzeBias(ENUM_TIMEFRAMES timeframe) {
    MqlRates rates[];
    if (LoadRates(timeframe, BiasLookbackBars, rates) < 30) return BIAS_NEUTRAL;

    SwingPoint highs[], lows[];
    int nh = FindSwings(rates, ArraySize(rates), true,  highs);
    int nl = FindSwings(rates, ArraySize(rates), false, lows);
    if (nh < 2 || nl < 2) return BIAS_NEUTRAL;

    if (highs[0].price > highs[1].price && lows[0].price > lows[1].price) return BIAS_BULLISH;
    if (highs[0].price < highs[1].price && lows[0].price < lows[1].price) return BIAS_BEARISH;
    return BIAS_NEUTRAL;
}

bool IsAlignmentValid(BiasDirection d1, BiasDirection h4, BiasDirection m30) {
    if (d1 == BIAS_NEUTRAL) return false;
    return (d1 == h4 && h4 == m30);
}

//+------------------------------------------------------------------+
// SETUP DISCOVERY
//+------------------------------------------------------------------+

// The bullish impulse tops at the most recent swing high; its origin is the
// nearest swing low BEFORE it. The retracement creates a newer swing low after
// the high, which must not be mistaken for the origin.
bool DetectImpulse(BiasDirection direction, const MqlRates &rates[], int total,
                   double &impulseHigh, double &impulseLow,
                   int &highShift, int &lowShift) {
    SwingPoint highs[], lows[];
    int nh = FindSwings(rates, total, true,  highs);
    int nl = FindSwings(rates, total, false, lows);
    if (nh < 1 || nl < 1) return false;

    if (direction == BIAS_BULLISH) {
        impulseHigh = highs[0].price;
        highShift   = highs[0].shift;

        int idx = -1;
        for (int i = 0; i < nl; i++)
            if (lows[i].shift > highShift) { idx = i; break; }
        if (idx < 0) return false;

        impulseLow = lows[idx].price;
        lowShift   = lows[idx].shift;
    } else {
        impulseLow = lows[0].price;
        lowShift   = lows[0].shift;

        int idx = -1;
        for (int i = 0; i < nh; i++)
            if (highs[i].shift > lowShift) { idx = i; break; }
        if (idx < 0) return false;

        impulseHigh = highs[idx].price;
        highShift   = highs[idx].shift;
    }

    if ((impulseHigh - impulseLow) / PipSize() < MinImpulsePips) return false;
    return (MathAbs(highShift - lowShift) >= ImpulseMinBars);
}

// Bullish FVG: the low of the newest candle in the triplet sits ABOVE the high
// of the oldest, leaving an untraded gap. Only gaps inside the impulse leg and
// beyond the 50% level qualify - price reaching such a gap has by construction
// retraced at least 50%, so no separate retracement test is needed.
bool DetectFVG(BiasDirection direction, const MqlRates &rates[], int total,
               double impulseHigh, double impulseLow, int highShift, int lowShift,
               double &fvgHigh, double &fvgLow) {
    double range    = impulseHigh - impulseLow;
    double fibLevel = (direction == BIAS_BULLISH)
                    ? impulseHigh - range * FibonacciRetracementLevel
                    : impulseLow  + range * FibonacciRetracementLevel;

    int newest = (direction == BIAS_BULLISH) ? highShift : lowShift;
    int oldest = (direction == BIAS_BULLISH) ? lowShift  : highShift;
    double minGap = FVGMinPips * PipSize();

    for (int i = newest; i + 2 <= oldest && i + 2 < total; i++) {
        double gapLow, gapHigh;

        if (direction == BIAS_BULLISH) {
            gapLow  = rates[i+2].high;
            gapHigh = rates[i].low;
            if (gapHigh - gapLow < minGap)                continue;
            if (gapLow < impulseLow)                      continue;
            if ((gapHigh + gapLow) * 0.5 > fibLevel)      continue;
        } else {
            gapLow  = rates[i].high;
            gapHigh = rates[i+2].low;
            if (gapHigh - gapLow < minGap)                continue;
            if (gapHigh > impulseHigh)                    continue;
            if ((gapHigh + gapLow) * 0.5 < fibLevel)      continue;
        }

        fvgHigh = gapHigh;
        fvgLow  = gapLow;
        return true;   // most recent qualifying gap
    }
    return false;
}

//+------------------------------------------------------------------+
// ARMED SETUP TRACKING
//+------------------------------------------------------------------+

bool PriceInFVG(const MqlRates &rates[]) {
    return (rates[1].low <= g_setup.fvgHigh && rates[1].high >= g_setup.fvgLow);
}

bool SetupInvalidated(const MqlRates &rates[]) {
    if (g_setup.age > SetupMaxBars) { Debug("setup expired"); return true; }

    if (g_setup.direction == BIAS_BULLISH) {
        if (rates[1].close < g_setup.impulseLow) { Debug("impulse origin broken"); return true; }
    } else {
        if (rates[1].close > g_setup.impulseHigh) { Debug("impulse origin broken"); return true; }
    }
    return false;
}

// Reaction read on bars 3 -> 2 -> 1, all closed. Every consecutive triple is
// tested once, on the bar right after it completes.
bool ValidateReaction(const MqlRates &rates[]) {
    double range3 = rates[3].high - rates[3].low;
    double range2 = rates[2].high - rates[2].low;
    double range1 = rates[1].high - rates[1].low;
    if (range3 <= 0.0 || range2 <= 0.0 || range1 <= 0.0) return false;

    bool bullish = (g_setup.direction == BIAS_BULLISH);

    if (RequireRejectionCandle) {
        bool ok = bullish
                ? (rates[3].low <= g_setup.fvgHigh && rates[3].close >= rates[3].low + range3 * 0.5)
                : (rates[3].high >= g_setup.fvgLow && rates[3].close <= rates[3].high - range3 * 0.5);
        if (!ok) return false;
    }

    if (RequireIndecisionCandle) {
        double body2 = MathAbs(rates[2].close - rates[2].open);
        if (body2 / range2 * 100.0 > MaxIndecisionBodyPercent) return false;
    }

    if (RequireConfirmationCandle) {
        double body1 = bullish ? rates[1].close - rates[1].open
                               : rates[1].open  - rates[1].close;
        if (body1 <= 0.0) return false;
        if (body1 / range1 * 100.0 < MinConfirmationBodyPercent) return false;

        if (RequireVolumeConfirmation) {
            long v1 = (long)rates[1].tick_volume;
            if (v1 <= (long)rates[2].tick_volume || v1 <= (long)rates[3].tick_volume) return false;
        }
    }

    return true;
}

//+------------------------------------------------------------------+
// PRICE TARGETS
//+------------------------------------------------------------------+

void CollectTargets(ENUM_TIMEFRAMES timeframe, bool wantHighs, double refPrice, double &out[]) {
    MqlRates rates[];
    if (LoadRates(timeframe, BiasLookbackBars, rates) < 30) return;

    SwingPoint swings[];
    int n = FindSwings(rates, ArraySize(rates), wantHighs, swings);

    for (int i = 0; i < n; i++) {
        if (wantHighs  && swings[i].price <= refPrice) continue;
        if (!wantHighs && swings[i].price >= refPrice) continue;

        int size = ArraySize(out);
        ArrayResize(out, size + 1);
        out[size] = swings[i].price;
    }
}

// Nearest structural level that still satisfies the minimum R:R.
bool FindTakeProfit(BiasDirection direction, double entry, double risk, double &takeProfit) {
    double candidates[];
    ArrayResize(candidates, 0);

    bool wantHighs = (direction == BIAS_BULLISH);
    CollectTargets(PERIOD_M30, wantHighs, entry, candidates);
    CollectTargets(PERIOD_H4,  wantHighs, entry, candidates);

    double best = 0.0;
    for (int i = 0; i < ArraySize(candidates); i++) {
        double reward = wantHighs ? candidates[i] - entry : entry - candidates[i];
        if (reward / risk < MinRiskRewardRatio) continue;

        if (best == 0.0) best = candidates[i];
        else if (wantHighs  && candidates[i] < best) best = candidates[i];
        else if (!wantHighs && candidates[i] > best) best = candidates[i];
    }

    if (best == 0.0) return false;
    takeProfit = best;
    return true;
}

bool CalculateTargets(const MqlRates &rates[], double &entry, double &stopLoss, double &takeProfit) {
    double buffer  = SLBufferPoints * _Point;
    double minDist = MinStopDistance();
    bool   bullish = (g_setup.direction == BIAS_BULLISH);

    if (bullish) {
        entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double low = MathMin(g_setup.fvgLow, MathMin(rates[1].low, MathMin(rates[2].low, rates[3].low)));
        stopLoss = low - buffer;
        if (entry - stopLoss < minDist) { Debug("stop too close to market"); return false; }
    } else {
        entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double high = MathMax(g_setup.fvgHigh, MathMax(rates[1].high, MathMax(rates[2].high, rates[3].high)));
        stopLoss = high + buffer;
        if (stopLoss - entry < minDist) { Debug("stop too close to market"); return false; }
    }

    double risk = MathAbs(entry - stopLoss);
    if (risk <= 0.0) return false;

    if (!FindTakeProfit(g_setup.direction, entry, risk, takeProfit)) {
        Debug(StringFormat("no structural target reaching %.1f:1", MinRiskRewardRatio));
        return false;
    }
    if (MathAbs(takeProfit - entry) < minDist) { Debug("target too close to market"); return false; }

    entry      = NormalizeDouble(entry,      _Digits);
    stopLoss   = NormalizeDouble(stopLoss,   _Digits);
    takeProfit = NormalizeDouble(takeProfit, _Digits);
    return true;
}

//+------------------------------------------------------------------+
// POSITION SIZING
//+------------------------------------------------------------------+

// Risk is converted through tick value / tick size, not raw points: on symbols
// where tick size differs from point, the two are not interchangeable.
double CalculateLotSize(double entry, double stopLoss) {
    double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercentage / 100.0;
    double distance   = MathAbs(entry - stopLoss);
    if (distance <= 0.0 || riskAmount <= 0.0) return 0.0;

    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    if (tickValue <= 0.0 || tickSize <= 0.0) return 0.0;

    double lossPerLot = distance / tickSize * tickValue;
    if (lossPerLot <= 0.0) return 0.0;

    double lots    = riskAmount / lossPerLot;
    double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    if (stepLot <= 0.0) stepLot = minLot;

    lots = MathFloor(lots / stepLot) * stepLot;
    lots = NormalizeDouble(lots, VolumeDigits(stepLot));

    if (lots > maxLot) lots = maxLot;
    if (lots < minLot) {
        Debug(StringFormat("risk %.2f too small for min lot %.2f", riskAmount, minLot));
        return 0.0;
    }

    double margin = 0.0;
    if (!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lots,
                         SymbolInfoDouble(_Symbol, SYMBOL_ASK), margin)) return 0.0;
    if (margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE) * 0.9) {
        Debug("not enough free margin");
        return 0.0;
    }
    return lots;
}

//+------------------------------------------------------------------+
// EXECUTION & MANAGEMENT
//+------------------------------------------------------------------+

bool ExecuteTrade(double stopLoss, double takeProfit, double lots) {
    trade.SetTypeFillingBySymbol(_Symbol);
    trade.SetDeviationInPoints(SlippagePoints);

    bool bullish = (g_setup.direction == BIAS_BULLISH);
    bool ok = bullish ? trade.Buy(lots, _Symbol, 0.0, stopLoss, takeProfit, "FVG Buy")
                      : trade.Sell(lots, _Symbol, 0.0, stopLoss, takeProfit, "FVG Sell");

    if (!ok) {
        Print("[FVG] Order failed. Retcode=", trade.ResultRetcode(),
              " (", trade.ResultRetcodeDescription(), ")");
        return false;
    }

    double fill = trade.ResultPrice();
    Print(StringFormat("[FVG] %s %.2f lots | entry %s | SL %s | TP %s | R:R %.2f",
          (bullish ? "BUY" : "SELL"), lots,
          DoubleToString(fill, _Digits),
          DoubleToString(stopLoss, _Digits),
          DoubleToString(takeProfit, _Digits),
          MathAbs(takeProfit - fill) / MathAbs(fill - stopLoss)));
    return true;
}

int CountOpenTrades() {
    int count = 0;

    for (int i = PositionsTotal() - 1; i >= 0; i--)
        if (posInfo.SelectByIndex(i) &&
            posInfo.Symbol() == _Symbol && posInfo.Magic() == MagicNumber) count++;

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        ulong ticket = OrderGetTicket(i);
        if (ticket > 0 &&
            OrderGetString(ORDER_SYMBOL) == _Symbol &&
            OrderGetInteger(ORDER_MAGIC) == MagicNumber) count++;
    }
    return count;
}

void UpdateTrailingStops() {
    double bid      = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask      = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double distance = TrailingStopPoints * _Point;
    double minDist  = MinStopDistance();

    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (!posInfo.SelectByIndex(i)) continue;
        if (posInfo.Symbol() != _Symbol || posInfo.Magic() != MagicNumber) continue;

        double currentSL = posInfo.StopLoss();
        double openPrice = posInfo.PriceOpen();

        if (posInfo.PositionType() == POSITION_TYPE_BUY) {
            if (bid - openPrice < distance) continue;       // only trail once in profit
            double newSL = NormalizeDouble(bid - distance, _Digits);
            if (newSL > currentSL + _Point && bid - newSL >= minDist)
                trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
        } else {
            if (openPrice - ask < distance) continue;
            double newSL = NormalizeDouble(ask + distance, _Digits);
            if ((currentSL == 0.0 || newSL < currentSL - _Point) && newSL - ask >= minDist)
                trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
        }
    }
}

//+------------------------------------------------------------------+
// LIFECYCLE
//+------------------------------------------------------------------+

int OnInit() {
    trade.SetExpertMagicNumber(MagicNumber);
    ZeroMemory(g_setup);
    ZeroMemory(g_funnel);

    if (RiskPercentage <= 0.0 || RiskPercentage > 5.0) {
        Print("[FVG] RiskPercentage must be between 0 and 5");
        return INIT_PARAMETERS_INCORRECT;
    }
    if (FibonacciRetracementLevel <= 0.0 || FibonacciRetracementLevel >= 1.0) {
        Print("[FVG] FibonacciRetracementLevel must be between 0 and 1");
        return INIT_PARAMETERS_INCORRECT;
    }

    Print("=== FVG Strategy EA v3.00 ===");
    Print("Symbol: ", _Symbol, " | Risk: ", RiskPercentage, "% | Min R:R: ", MinRiskRewardRatio);

    ENUM_TIMEFRAMES frames[] = {PERIOD_D1, PERIOD_H4, PERIOD_M30};
    string names[] = {"D1", "H4", "M30"};
    for (int i = 0; i < 3; i++) {
        int available = Bars(_Symbol, frames[i]);
        if (available < BiasLookbackBars)
            Print("[FVG] Warning: ", names[i], " has ", available, " bars, ",
                  BiasLookbackBars, " expected. Load more history.");
    }
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    Print("=== FVG funnel (bars reaching each gate) ===");
    Print("  bars evaluated .... ", g_funnel.bars);
    Print("  trading hours ..... ", g_funnel.timeOK);
    Print("  spread ok ......... ", g_funnel.spreadOK);
    Print("  free slot ......... ", g_funnel.slotOK);
    Print("  D1=H4=M30 aligned . ", g_funnel.aligned);
    Print("  impulse found ..... ", g_funnel.impulse);
    Print("  FVG below 50% ..... ", g_funnel.fvgFound);
    Print("  setups armed ...... ", g_funnel.armed);
    Print("  price back in FVG . ", g_funnel.returned);
    Print("  3-candle reaction . ", g_funnel.reaction);
    Print("  SL/TP valid ....... ", g_funnel.targetsOK);
    Print("  lot size valid .... ", g_funnel.lotsOK);
    Print("  orders sent ....... ", g_funnel.orders);
}

void OnTick() {
    if (UseTrailingStop) UpdateTrailingStops();
    if (!IsNewBar()) return;

    g_funnel.bars++;
    if (!IsTradingTime()) return;
    g_funnel.timeOK++;
    if (!SpreadOK()) return;
    g_funnel.spreadOK++;
    if (CountOpenTrades() >= MaxOpenTrades) return;
    g_funnel.slotOK++;

    MqlRates rates[];
    int copied = LoadRates(PERIOD_M30, EntryLookbackBars, rates);
    if (copied < 50) { Debug(StringFormat("only %d M30 bars available", copied)); return; }

    // ---- an armed setup is watched until it fires or dies -------------------
    if (g_setup.active) {
        g_setup.age++;

        if (SetupInvalidated(rates)) { g_setup.active = false; return; }

        if (!g_setup.priceReturned) {
            if (!PriceInFVG(rates)) return;
            g_setup.priceReturned = true;
            g_funnel.returned++;
            Debug("price returned into the FVG, waiting for the reaction");
        }

        if (!ValidateReaction(rates)) return;
        g_funnel.reaction++;

        double entry, stopLoss, takeProfit;
        if (!CalculateTargets(rates, entry, stopLoss, takeProfit)) return;
        g_funnel.targetsOK++;

        double lots = CalculateLotSize(entry, stopLoss);
        if (lots <= 0.0) return;
        g_funnel.lotsOK++;

        if (ExecuteTrade(stopLoss, takeProfit, lots)) g_funnel.orders++;
        g_setup.active = false;
        return;
    }

    // ---- otherwise look for a new setup ------------------------------------
    BiasDirection d1  = AnalyzeBias(PERIOD_D1);
    BiasDirection h4  = AnalyzeBias(PERIOD_H4);
    BiasDirection m30 = AnalyzeBias(PERIOD_M30);

    static string lastState = "";
    string state = BiasName(d1) + " / " + BiasName(h4) + " / " + BiasName(m30);
    if (state != lastState) {
        lastState = state;
        Debug("bias D1/H4/M30 = " + state +
              (IsAlignmentValid(d1, h4, m30) ? "   << ALIGNED" : ""));
    }
    if (!IsAlignmentValid(d1, h4, m30)) return;
    g_funnel.aligned++;

    double impulseHigh, impulseLow;
    int highShift, lowShift;
    if (!DetectImpulse(d1, rates, copied, impulseHigh, impulseLow, highShift, lowShift)) return;
    g_funnel.impulse++;

    double fvgHigh, fvgLow;
    if (!DetectFVG(d1, rates, copied, impulseHigh, impulseLow, highShift, lowShift,
                   fvgHigh, fvgLow)) return;
    g_funnel.fvgFound++;

    g_setup.active        = true;
    g_setup.direction     = d1;
    g_setup.fvgHigh       = fvgHigh;
    g_setup.fvgLow        = fvgLow;
    g_setup.impulseHigh   = impulseHigh;
    g_setup.impulseLow    = impulseLow;
    g_setup.priceReturned = false;
    g_setup.age           = 0;
    g_funnel.armed++;

    Debug(StringFormat("%s setup armed | impulse %s-%s | FVG %s-%s",
          BiasName(d1),
          DoubleToString(impulseLow, _Digits), DoubleToString(impulseHigh, _Digits),
          DoubleToString(fvgLow, _Digits), DoubleToString(fvgHigh, _Digits)));
}
//+------------------------------------------------------------------+
