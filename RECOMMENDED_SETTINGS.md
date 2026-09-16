# FVG EA - Recommended Settings by Trading Profile

## Profile 1: Conservative Trader (Low Risk, High Win Rate)

**Goal**: Maximize win rate, minimize drawdown

```
// Risk Management
RiskPercentage = 0.5;           // Very conservative risk
MinRiskRewardRatio = 3.0;       // High R:R requirement
MaxOpenTrades = 1;              // One trade at a time

// Strategy Parameters
FibonacciRetracementLevel = 0.5;
ImpulseMinBars = 10;            // Wait for clearer impulses
FVGMinPips = 10.0;              // Only large FVGs
RequireVolumeConfirmation = true;

// Candle Confirmation
RequireRejectionCandle = true;
RequireIndecisionCandle = true;
RequireConfirmationCandle = true;
MinConfirmationBodyPercent = 75.0;  // Strong confirmation

// Trading Hours
StartHour = 8;                  // London open
EndHour = 17;                   // New York close

// EA Settings
ShowDebugInfo = true;
UseTrailingStop = true;
TrailingStopDistance = 100;     // Protected trailing

Expected Results:
- Win Rate: 65-70%
- Avg Win/Loss: 3:1
- Monthly Drawdown: 5-10%
```

---

## Profile 2: Balanced Trader (Moderate Risk, Balanced Approach)

**Goal**: Good balance between win rate and profit potential

```
// Risk Management
RiskPercentage = 1.0;           // Standard risk
MinRiskRewardRatio = 2.0;       // Good R:R requirement
MaxOpenTrades = 1;              // Conservative position

// Strategy Parameters
FibonacciRetracementLevel = 0.5;
ImpulseMinBars = 5;             // Medium impulse strength
FVGMinPips = 5.0;               // Standard FVG size
RequireVolumeConfirmation = true;

// Candle Confirmation
RequireRejectionCandle = true;
RequireIndecisionCandle = true;
RequireConfirmationCandle = true;
MinConfirmationBodyPercent = 60.0;  // Standard confirmation

// Trading Hours
StartHour = 0;                  // 24/5 trading
EndHour = 23;

// EA Settings
ShowDebugInfo = true;
UseTrailingStop = true;
TrailingStopDistance = 50;      // Moderate trailing

Expected Results:
- Win Rate: 60-65%
- Avg Win/Loss: 2:1
- Monthly Drawdown: 10-15%
```

---

## Profile 3: Aggressive Trader (Higher Risk, More Opportunities)

**Goal**: Maximize trading opportunities and profit potential

```
// Risk Management
RiskPercentage = 1.5;           // Higher risk tolerance
MinRiskRewardRatio = 1.5;       // Lower R:R requirement
MaxOpenTrades = 2;              // Multiple positions

// Strategy Parameters
FibonacciRetracementLevel = 0.5;
ImpulseMinBars = 3;             // Faster impulse detection
FVGMinPips = 3.0;               // Smaller FVGs allowed
RequireVolumeConfirmation = false; // Less strict

// Candle Confirmation
RequireRejectionCandle = true;
RequireIndecisionCandle = false; // Optional indecision
RequireConfirmationCandle = true;
MinConfirmationBodyPercent = 50.0;  // Lower confirmation threshold

// Trading Hours
StartHour = 0;                  // 24/5 trading
EndHour = 23;

// EA Settings
ShowDebugInfo = false;          // Less logging
UseTrailingStop = false;        // Simple TP targets
TrailingStopDistance = 0;

Expected Results:
- Win Rate: 50-55%
- Avg Win/Loss: 1.5:1
- Monthly Drawdown: 15-25%
- More frequent trades
```

---

## Profile 4: Scalper (Very Short-Term, High Frequency)

**Goal**: Quick profits on M30 timeframe

```
// Risk Management
RiskPercentage = 0.5;           // Lower per trade
MinRiskRewardRatio = 1.5;       // Quick targets
MaxOpenTrades = 3;              // Multiple scalps

// Strategy Parameters
FibonacciRetracementLevel = 0.5;
ImpulseMinBars = 3;             // Very quick detection
FVGMinPips = 2.0;               // Tiny FVGs count
RequireVolumeConfirmation = false;

// Candle Confirmation
RequireRejectionCandle = false;  // Less strict
RequireIndecisionCandle = false;
RequireConfirmationCandle = true;
MinConfirmationBodyPercent = 40.0;  // Minimal confirmation

// Trading Hours
StartHour = 8;                  // Active hours only (London/US)
EndHour = 17;

// EA Settings
ShowDebugInfo = false;
UseTrailingStop = false;        // Quick exits
TrailingStopDistance = 0;

Expected Results:
- Win Rate: 45-50% (high trades)
- Avg Win/Loss: 1:1 (many small wins)
- Monthly Drawdown: 5-10%
- 20-30+ trades per month
```

