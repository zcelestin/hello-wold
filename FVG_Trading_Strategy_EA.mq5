//+------------------------------------------------------------------+
//|                                       FVG_Trading_Strategy_EA.mq5 |
//|                                                                   |
//| D1 bias -> H4 confirm -> M30 entry                                |
//| Impulse -> 50% retracement -> FVG -> 3-candle reaction -> market  |
//+------------------------------------------------------------------+
#property copyright "Celestin Zongo"
#property version   "2.01"
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
input int    ImpulseMinBars            = 5;      // Minimum bars in the impulse leg
input double MinImpulsePips            = 20.0;   // Minimum impulse size (pips)

input group "=== Retracement / FVG ===";
input double FibonacciRetracementLevel = 0.5;    // Minimum retracement (0.5 = 50%)
input double MaxRetracement            = 1.0;    // Above this the setup is invalid
input double FVGMinPips                = 3.0;    // Minimum FVG size (pips)

input group "=== Candle Confirmation ===";
input bool   RequireRejectionCandle     = true;  // Candle 1: rejection inside FVG
input bool   RequireIndecisionCandle    = true;  // Candle 2: indecision
input bool   RequireConfirmationCandle  = true;  // Candle 3: strong close
input bool   RequireVolumeConfirmation  = true;  // Candle 3 volume > candles 1 & 2
input double MaxIndecisionBodyPercent   = 40.0;  // Max body size for indecision (%)
input double MinConfirmationBodyPercent = 60.0;  // Min body size for confirmation (%)

input group "=== Execution ===";
input int    MaxSpreadPoints    = 30;   // Max spread allowed (points, 0 = off)
input int    SlippagePoints     = 20;   // Max deviation (points)
input int    SLBufferPoints     = 20;   // Extra distance below/above invalidation

input group "=== Trading Hours (server time) ===";
input int    StartHour = 0;             // Start trading at (0-23)
input int    EndHour   = 23;            // Stop trading at (0-23)

input group "=== EA Settings ===";
input bool   ShowDebugInfo        = true;   // Log why a setup was rejected
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

struct FVGSetup {
    bool          isValid;
    BiasDirection direction;
    double        impulseHigh;
    double        impulseLow;
    int           impulseHighShift;
    int           impulseLowShift;
    double        fibLevel;
    double        fvgHigh;
    double        fvgLow;
};

datetime g_lastBarTime = 0;

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

bool IsNewBar() {
    datetime t = iTime(_Symbol, PERIOD_M30, 0);
    if (t == 0 || t == g_lastBarTime) return false;
    g_lastBarTime = t;
    return true;
}

bool IsTradingTime() {
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    if (StartHour == EndHour) return true;
    if (StartHour < EndHour)  return (dt.hour >= StartHour && dt.hour < EndHour);
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
    ArraySetAsSeries(rates, true);

    int copied = CopyRates(_Symbol, timeframe, 0, BiasLookbackBars, rates);
    if (copied < 30) return BIAS_NEUTRAL;

    SwingPoint highs[], lows[];
    int nh = FindSwings(rates, copied, true,  highs);
    int nl = FindSwings(rates, copied, false, lows);
    if (nh < 2 || nl < 2) return BIAS_NEUTRAL;

    bool higherHigh = highs[0].price > highs[1].price;
    bool higherLow  = lows[0].price  > lows[1].price;
    bool lowerHigh  = highs[0].price < highs[1].price;
    bool lowerLow   = lows[0].price  < lows[1].price;

    if (higherHigh && higherLow) return BIAS_BULLISH;
    if (lowerHigh  && lowerLow)  return BIAS_BEARISH;
    return BIAS_NEUTRAL;
}

bool IsAlignmentValid(BiasDirection d1, BiasDirection h4, BiasDirection m30) {
    if (d1 == BIAS_NEUTRAL) return false;
    return (d1 == h4 && h4 == m30);
}

//+------------------------------------------------------------------+
// IMPULSE DETECTION
//+------------------------------------------------------------------+

