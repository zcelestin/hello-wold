//+------------------------------------------------------------------+
//|                    FVG Trading Strategy EA                        |
//|                                                                   |
//| Strategy: Fair Value Gap (FVG) with Multi-Timeframe Analysis     |
//| Timeframes: D1 (Bias) → H4 (Confirmation) → M30 (Entry)         |
//| Created: 2026                                                    |
//+------------------------------------------------------------------+

#property copyright "FVG Trading System"
#property link "https://github.com/zcelestin/hello-wold"
#property version "1.0"
#property description "FVG Trading Strategy EA based on Multi-Timeframe Analysis"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
// INPUT PARAMETERS
//+------------------------------------------------------------------+

input group "=== Risk Management ==="
input double RiskPercentage = 1.0;              // Risk per trade (0.5 - 1%)
input double MinRiskRewardRatio = 2.0;          // Minimum Risk/Reward ratio
input int MaxOpenTrades = 1;                    // Maximum simultaneous trades

input group "=== Strategy Parameters ==="
input double FibonacciRetracementLevel = 0.5;  // Fibonacci retracement level (50%)
input int ImpulseMinBars = 5;                   // Minimum bars for impulse
input double FVGMinPips = 5.0;                  // Minimum FVG size in pips
input bool RequireVolumeConfirmation = true;   // Require volume confirmation

input group "=== Candle Confirmation ==="
input bool RequireRejectionCandle = true;      // Candle 1: Rejection
input bool RequireIndecisionCandle = true;     // Candle 2: Indecision
input bool RequireConfirmationCandle = true;   // Candle 3: Strong confirmation
input double MinConfirmationBodyPercent = 60.0; // Min body size for confirmation (%)

input group "=== Trading Hours ==="
input int StartHour = 0;                       // Start trading at (0-23)
input int EndHour = 23;                        // Stop trading at (0-23)

input group "=== EA Settings ==="
input bool ShowDebugInfo = true;               // Show debug information
input bool UseTrailingStop = false;             // Use trailing stop
input int TrailingStopDistance = 50;            // Trailing stop distance (pips)

//+------------------------------------------------------------------+
// GLOBAL VARIABLES
//+------------------------------------------------------------------+

CTrade trade;
CSymbolInfo symInfo;

enum BiasDirection {
    BIAS_NEUTRAL = 0,
    BIAS_BULLISH = 1,
    BIAS_BEARISH = -1
};

struct FVGSetup {
    bool isValid;
    BiasDirection direction;
    double fvgHigh;
    double fvgLow;
    double fibLevel;
    int detectionBar;
    double impulseHigh;
    double impulseLow;
};

struct ConfirmationPattern {
    bool hasRejectionCandle;
    bool hasIndecisionCandle;
    bool hasConfirmationCandle;
    bool isComplete;
};

//+------------------------------------------------------------------+
// INITIALIZATION & DEINITIALIZATION
//+------------------------------------------------------------------+

int OnInit() {
    trade.SetExpertMagicNumber(123456);

    if (!symInfo.Name(_Symbol)) {
        Print("Error: Failed to initialize symbol info");
        return INIT_FAILED;
    }

    if (ShowDebugInfo) {
        Print("=== FVG Trading Strategy EA Initialized ===");
        Print("Symbol: ", _Symbol);
        Print("Risk per trade: ", RiskPercentage, "%");
        Print("Min R:R Ratio: ", MinRiskRewardRatio, ":1");
    }

    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    if (ShowDebugInfo) {
        Print("EA Deinitialized");
    }
}

//+------------------------------------------------------------------+
// MAIN LOOP
//+------------------------------------------------------------------+