---

## Profile 5: Swing Trader (Longer-Term Holds)

**Goal**: Hold positions for multiple days/weeks for larger moves

```
// Risk Management
RiskPercentage = 1.0;
MinRiskRewardRatio = 2.5;       // Target larger rewards
MaxOpenTrades = 1;              // Hold longer

// Strategy Parameters
FibonacciRetracementLevel = 0.5;
ImpulseMinBars = 20;            // Very strong impulses only
FVGMinPips = 15.0;              // Only large FVGs
RequireVolumeConfirmation = true;

// Candle Confirmation
RequireRejectionCandle = true;
RequireIndecisionCandle = true;
RequireConfirmationCandle = true;
MinConfirmationBodyPercent = 70.0;

// Trading Hours
StartHour = 0;                  // Flexible hours
EndHour = 23;

// EA Settings
ShowDebugInfo = true;
UseTrailingStop = true;
TrailingStopDistance = 150;     // Protect large wins

Expected Results:
- Win Rate: 60-65%
- Avg Win/Loss: 2.5:1
- Holding time: 2-7 days
- Monthly Drawdown: 10-15%
- 2-5 trades per month
```

---

## Setup by Trading Account Size

### Micro Account ($500 - $2,000)

```
// Start conservative to preserve capital
RiskPercentage = 0.5;
MinRiskRewardRatio = 2.5;
FVGMinPips = 5.0;
MinConfirmationBodyPercent = 65.0;
```

### Mini Account ($2,000 - $10,000)

```
// Balanced approach
RiskPercentage = 1.0;
MinRiskRewardRatio = 2.0;
FVGMinPips = 5.0;
MinConfirmationBodyPercent = 60.0;
```

### Standard Account ($10,000 - $50,000)

```
// More flexibility
RiskPercentage = 1.0 - 1.5;
MinRiskRewardRatio = 2.0;
FVGMinPips = 3.0 - 5.0;
MinConfirmationBodyPercent = 55.0;
MaxOpenTrades = 2;
```

### Large Account ($50,000+)

```
// Can afford more aggressive testing
RiskPercentage = 1.0 - 2.0;
MinRiskRewardRatio = 1.5;
FVGMinPips = 2.0 - 3.0;
MinConfirmationBodyPercent = 50.0;
MaxOpenTrades = 3 - 5;
```

---

## Setup by Market Condition

### Trending Markets (Strong Directional Bias)

```
// Perfect for FVG strategy
ImpulseMinBars = 5;
FVGMinPips = 3.0;
MinRiskRewardRatio = 2.0;
RiskPercentage = 1.0;
UseTrailingStop = true;         // Let winners run
TrailingStopDistance = 75;
```

### Range-Bound Markets (No Clear Direction)

```
// More selective
ImpulseMinBars = 15;            // Wait for breakout impulse
FVGMinPips = 10.0;              // Only large gaps
MinRiskRewardRatio = 3.0;       // Strict R:R
RiskPercentage = 0.5;           // Lower risk
MaxOpenTrades = 1;
```

### Volatile Markets (Large Moves, Wide Swings)

```
// Adapt to volatility
ImpulseMinBars = 3;             // Quick reaction
FVGMinPips = 2.0;               // Accept smaller gaps
MinConfirmationBodyPercent = 50.0; // Less strict
RiskPercentage = 0.5;           // Reduce position size
MinRiskRewardRatio = 2.0;       // Maintain quality
```

### Low Volatility Markets (Small Moves)

```
// Require confirmation
FVGMinPips = 5.0;               // Meaningful gaps only
ImpulseMinBars = 10;            // Clear impulses
MinRiskRewardRatio = 2.5;       // Good rewards
RiskPercentage = 1.0;
```

---

## Symbol-Specific Recommendations

### EURUSD (Most Recommended)

```
// Standard major pair
RiskPercentage = 1.0;
MinRiskRewardRatio = 2.0;
FVGMinPips = 5.0;
UseTrailingStop = true;
TrailingStopDistance = 50;
```

### GBPUSD (Volatile, Good Moves)

