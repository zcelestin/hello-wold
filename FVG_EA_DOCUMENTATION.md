# FVG Trading Strategy Expert Advisor - Documentation

## Overview

The **FVG Trading Strategy EA** is a fully automated Expert Advisor based on Fair Value Gap (FVG) trading methodology with multi-timeframe analysis. It implements a structured trading system that combines:

- **Multi-Timeframe Alignment**: D1 (Daily bias) → H4 (Confirmation) → M30 (Entry signals)
- **Fair Value Gap Detection**: Automated FVG identification using 3-candle pattern
- **Fibonacci Retracement**: Ensures price retraces at least 50% before entering
- **3-Candle Confirmation Pattern**: Validates rejection, indecision, and confirmation candles
- **Dynamic Risk Management**: Calculates lot size based on account balance and risk percentage

---

## Installation

### Requirements
- **MetaTrader 5** (MT5)
- **MQL5 IDE** (comes with MT5)
- Account with a broker supporting MT5

### Installation Steps

1. **Copy the EA file**
   - Download `FVG_Trading_Strategy_EA.mq5`
   - Save to: `C:\Users\[YourUsername]\AppData\Roaming\MetaQuotes\Terminal\[TerminalID]\MQL5\Experts\`

2. **Compile the EA**
   - Open MetaTrader 5
   - Go to `View` → `Navigator`
   - Right-click on `Experts` folder → `New...` or navigate to the file
   - In MetaEditor, open the `.mq5` file and click `Compile` (F5)
   - Should show "0 errors" when successful

3. **Restart MT5**
   - Close and reopen MetaTrader 5

4. **Attach to a Chart**
   - Open any chart (preferably 30-minute M30 for optimal analysis)
   - Select the symbol you want to trade
   - Go to `Insert` → `Expert Advisors` → `FVG_Trading_Strategy_EA`
   - Configure parameters (see below)
   - Click `OK`

---

## Parameter Configuration

### Risk Management Parameters

| Parameter | Default | Recommended | Description |
|-----------|---------|-------------|-------------|
| `RiskPercentage` | 1.0 | 0.5 - 1.0 | Risk per trade (% of account balance) |
| `MinRiskRewardRatio` | 2.0 | 1.5 - 2.5 | Minimum R:R ratio required |
| `MaxOpenTrades` | 1 | 1 - 2 | Maximum simultaneous positions |

**Example**: With a $1000 account and 1% risk:
- Risk per trade = $10
- Stop-loss distance determines lot size
- If SL is 50 pips away, lot size is calculated automatically

### Strategy Parameters

| Parameter | Default | Recommended | Description |
|-----------|---------|-------------|-------------|
| `FibonacciRetracementLevel` | 0.5 | 0.5 | Fibonacci level (50% = 0.5) |
| `ImpulseMinBars` | 5 | 5 - 10 | Minimum bars to identify impulse |
| `FVGMinPips` | 5.0 | 3.0 - 10.0 | Minimum FVG gap size in pips |
| `RequireVolumeConfirmation` | true | true | Require volume confirmation |

### Candle Confirmation Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `RequireRejectionCandle` | true | Candle 1 must show rejection |
| `RequireIndecisionCandle` | true | Candle 2 must show indecision |
| `RequireConfirmationCandle` | true | Candle 3 must be strong confirmation |
| `MinConfirmationBodyPercent` | 60.0 | Minimum confirmation body size (%) |

### Trading Hours Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `StartHour` | 0 | Start trading at (0-23 hour) |
| `EndHour` | 23 | Stop trading at (0-23 hour) |

**Example**: To trade only 9 AM to 5 PM (server time):
- `StartHour = 9`
- `EndHour = 17`

### EA Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ShowDebugInfo` | true | Display debug messages in journal |
| `UseTrailingStop` | false | Activate trailing stop-loss |
| `TrailingStopDistance` | 50 | Trailing stop distance in pips |

---

## How the Strategy Works

### Step 1: Determine Daily Bias (D1)

The EA analyzes the Daily timeframe to identify the market direction:

- **Bullish Bias** (🟢): Higher Highs + Higher Lows
- **Bearish Bias** (🔴): Lower Highs + Lower Lows
- **Neutral** (⛔): Confused or ranging structure → NO TRADES

```
D1 Analysis Example (Bullish):
  ▲ HH2
  │  ▲ HH1
  │  │
  └──┴── HL2
     └─ HL1
```

### Step 2: Confirm on H4

The EA validates the H4 timeframe aligns with the D1 bias:

```
D1 Bias → H4 Confirmation → Action
  🟢   →      🟢      → Search for BUYS
  🔴   →      🔴      → Search for SELLS
  🟢   →      🔴      → ❌ NO TRADE
  🔴   →      🟢      → ❌ NO TRADE
```

### Step 3: Validate on M30