void OnTick() {
    // Check if it's trading time
    if (!IsTradingTime()) {
        return;
    }

    // Check existing positions
    if (CountOpenTrades() >= MaxOpenTrades) {
        ManageExistingTrades();
        return;
    }

    // Analyze market setup
    BiasDirection d1Bias = AnalyzeBias(PERIOD_D1);
    BiasDirection h4Bias = AnalyzeBias(PERIOD_H4);
    BiasDirection m30Bias = AnalyzeBias(PERIOD_M30);

    // Validate alignment
    if (!IsAlignmentValid(d1Bias, h4Bias, m30Bias)) {
        return;
    }

    // Identify impulse and FVG
    FVGSetup fvgSetup = DetectFVGSetup(m30Bias);
    if (!fvgSetup.isValid) {
        return;
    }

    // Check confirmation pattern
    ConfirmationPattern pattern = ValidateConfirmationPattern(fvgSetup);
    if (!pattern.isComplete) {
        return;
    }

    // Calculate entry, SL, TP
    double entryPrice, stopLoss, takeProfit;
    if (!CalculatePriceTargets(fvgSetup, entryPrice, stopLoss, takeProfit)) {
        return;
    }

    // Validate R:R ratio
    double riskRewardRatio = CalculateRiskReward(entryPrice, stopLoss, takeProfit, fvgSetup.direction);
    if (riskRewardRatio < MinRiskRewardRatio) {
        if (ShowDebugInfo) {
            Print("R:R ratio too low: ", riskRewardRatio, " vs required: ", MinRiskRewardRatio);
        }
        return;
    }

    // Calculate lot size
    double lotSize = CalculateLotSize(stopLoss, fvgSetup.direction);
    if (lotSize <= 0) {
        return;
    }

    // Execute trade
    ExecuteTrade(fvgSetup.direction, entryPrice, stopLoss, takeProfit, lotSize);
}

//+------------------------------------------------------------------+
// TIMEFRAME BIAS ANALYSIS
//+------------------------------------------------------------------+

BiasDirection AnalyzeBias(ENUM_TIMEFRAMES timeframe) {
    int bars = 20; // Analyze last 20 bars
    double highestHigh = High[iHighest(_Symbol, timeframe, MODE_HIGH, bars, 1)];
    double lowestLow = Low[iLowest(_Symbol, timeframe, MODE_LOW, bars, 1)];

    // Count Higher Highs, Higher Lows (bullish) vs Lower Highs, Lower Lows (bearish)
    int hhCount = 0, llCount = 0;

    for (int i = 2; i < bars - 1; i++) {
        double high_i = iHigh(_Symbol, timeframe, i);
        double high_i1 = iHigh(_Symbol, timeframe, i + 1);
        double low_i = iLow(_Symbol, timeframe, i);
        double low_i1 = iLow(_Symbol, timeframe, i + 1);

        if (high_i > high_i1) hhCount++;
        if (low_i < low_i1) llCount++;
    }

    // Determine bias
    if (hhCount > llCount) {
        return BIAS_BULLISH;
    } else if (llCount > hhCount) {
        return BIAS_BEARISH;
    }

    return BIAS_NEUTRAL;
}

//+------------------------------------------------------------------+
// ALIGNMENT VALIDATION
//+------------------------------------------------------------------+