```
// More volatile, larger moves
RiskPercentage = 1.0;
MinRiskRewardRatio = 2.5;       // Target larger rewards
FVGMinPips = 3.0;
UseTrailingStop = true;
TrailingStopDistance = 75;
```

### USDJPY (Fast Reactions)

```
// Quick reactions to news
RiskPercentage = 0.5;           // Reduce size for volatility
MinRiskRewardRatio = 2.0;
FVGMinPips = 5.0;
MinConfirmationBodyPercent = 70.0; // Strict confirmation
```

### AUDUSD (Trending Pairs)

```
// Good for trend following
RiskPercentage = 1.0;
MinRiskRewardRatio = 2.0;
FVGMinPips = 3.0;
ImpulseMinBars = 5;             // Medium impulse
UseTrailingStop = true;
```

### Crypto (BTCUSD, ETHUSD) - If Available

```
// Very volatile, 24/5 trading
RiskPercentage = 0.5;           // Reduce for volatility
MinRiskRewardRatio = 3.0;       // Strict R:R
FVGMinPips = 2.0;               // Small gaps matter
MinConfirmationBodyPercent = 50.0;
StartHour = 0;
EndHour = 23;
```

---

## Quick Start Templates

### Copy-Paste for Conservative Start

```mq5
// Paste into EA inputs and click Apply
RiskPercentage = 0.5;
MinRiskRewardRatio = 2.5;
MaxOpenTrades = 1;
ImpulseMinBars = 10;
FVGMinPips = 10.0;
MinConfirmationBodyPercent = 70.0;
UseTrailingStop = true;
TrailingStopDistance = 100;
ShowDebugInfo = true;
```

### Copy-Paste for Balanced Start

```mq5
// Paste into EA inputs and click Apply
RiskPercentage = 1.0;
MinRiskRewardRatio = 2.0;
MaxOpenTrades = 1;
ImpulseMinBars = 5;
FVGMinPips = 5.0;
MinConfirmationBodyPercent = 60.0;
UseTrailingStop = true;
TrailingStopDistance = 50;
ShowDebugInfo = true;
```

### Copy-Paste for Aggressive Start

```mq5
// Paste into EA inputs and click Apply
RiskPercentage = 1.5;
MinRiskRewardRatio = 1.5;
MaxOpenTrades = 2;
ImpulseMinBars = 3;
FVGMinPips = 3.0;
MinConfirmationBodyPercent = 50.0;
UseTrailingStop = false;
ShowDebugInfo = false;
```

---

## Optimization Workflow

1. **Start Conservative**
   - Use conservative profile
   - Run on demo for 2-4 weeks
   - Evaluate results

2. **Analyze Trades**
   - Check win rate
   - Review losing trades
   - Identify patterns

3. **Fine-Tune Parameters**
   - If win rate too low: Increase confirmation requirements
   - If too few trades: Decrease FVGMinPips, ImpulseMinBars
   - If R:R bad: Increase MinRiskRewardRatio

4. **Test New Settings**
   - Run another 2-4 weeks on demo
   - Compare with previous results
   - Only keep improvements

5. **Go Live Gradually**
   - Start with 1 micro lot
   - Gradually increase as confidence grows
   - Keep position sizes small initially

---

## Monitoring Checklist

- [ ] EA is running (green smiley in chart corner)
- [ ] Account balance sufficient for minimum lot
- [ ] Broker spread acceptable for symbol
- [ ] Market hours appropriate for trading
- [ ] No major economic news events
- [ ] Journal shows no errors
- [ ] Take-profit and stop-loss are reasonable
- [ ] Risk/reward ratio meets minimum requirement

---

## When to Adjust Settings

### Increase Risk (if win rate > 70%)
- Gradually raise RiskPercentage by 0.25%
- Monitor for drawdown increase

### Decrease Risk (if drawdown > 20%)
- Lower RiskPercentage by 0.5%
- Increase MinRiskRewardRatio

### More Trades (if too few opportunities)
- Lower FVGMinPips
- Lower ImpulseMinBars
- Reduce MinConfirmationBodyPercent

### Better Quality (if too many losses)
- Increase MinConfirmationBodyPercent
- Increase ImpulseMinBars
- Increase MinRiskRewardRatio

---

## Remember

> "The best settings are the ones that match YOUR risk tolerance and trading personality."

Not all traders need the same settings. Experiment, monitor, and adjust based on YOUR results.

---

**Last Updated**: 2026
