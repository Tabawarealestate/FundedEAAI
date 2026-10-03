//+------------------------------------------------------------------+
//|                                                         Types.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "Constants.mqh"

//+------------------------------------------------------------------+
//| Enumeration: Challenge Evaluation Phase                          |
//+------------------------------------------------------------------+
enum ENUM_CHALLENGE_PHASE
  {
   CHALLENGE_PHASE_1 = 1,        // Phase 1 Evaluation (e.g. 10% Target)
   CHALLENGE_PHASE_2 = 2,        // Phase 2 Verification (e.g. 5% Target)
   CHALLENGE_FUNDED = 3,         // Live Funded Account (0% Target, Strict DD)
   CHALLENGE_CUSTOM = 4          // Custom User Defined Rules
  };

//+------------------------------------------------------------------+
//| Enumeration: Daily Loss Calculation Mode                         |
//+------------------------------------------------------------------+
enum ENUM_DAILY_LOSS_MODE
  {
   DAILY_LOSS_MODE_A_EQUITY  = 1, // Mode A: Daily loss based on Beginning-Of-Day Equity
   DAILY_LOSS_MODE_B_BALANCE = 2, // Mode B: Daily loss based on Beginning-Of-Day Balance
   DAILY_LOSS_MODE_C_CUSTOM  = 3  // Mode C: Custom Provider Formula
  };

//+------------------------------------------------------------------+
//| Enumeration: Overall Drawdown Calculation Model                  |
//+------------------------------------------------------------------+
enum ENUM_DRAWDOWN_MODEL
  {
   DRAWDOWN_STATIC   = 1, // Static Max Loss relative to Initial Starting Balance
   DRAWDOWN_TRAILING = 2  // Trailing Max Loss relative to Peak Equity High-Water Mark
  };

//+------------------------------------------------------------------+
//| Enumeration: System Risk Strategy Modes                          |
//+------------------------------------------------------------------+
enum ENUM_RISK_MODE
  {
   RISK_MODE_CONSERVATIVE = 1,   // Low Risk (0.10% - 0.25%), High Setup Score Only
   RISK_MODE_BALANCED     = 2,   // Standard Risk (0.25% - 0.50%)
   RISK_MODE_AGGRESSIVE   = 3,   // Higher Risk (0.50% - 1.00%), Hard Limits Enforced
   RISK_MODE_DEFENSIVE    = 4,   // Drawdown Mode (0.10%), Strictly Defensive
   RISK_MODE_CUSTOM       = 5    // User Defined Risk Percentage
  };

//+------------------------------------------------------------------+
//| Enumeration: Market Regime Classification                        |
//+------------------------------------------------------------------+
enum ENUM_MARKET_REGIME
  {
   REGIME_STRONG_BULL_TREND = 1, // Clear Higher Highs / Higher Lows
   REGIME_STRONG_BEAR_TREND = 2, // Clear Lower Highs / Lower Lows
   REGIME_WEAK_TREND        = 3, // Indecisive Directional Bias
   REGIME_RANGE             = 4, // Horizontal Consolidation
   REGIME_HIGH_VOLATILITY   = 5, // Abnormally High ATR / Wide Spreads
   REGIME_LOW_VOLATILITY    = 6, // Low ATR / Tight Range
   REGIME_ABNORMAL          = 7  // Extreme Volatility / News Event / Illiquid
  };

//+------------------------------------------------------------------+
//| Enumeration: EA Operational Status                               |
//+------------------------------------------------------------------+
enum ENUM_EA_STATUS
  {
   EA_STATUS_ACTIVE           = 1, // Fully Operational & Scan Active
   EA_STATUS_PAUSED           = 2, // Paused by User or Strategy Condition
   EA_STATUS_DEFENSIVE        = 3, // Operating in Defensive Mode (Reduced Risk)
   EA_STATUS_EMERGENCY_STOP   = 4, // Emergency Hard Lock (Rule Safety Triggered)
   EA_STATUS_TARGET_REACHED   = 5  // Challenge Profit Target Reached
  };

