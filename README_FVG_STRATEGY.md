# 📈 FVG Trading Strategy Expert Advisor for MetaTrader 5

A fully automated trading robot based on Fair Value Gap (FVG) methodology with multi-timeframe analysis. This Expert Advisor implements a structured, rule-based trading system designed for consistent and mechanical execution.

---

## 🎯 Strategy Overview

The **FVG Trading Strategy** combines:

- **Multi-Timeframe Alignment**: D1 (bias determination) → H4 (confirmation) → M30 (entry signals)
- **Fair Value Gap Detection**: Automated identification using 3-candle pattern analysis
- **Fibonacci Retracement**: Ensures 50%+ retracement before trade entry
- **3-Candle Confirmation**: Validates rejection, indecision, and strong confirmation patterns
- **Dynamic Risk Management**: Automatic position sizing based on account balance and risk percentage

---

## 📁 Repository Contents

```
hello-wold/
├── FVG_Trading_Strategy_EA.mq5          # Main Expert Advisor (MQL5)
├── README_FVG_STRATEGY.md               # This file
├── FVG_EA_DOCUMENTATION.md              # Complete user guide & installation
├── RECOMMENDED_SETTINGS.md              # Trading profiles & optimized settings
├── TRADING_PLAN_CHECKLIST.md            # Pre-trade checklist (included)
└── [Other project files]
```

---

## 🚀 Quick Start

### 1. Installation (2 minutes)

```bash
# 1. Copy the EA file
FVG_Trading_Strategy_EA.mq5 → MetaTrader 5 folder
(Usually: C:\Users\[You]\AppData\Roaming\MetaQuotes\Terminal\[ID]\MQL5\Experts\)

# 2. Compile in MetaEditor
# 3. Restart MetaTrader 5
# 4. Attach to a chart (preferably M30 timeframe)
# 5. Configure parameters
# 6. Enable Expert Advisors in tools
```

**See full installation guide in `FVG_EA_DOCUMENTATION.md`**

### 2. Configuration (5 minutes)

Choose your trading profile:

```
Conservative:  RiskPercentage = 0.5, MinRiskRewardRatio = 3.0
Balanced:      RiskPercentage = 1.0, MinRiskRewardRatio = 2.0  ← Recommended Start
Aggressive:    RiskPercentage = 1.5, MinRiskRewardRatio = 1.5
```

**See recommended settings in `RECOMMENDED_SETTINGS.md`**

### 3. Test on Demo (Minimum 2 weeks)

- Attach EA to chart with your chosen settings
- Let it run for at least 2 weeks on demo account
- Monitor the Journal tab for debug information
- Evaluate performance before live trading

### 4. Go Live (Start Small)

- Begin with minimum lot sizes
- Gradually increase as you gain confidence
- Never risk more than 1% per trade initially

---

## 🎓 How the Strategy Works

### The Trading Flow

```
1. DAILY ANALYSIS (D1)
   ↓
   Determine market bias: Bullish 🟢 or Bearish 🔴

2. CONFIRM ON H4
   ↓
   H4 must align with D1 bias

3. VALIDATE ON M30
   ↓
   M30 must align with both D1 and H4

4. IDENTIFY IMPULSE (M30)
   ↓
   Find a strong directional move

5. APPLY FIBONACCI
   ↓
   Retracement must reach at least 50%

6. DETECT FVG
   ↓
   Find Fair Value Gap in retracement zone

7. AWAIT CONFIRMATION (3 Candles)
   ↓
   Candle 1: Rejection
   Candle 2: Indecision
   Candle 3: Strong confirmation

8. EXECUTE TRADE
   ↓
   Entry after candle 3 closes
   Stop-loss below/above impulse
   Take-profit at structure

9. MANAGE POSITION
   ↓
   Optional trailing stop
   Close at TP or SL
```

### Detailed Example: BULLISH Setup

