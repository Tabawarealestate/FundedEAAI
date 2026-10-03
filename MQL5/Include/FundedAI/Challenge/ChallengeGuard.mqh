//+------------------------------------------------------------------+
//|                                               ChallengeGuard.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"
#include "ChallengeProfile.mqh"

//+------------------------------------------------------------------+
//| Class CChallengeGuard                                            |
//| Dedicated Safety Engine enforcing challenge limits, equity       |
//| drawdown rules, and emergency shutdown triggers.                  |
//+------------------------------------------------------------------+
class CChallengeGuard
  {
private:
   CChallengeProfile       *m_profile;
   ENUM_EA_STATUS           m_currentStatus;
   string                   m_lastStatusReason;

public:
                     CChallengeGuard(void);
                    ~CChallengeGuard(void);

   void              SetProfile(CChallengeProfile *profile) { m_profile = profile; }

   //--- Core Evaluation
   ENUM_EA_STATUS    EvaluateState(double currentBalance, double currentEquity, double dailyStartingEquity);

   //--- Status Checks
   ENUM_EA_STATUS    GetStatus(void) const { return m_currentStatus; }
   string            GetStatusReason(void) const { return m_lastStatusReason; }

   bool              CanOpenNewTrade(void) const;
   bool              ShouldCloseAllPositions(void) const;
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CChallengeGuard::CChallengeGuard(void)
  : m_profile(NULL),
    m_currentStatus(EA_STATUS_ACTIVE),
    m_lastStatusReason("Initial state: ACTIVE")
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CChallengeGuard::~CChallengeGuard(void)
  {
  }

//+------------------------------------------------------------------+
//| Evaluates current account metrics against safety thresholds     |
//+------------------------------------------------------------------+
ENUM_EA_STATUS CChallengeGuard::EvaluateState(double currentBalance, double currentEquity, double dailyStartingEquity)
  {
   if(m_profile == NULL)
     {
      m_currentStatus = EA_STATUS_EMERGENCY_STOP;
      m_lastStatusReason = "ERROR: Challenge profile unassigned";
      return m_currentStatus;
     }

   // Update profile calculations
   m_profile.UpdateAccountStatus(currentBalance, currentEquity, dailyStartingEquity);

   // Check 1: Profit Target Reached
   if(m_profile.IsTargetReached())
     {
      m_currentStatus = EA_STATUS_TARGET_REACHED;
      m_lastStatusReason = "CHALLENGE TARGET REACHED: Trading locked to preserve result.";
      return m_currentStatus;
     }

   // Check 2: Emergency Drawdown Triggers
   if(m_profile.IsDailyLossEmergency())
     {
      m_currentStatus = EA_STATUS_EMERGENCY_STOP;
      m_lastStatusReason = "EMERGENCY STOP: Daily loss limit or safety buffer breached!";
      return m_currentStatus;
     }

   if(m_profile.IsOverallLossEmergency())
     {
      m_currentStatus = EA_STATUS_EMERGENCY_STOP;
      m_lastStatusReason = "EMERGENCY STOP: Overall drawdown limit or safety buffer breached!";
      return m_currentStatus;
     }

   // Check 3: Soft Stop Triggers (Halt New Entries)
   if(m_profile.IsDailyLossSoftStop())
     {
      m_currentStatus = EA_STATUS_PAUSED;
      m_lastStatusReason = "DAILY SOFT STOP: Daily loss soft threshold reached. New trades paused.";
      return m_currentStatus;
     }

   // Check 4: Warning Level Triggers (Defensive Mode)
   if(m_profile.IsDailyLossWarning() || m_profile.IsOverallLossWarning())
     {
      m_currentStatus = EA_STATUS_DEFENSIVE;
      m_lastStatusReason = "DEFENSIVE MODE ACTIVE: Drawdown elevated. Risk scaled down.";
      return m_currentStatus;
     }

   // Normal Operation
   m_currentStatus = EA_STATUS_ACTIVE;
   m_lastStatusReason = "ACTIVE: Normal trading within safety limits.";
   return m_currentStatus;
  }

//+------------------------------------------------------------------+
//| Validates whether new entries are permitted                     |
//+------------------------------------------------------------------+
bool CChallengeGuard::CanOpenNewTrade(void) const
  {
   if(m_currentStatus == EA_STATUS_ACTIVE || m_currentStatus == EA_STATUS_DEFENSIVE)
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//| Checks whether emergency liquidation is required               |
//+------------------------------------------------------------------+
bool CChallengeGuard::ShouldCloseAllPositions(void) const
  {
   if(m_currentStatus == EA_STATUS_EMERGENCY_STOP || m_currentStatus == EA_STATUS_TARGET_REACHED)
      return true;
   return false;
  }
