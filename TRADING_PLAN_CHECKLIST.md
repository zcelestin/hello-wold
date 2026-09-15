# 📋 FVG Trading Strategy - Pre-Trade Checklist

Use this checklist before each trading session and before enabling the EA for live trading.

---

## 🚀 EA Installation & Setup Checklist

### Before First Use

- [ ] Downloaded FVG_Trading_Strategy_EA.mq5
- [ ] Placed file in correct folder:
      `C:\Users\[You]\AppData\Roaming\MetaQuotes\Terminal\[ID]\MQL5\Experts\`
- [ ] Opened file in MetaEditor
- [ ] Clicked Compile (F5) → "0 errors" message appeared
- [ ] Closed MetaEditor
- [ ] Restarted MetaTrader 5
- [ ] Attached EA to a test chart
- [ ] EA appears in chart (visible in top-left corner)
- [ ] Chart shows no errors in Journal tab

### Before Each Session

- [ ] MetaTrader 5 running smoothly
- [ ] Internet connection stable
- [ ] Broker server connection active (shows online)
- [ ] Chart refreshing properly
- [ ] No pending updates for MT5
- [ ] Antivirus not blocking MT5

---

## ⚙️ Parameter Configuration Checklist

### Risk Management Settings

- [ ] **RiskPercentage** set: _____ (0.5-1.0 recommended for start)
- [ ] **MinRiskRewardRatio** set: _____ (2.0 recommended)
- [ ] **MaxOpenTrades** set: _____ (1 recommended for beginners)

**Validation**:
- [ ] Risk = account balance × RiskPercentage
- [ ] Risk amount is reasonable for account size
- [ ] Stop-loss distance won't exceed risk capacity

### Strategy Parameters

- [ ] **FibonacciRetracementLevel**: 0.5 (50% standard)
- [ ] **ImpulseMinBars**: _____ (5-10 recommended)
- [ ] **FVGMinPips**: _____ (3-10 recommended)
- [ ] **RequireVolumeConfirmation**: true/false chosen

### Candle Confirmation

- [ ] **RequireRejectionCandle**: enabled/disabled (recommended: enabled)
- [ ] **RequireIndecisionCandle**: enabled/disabled (recommended: enabled)
- [ ] **RequireConfirmationCandle**: enabled/disabled (recommended: enabled)
- [ ] **MinConfirmationBodyPercent**: _____ (60-70 recommended)

### Trading Hours

- [ ] **StartHour**: _____ (UTC format)
- [ ] **EndHour**: _____ (UTC format)
- [ ] Confirmed these are correct for broker's server time
- [ ] Trader availability during these hours confirmed

### EA Settings

- [ ] **ShowDebugInfo**: true (while testing) / false (live)
- [ ] **UseTrailingStop**: enabled/disabled (recommended: enabled)
- [ ] **TrailingStopDistance**: _____ pips (50 recommended)

**Settings Review**:
- [ ] All parameters read back correctly from EA
- [ ] No "input validation error" messages
- [ ] All numbers are reasonable for symbol being traded

---

## 📊 Account & Broker Setup

### Account Information

- [ ] Account type confirmed: Demo / Live
- [ ] Account balance: $________ or equivalent
- [ ] Leverage: 1:_____ (1:20 or lower recommended)
- [ ] Commission/spread understood
- [ ] Minimum lot size: __________
- [ ] Maximum lot size: __________
- [ ] Lot step size: __________

### Broker Verification

- [ ] Broker name: _______________
- [ ] MT5 server connection: ✓ Connected
- [ ] Account number verified: ______________
- [ ] Broker allows Expert Advisors
- [ ] Spread for trading symbol acceptable (< 3 pips for majors)
- [ ] Broker hours match trading hours set in EA
- [ ] No account restrictions on automated trading

---

## 📈 Symbol & Timeframe Setup

### Symbol Information

- [ ] Symbol selected: __________
- [ ] Symbol is liquid (EURUSD, GBPUSD, USDJPY recommended)
- [ ] Bid/Ask prices updating in real-time
- [ ] No "no quotes" message appearing
- [ ] Correct currency pair chosen
- [ ] Pip value understood for this symbol

### Timeframe Verification

- [ ] **M30 (30-min) chart** open and displaying
- [ ] M30 chart has at least 100 candles loaded
- [ ] **H4 (4-hour)** data available (not needed to open)
- [ ] **D1 (daily)** data available (not needed to open)
- [ ] No gaps in candle history

### Chart Display

- [ ] Chart zoom appropriate (can see 50+ candles)
- [ ] Chart colors set properly (can distinguish candles)
- [ ] Indicators not cluttering chart (if any)
- [ ] No alerts from other EAs interfering
- [ ] Chart not "frozen" (price updating)

---

## 🔍 Pre-Trade Analysis Checklist

### Daily Timeframe (D1) Analysis

- [ ] D1 trend direction identified: Bullish / Bearish / Neutral
- [ ] Structure clear on D1: HH/HL (bullish) or LH/LL (bearish)
- [ ] No major economic news expected today
- [ ] D1 bias matches intended trading direction

**D1 Bias Check**:
```
Is D1 bullish (HH, HL)?       YES / NO
Is D1 bearish (LH, LL)?       YES / NO
Is D1 neutral/ranging?        YES / NO