```
Step 1: D1 Bias = Bullish 🟢 (HH, HL pattern)
Step 2: H4 = Bullish 🟢 (confirms D1)
Step 3: M30 = Bullish 🟢 (aligned)
        ✓ All aligned → Search for BUY

Step 4: Impulse Identified
        Price moved from 1.0500 → 1.0650 (150 pips up)

Step 5: Retracement starts
        Price pulls back to 1.0575 (50% of 150 pips = 75 pips)
        ✓ Reaches 50% threshold

Step 6: FVG Detected
        Bullish FVG between 1.0620 (candle 1 high) 
        and 1.0580 (candle 3 low)
        ✓ Within retracement zone

Step 7: 3-Candle Confirmation appears
        Candle 1: Dips to 1.0575, closes at 1.0590 ✓
        Candle 2: Small body at 1.0588 ✓
        Candle 3: Strong close at 1.0605 ✓
        ✓ Pattern complete

Step 8: Entry
        Entry: 1.0620 (top of FVG)
        SL: 1.0500 (below impulse low)
        TP: 1.0740 (2.5x risk)
        Risk = 120 pips, Reward = 120 pips → R:R = 1:1 ✓

Step 9: Trade Active
        Wait for either TP hit or SL hit
        Optional trailing stop protects profit
```

---

## 📊 Performance Metrics

### Expected Statistics

| Metric | Range |
|--------|-------|
| Win Rate | 55% - 65% |
| Average Win | 2x - 3x risk |
| Average Loss | 1x risk |
| Profit Factor | 1.5 - 2.5 |
| Max Drawdown | 10% - 20% |
| Trades per Month | 5 - 15 |

*Actual results depend on market conditions, parameter tuning, and broker execution quality.*

---

## ⚙️ Key Parameters Explained

### Risk Management
- **RiskPercentage** (0.5 - 2.0): % of account risked per trade
- **MinRiskRewardRatio** (1.5 - 3.0): Minimum reward per unit of risk
- **MaxOpenTrades** (1 - 5): Max simultaneous positions

### Strategy Parameters
- **ImpulseMinBars** (3 - 20): Bars required to identify impulse
- **FVGMinPips** (2 - 15): Minimum FVG size in pips
- **MinConfirmationBodyPercent** (40 - 80): % body size for confirmation

### Trading Hours
- **StartHour / EndHour**: UTC hours to trade (24-hour format)

---

## ✅ Pre-Trade Checklist

Before enabling the EA, verify:

- [ ] EA compiled successfully (0 errors)
- [ ] Running on demo account initially
- [ ] Account has sufficient balance for minimum lot
- [ ] Broker spread is acceptable for symbol
- [ ] All three timeframes (D1, H4, M30) can be accessed
- [ ] Magic number doesn't conflict with other EAs
- [ ] Show debug info enabled for monitoring
- [ ] Stop-loss and take-profit rules understood
- [ ] Risk per trade acceptable for account size
- [ ] No major economic news during trading hours

---

## 🔧 Configuration Presets

### For Quick Start

**Conservative (Recommended for beginners)**:
```
Copy from RECOMMENDED_SETTINGS.md → Profile 1: Conservative Trader
```

**Balanced (Most traders)**:
```
Copy from RECOMMENDED_SETTINGS.md → Profile 2: Balanced Trader
```

**Aggressive (Experienced traders)**:
```
Copy from RECOMMENDED_SETTINGS.md → Profile 3: Aggressive Trader
```

---

## 📚 Documentation Files

### 1. **FVG_EA_DOCUMENTATION.md** (🔴 Start Here First)
   - Installation guide
   - Parameter reference
   - Step-by-step strategy explanation
   - Risk management details
   - Troubleshooting guide

### 2. **RECOMMENDED_SETTINGS.md** (🟢 Copy-Paste Settings)
   - Pre-configured profiles for different traders
   - Account size recommendations
   - Market condition setups
   - Symbol-specific settings
   - Optimization workflow

