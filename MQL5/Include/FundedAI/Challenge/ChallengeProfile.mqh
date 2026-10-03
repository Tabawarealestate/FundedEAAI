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

   //--- Getter Methods
   SChallengeProfileConfig GetConfig(void) const { return m_config; }
   SChallengeAccountStatus GetStatus(void) const { return m_status; }

   double            GetInitialBalance(void) const { return m_config.initialBalance; }
   double            GetProfitTargetPercent(void) const { return m_config.profitTargetPercent; }
   double            GetMaxDailyLossPercent(void) const { return m_config.maxDailyLossPercent; }
   double            GetMaxOverallLossPercent(void) const { return m_config.maxOverallLossPercent; }
   ENUM_CHALLENGE_PHASE GetPhase(void) const { return m_config.phase; }

   //--- Calculation & Tracking Methods
   void              UpdateAccountStatus(double currentBalance, double currentEquity, double dailyStartingEquity);
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

   //--- Set Profit Target based on phase
   if(phase == CHALLENGE_PHASE_1)
      m_config.profitTargetPercent = 10.0; // 10% Phase 1 Target
   else if(phase == CHALLENGE_PHASE_2)
      m_config.profitTargetPercent = 5.0;  // 5% Phase 2 Target
   else
      m_config.profitTargetPercent = 0.0;  // Live Funded (No profit target ceiling required)

   //--- Standard Prop Firm Risk Parameters
   m_config.maxDailyLossPercent   = 5.0;   // 5% Hard Daily Limit
   m_config.maxOverallLossPercent = 10.0;  // 10% Hard Total Drawdown Limit
   m_config.minTradingDays        = 4;     // Minimum 4 trading days
   m_config.maxTradingDays        = 0;     // Unlimited trading days
   m_config.allowWeekendHolding   = false;
   m_config.allowNewsTrading      = false;
   m_config.allowOvernightTrading = true;
   m_config.maxOpenPositions      = 5;
   m_config.maxLotSize            = 0.0;   // Auto lot limit based on risk
   m_config.customRulesDescription= "Default Prop Firm Profile Settings";

   //--- Internal Safety Buffers (Triggers before hitting hard limits)
   m_config.dailyLossWarningPercent   = 3.0; // 3.0% daily loss triggers DEFENSIVE mode
   m_config.dailyLossSoftStopPercent  = 4.0; // 4.0% daily loss halts new entries
   m_config.dailyLossEmergencyPercent = 4.5; // 4.5% daily loss closes trades & locks EA
   m_config.maxLossWarningPercent     = 7.5; // 7.5% total drawdown triggers DEFENSIVE mode
   m_config.maxLossEmergencyPercent   = 8.5; // 8.5% total drawdown locks EA

   // Initialize Status
   UpdateAccountStatus(m_config.initialBalance, m_config.initialBalance, m_config.initialBalance);
  }

//+------------------------------------------------------------------+
//| Configures custom user parameters                                |
//+------------------------------------------------------------------+
void CChallengeProfile::Configure(const SChallengeProfileConfig &config)
  {
   m_config = config;
   UpdateAccountStatus(m_config.initialBalance, m_config.initialBalance, m_config.initialBalance);
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
void CChallengeProfile::UpdateAccountStatus(double currentBalance, double currentEquity, double dailyStartingEquity)
  {
   m_status.startingBalance       = m_config.initialBalance;
   m_status.currentBalance        = currentBalance;
   m_status.currentEquity         = currentEquity;
   m_status.dailyStartingEquity   = (dailyStartingEquity > 0.0) ? dailyStartingEquity : currentEquity;

   //--- Daily P/L Calculation (Equity vs Daily Starting Equity)
   m_status.dailyPL               = currentEquity - m_status.dailyStartingEquity;
   m_status.overallPL             = currentEquity - m_status.startingBalance;

   //--- Daily Drawdown % (Positive value represents loss %)
   if(m_status.dailyPL < 0.0 && m_status.dailyStartingEquity > 0.0)
      m_status.currentDailyDrawdownPercent = (-m_status.dailyPL / m_status.dailyStartingEquity) * 100.0;
   else
      m_status.currentDailyDrawdownPercent = 0.0;

   //--- Overall Drawdown % (Positive value represents loss %)
   if(m_status.overallPL < 0.0 && m_status.startingBalance > 0.0)
      m_status.currentOverallDrawdownPercent = (-m_status.overallPL / m_status.startingBalance) * 100.0;
   else
      m_status.currentOverallDrawdownPercent = 0.0;

   //--- Allowances Remaining in Currency ($)
   double maxDailyAllowedLossDollars = m_status.dailyStartingEquity * (m_config.maxDailyLossPercent / 100.0);
   m_status.remainingDailyLossAllowance = maxDailyAllowedLossDollars + m_status.dailyPL;
   if(m_status.remainingDailyLossAllowance < 0.0)
      m_status.remainingDailyLossAllowance = 0.0;

   double maxOverallAllowedLossDollars = m_status.startingBalance * (m_config.maxOverallLossPercent / 100.0);
   m_status.remainingOverallLossAllowance = maxOverallAllowedLossDollars + m_status.overallPL;
   if(m_status.remainingOverallLossAllowance < 0.0)
      m_status.remainingOverallLossAllowance = 0.0;

   //--- Target Progress %
   if(m_config.profitTargetPercent > 0.0)
     {
      double requiredProfitDollars = m_status.startingBalance * (m_config.profitTargetPercent / 100.0);
      m_status.targetProgressPercent = (m_status.overallPL / requiredProfitDollars) * 100.0;
      if(m_status.targetProgressPercent < 0.0)
         m_status.targetProgressPercent = 0.0;
      m_status.isTargetReached = (m_status.overallPL >= requiredProfitDollars);
     }
   else
     {
      m_status.targetProgressPercent = 100.0;
      m_status.isTargetReached = false; // Live funded does not stop at profit target
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
