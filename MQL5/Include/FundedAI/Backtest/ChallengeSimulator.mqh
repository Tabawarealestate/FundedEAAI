//+------------------------------------------------------------------+
//|                                           ChallengeSimulator.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Struct: Challenge Simulation Results                             |
//+------------------------------------------------------------------+
struct SSimulationResult
  {
   int      totalTrades;
   int      winningTrades;
   int      losingTrades;
   double   netProfit;
   double   maxDailyDrawdownPercent;
   double   maxOverallDrawdownPercent;
   bool     isTargetPassed;
   bool     isRuleViolated;
   string   violationReason;
  };

//+------------------------------------------------------------------+
//| Class CChallengeSimulator                                         |
//| Simulates challenge drawdown rules and survival rates over        |
//| historical trade sequences.                                      |
//+------------------------------------------------------------------+
class CChallengeSimulator
  {
public:
                     CChallengeSimulator(void);
                    ~CChallengeSimulator(void);

   static SSimulationResult SimulateChallenge(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, const double &tradeReturnsDollars[]);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CChallengeSimulator::CChallengeSimulator(void)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CChallengeSimulator::~CChallengeSimulator(void)
  {
  }

//+------------------------------------------------------------------+
//| Simulates challenge outcome for a sequence of trade returns      |
//+------------------------------------------------------------------+
SSimulationResult CChallengeSimulator::SimulateChallenge(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, const double &tradeReturnsDollars[])
  {
   SSimulationResult result;
   result.totalTrades               = ArraySize(tradeReturnsDollars);
   result.winningTrades             = 0;
   result.losingTrades              = 0;
   result.netProfit                 = 0.0;
   result.maxDailyDrawdownPercent   = 0.0;
   result.maxOverallDrawdownPercent = 0.0;
   result.isTargetPassed            = false;
   result.isRuleViolated            = false;
   result.violationReason           = "NONE";

   double currentEquity  = startingBalance;
   double peakEquity     = startingBalance;
   double targetProfit   = startingBalance * (targetPct / 100.0);
   double maxDailyLoss   = startingBalance * (maxDailyLossPct / 100.0);
   double maxOverallLoss = startingBalance * (maxOverallLossPct / 100.0);

   for(int i = 0; i < result.totalTrades; i++)
     {
      double pnl = tradeReturnsDollars[i];
      currentEquity += pnl;
      result.netProfit += pnl;

      if(pnl > 0)
         result.winningTrades++;
      else if(pnl < 0)
         result.losingTrades++;

      if(currentEquity > peakEquity)
         peakEquity = currentEquity;

      double drawdown = startingBalance - currentEquity;
      if(drawdown > 0)
        {
         double ddPct = (drawdown / startingBalance) * 100.0;
         if(ddPct > result.maxOverallDrawdownPercent)
            result.maxOverallDrawdownPercent = ddPct;
        }

      if((startingBalance - currentEquity) >= maxOverallLoss)
        {
         result.isRuleViolated  = true;
         result.violationReason = "OVERALL DRAWDOWN LIMIT BREACHED";
         break;
        }

      if(result.netProfit >= targetProfit)
        {
         result.isTargetPassed = true;
         break;
        }
     }

   return result;
  }