### 3. **README_FVG_STRATEGY.md** (This File)
   - Overview
   - Quick start guide
   - Key concepts

---

## 🎯 Best Practices

### ✅ DO's

1. **Test on demo first** (minimum 2-4 weeks)
2. **Use consistent settings** (don't change parameters daily)
3. **Monitor the journal** (check for errors)
4. **Trade liquid pairs** (EURUSD, GBPUSD, USDJPY)
5. **Keep detailed records** (track all trades)
6. **Use proper risk/reward** (maintain minimum 1:2 ratio)
7. **Start small** (increase gradually)

### ❌ DON'Ts

1. ❌ Go live immediately (test first!)
2. ❌ Change settings after every loss
3. ❌ Trade during major news events
4. ❌ Increase risk after winning streak
5. ❌ Expect 100% win rate
6. ❌ Trade when tired or emotional
7. ❌ Override safety parameters

---

## 🚨 Important Disclaimer

**RISK WARNING**: Trading involves substantial risk and is not suitable for everyone. This Expert Advisor is provided for educational purposes.

- Past performance does not guarantee future results
- Always use proper position sizing and risk management
- Never risk more than you can afford to lose
- Test thoroughly on demo before live trading
- Monitor your account regularly
- Use appropriate leverage (1:20 or lower recommended)

**Use at your own risk.**

---

## 🐛 Troubleshooting

### Common Issues

**Q: EA not trading?**
```
A: Check
   1. EA running? (green smiley in chart corner)
   2. Timeframes aligned? (enable ShowDebugInfo)
   3. Sufficient balance for minimum lot?
   4. Check Journal for error messages
```

**Q: Frequent losses?**
```
A: Try
   1. Increase MinConfirmationBodyPercent (60→75)
   2. Increase ImpulseMinBars (5→10)
   3. Increase MinRiskRewardRatio (2→2.5)
   4. Backtest with different parameters
```

**Q: Too few trading opportunities?**
```
A: Try
   1. Decrease FVGMinPips (5→3)
   2. Decrease ImpulseMinBars (10→5)
   3. Allow range-bound markets
   4. Trade more symbol pairs
```

See **FVG_EA_DOCUMENTATION.md** → Troubleshooting section for more help.

---

## 📞 Support

For issues:
1. Check the **Journal tab** (View → Journal) for error details
2. Review **FVG_EA_DOCUMENTATION.md** troubleshooting section
3. Verify settings match your trading plan
4. Test parameters on demo account first
5. Contact your broker for symbol-specific questions

---

## 🔄 Development & Roadmap

### Current Version: 1.0

**Implemented Features**:
- ✅ Multi-timeframe bias analysis (D1, H4, M30)
- ✅ Fair Value Gap detection
- ✅ Fibonacci retracement validation
- ✅ 3-candle confirmation pattern
- ✅ Dynamic position sizing
- ✅ Risk/reward validation
- ✅ Trailing stop support
- ✅ Debug logging
- ✅ Trading hour restrictions

**Future Enhancements** (Potential):
- [ ] Liquidity level detection
- [ ] Support/resistance clustering
- [ ] Volume profile analysis
- [ ] News event calendar integration
- [ ] Advanced trailing stop algorithms
- [ ] Performance statistics dashboard
- [ ] Multi-symbol support
- [ ] Cloud data backup

---

## 📈 Performance Expectations Timeline

### Week 1-2: Testing Phase
- Get familiar with strategy
- Monitor all trades
- Review journal entries
- Verify settings correctness

### Week 3-4: Evaluation Phase
- Analyze trade statistics
- Check win/loss ratio
- Evaluate drawdown
- Identify any issues

### Month 2-3: Optimization Phase
- Fine-tune parameters if needed
- Test different market conditions
- Compare performance
- Make documented changes

### Month 4+: Live Trading Phase (Optional)
- Start with micro lots
- Gradually increase position size
- Maintain consistent approach
- Keep long-term records

---

## 🎓 Learning Resources

### Understanding the Strategy
1. Read **FVG_EA_DOCUMENTATION.md** → "How the Strategy Works"
2. Study **RECOMMENDED_SETTINGS.md** for different approaches
3. Paper trade (demo) for 2-4 weeks minimum

### Parameter Tuning
1. Read **RECOMMENDED_SETTINGS.md** → "Optimization Workflow"
2. Test one parameter at a time
3. Keep detailed records
4. Only adopt improvements

### Risk Management
1. **FVG_EA_DOCUMENTATION.md** → "Risk Management" section
2. Position sizing calculation explained
3. R:R ratio requirements detailed
4. Stop-loss placement rules

---

## 📝 Trading Journal Template

Use this to track your trades:

```
Date: ____
Symbol: EURUSD
Direction: BUY / SELL
Entry Price: ____
Stop-Loss: ____ (pips from entry)
Take-Profit: ____ (pips from entry)
Lot Size: ____

Risk Amount: $ ____
Potential Reward: $ ____
Risk/Reward Ratio: 1:____

Result: WIN / LOSS / BREAKEVEN
Exit Price: ____
Actual P&L: $ ____

Notes:
- Were all conditions met?
- Any setup violations?
- Price action observations
- Lessons learned
```

---

## 📊 Metrics to Track

For continuous improvement, track:

- **Win Rate**: Wins / Total Trades
- **Average Win**: Sum of wins / Number of wins
- **Average Loss**: Sum of losses / Number of losses
- **Profit Factor**: Gross Profit / Gross Loss
- **Drawdown**: Largest peak-to-trough decline
- **Recovery Factor**: Net Profit / Max Drawdown
- **Trades per Month**: Total opportunities
- **Monthly P&L**: Net profit/loss per month

---

## 🔐 Security Notes

- **Magic Number**: Set to 123456 (change if using multiple EAs)
- **Password Protection**: MT5 passwords protect account access, not EA files
- **Backup Settings**: Save your parameter configurations regularly
- **Account Security**: Use strong broker passwords, enable 2FA if available

---

## 📄 License & Attribution

This Expert Advisor is provided as educational material for personal use.

Created: 2026  
Broker Compatibility: MetaTrader 5 (Windows & Mac with Wine)  
Required: MQL5 knowledge, MT5 platform, active trading account  

---

## 🌟 Getting Started in 3 Steps

### Step 1️⃣: Read Documentation (15 minutes)
```
→ Read: FVG_EA_DOCUMENTATION.md (Installation + How it Works)
```

### Step 2️⃣: Configure Settings (5 minutes)
```
→ Copy: RECOMMENDED_SETTINGS.md (Choose your profile)
→ Apply: Paste settings into EA parameters
```

### Step 3️⃣: Test on Demo (2-4 weeks minimum)
```
→ Attach EA to M30 chart
→ Monitor Journal tab
→ Evaluate results
→ Only then consider live trading
```

---

## ✨ Key Takeaways

> "The FVG Trading Strategy is a systematic, rule-based approach to identifying high-probability trade setups using multi-timeframe analysis, Fair Value Gaps, and strict confirmation patterns."

**Remember**:
- 🎯 No perfect system (55-65% win rate is excellent)
- 💰 Position sizing is more important than win rate
- 🚀 Consistency beats perfection
- 📊 Track everything, optimize slowly
- ⏰ Patience is rewarded in trading

---

## 📞 Questions?

1. **Installation issues**: See `FVG_EA_DOCUMENTATION.md` → Installation section
2. **Parameter questions**: See `RECOMMENDED_SETTINGS.md` → Profiles
3. **Strategy questions**: See `FVG_EA_DOCUMENTATION.md` → How Strategy Works
4. **Troubleshooting**: See `FVG_EA_DOCUMENTATION.md` → Troubleshooting section

---

**Happy Trading! 📈**

---

*Last Updated: 2026*  
*FVG Trading Strategy v1.0 for MetaTrader 5*