//+------------------------------------------------------------------+
//| Enumeration: Setup Quality Classification                        |
//+------------------------------------------------------------------+
enum ENUM_SETUP_QUALITY
  {
   SETUP_VERY_STRONG = 1,        // Score 85 - 100
   SETUP_QUALIFIED   = 2,        // Score 70 - 84
   SETUP_WATCHLIST   = 3,        // Score 55 - 69
   SETUP_REJECTED    = 4         // Score < 55
  };

//+------------------------------------------------------------------+
//| Struct: Challenge Profile Rules Configuration                    |
//+------------------------------------------------------------------+
struct SChallengeProfileConfig
  {
   string                profileName;                 // Name of Prop Firm / Custom Profile
   double                initialBalance;              // Base Capital (e.g. $100,000)
   ENUM_CHALLENGE_PHASE  phase;                       // Phase 1, Phase 2, Funded, Custom
   ENUM_DAILY_LOSS_MODE  dailyLossMode;               // Mode A (Equity), Mode B (Balance), Mode C
   ENUM_DRAWDOWN_MODEL   drawdownModel;               // Static vs Trailing High-Water Mark
   double                profitTargetPercent;         // Target Profit (e.g. 10.0%)
   double                maxDailyLossPercent;         // Daily Loss Limit (e.g. 5.0%)
   double                maxOverallLossPercent;       // Overall Drawdown Limit (e.g. 10.0%)
   int                   minTradingDays;              // Minimum required trading days
   int                   maxTradingDays;              // Maximum allowed trading days (0 = unlimited)
   bool                  allowWeekendHolding;         // Can positions be held over weekend?
   bool                  allowNewsTrading;            // Is trading permitted during high impact news?
   bool                  allowOvernightTrading;       // Can trades be held overnight?
   int                   maxOpenPositions;            // Max concurrent open trades
   double                maxPortfolioRiskPercent;     // Max total portfolio risk across open trades
   double                maxLotSize;                  // Max lot size limit (0 = auto)
   string                customRulesDescription;      // Extra rule notes

   //--- Safety Buffers (Internal Risk Control Thresholds)
   double                dailyLossWarningPercent;     // Threshold to trigger Defensive Mode (e.g. 3.0%)
   double                dailyLossSoftStopPercent;    // Threshold to halt new entries (e.g. 4.0%)
   double                dailyLossEmergencyPercent;   // Threshold to close all trades & halt (e.g. 4.5%)
   double                maxLossWarningPercent;       // Overall drawdown warning threshold (e.g. 7.5%)
   double                maxLossEmergencyPercent;     // Overall drawdown emergency threshold (e.g. 8.5%)
  };

//+------------------------------------------------------------------+
//| Struct: Live Challenge Account Tracking Data                     |
//+------------------------------------------------------------------+
struct SChallengeAccountStatus
  {
   double                startingBalance;             // Initial Challenge Balance
   double                currentBalance;              // Current Account Balance
   double                currentEquity;               // Current Account Equity
   double                highWaterMark;               // Peak Equity High-Water Mark for Trailing DD
   double                dailyStartingEquity;         // Equity at start of broker trading day
   double                dailyStartingBalance;        // Balance at start of broker trading day
   double                dailyPL;                     // Today's Realized + Floating P/L
   double                overallPL;                   // Total Realized + Floating P/L
   double                currentDailyDrawdownPercent; // Current daily drawdown percentage
   double                currentOverallDrawdownPercent;// Current overall equity drawdown percentage
   double                remainingDailyLossAllowance; // Dollars remaining before daily loss limit
   double                remainingOverallLossAllowance;// Dollars remaining before overall drawdown limit
   double                targetProgressPercent;       // Progress towards profit target (0 - 100%)
   int                   activeTradingDays;           // Days traded so far
   bool                  isTargetReached;             // True if profit target achieved
   bool                  isMinTradingDaysMet;         // True if minimum trading days met
   bool                  isDailyLimitBreached;        // True if daily safety/hard limit breached
   bool                  isOverallLimitBreached;      // True if overall safety/hard limit breached
   bool                  isNewsDataAvailable;         // False = NEWS DATA UNAVAILABLE
  };