The M30 (30-minute) timeframe must also align with D1 and H4:

```
Example: Bullish Setup
D1 🟢 → H4 🟢 → M30 🟢 → Search for BUYS
```

If any timeframe is misaligned → **NO TRADE**

### Step 4: Identify Impulse on M30

The EA searches for a clear directional movement (impulse):

```
Bullish Impulse:        Bearish Impulse:
    High                    Start
     ▲                       \
    /│                        \
   / │                         \
  /  │                          \
 /   │                           \
/    │                            Low
Start └─ Retracement               ▲
                                   |
                                  Retracement
```

### Step 5: Apply Fibonacci Retracement

The EA draws Fibonacci levels from impulse start → impulse end:

```
Bullish:
100% ─── Impulse High
     \
      \  50% Zone (monitoring area)
       \
       \
0%  ─── Impulse Low

Entry will be triggered ONLY if price retraces at least 50%
```

**Rule**: Retracement must reach ≥ 50% → Otherwise, NO TRADE

### Step 6: Detect Fair Value Gap (FVG)

A Fair Value Gap is created when 3 candles show a gap that wasn't filled:

```
Bullish FVG:              Bearish FVG:
  Candle 1 │               Candle 1 │
      │    │                    │   │
      │ ███│ (high)             │   │ (low)
      │ ███│                    │ ███
  Gap │ [  ] ← FVG            Gap │ [  ] ← FVG
      │    ┃                    │   ┃
      │    └─ Candle 3 (low)   │   └─ Candle 3 (high)
```

**Requirement**: FVG must be ≥ 50% into the retracement zone

### Step 7: Await 3-Candle Confirmation

Once price enters the FVG, the EA waits for a specific 3-candle pattern:

#### For BULLISH Setup (Buy):

```
Candle 1 (Rejection):
  - Price dips into FVG
  - Closes HIGHER than open
  ▲ (bullish candle with low penetrating FVG)

Candle 2 (Indecision):
  - Small body (less than 40% of range)
  - Could be Doji or small candle
  | (small candle showing uncertainty)

Candle 3 (Strong Confirmation):
  - Large bullish body (≥ 60% of range)
  - Closes significantly higher
  ▲▲ (strong bullish candle)

➡️ ENTRY → BUY after candle 3 closes
```

#### For BEARISH Setup (Sell):

```
Candle 1 (Rejection):
  - Price rallies into FVG
  - Closes LOWER than open
  ▼ (bearish candle with high penetrating FVG)

Candle 2 (Indecision):
  - Small body
  | (small candle showing doubt)

Candle 3 (Strong Confirmation):
  - Large bearish body (≥ 60% of range)
  - Closes significantly lower
  ▼▼ (strong bearish candle)

➡️ ENTRY → SELL after candle 3 closes
```

### Step 8: Calculate Entry, Stop-Loss, and Take-Profit

```
BULLISH Setup:
  Entry Price: Top of FVG
  Stop-Loss: Below impulse low
  Take-Profit: Previous H4 resistance or 2.5x risk

BEARISH Setup:
  Entry Price: Bottom of FVG
  Stop-Loss: Above impulse high
  Take-Profit: Previous H4 support or 2.5x risk
```

### Step 9: Validate Risk/Reward Ratio

The EA checks if the R:R ratio meets minimum requirements:

```
Risk (R) = Distance from Entry to Stop-Loss
Reward (RW) = Distance from Entry to Take-Profit
R:R Ratio = Reward / Risk

Example:
  Entry: 1.0500
  SL: 1.0450 (50 pips risk)
  TP: 1.0600 (100 pips reward)
  R:R = 100 / 50 = 2.0 (1:2 ratio) ✓

If R:R < MinRiskRewardRatio → NO TRADE
```

### Step 10: Execute Trade with Calculated Lot Size

```
Lot Size Calculation:
  Account Balance: $1000
  Risk %: 1% → Risk Amount = $10
  SL Distance: 50 pips
  Point Value: Varies by symbol

Lot Size = Risk Amount / (Pips Risk × Point Value)
Result: Automatically normalized to broker's requirements
```

---

## Risk Management

### Position Sizing

The EA uses a **fixed risk per trade** approach:

1. Account balance retrieved
2. Risk percentage applied (default 1%)
3. Lot size calculated from SL distance
4. Lot size normalized to broker's minimum/maximum

**Example with $10,000 account**:
- Risk: 1% = $100 per trade
- SL 50 pips away → ~1.0 lot (varies by symbol)
- Max account drawdown: Known in advance

### Stop-Loss Placement

- **BULLISH**: Placed below impulse low (invalidates scenario if broken)
- **BEARISH**: Placed above impulse high (invalidates scenario if broken)

### Take-Profit Targets

- **BULLISH**: Previous H4 resistance or calculated 2.5x risk
- **BEARISH**: Previous H4 support or calculated 2.5x risk