→ If NEUTRAL, consider not trading today
```

### 4-Hour Timeframe (H4) Analysis

- [ ] H4 trend identified: Bullish / Bearish / Neutral
- [ ] H4 matches D1 direction: YES / NO
- [ ] H4 structure confirms D1: YES / NO

**H4 Confirmation Check**:
```
D1 Direction: ___________
H4 Direction: ___________
Do they match? YES / NO

→ If NO, do not trade
→ If YES, proceed to M30
```

### 30-Minute Timeframe (M30) Analysis

- [ ] M30 trend: Bullish / Bearish / Neutral
- [ ] M30 aligns with D1 & H4: YES / NO
- [ ] Impulsive move identifiable: YES / NO
- [ ] Impulse size reasonable: YES / NO

**Alignment Confirmation**:
```
D1: ___________
H4: ___________
M30: __________
All three aligned? YES / NO

→ If YES, ready for entry signals
→ If NO, wait for better alignment
```

---

## 🎯 Entry Setup Validation

### Impulse Detection

- [ ] Clear impulse identified on M30: YES / NO
- [ ] Impulse has minimum bars: _____ bars (≥ ImpulseMinBars)
- [ ] Impulse size significant: YES / NO

**Impulse Measurement**:
```
Impulse High: __________
Impulse Low: __________
Impulse Pips: _____ pips
```

### Fibonacci Retracement

- [ ] Fibonacci drawn from impulse start → end: YES / NO
- [ ] 50% level calculated: __________
- [ ] Price has retraced to 50% level: YES / NO
- [ ] Retracement NOT excessive (not past 50%): YES / NO

**Retracement Validation**:
```
Current Price: __________
50% Fib Level: __________
Is price ≥ 50% retrace? YES / NO

→ If NO, no entry signal yet
→ If YES, look for FVG
```

### Fair Value Gap (FVG)

- [ ] FVG present on M30: YES / NO
- [ ] FVG size ≥ FVGMinPips: YES / NO
- [ ] FVG located in/after 50% zone: YES / NO
- [ ] FVG gap clearly visible: YES / NO

**FVG Measurements**:
```
FVG High: __________
FVG Low: __________
FVG Width: _____ pips
Within retracement? YES / NO
```

### 3-Candle Confirmation Pattern

- [ ] Candle 1 (Rejection) present: YES / NO
- [ ] Candle 2 (Indecision) present: YES / NO
- [ ] Candle 3 (Confirmation) present: YES / NO
- [ ] Pattern complete: YES / NO

**Candle Pattern Verification**:
```
Candle 1: Rejection (dip/rally in FVG, close opposite)
          Open: ____ Close: ____ OK? YES / NO

Candle 2: Indecision (small body, less than 40% of range)
          Range: ____ Body: ____ OK? YES / NO

Candle 3: Confirmation (large body, strong direction)
          Body %: ____% (≥ MinConfirmBodyPercent) OK? YES / NO

Pattern Complete? YES / NO
```

---

## 📐 Price Target Validation

### Entry Price Calculation

- [ ] Entry price determined: __________
- [ ] Entry price is at FVG level: YES / NO
- [ ] Entry price is reasonable: YES / NO
- [ ] Entry not against recent resistance/support: YES / NO

```
For BULLISH: Entry = FVG High
For BEARISH: Entry = FVG Low
```

### Stop-Loss Placement

- [ ] Stop-loss level determined: __________
- [ ] SL placed outside impulse extremes: YES / NO
- [ ] SL invalidates scenario if hit: YES / NO
- [ ] SL distance reasonable: _____ pips

```
For BULLISH: SL = Below Impulse Low
For BEARISH: SL = Above Impulse High
```

### Take-Profit Target

- [ ] Take-profit level determined: __________
- [ ] TP based on structure/liquidity: YES / NO
- [ ] TP not arbitrary or too far: YES / NO
- [ ] TP distance reasonable: _____ pips

### Risk/Reward Validation

- [ ] Risk amount calculated: $__________
- [ ] Reward amount calculated: $__________
- [ ] Risk/Reward ratio: 1:______
- [ ] Ratio meets minimum (≥ MinRiskRewardRatio): YES / NO

**R:R Calculation**:
```
Entry: __________
SL: __________
TP: __________

