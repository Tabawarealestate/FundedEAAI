//+------------------------------------------------------------------+
//|                                             ChallengeProfile.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Class CChallengeProfile                                          |
//| Manages prop firm challenge parameters, safety thresholds, and    |
//| evaluation phase metrics.                                        |
//+------------------------------------------------------------------+
class CChallengeProfile
  {
private:
   SChallengeProfileConfig  m_config;
   SChallengeAccountStatus m_status;

public:
                     CChallengeProfile(void);
                    ~CChallengeProfile(void);

   //--- Profile Configuration Methods
   void              LoadDefaultPreset(double initialBalance = 100000.0, ENUM_CHALLENGE_PHASE phase = CHALLENGE_PHASE_1);
   void              Configure(const SChallengeProfileConfig &config);
   void              SetPhase(ENUM_CHALLENGE_PHASE phase);
   void              SetHighWaterMark(double hwm) { m_status.highWaterMark = MathMax(m_config.initialBalance, hwm); }

   //--- Getter Methods
   SChallengeProfileConfig GetConfig(void) const { return m_config; }
   SChallengeAccountStatus GetStatus(void) const { return m_status; }

   double            GetInitialBalance(void) const { return m_config.initialBalance; }
   double            GetProfitTargetPercent(void) const { return m_config.profitTargetPercent; }
   double            GetMaxDailyLossPercent(void) const { return m_config.maxDailyLossPercent; }
   double            GetMaxOverallLossPercent(void) const { return m_config.maxOverallLossPercent; }
   ENUM_CHALLENGE_PHASE GetPhase(void) const { return m_config.phase; }
   string            GetProfileID(void) const { return m_config.profileID; }

   //--- Calculation & Tracking Methods
   void              UpdateAccountStatus(double currentBalance, double currentEquity, double dailyStartingEquity, double dailyStartingBalance, int activeTradingDays = 1, int currentDateKey = 0);
   bool              IsDailyLossWarning(void) const;
   bool              IsDailyLossSoftStop(void) const;
   bool              IsDailyLossEmergency(void) const;
   bool              IsOverallLossWarning(void) const;
   bool              IsOverallLossEmergency(void) const;
   bool              IsTargetReached(void) const;
   bool              IsTradingAllowed(void) const;
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CChallengeProfile::CChallengeProfile(void)
  {
   LoadDefaultPreset(100000.0, CHALLENGE_PHASE_1);
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CChallengeProfile::~CChallengeProfile(void)
  {
  }

//+------------------------------------------------------------------+
//| Loads standard industry defaults for a given account balance     |
//+------------------------------------------------------------------+
void CChallengeProfile::LoadDefaultPreset(double initialBalance, ENUM_CHALLENGE_PHASE phase)
  {
   m_config.profileName           = "Standard Challenge Preset";
   m_config.initialBalance        = (initialBalance > 0.0) ? initialBalance : 100000.0;
   m_config.phase                 = phase;
   m_config.dailyLossMode         = DAILY_LOSS_MODE_A_EQUITY;
   m_config.drawdownModel         = DRAWDOWN_STATIC_BALANCE;
   m_config.hwmSource             = HWM_SOURCE_EQUITY;
   m_config.unrealizedMovesHWM    = true;
   m_config.profileID             = StringFormat("PROF_DEFAULT_%.0f_PH%d", m_config.initialBalance, (int)phase);

   //--- Set Profit Target based on phase
   if(phase == CHALLENGE_PHASE_1)
      m_config.profitTargetPercent = 10.0; // 10% Phase 1 Target
   else if(phase == CHALLENGE_PHASE_2)
      m_config.profitTargetPercent = 5.0;  // 5% Phase 2 Target
   else
      m_config.profitTargetPercent = 0.0;  // Live Funded

   //--- Standard Prop Firm Risk Parameters
   m_config.maxDailyLossPercent   = 5.0;   // 5% Hard Daily Limit
   m_config.maxOverallLossPercent = 10.0;  // 10% Hard Total Drawdown Limit
   m_config.minTradingDays        = 4;     // Minimum 4 trading days
   m_config.maxTradingDays        = 0;     // Unlimited trading days
   m_config.allowWeekendHolding   = false;
   m_config.allowNewsTrading      = false;
   m_config.allowOvernightTrading = true;
   m_config.maxOpenPositions      = 5;
   m_config.maxPortfolioRiskPercent= 2.0;  // 2.0% max total portfolio risk
   m_config.maxLotSize            = 0.0;   // Auto lot limit based on risk
   m_config.customRulesDescription= "Default Prop Firm Profile Settings";

   //--- Internal Safety Buffers
   m_config.dailyLossWarningPercent   = 3.0; // 3.0% daily loss triggers DEFENSIVE mode
   m_config.dailyLossSoftStopPercent  = 4.0; // 4.0% daily loss halts new entries
   m_config.dailyLossEmergencyPercent = 4.5; // 4.5% daily loss closes trades & locks EA
   m_config.maxLossWarningPercent     = 7.5; // 7.5% total drawdown triggers DEFENSIVE mode
   m_config.maxLossEmergencyPercent   = 8.5; // 8.5% total drawdown locks EA

   m_status.highWaterMark = m_config.initialBalance;
   m_status.profileID     = m_config.profileID;

   // Initialize Status
   UpdateAccountStatus(m_config.initialBalance, m_config.initialBalance, m_config.initialBalance, m_config.initialBalance, 1, 0);
  }

//+------------------------------------------------------------------+
//| Configures custom user parameters                                |
//+------------------------------------------------------------------+
void CChallengeProfile::Configure(const SChallengeProfileConfig &config)
  {
   m_config = config;
   m_status.profileID = m_config.profileID;
   if(m_status.highWaterMark < m_config.initialBalance)
      m_status.highWaterMark = m_config.initialBalance;
   UpdateAccountStatus(m_config.initialBalance, m_config.initialBalance, m_config.initialBalance, m_config.initialBalance, 1, 0);
  }

//+------------------------------------------------------------------+
//| Dynamic Phase Switcher                                           |
//+------------------------------------------------------------------+
void CChallengeProfile::SetPhase(ENUM_CHALLENGE_PHASE phase)
  {
   m_config.phase = phase;
   if(phase == CHALLENGE_PHASE_1)
      m_config.profitTargetPercent = 10.0;
   else if(phase == CHALLENGE_PHASE_2)
      m_config.profitTargetPercent = 5.0;
   else
      m_config.profitTargetPercent = 0.0;
  }

//+------------------------------------------------------------------+
//| Updates current account metrics & calculates safety margins      |
//+------------------------------------------------------------------+
void CChallengeProfile::UpdateAccountStatus(double currentBalance, double currentEquity, double dailyStartingEquity, double dailyStartingBalance, int activeTradingDays, int currentDateKey)
  {
   m_status.profileID             = m_config.profileID;
   m_status.startingBalance       = m_config.initialBalance;
   m_status.currentBalance        = currentBalance;
   m_status.currentEquity         = currentEquity;
   m_status.dailyStartingEquity   = (dailyStartingEquity > 0.0) ? dailyStartingEquity : currentEquity;
   m_status.dailyStartingBalance  = (dailyStartingBalance > 0.0) ? dailyStartingBalance : currentBalance;
   m_status.activeTradingDays     = activeTradingDays;
   m_status.lastDailyResetDateKey = currentDateKey;
   m_status.isMinTradingDaysMet   = (activeTradingDays >= m_config.minTradingDays);

   // Update Peak High-Water Mark based on configured source (Equity vs Balance)
   double hwmReference = (m_config.hwmSource == HWM_SOURCE_BALANCE) ? currentBalance : currentEquity;
   if(!m_config.unrealizedMovesHWM)
      hwmReference = currentBalance; // Pure balance HWM if unrealized profit excluded

   // HWM is monotonic - never moves backward
   if(hwmReference > m_status.highWaterMark)
      m_status.highWaterMark = hwmReference;

   //--- Daily P/L Calculation according to Configured Daily Loss Mode
   if(m_config.dailyLossMode == DAILY_LOSS_MODE_A_EQUITY)
      m_status.dailyPL = currentEquity - m_status.dailyStartingEquity;
   else if(m_config.dailyLossMode == DAILY_LOSS_MODE_B_BALANCE)
      m_status.dailyPL = currentEquity - m_status.dailyStartingBalance;
   else
      m_status.dailyPL = currentEquity - MathMin(m_status.dailyStartingEquity, m_status.dailyStartingBalance);

   //--- Overall Drawdown Calculation according to Drawdown Model
   if(m_config.drawdownModel == DRAWDOWN_STATIC_BALANCE)
      m_status.overallPL = currentEquity - m_status.startingBalance;
   else if(m_config.drawdownModel == DRAWDOWN_STATIC_EQUITY)
      m_status.overallPL = currentEquity - m_status.startingBalance;
   else if(m_config.drawdownModel == TRAILING_BALANCE_HWM || m_config.drawdownModel == TRAILING_EQUITY_HWM)
      m_status.overallPL = currentEquity - m_status.highWaterMark;
   else
      m_status.overallPL = currentEquity - m_status.startingBalance;

   //--- Daily Drawdown %
   double dailyBase = (m_config.dailyLossMode == DAILY_LOSS_MODE_B_BALANCE) ? m_status.dailyStartingBalance : m_status.dailyStartingEquity;
   if(m_status.dailyPL < 0.0 && dailyBase > 0.0)
      m_status.currentDailyDrawdownPercent = (-m_status.dailyPL / dailyBase) * 100.0;
   else
      m_status.currentDailyDrawdownPercent = 0.0;

   //--- Overall Drawdown %
   double overallBase = (m_config.drawdownModel == TRAILING_BALANCE_HWM || m_config.drawdownModel == TRAILING_EQUITY_HWM) ? m_status.highWaterMark : m_status.startingBalance;
   if(m_status.overallPL < 0.0 && overallBase > 0.0)
      m_status.currentOverallDrawdownPercent = (-m_status.overallPL / overallBase) * 100.0;
   else
      m_status.currentOverallDrawdownPercent = 0.0;

   //--- Allowances Remaining in Currency ($)
   double maxDailyAllowedLossDollars = dailyBase * (m_config.maxDailyLossPercent / 100.0);
   m_status.remainingDailyLossAllowance = maxDailyAllowedLossDollars + m_status.dailyPL;
   if(m_status.remainingDailyLossAllowance < 0.0)
      m_status.remainingDailyLossAllowance = 0.0;

   double maxOverallAllowedLossDollars = overallBase * (m_config.maxOverallLossPercent / 100.0);
   m_status.remainingOverallLossAllowance = maxOverallAllowedLossDollars + m_status.overallPL;
   if(m_status.remainingOverallLossAllowance < 0.0)
      m_status.remainingOverallLossAllowance = 0.0;

   //--- Target Progress %
   if(m_config.profitTargetPercent > 0.0)
     {
      double requiredProfitDollars = m_status.startingBalance * (m_config.profitTargetPercent / 100.0);
      double totalGainDollars = currentEquity - m_status.startingBalance;
      m_status.targetProgressPercent = (totalGainDollars / requiredProfitDollars) * 100.0;
      if(m_status.targetProgressPercent < 0.0)
         m_status.targetProgressPercent = 0.0;
      m_status.isTargetReached = (totalGainDollars >= requiredProfitDollars);
     }
   else
     {
      m_status.targetProgressPercent = 100.0;
      m_status.isTargetReached = false;
     }

   //--- Rule Violation Flags
   m_status.isDailyLimitBreached = (m_status.currentDailyDrawdownPercent >= m_config.maxDailyLossPercent);
   m_status.isOverallLimitBreached = (m_status.currentOverallDrawdownPercent >= m_config.maxOverallLossPercent);
  }

//+------------------------------------------------------------------+
//| Safety Check Functions                                           |
//+------------------------------------------------------------------+
bool CChallengeProfile::IsDailyLossWarning(void) const
  {
   return (m_status.currentDailyDrawdownPercent >= m_config.dailyLossWarningPercent);
  }

bool CChallengeProfile::IsDailyLossSoftStop(void) const
  {
   return (m_status.currentDailyDrawdownPercent >= m_config.dailyLossSoftStopPercent);
  }

bool CChallengeProfile::IsDailyLossEmergency(void) const
  {
   return (m_status.currentDailyDrawdownPercent >= m_config.dailyLossEmergencyPercent) || m_status.isDailyLimitBreached;
  }

bool CChallengeProfile::IsOverallLossWarning(void) const
  {
   return (m_status.currentOverallDrawdownPercent >= m_config.maxLossWarningPercent);
  }

bool CChallengeProfile::IsOverallLossEmergency(void) const
  {
   return (m_status.currentOverallDrawdownPercent >= m_config.maxLossEmergencyPercent) || m_status.isOverallLimitBreached;
  }

bool CChallengeProfile::IsTargetReached(void) const
  {
   return m_status.isTargetReached;
  }

bool CChallengeProfile::IsTradingAllowed(void) const
  {
   if(IsDailyLossEmergency() || IsOverallLossEmergency())
      return false;
   if(m_config.profitTargetPercent > 0.0 && IsTargetReached())
      return false;
   return true;
  }