bool IsAlignmentValid(BiasDirection d1, BiasDirection h4, BiasDirection m30) {
    // All three timeframes must align
    if (d1 == BIAS_NEUTRAL || h4 == BIAS_NEUTRAL || m30 == BIAS_NEUTRAL) {
        return false;
    }

    if (d1 != h4 || h4 != m30) {
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
// FVG DETECTION
//+------------------------------------------------------------------+

FVGSetup DetectFVGSetup(BiasDirection direction) {
    FVGSetup setup;
    setup.isValid = false;
    setup.direction = direction;

    // Detect impulse first
    if (!DetectImpulse(direction, setup.impulseHigh, setup.impulseLow, setup.detectionBar)) {
        return setup;
    }

    // Calculate Fibonacci retracement
    double fibLevel = CalculateFibonacciLevel(setup.impulseHigh, setup.impulseLow, direction);
    setup.fibLevel = fibLevel;

    // Check if retracement reaches 50%
    double currentPrice = Close[0];
    if (direction == BIAS_BULLISH) {
        double retracementPercent = (setup.impulseHigh - currentPrice) / (setup.impulseHigh - setup.impulseLow);
        if (retracementPercent < 0.5) {
            return setup; // Retracement less than 50%
        }
    } else {
        double retracementPercent = (currentPrice - setup.impulseLow) / (setup.impulseHigh - setup.impulseLow);
        if (retracementPercent < 0.5) {
            return setup; // Retracement less than 50%
        }
    }

    // Detect FVG
    if (!DetectFVG(direction, setup.fvgHigh, setup.fvgLow)) {
        return setup;
    }

    // Validate FVG is within Fibonacci zone
    if (!IsValidFVGPosition(setup, direction)) {
        return setup;
    }

    setup.isValid = true;
    return setup;
}

bool DetectImpulse(BiasDirection direction, double &impulseHigh, double &impulseLow, int &detectionBar) {
    if (direction == BIAS_BULLISH) {
        impulseHigh = iHigh(_Symbol, PERIOD_M30, iHighest(_Symbol, PERIOD_M30, MODE_HIGH, ImpulseMinBars, 1));
        impulseHigh = MathMax(impulseHigh, iHigh(_Symbol, PERIOD_M30, 1));

        // Find the low point before the impulse
        int lowestBar = iLowest(_Symbol, PERIOD_M30, MODE_LOW, ImpulseMinBars, 1);
        impulseLow = iLow(_Symbol, PERIOD_M30, lowestBar);

        detectionBar = 1;
        return impulseHigh > impulseLow + FVGMinPips * _Point;
    } else {
        impulseLow = iLow(_Symbol, PERIOD_M30, iLowest(_Symbol, PERIOD_M30, MODE_LOW, ImpulseMinBars, 1));
        impulseLow = MathMin(impulseLow, iLow(_Symbol, PERIOD_M30, 1));

        // Find the high point before the impulse
        int highestBar = iHighest(_Symbol, PERIOD_M30, MODE_HIGH, ImpulseMinBars, 1);
        impulseHigh = iHigh(_Symbol, PERIOD_M30, highestBar);

        detectionBar = 1;
        return impulseHigh > impulseLow + FVGMinPips * _Point;
    }
}

double CalculateFibonacciLevel(double high, double low, BiasDirection direction) {
    if (direction == BIAS_BULLISH) {
        return high - ((high - low) * FibonacciRetracementLevel);
    } else {
        return low + ((high - low) * FibonacciRetracementLevel);
    }
}

bool DetectFVG(BiasDirection direction, double &fvgHigh, double &fvgLow) {
    // FVG is created by 3 candles: gap between candle 1 high and candle 3 low (bullish)
    // or gap between candle 1 low and candle 3 high (bearish)

    if (direction == BIAS_BULLISH) {
        // Check for bullish FVG: High(1) > Low(3)
        double candle1High = iHigh(_Symbol, PERIOD_M30, 3);
        double candle3Low = iLow(_Symbol, PERIOD_M30, 1);

        if (candle1High > candle3Low) {
            fvgLow = candle3Low;
            fvgHigh = candle1High;
            return true;
        }
    } else {
        // Check for bearish FVG: Low(1) < High(3)
        double candle1Low = iLow(_Symbol, PERIOD_M30, 3);
        double candle3High = iHigh(_Symbol, PERIOD_M30, 1);

        if (candle1Low < candle3High) {
            fvgLow = candle1Low;
            fvgHigh = candle3High;
            return true;
        }
    }

    return false;
}

bool IsValidFVGPosition(FVGSetup &setup, BiasDirection direction) {
    // FVG should be within 50% - 100% of retracement zone
    if (direction == BIAS_BULLISH) {
        double fvgMid = (setup.fvgHigh + setup.fvgLow) / 2;
        return fvgMid >= setup.fibLevel && fvgMid <= setup.impulseHigh;
    } else {
        double fvgMid = (setup.fvgHigh + setup.fvgLow) / 2;
        return fvgMid <= setup.fibLevel && fvgMid >= setup.impulseLow;
    }
}

//+------------------------------------------------------------------+
// CONFIRMATION PATTERN (3 CANDLES)
//+------------------------------------------------------------------+

ConfirmationPattern ValidateConfirmationPattern(FVGSetup &setup) {
    ConfirmationPattern pattern;
    pattern.hasRejectionCandle = false;
    pattern.hasIndecisionCandle = false;
    pattern.hasConfirmationCandle = false;
    pattern.isComplete = false;

    if (!RequireRejectionCandle && !RequireIndecisionCandle && !RequireConfirmationCandle) {
        pattern.isComplete = true;
        return pattern;
    }

    // Analyze last 3 candles for pattern
    double close0 = iClose(_Symbol, PERIOD_M30, 0);
    double close1 = iClose(_Symbol, PERIOD_M30, 1);
    double close2 = iClose(_Symbol, PERIOD_M30, 2);
    double close3 = iClose(_Symbol, PERIOD_M30, 3);

    double open0 = iOpen(_Symbol, PERIOD_M30, 0);
    double open1 = iOpen(_Symbol, PERIOD_M30, 1);
    double open2 = iOpen(_Symbol, PERIOD_M30, 2);

    double high0 = iHigh(_Symbol, PERIOD_M30, 0);
    double high1 = iHigh(_Symbol, PERIOD_M30, 1);
    double high2 = iHigh(_Symbol, PERIOD_M30, 2);

    double low0 = iLow(_Symbol, PERIOD_M30, 0);
    double low1 = iLow(_Symbol, PERIOD_M30, 1);
    double low2 = iLow(_Symbol, PERIOD_M30, 2);

    if (setup.direction == BIAS_BULLISH) {
        // Candle 1: Rejection - dips into FVG but closes higher
        if (RequireRejectionCandle) {
            pattern.hasRejectionCandle = (low1 < setup.fvgHigh) && (close1 > open1);
        }

        // Candle 2: Indecision - small body, low volume mentally
        if (RequireIndecisionCandle) {
            double bodySize = MathAbs(close0 - open0);
            double range = high0 - low0;
            pattern.hasIndecisionCandle = (bodySize < range * 0.4); // Body < 40% of range
        }

        // Candle 3: Strong confirmation - large bullish body
        if (RequireConfirmationCandle) {
            double bodySize = close0 - open0;
            double range = high0 - low0;
            double bodyPercent = (bodySize / range) * 100.0;
            pattern.hasConfirmationCandle = (bodyPercent >= MinConfirmationBodyPercent) && (close0 > open0);
        }
    } else {
        // Candle 1: Rejection - rallies into FVG but closes lower
        if (RequireRejectionCandle) {
            pattern.hasRejectionCandle = (high1 > setup.fvgLow) && (close1 < open1);
        }

        // Candle 2: Indecision - small body
        if (RequireIndecisionCandle) {
            double bodySize = MathAbs(close0 - open0);
            double range = high0 - low0;
            pattern.hasIndecisionCandle = (bodySize < range * 0.4);
        }

        // Candle 3: Strong confirmation - large bearish body
        if (RequireConfirmationCandle) {
            double bodySize = open0 - close0;
            double range = high0 - low0;
            double bodyPercent = (bodySize / range) * 100.0;
            pattern.hasConfirmationCandle = (bodyPercent >= MinConfirmationBodyPercent) && (close0 < open0);
        }
    }

    // Check if pattern is complete
    pattern.isComplete = pattern.hasRejectionCandle || pattern.hasIndecisionCandle || pattern.hasConfirmationCandle;

    return pattern;
}

//+------------------------------------------------------------------+
// PRICE TARGETS CALCULATION
//+------------------------------------------------------------------+

bool CalculatePriceTargets(FVGSetup &setup, double &entryPrice, double &stopLoss, double &takeProfit) {
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    if (setup.direction == BIAS_BULLISH) {
        entryPrice = setup.fvgHigh; // Enter on FVG top
        stopLoss = setup.impulseLow - (FVGMinPips * _Point); // SL below impulse low

        // TP: Look for previous H4 high or structure
        takeProfit = GetPreviousResistance(setup.impulseHigh);

        if (takeProfit <= entryPrice) {
            takeProfit = entryPrice + (MathAbs(entryPrice - stopLoss) * 2.5);
        }
    } else {
        entryPrice = setup.fvgLow; // Enter on FVG bottom
        stopLoss = setup.impulseHigh + (FVGMinPips * _Point); // SL above impulse high

        // TP: Look for previous H4 low or structure
        takeProfit = GetPreviousSupport(setup.impulseLow);

        if (takeProfit >= entryPrice) {
            takeProfit = entryPrice - (MathAbs(stopLoss - entryPrice) * 2.5);
        }
    }

    return true;
}

double GetPreviousResistance(double baseLevel) {
    // Find previous resistance level on H4
    double highest = baseLevel;
    int barsToCheck = 50;

    for (int i = 2; i < barsToCheck; i++) {
        double high = iHigh(_Symbol, PERIOD_H4, i);
        if (high > baseLevel && high > highest) {
            highest = high;
        }
    }

    return highest;
}

double GetPreviousSupport(double baseLevel) {
    // Find previous support level on H4
    double lowest = baseLevel;
    int barsToCheck = 50;

    for (int i = 2; i < barsToCheck; i++) {
        double low = iLow(_Symbol, PERIOD_H4, i);
        if (low < baseLevel && low < lowest) {
            lowest = low;
        }
    }

    return lowest;
}

//+------------------------------------------------------------------+
// RISK/REWARD CALCULATION
//+------------------------------------------------------------------+

double CalculateRiskReward(double entry, double sl, double tp, BiasDirection direction) {
    double risk = MathAbs(entry - sl);
    double reward = MathAbs(tp - entry);

    if (risk == 0) return 0;

    return reward / risk;
}

//+------------------------------------------------------------------+
// LOT SIZE CALCULATION
//+------------------------------------------------------------------+

double CalculateLotSize(double stopLoss, BiasDirection direction) {
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = accountBalance * (RiskPercentage / 100.0);

    double entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double pipsRisk = MathAbs(entryPrice - stopLoss) / _Point;

    if (pipsRisk <= 0) return 0;

    double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lotSize = riskAmount / (pipsRisk * pointValue);

    // Normalize lot size
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    if (lotSize < minLot) return 0; // Risk too small
    if (lotSize > maxLot) lotSize = maxLot;

    // Round to step
    lotSize = MathFloor(lotSize / stepLot) * stepLot;

    return lotSize;
}

//+------------------------------------------------------------------+
// TRADE EXECUTION
//+------------------------------------------------------------------+

bool ExecuteTrade(BiasDirection direction, double entry, double sl, double tp, double lots) {
    if (!trade.SetTypeFillingBySymbol(_Symbol)) {
        return false;
    }

    bool result = false;

    if (direction == BIAS_BULLISH) {
        result = trade.BuyLimit(lots, entry, _Symbol, sl, tp, ORDER_TIME_GTC, 0, "FVG Buy Setup");
    } else {
        result = trade.SellLimit(lots, entry, _Symbol, sl, tp, ORDER_TIME_GTC, 0, "FVG Sell Setup");
    }

    if (result) {
        if (ShowDebugInfo) {
            Print("Trade executed successfully!");
            Print("Direction: ", (direction == BIAS_BULLISH ? "BUY" : "SELL"));
            Print("Entry: ", entry, " | SL: ", sl, " | TP: ", tp);
            Print("Lots: ", lots);
        }
    } else {
        Print("Trade failed! Error: ", GetLastError());
    }

    return result;
}

//+------------------------------------------------------------------+
// TRADE MANAGEMENT
//+------------------------------------------------------------------+

void ManageExistingTrades() {
    // Check for trailing stop
    if (UseTrailingStop) {
        UpdateTrailingStops();
    }
}

void UpdateTrailingStops() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (trade.SelectByIndex(i)) {
            if (trade.PositionSymbol() == _Symbol) {
                double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                double stopLoss = trade.PositionStopLoss();

                if (trade.PositionType() == POSITION_TYPE_BUY) {
                    double newSL = currentPrice - (TrailingStopDistance * _Point);
                    if (newSL > stopLoss) {
                        trade.PositionModify(_Symbol, newSL, trade.PositionTakeProfit());
                    }
                } else if (trade.PositionType() == POSITION_TYPE_SELL) {
                    double newSL = currentPrice + (TrailingStopDistance * _Point);
                    if (newSL < stopLoss) {
                        trade.PositionModify(_Symbol, newSL, trade.PositionTakeProfit());
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
// UTILITY FUNCTIONS
//+------------------------------------------------------------------+

int CountOpenTrades() {
    int count = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (trade.SelectByIndex(i)) {
            if (trade.PositionSymbol() == _Symbol) {
                count++;
            }
        }
    }
    return count;
}

bool IsTradingTime() {
    int currentHour = Hour();

    if (StartHour < EndHour) {
        return (currentHour >= StartHour && currentHour < EndHour);
    } else {
        return (currentHour >= StartHour || currentHour < EndHour);
    }
}

//+------------------------------------------------------------------+
// END OF EA
//+------------------------------------------------------------------+