Risk Pips: _____ pips
Reward Pips: _____ pips
R:R Ratio: 1:_____ 

✓ Minimum requirement? YES / NO
```

---

## 💰 Position Sizing & Risk

### Account Verification (Before Executing)

- [ ] Current account balance: $__________
- [ ] Available margin: $__________
- [ ] Used margin (before trade): __________
- [ ] Buffer margin exists: YES / NO

### Lot Size Calculation

- [ ] Risk amount for this trade: $__________
- [ ] SL distance in pips: _____ pips
- [ ] Broker's pip value: $__________
- [ ] Calculated lot size: _____ lots
- [ ] Lot size within broker limits: YES / NO
- [ ] Lot size normalized correctly: YES / NO

**Verification**:
```
Lot Size: _____ lots
Min Lot: _____ YES / NO
Max Lot: _____ YES / NO
Step aligned: YES / NO

→ If any NO, recalculate
```

### Account Impact Check

- [ ] Trade risk: $__________
- [ ] Account %: _____ % of balance
- [ ] Risk acceptable: YES / NO
- [ ] Margin sufficient: YES / NO
- [ ] No liquidity concerns: YES / NO

---

## ⚠️ Safety & Invalidation Check

### Invalidation Conditions (Do NOT trade if any are true)

- [ ] D1 or H4 misaligned: YES → ❌ NO TRADE
- [ ] H4 and M30 misaligned: YES → ❌ NO TRADE
- [ ] No clear impulse: YES → ❌ NO TRADE
- [ ] Retracement < 50%: YES → ❌ NO TRADE
- [ ] No FVG present: YES → ❌ NO TRADE
- [ ] FVG too far from 50% zone: YES → ❌ NO TRADE
- [ ] Confirmation pattern incomplete: YES → ❌ NO TRADE
- [ ] R:R ratio too low: YES → ❌ NO TRADE
- [ ] Stop-loss too wide: YES → ❌ NO TRADE
- [ ] Outside trading hours: YES → ❌ NO TRADE
- [ ] Major news event coming: YES → ❌ NO TRADE

**Final Safety Check**:
```
Any of above conditions present? YES / NO

→ If YES, do NOT execute trade
→ If NO, safe to proceed
```

---

## 📋 Order Execution Checklist

### Before Clicking "Buy" or "Sell"

- [ ] All above checklists completed: YES / NO
- [ ] Parameters double-checked: YES / NO
- [ ] Entry price correct: __________
- [ ] Stop-loss price correct: __________
- [ ] Take-profit price correct: __________
- [ ] Lot size correct: _____ lots
- [ ] Direction correct: BUY / SELL
- [ ] Trade type: Market / Limit chosen correctly

### Execution

- [ ] Order sent successfully
- [ ] Order confirmation received
- [ ] Trade appears in Terminal → Positions
- [ ] Entry, SL, TP all visible
- [ ] No error messages in Journal

**Order Confirmation**:
```
Position Open? YES / NO
Magic Number: 123456
Entry Price: __________
Entry Time: ____ : ____
Status: ACTIVE
```

---

## 🔐 Post-Trade Monitoring

### Immediate (First 5 minutes)

- [ ] Price moving in intended direction
- [ ] No immediate SL hit
- [ ] No unusual volatility
- [ ] No connection issues
- [ ] EA still running (green smiley visible)

### Short-term (During Trade)

- [ ] Monitor for TP or SL
- [ ] Check no slippage at entry
- [ ] Verify position not reversed
- [ ] Optional: monitor trailing stop

### End of Session

- [ ] Trade result recorded: WIN / LOSS / BREAKEVEN
- [ ] Actual P&L logged: $__________
- [ ] Trade notes written (what happened)
- [ ] Any violations noted
- [ ] Lessons recorded for improvement

---

## 📊 Daily Review Checklist

### End of Day (After Trading)

- [ ] All trades closed or in progress noted
- [ ] Daily P&L calculated: $__________
- [ ] Win rate today: _____ % (____ wins / ____ trades)
- [ ] Average win: $__________
- [ ] Average loss: $__________
- [ ] Largest win today: $__________
- [ ] Largest loss today: $__________

### Weekly Review (Every Friday)

- [ ] Total trades this week: ______
- [ ] Weekly win rate: _____ %
- [ ] Weekly P&L: $__________
- [ ] Largest drawdown this week: _____ %
- [ ] Any pattern violations: YES / NO
- [ ] Any parameter adjustments needed: YES / NO
- [ ] Confidence level: _____ / 10

### Monthly Review (End of month)

- [ ] Total trades this month: ______
- [ ] Monthly win rate: _____ %
- [ ] Monthly P&L: $__________
- [ ] Max drawdown this month: _____ %
- [ ] Profit factor: __________
- [ ] Most common win setup: _____________
- [ ] Most common loss setup: _____________
- [ ] Improvements for next month: _______________

---

## 🚨 Emergency Stop Conditions

### STOP EA Immediately If:

- [ ] Account drawdown > 20%: **EMERGENCY STOP**
- [ ] Two consecutive losses > 2% each: **PAUSE**
- [ ] Slippage > 5 pips consistently: **CHECK CONNECTION**
- [ ] Connection dropped: **RECONNECT & VERIFY**
- [ ] EA taking wrong direction trades: **CHECK PARAMETERS**
- [ ] Broker issues observed: **CONTACT SUPPORT**
- [ ] Unusual market conditions: **ASSESS & DECIDE**
- [ ] Major economic news: **DISABLE EA**

**Action Upon Emergency**:
```
1. Close all open positions immediately
2. Disable EA
3. Investigate root cause
4. Fix issue
5. Resume on demo only
6. Resume live only after confirmation
```

---

## 📝 Trade Journal Template

For each trade, record:

```
═══════════════════════════════════════════════════
TRADE #____ | Date: __________ | Symbol: EURUSD
───────────────────────────────────────────────────
Setup Confirmed?           [ ] YES  [ ] NO
D1 Bias:                   [ ] BUY  [ ] SELL
H4 Confirmation:           [ ] YES  [ ] NO
M30 Alignment:             [ ] YES  [ ] NO

