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
//| Enumeration: Explicit Overall Drawdown Calculation Model         |
//+------------------------------------------------------------------+
enum ENUM_DRAWDOWN_MODEL
  {
   DRAWDOWN_STATIC_BALANCE = 1, // Static Max Loss relative to Initial Balance
   DRAWDOWN_STATIC_EQUITY  = 2, // Static Max Loss relative to Initial Equity
   TRAILING_BALANCE_HWM    = 3, // Trailing Max Loss relative to Peak Balance HWM
   TRAILING_EQUITY_HWM     = 4  // Trailing Max Loss relative to Peak Equity HWM
  };

//+------------------------------------------------------------------+
//| Enumeration: High-Water Mark Source                              |
//+------------------------------------------------------------------+
enum ENUM_HWM_SOURCE
  {
   HWM_SOURCE_BALANCE = 1, // High-Water Mark tracked from Peak Balance
   HWM_SOURCE_EQUITY  = 2  // High-Water Mark tracked from Peak Equity
  };

//+------------------------------------------------------------------+
//| Enumeration: Daylight Saving Time (DST) Profiles                 |
//+------------------------------------------------------------------+
enum ENUM_DST_PROFILE
  {
   DST_NONE   = 0, // No DST Adjustment
   DST_EUROPE = 1, // European DST (Last Sunday March to Last Sunday October)
   DST_US     = 2, // US DST (Second Sunday March to First Sunday November)
   DST_MANUAL = 3  // Manual DST Offset Override
  };

//+------------------------------------------------------------------+
//| Enumeration: Execution Error Classification                      |
//+------------------------------------------------------------------+
enum ENUM_EXECUTION_ERROR_TYPE
  {
   ERROR_TYPE_NONE                 = 0,
   ERROR_TYPE_RETRYABLE            = 1, // Requote, timeout, price changed
   ERROR_TYPE_NON_RETRYABLE        = 2, // Invalid stops, market closed, no money
   ERROR_TYPE_REQUIRES_USER_ACTION = 3  // Trading disabled, invalid volume/symbol
  };

//+------------------------------------------------------------------+
//| Enumeration: Exposure Group Categories                           |
//+------------------------------------------------------------------+
enum ENUM_EXPOSURE_GROUP
  {
   EXPOSURE_FOREX_CURRENCY = 1, // Standard Forex currency pair exposure
   EXPOSURE_GOLD_RISK      = 2, // Gold / Precious Metals exposure
   EXPOSURE_US_EQUITY_RISK = 3, // US Indices (US30, NAS100, SPX500)
   EXPOSURE_CRYPTO_RISK    = 4, // Cryptocurrency pairs
   EXPOSURE_NOT_APPLICABLE = 5  // Other / Unclassified CFDs
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
   string                profileID;                   // Unique Profile Hash/ID
   string                profileName;                 // Name of Prop Firm / Custom Profile
   double                initialBalance;              // Base Capital (e.g. $100,000)
   ENUM_CHALLENGE_PHASE  phase;                       // Phase 1, Phase 2, Funded, Custom
   ENUM_DAILY_LOSS_MODE  dailyLossMode;               // Mode A (Equity), Mode B (Balance), Mode C
   ENUM_DRAWDOWN_MODEL   drawdownModel;               // Static Balance, Static Equity, Trailing Balance, Trailing Equity
   ENUM_HWM_SOURCE       hwmSource;                   // Peak Balance vs Peak Equity
   bool                  unrealizedMovesHWM;          // True if floating profit moves HWM
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
   int                   gmtOffsetHours;              // Broker GMT Offset in Hours
   ENUM_DST_PROFILE      dstProfile;                  // Daylight Saving Time Profile
   string                customRulesDescription;      // Extra rule notes

   //--- Safety Buffers
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
   string                profileID;                   // Profile Identity
   double                startingBalance;             // Initial Challenge Balance
   double                currentBalance;              // Current Account Balance
   double                currentEquity;               // Current Account Equity
   double                highWaterMark;               // Peak High-Water Mark for Trailing DD
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
   int                   lastDailyResetDateKey;       // YearMonthDay Integer Key (e.g. 20261007)
   bool                  isTargetReached;             // True if profit target achieved
   bool                  isMinTradingDaysMet;         // True if minimum trading days met
   bool                  isDailyLimitBreached;        // True if daily safety/hard limit breached
   bool                  isOverallLimitBreached;      // True if overall safety/hard limit breached
   bool                  isNewsDataAvailable;         // False = NEWS DATA UNAVAILABLE
  };

//+------------------------------------------------------------------+
//| Struct: Complete Persisted State Recovery Package               |
//+------------------------------------------------------------------+
struct SChallengeStatePersist
  {
   string                profileID;                   // Profile Identity Code
   int                   configVersion;               // Version Code
   ENUM_CHALLENGE_PHASE  phase;                       // Challenge Phase
   datetime              challengeStartTime;          // Challenge Creation Time
   double                startingBalance;             // Initial Challenge Balance
   double                dailyStartingBalance;        // Daily Baseline Balance
   double                dailyStartingEquity;         // Daily Baseline Equity
   double                highWaterMark;               // Peak High-Water Mark
   ENUM_HWM_SOURCE       hwmSource;                   // HWM Source (Balance/Equity)
   ENUM_DRAWDOWN_MODEL   drawdownModel;               // Drawdown Model
   bool                  unrealizedMovesHWM;          // Unrealized Profit Flag
   int                   lastDailyResetDateKey;       // Date Key of last reset (YYYYMMDD)
   int                   activeTradingDays;           // Traded Days
   datetime              lastStateSaveTime;           // Last Saved Timestamp
  };