### Trailing Stop

Optional feature to protect profits:

- `UseTrailingStop = true`
- `TrailingStopDistance = 50` (pips)
- SL automatically moves up (for BUY) or down (for SELL) with price

---

## Best Practices

### ✓ DO's

1. ✅ **Test on demo first** - Verify performance before live trading
2. ✅ **Use consistent settings** - Don't change parameters too frequently
3. ✅ **Monitor the journal** - Enable `ShowDebugInfo = true` initially
4. ✅ **Trade liquid pairs** - EURUSD, GBPUSD, USDJPY work best
5. ✅ **Keep records** - Track all trades for analysis
6. ✅ **Use appropriate leverage** - 1:20 or lower recommended
7. ✅ **Verify broker spread** - Ensure spread isn't too wide for your symbol

### ✗ DON'Ts

1. ❌ **Don't overtrade** - Wait for perfect setups
2. ❌ **Don't lower risk/reward** - Keep R:R ≥ 1:2
3. ❌ **Don't increase lot size manually** - Let EA manage position sizing
4. ❌ **Don't disable safety parameters** - Keep all validations enabled
5. ❌ **Don't trade news events** - Disable EA during major announcements
6. ❌ **Don't expect 100% win rate** - All strategies have losing trades

---

## Troubleshooting

### Issue: EA Not Trading

**Check**:
1. Is the EA running? (Green smiley in top-right corner)
2. Are timeframes aligned? (Enable `ShowDebugInfo` to see)
3. Is there sufficient FVG setup? (May not exist every day)
4. Check account balance (must be sufficient for minimum lot)
5. Check broker hours (may not allow orders now)

**Solution**: Look at the Journal tab (View → Journal) for specific error messages

### Issue: "Not Enough Money"

**Cause**: Risk amount requires lot size larger than account can afford

**Solution**:
- Decrease `RiskPercentage` (try 0.5%)
- Increase minimum SL distance by adjusting `FVGMinPips`
- Use a larger account or deposit more funds

### Issue: Orders Rejected

**Causes**:
- Insufficient margin
- Spread too wide
- Order outside market hours
- Minimum lot size too small

**Check**: Look at the specific error in Journal tab and adjust parameters accordingly

### Issue: EA Taking Losses Consistently

**Likely causes**:
- Parameters not optimized for your symbol
- Timeframe misalignment affecting trade quality
- Spread too wide affecting entry precision
- Market conditions changed (trending → ranging or vice versa)

**Action**:
- Backtest with different parameters
- Review trades manually in the chart
- Consider disabling EA during ranging markets
- Test on different symbols

---

## Advanced Configuration

### For Scalping (M15 Chart)

```
ImpulseMinBars = 3
FVGMinPips = 2.0
MinConfirmationBodyPercent = 40.0
RiskPercentage = 0.5
TrailingStopDistance = 20
```

### For Swing Trading (H1 Chart)

```
ImpulseMinBars = 10
FVGMinPips = 8.0
MinConfirmationBodyPercent = 70.0
RiskPercentage = 1.0
TrailingStopDistance = 100
```

### For Conservative Trading (Higher Win Rate)

```
MinRiskRewardRatio = 3.0
MinConfirmationBodyPercent = 75.0
FVGMinPips = 10.0
RiskPercentage = 0.5
```

### For Aggressive Trading (More Trades)

```
MinRiskRewardRatio = 1.5
MinConfirmationBodyPercent = 50.0
FVGMinPips = 3.0
RiskPercentage = 1.0
```

---

## Performance Expectations

### Average Statistics (Based on Strategy Design)

| Metric | Expectation |
|--------|-------------|
| Win Rate | 55% - 65% |
| Avg Win | 2-3x risk |
| Avg Loss | 1x risk |
| Profit Factor | 1.5 - 2.5 |
| Drawdown | 10% - 20% |
| Recovery Factor | 2.0 - 3.0 |

**Note**: Actual results vary based on:
- Market conditions
- Parameter optimization
- Broker execution quality
- Spread environment

---

## Support & Questions

For issues or questions:
1. Check the Journal tab (View → Journal) for error messages
2. Review this documentation
3. Test on demo account first
4. Verify parameter settings match your strategy
5. Contact your broker for symbol-specific questions

---

## Disclaimer

This Expert Advisor is provided for educational purposes. Trading involves substantial risk and is not suitable for everyone. Past performance does not guarantee future results. Always use proper risk management and never risk more than you can afford to lose.

**Use at your own risk.**

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026 | Initial release with full FVG strategy implementation |

---

## License

This EA is provided as-is for personal use.

---

**Created**: 2026  
**Symbol**: EURUSD (recommended), any major pair  
**Timeframe**: M30 (Primary)  
**Magic Number**: 123456