Entry Details:
  Entry Price:             __________
  Entry Time:              ____:____
  Lot Size:                _____ lots
  Risk Amount:             $__________

Order Details:
  Stop Loss:               __________ (____ pips)
  Take Profit:             __________ (____ pips)
  Risk/Reward:             1:____

Exit:
  Exit Price:              __________
  Exit Time:               ____:____
  Result:                  [ ] WIN [ ] LOSS [ ] BREAK
  P&L:                     $__________

Analysis:
  Setups Complete?         YES / NO
  Any Violations?          YES / NO
  What Happened:           ________________
  What Learned:            ________________
  Next Time:               ________________
═══════════════════════════════════════════════════
```

---

## ✅ Final Go-Live Checklist

### Before FIRST LIVE Trade

- [ ] Tested on demo for ≥ 2 weeks
- [ ] Demo results satisfactory (positive P&L)
- [ ] All parameters optimized
- [ ] Risk management understood
- [ ] Position sizing correct
- [ ] Account size sufficient ($1000+ recommended)
- [ ] Broker reliable and regulated
- [ ] All safety features enabled
- [ ] Emotional readiness confirmed
- [ ] Can afford to lose initial stake: YES / NO

### On Go-Live Day

- [ ] Start with 1 micro lot only
- [ ] Monitor first 5 trades closely
- [ ] Verify results match demo
- [ ] Check for slippage/spread differences
- [ ] Confirm broker execution quality
- [ ] Gradually increase position size over 1-2 weeks
- [ ] Never rush to larger lots

---

## 🎓 Remember

> "A checklist might seem tedious, but it's the difference between a professional trader and an amateur."

Every successful trader uses a checklist. It removes emotion and ensures consistency.

---

## 📌 Quick Reference

### Entry Checklist (One-liner):
```
✓ D1=H4=M30 Aligned ✓ Impulse+50%Fib ✓ FVG Present 
✓ 3-Candle Complete ✓ R:R≥1:2 ✓ All Checks Passed → ENTRY OK
```

### No Entry If:
```
❌ Timeframes misaligned ❌ No impulse ❌ <50% retrace 
❌ No FVG ❌ Pattern incomplete ❌ R:R too low
```

### Trade Flow:
```
1. Pre-session check → 2. Chart setup → 3. Timeframe analysis
4. Entry setup check → 5. Risk/reward validation → 6. Position sizing
7. Execute order → 8. Manage trade → 9. Record result
10. Daily review → 11. Weekly review → 12. Optimization
```

---

**Print this checklist and keep it at your desk!**

*Last Updated: 2026*