// The bullish impulse tops at the most recent swing high; its origin is the
// nearest swing low BEFORE it. The retracement we are waiting for creates a
// newer swing low after the high, which must not be mistaken for the origin.
bool DetectImpulse(BiasDirection direction, const MqlRates &rates[], int total, FVGSetup &setup) {
    SwingPoint highs[], lows[];
    int nh = FindSwings(rates, total, true,  highs);
    int nl = FindSwings(rates, total, false, lows);
    if (nh < 1 || nl < 1) { Debug("not enough M30 swings"); return false; }

    if (direction == BIAS_BULLISH) {
        setup.impulseHigh      = highs[0].price;
        setup.impulseHighShift = highs[0].shift;

        int idx = -1;
        for (int i = 0; i < nl; i++)
            if (lows[i].shift > setup.impulseHighShift) { idx = i; break; }
        if (idx < 0) { Debug("no swing low precedes the impulse high"); return false; }

        setup.impulseLow      = lows[idx].price;
        setup.impulseLowShift = lows[idx].shift;
    } else {
        setup.impulseLow      = lows[0].price;
        setup.impulseLowShift = lows[0].shift;

        int idx = -1;
        for (int i = 0; i < nh; i++)
            if (highs[i].shift > setup.impulseLowShift) { idx = i; break; }
        if (idx < 0) { Debug("no swing high precedes the impulse low"); return false; }

        setup.impulseHigh      = highs[idx].price;
        setup.impulseHighShift = highs[idx].shift;
    }

    double sizePips = (setup.impulseHigh - setup.impulseLow) / PipSize();
    if (sizePips < MinImpulsePips) {
        Debug(StringFormat("impulse %.1f pips < %.1f required", sizePips, MinImpulsePips));
        return false;
    }

    int legBars = MathAbs(setup.impulseHighShift - setup.impulseLowShift);
    if (legBars < ImpulseMinBars) {
        Debug(StringFormat("impulse leg %d bars < %d required", legBars, ImpulseMinBars));
        return false;
    }
    return true;
}

double CalculateFibonacciLevel(const FVGSetup &setup, BiasDirection direction) {
    double range = setup.impulseHigh - setup.impulseLow;
    if (direction == BIAS_BULLISH) return setup.impulseHigh - range * FibonacciRetracementLevel;
    return setup.impulseLow + range * FibonacciRetracementLevel;
}

//+------------------------------------------------------------------+
// FVG DETECTION
//+------------------------------------------------------------------+

// Bullish FVG: the low of the third candle sits ABOVE the high of the first,
// leaving an untraded gap. Bearish is the mirror. Only gaps inside the impulse
// leg and at/beyond the 50% level qualify.
bool DetectFVG(BiasDirection direction, const MqlRates &rates[], int total, FVGSetup &setup) {
    int newest = (direction == BIAS_BULLISH) ? setup.impulseHighShift : setup.impulseLowShift;
    int oldest = (direction == BIAS_BULLISH) ? setup.impulseLowShift  : setup.impulseHighShift;

    double minGap = FVGMinPips * PipSize();

    for (int i = newest; i + 2 <= oldest && i + 2 < total; i++) {
        double gapLow, gapHigh;

        if (direction == BIAS_BULLISH) {
            gapLow  = rates[i+2].high;
            gapHigh = rates[i].low;
            if (gapHigh - gapLow < minGap)      continue;
            if (gapLow < setup.impulseLow)      continue;
            if ((gapHigh + gapLow) * 0.5 > setup.fibLevel) continue;
        } else {
            gapLow  = rates[i].high;
            gapHigh = rates[i+2].low;
            if (gapHigh - gapLow < minGap)      continue;
            if (gapHigh > setup.impulseHigh)    continue;
            if ((gapHigh + gapLow) * 0.5 < setup.fibLevel) continue;
        }

        setup.fvgHigh = gapHigh;
        setup.fvgLow  = gapLow;
        return true;   // most recent qualifying gap
    }
    return false;
}

FVGSetup DetectFVGSetup(BiasDirection direction, const MqlRates &rates[], int total) {
    FVGSetup setup;
    ZeroMemory(setup);
    setup.direction = direction;

    if (!DetectImpulse(direction, rates, total, setup)) {
        Debug("no valid impulse");
        return setup;
    }

    setup.fibLevel = CalculateFibonacciLevel(setup, direction);

    // Measured at the deepest point reached since the impulse ended, not at the
    // latest close: by the time the reaction confirms, price has already left
    // the zone and the current close would understate the retracement.
    double range = setup.impulseHigh - setup.impulseLow;
    double retracement;

    if (direction == BIAS_BULLISH) {
        double deepest = rates[1].low;
        for (int i = 1; i <= setup.impulseHighShift && i < total; i++)
            deepest = MathMin(deepest, rates[i].low);
        retracement = (setup.impulseHigh - deepest) / range;
    } else {
        double highest = rates[1].high;
        for (int i = 1; i <= setup.impulseLowShift && i < total; i++)
            highest = MathMax(highest, rates[i].high);
        retracement = (highest - setup.impulseLow) / range;
    }

    if (retracement < FibonacciRetracementLevel) {
        Debug(StringFormat("retracement %.1f%% < %.0f%%", retracement * 100.0,
                           FibonacciRetracementLevel * 100.0));
        return setup;
    }
    if (retracement > MaxRetracement) {
        Debug(StringFormat("retracement %.1f%% invalidates the leg", retracement * 100.0));
        return setup;
    }

    if (!DetectFVG(direction, rates, total, setup)) {
        Debug("no FVG in the retracement zone");
        return setup;
    }

    setup.isValid = true;
    return setup;
}

