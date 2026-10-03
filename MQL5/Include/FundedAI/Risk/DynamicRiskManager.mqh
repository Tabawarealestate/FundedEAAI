//+------------------------------------------------------------------+
//|                                           DynamicRiskManager.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Class CDynamicRiskManager                                        |
//| Dynamic Risk Engine regulating risk multipliers based on account  |
//| drawdown state, loss streaks, target progress, and EA status.     |
//+------------------------------------------------------------------+
class CDynamicRiskManager
  {
private:
   ENUM_RISK_MODE    m_riskMode;
   double            m_baseRiskPercent;

public:
                     CDynamicRiskManager(void);
                    ~CDynamicRiskManager(void);

   void              SetRiskMode(ENUM_RISK_MODE mode, double customRiskPercent = 0.25);
   double            GetBaseRiskPercent(void) const { return m_baseRiskPercent; }

   //--- Dynamic Multiplier Calculation
   double            CalculateRiskMultiplier(ENUM_EA_STATUS status,
                                             int consecutiveLosses,
                                             double targetProgressPercent,
                                             double dailyDrawdownPercent,
                                             double maxDailyLossLimit);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CDynamicRiskManager::CDynamicRiskManager(void)
  : m_riskMode(RISK_MODE_BALANCED),
    m_baseRiskPercent(DEFAULT_RISK_PERCENT)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CDynamicRiskManager::~CDynamicRiskManager(void)
  {
  }

//+------------------------------------------------------------------+
//| Sets risk mode & base risk percentage                            |
//+------------------------------------------------------------------+
void CDynamicRiskManager::SetRiskMode(ENUM_RISK_MODE mode, double customRiskPercent)
  {
   m_riskMode = mode;
   switch(mode)
     {
      case RISK_MODE_CONSERVATIVE:
         m_baseRiskPercent = 0.15;
         break;
      case RISK_MODE_BALANCED:
         m_baseRiskPercent = 0.25;
         break;
      case RISK_MODE_AGGRESSIVE:
         m_baseRiskPercent = 0.50;
         break;
      case RISK_MODE_DEFENSIVE:
         m_baseRiskPercent = 0.10;
         break;
      case RISK_MODE_CUSTOM:
         m_baseRiskPercent = (customRiskPercent > 0.0) ? customRiskPercent : DEFAULT_RISK_PERCENT;
         break;
      default:
         m_baseRiskPercent = DEFAULT_RISK_PERCENT;
         break;
     }
  }

//+------------------------------------------------------------------+
//| Calculates dynamic risk multiplier based on account conditions   |
//+------------------------------------------------------------------+
double CDynamicRiskManager::CalculateRiskMultiplier(ENUM_EA_STATUS status,
                                                    int consecutiveLosses,
                                                    double targetProgressPercent,
                                                    double dailyDrawdownPercent,
                                                    double maxDailyLossLimit)
  {
   // 1. If EA is Emergency Stopped or Target Reached -> ZERO RISK
   if(status == EA_STATUS_EMERGENCY_STOP || status == EA_STATUS_TARGET_REACHED || status == EA_STATUS_PAUSED)
      return 0.0;

   double multiplier = 1.0;

   // 2. Status-based Scaling
   if(status == EA_STATUS_DEFENSIVE)
      multiplier *= 0.50; // Cut risk by 50% in defensive state

   // 3. Drawdown Proximity Scaling
   if(maxDailyLossLimit > 0.0)
     {
      double drawdownRatio = dailyDrawdownPercent / maxDailyLossLimit;
      if(drawdownRatio >= 0.70)
         multiplier *= 0.25; // 70% towards daily loss limit -> 25% risk
      else if(drawdownRatio >= 0.50)
         multiplier *= 0.50; // 50% towards daily loss limit -> 50% risk
     }

   // 4. Consecutive Loss De-escalation (No Martingale!)
   if(consecutiveLosses > 0)
     {
      double lossReduction = 1.0 - (consecutiveLosses * 0.20);
      if(lossReduction < 0.25)
         lossReduction = 0.25; // Floor at 25% of normal risk after 4+ losses
      multiplier *= lossReduction;
     }

   // 5. Target Proximity Scaling (Protect profit near challenge finish line)
   if(targetProgressPercent >= 95.0)
      multiplier *= 0.25; // 95%+ towards target -> 25% risk
   else if(targetProgressPercent >= 80.0)
      multiplier *= 0.50; // 80%+ towards target -> 50% risk

   return multiplier;
  }