//+------------------------------------------------------------------+
// 3-CANDLE CONFIRMATION (bars 3 -> 2 -> 1, all closed)
//+------------------------------------------------------------------+

bool ValidateConfirmation(BiasDirection direction, const MqlRates &rates[], const FVGSetup &setup) {
    double range3 = rates[3].high - rates[3].low;
    double range2 = rates[2].high - rates[2].low;
    double range1 = rates[1].high - rates[1].low;
    if (range3 <= 0.0 || range2 <= 0.0 || range1 <= 0.0) return false;

    bool rejection    = true;
    bool indecision   = true;
    bool confirmation = true;

    if (RequireRejectionCandle) {
        if (direction == BIAS_BULLISH) {
            rejection = (rates[3].low <= setup.fvgHigh) &&
                        (rates[3].close >= rates[3].low + range3 * 0.5);
        } else {
            rejection = (rates[3].high >= setup.fvgLow) &&
                        (rates[3].close <= rates[3].high - range3 * 0.5);
        }
        if (!rejection) { Debug("candle 3: no rejection in FVG"); return false; }
    }

    if (RequireIndecisionCandle) {
        double body2 = MathAbs(rates[2].close - rates[2].open);
        indecision = (body2 / range2 * 100.0 <= MaxIndecisionBodyPercent);
        if (!indecision) { Debug("candle 2: not an indecision candle"); return false; }
    }

    if (RequireConfirmationCandle) {
        double body1 = (direction == BIAS_BULLISH)
                     ? rates[1].close - rates[1].open
                     : rates[1].open  - rates[1].close;

        confirmation = (body1 > 0.0) && (body1 / range1 * 100.0 >= MinConfirmationBodyPercent);
        if (!confirmation) { Debug("candle 1: confirmation body too weak"); return false; }

        if (RequireVolumeConfirmation) {
            long v1 = (long)rates[1].tick_volume;
            if (v1 <= (long)rates[2].tick_volume || v1 <= (long)rates[3].tick_volume) {
                Debug("candle 1: volume does not confirm");
                return false;
            }
        }
    }

    return true;
}

//+------------------------------------------------------------------+
// PRICE TARGETS
//+------------------------------------------------------------------+

// Collect swing levels beyond refPrice as take-profit candidates.
void CollectTargets(ENUM_TIMEFRAMES timeframe, bool wantHighs, double refPrice, double &out[]) {
    MqlRates rates[];
    ArraySetAsSeries(rates, true);

    int copied = CopyRates(_Symbol, timeframe, 0, BiasLookbackBars, rates);
    if (copied < 30) return;

    SwingPoint swings[];
    int n = FindSwings(rates, copied, wantHighs, swings);

    for (int i = 0; i < n; i++) {
        if (wantHighs && swings[i].price <= refPrice) continue;
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
        double reward = (direction == BIAS_BULLISH) ? candidates[i] - entry
                                                    : entry - candidates[i];
        if (reward / risk < MinRiskRewardRatio) continue;

        if (best == 0.0) best = candidates[i];
        else if (direction == BIAS_BULLISH && candidates[i] < best) best = candidates[i];
        else if (direction == BIAS_BEARISH && candidates[i] > best) best = candidates[i];
    }

    if (best == 0.0) return false;
    takeProfit = best;
    return true;
}

bool CalculateTargets(BiasDirection direction, const MqlRates &rates[], const FVGSetup &setup,
                      double &entry, double &stopLoss, double &takeProfit) {
    double buffer  = SLBufferPoints * _Point;
    double minDist = MinStopDistance();

    if (direction == BIAS_BULLISH) {
        entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        double structureLow = MathMin(setup.fvgLow, rates[1].low);
        structureLow = MathMin(structureLow, MathMin(rates[2].low, rates[3].low));
        stopLoss = structureLow - buffer;

        if (entry - stopLoss < minDist) { Debug("stop too close to market"); return false; }
    } else {
        entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);

        double structureHigh = MathMax(setup.fvgHigh, rates[1].high);
        structureHigh = MathMax(structureHigh, MathMax(rates[2].high, rates[3].high));
        stopLoss = structureHigh + buffer;

        if (stopLoss - entry < minDist) { Debug("stop too close to market"); return false; }
    }

    double risk = MathAbs(entry - stopLoss);
    if (risk <= 0.0) return false;

    if (!FindTakeProfit(direction, entry, risk, takeProfit)) {
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
    double price  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    if (!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lots, price, margin)) return 0.0;
    if (margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE) * 0.9) {
        Debug("not enough free margin");
        return 0.0;
    }

    return lots;
}

//+------------------------------------------------------------------+
// EXECUTION & MANAGEMENT
//+------------------------------------------------------------------+

// Market entry on the open of the bar following the confirmation close.
bool ExecuteTrade(BiasDirection direction, double stopLoss, double takeProfit, double lots) {
    trade.SetTypeFillingBySymbol(_Symbol);
    trade.SetDeviationInPoints(SlippagePoints);

    bool ok = (direction == BIAS_BULLISH)
            ? trade.Buy(lots, _Symbol, 0.0, stopLoss, takeProfit, "FVG Buy")
            : trade.Sell(lots, _Symbol, 0.0, stopLoss, takeProfit, "FVG Sell");

    if (!ok) {
        Print("[FVG] Order failed. Retcode=", trade.ResultRetcode(),
              " (", trade.ResultRetcodeDescription(), ")");
        return false;
    }

    Print(StringFormat("[FVG] %s %.2f lots | entry %.5f | SL %.5f | TP %.5f | R:R %.2f",
          (direction == BIAS_BULLISH ? "BUY" : "SELL"), lots, trade.ResultPrice(),
          stopLoss, takeProfit,
          MathAbs(takeProfit - trade.ResultPrice()) / MathAbs(trade.ResultPrice() - stopLoss)));
    return true;
}

int CountOpenTrades() {
    int count = 0;

    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (posInfo.SelectByIndex(i) &&
            posInfo.Symbol() == _Symbol && posInfo.Magic() == MagicNumber) count++;
    }

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
            if (bid - openPrice < distance) continue;      // only trail once in profit
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

    if (RiskPercentage <= 0.0 || RiskPercentage > 5.0) {
        Print("[FVG] RiskPercentage must be between 0 and 5");
        return INIT_PARAMETERS_INCORRECT;
    }
    if (FibonacciRetracementLevel <= 0.0 || FibonacciRetracementLevel >= 1.0) {
        Print("[FVG] FibonacciRetracementLevel must be between 0 and 1");
        return INIT_PARAMETERS_INCORRECT;
    }
    if (MaxRetracement <= FibonacciRetracementLevel) {
        Print("[FVG] MaxRetracement must exceed FibonacciRetracementLevel");
        return INIT_PARAMETERS_INCORRECT;
    }

    Print("=== FVG Strategy EA v2.01 ===");
    Print("Symbol: ", _Symbol, " | Risk: ", RiskPercentage, "% | Min R:R: ", MinRiskRewardRatio);

    // Swing structure needs deep history on every timeframe; a short chart
    // silently reports a flat bias and the EA would never find an alignment.
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
    Print("[FVG] EA stopped (reason ", reason, ")");
}

void OnTick() {
    if (UseTrailingStop) UpdateTrailingStops();

    // Everything below runs once per closed M30 bar, never on a forming candle.
    if (!IsNewBar()) return;
    if (!IsTradingTime()) return;
    if (CountOpenTrades() >= MaxOpenTrades) return;
    if (!SpreadOK()) return;

    BiasDirection d1  = AnalyzeBias(PERIOD_D1);
    BiasDirection h4  = AnalyzeBias(PERIOD_H4);
    BiasDirection m30 = AnalyzeBias(PERIOD_M30);

    // Logged on change only, so the journal shows the structure trail without
    // one line per bar.
    static string lastState = "";
    string state = BiasName(d1) + " / " + BiasName(h4) + " / " + BiasName(m30);
    if (state != lastState) {
        lastState = state;
        Debug("bias D1/H4/M30 = " + state +
              (IsAlignmentValid(d1, h4, m30) ? "   << ALIGNED" : ""));
    }

    if (!IsAlignmentValid(d1, h4, m30)) return;

    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(_Symbol, PERIOD_M30, 0, EntryLookbackBars, rates);
    if (copied < 50) { Debug(StringFormat("only %d M30 bars available", copied)); return; }

    FVGSetup setup = DetectFVGSetup(d1, rates, copied);
    if (!setup.isValid) return;

    if (!ValidateConfirmation(d1, rates, setup)) return;

    double entry, stopLoss, takeProfit;
    if (!CalculateTargets(d1, rates, setup, entry, stopLoss, takeProfit)) return;

    double lots = CalculateLotSize(entry, stopLoss);
    if (lots <= 0.0) return;

    ExecuteTrade(d1, stopLoss, takeProfit, lots);
}
//+------------------------------------------------------------------+
