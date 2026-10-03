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
   double   winRatePercent;
   double   netProfit;
   double   profitFactor;
   double   maxDailyDrawdownPercent;
   double   maxOverallDrawdownPercent;
   int      worstLosingStreak;
   bool     isTargetPassed;
   bool     isRuleViolated;
   string   violationReason;
  };

//+------------------------------------------------------------------+
//| Struct: Monte Carlo Aggregate Survival Metrics                   |
//+------------------------------------------------------------------+
struct SMonteCarloResult
  {
   int      totalSimulations;
   int      passedSimulations;
   int      failedSimulations;
   double   passPercentage;
   double   averageNetProfit;
   double   maxOverallDrawdownPercent;
   double   profitFactor;
  };

//+------------------------------------------------------------------+
//| Struct: Walk-Forward Testing Window Metrics                      |
//+------------------------------------------------------------------+
struct SWalkForwardResult
  {
   SSimulationResult trainingInSample;
   SSimulationResult validationInSample;
   SSimulationResult outOfSample;
   double            outOfSampleEfficiencyPercent;
  };

//+------------------------------------------------------------------+
//| Class CChallengeSimulator                                         |
//| Simulates challenge drawdown rules, survival rates, Walk-Forward  |
//| and Monte Carlo trade order randomizations.                       |
//+------------------------------------------------------------------+
class CChallengeSimulator
  {
public:
                     CChallengeSimulator(void);
                    ~CChallengeSimulator(void);

   static SSimulationResult SimulateChallenge(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, ENUM_DRAWDOWN_MODEL ddModel, const double &tradeReturnsDollars[], int tradesPerDay = 3);
   static SMonteCarloResult RunMonteCarloSimulation(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, ENUM_DRAWDOWN_MODEL ddModel, const double &tradeReturnsDollars[], int iterations = 100);
   static SWalkForwardResult RunWalkForwardTesting(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, ENUM_DRAWDOWN_MODEL ddModel, const double &allTradesReturns[]);
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
//| Resets daily starting equity every tradesPerDay trades           |
//+------------------------------------------------------------------+
SSimulationResult CChallengeSimulator::SimulateChallenge(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, ENUM_DRAWDOWN_MODEL ddModel, const double &tradeReturnsDollars[], int tradesPerDay)
  {
   SSimulationResult result;
   result.totalTrades               = ArraySize(tradeReturnsDollars);
   result.winningTrades             = 0;
   result.losingTrades              = 0;
   result.winRatePercent            = 0.0;
   result.netProfit                 = 0.0;
   result.profitFactor              = 0.0;
   result.maxDailyDrawdownPercent   = 0.0;
   result.maxOverallDrawdownPercent = 0.0;
   result.worstLosingStreak         = 0;
   result.isTargetPassed            = false;
   result.isRuleViolated            = false;
   result.violationReason           = "NONE";

   if(result.totalTrades == 0)
      return result;

   double currentEquity      = startingBalance;
   double peakEquity         = startingBalance;
   double dailyStartingEquity= startingBalance;
   double targetProfit       = startingBalance * (targetPct / 100.0);
   double maxDailyLoss       = startingBalance * (maxDailyLossPct / 100.0);
   double maxOverallLoss     = startingBalance * (maxOverallLossPct / 100.0);

   double grossProfit    = 0.0;
   double grossLoss      = 0.0;
   int currentStreak     = 0;

   for(int i = 0; i < result.totalTrades; i++)
     {
      // Reset Daily Starting Equity every tradesPerDay boundary
      if(i > 0 && (i % tradesPerDay == 0))
         dailyStartingEquity = currentEquity;

      double pnl = tradeReturnsDollars[i];
      currentEquity += pnl;
      result.netProfit += pnl;

      if(pnl > 0)
        {
         result.winningTrades++;
         grossProfit += pnl;
         currentStreak = 0;
        }
      else if(pnl < 0)
        {
         result.losingTrades++;
         grossLoss += -pnl;
         currentStreak++;
         if(currentStreak > result.worstLosingStreak)
            result.worstLosingStreak = currentStreak;
        }

      if(currentEquity > peakEquity)
         peakEquity = currentEquity;

      // Track Daily Drawdown %
      double dailyDD = dailyStartingEquity - currentEquity;
      if(dailyDD > 0)
        {
         double dailyDDPct = (dailyDD / dailyStartingEquity) * 100.0;
         if(dailyDDPct > result.maxDailyDrawdownPercent)
            result.maxDailyDrawdownPercent = dailyDDPct;

         if(dailyDD >= maxDailyLoss)
           {
            result.isRuleViolated  = true;
            result.violationReason = "DAILY LOSS LIMIT BREACHED";
            break;
           }
        }

      // Track Overall Drawdown based on model
      double baseBalance = (ddModel == DRAWDOWN_STATIC) ? startingBalance : peakEquity;
      double overallDD = baseBalance - currentEquity;
      if(overallDD > 0)
        {
         double ddPct = (overallDD / baseBalance) * 100.0;
         if(ddPct > result.maxOverallDrawdownPercent)
            result.maxOverallDrawdownPercent = ddPct;
        }

      if(overallDD >= maxOverallLoss)
        {
         result.isRuleViolated  = true;
         result.violationReason = "OVERALL DRAWDOWN LIMIT BREACHED";
         break;
        }

      if(targetPct > 0.0 && result.netProfit >= targetProfit)
        {
         result.isTargetPassed = true;
         break;
        }
     }

   result.winRatePercent = (result.totalTrades > 0) ? ((double)result.winningTrades / result.totalTrades) * 100.0 : 0.0;
   result.profitFactor   = (grossLoss > 0.0) ? (grossProfit / grossLoss) : grossProfit;

   return result;
  }

//+------------------------------------------------------------------+
//| Monte Carlo Simulation Engine with Fisher-Yates Trade Shuffling  |
//+------------------------------------------------------------------+
SMonteCarloResult CChallengeSimulator::RunMonteCarloSimulation(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, ENUM_DRAWDOWN_MODEL ddModel, const double &tradeReturnsDollars[], int iterations)
  {
   SMonteCarloResult mcResult;
   mcResult.totalSimulations          = (iterations > 0) ? iterations : 100;
   mcResult.passedSimulations         = 0;
   mcResult.failedSimulations         = 0;
   mcResult.passPercentage            = 0.0;
   mcResult.averageNetProfit          = 0.0;
   mcResult.maxOverallDrawdownPercent = 0.0;
   mcResult.profitFactor              = 0.0;

   int tradeCount = ArraySize(tradeReturnsDollars);
   if(tradeCount == 0)
      return mcResult;

   double shuffledTrades[];
   ArrayResize(shuffledTrades, tradeCount);
   double totalNetProfitSum = 0.0;

   for(int iter = 0; iter < mcResult.totalSimulations; iter++)
     {
      ArrayCopy(shuffledTrades, tradeReturnsDollars);

      // Fisher-Yates Shuffle
      for(int i = tradeCount - 1; i > 0; i--)
        {
         int j = MathRand() % (i + 1);
         double temp = shuffledTrades[i];
         shuffledTrades[i] = shuffledTrades[j];
         shuffledTrades[j] = temp;
        }

      SSimulationResult singleRes = SimulateChallenge(startingBalance, targetPct, maxDailyLossPct, maxOverallLossPct, ddModel, shuffledTrades, 3);
      totalNetProfitSum += singleRes.netProfit;

      if(singleRes.isTargetPassed && !singleRes.isRuleViolated)
         mcResult.passedSimulations++;
      else
         mcResult.failedSimulations++;

      if(singleRes.maxOverallDrawdownPercent > mcResult.maxOverallDrawdownPercent)
         mcResult.maxOverallDrawdownPercent = singleRes.maxOverallDrawdownPercent;
     }

   mcResult.passPercentage   = ((double)mcResult.passedSimulations / mcResult.totalSimulations) * 100.0;
   mcResult.averageNetProfit = totalNetProfitSum / mcResult.totalSimulations;

   return mcResult;
  }

//+------------------------------------------------------------------+
//| Walk-Forward Testing Engine (In-Sample vs Out-of-Sample Windows) |
//+------------------------------------------------------------------+
SWalkForwardResult CChallengeSimulator::RunWalkForwardTesting(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, ENUM_DRAWDOWN_MODEL ddModel, const double &allTradesReturns[])
  {
   SWalkForwardResult wfResult;
   int total = ArraySize(allTradesReturns);
   if(total < 10)
      return wfResult;

   int trainSize = total * 50 / 100;
   int valSize   = total * 25 / 100;
   int oosSize   = total - trainSize - valSize;

   double trainTrades[], valTrades[], oosTrades[];
   ArrayResize(trainTrades, trainSize);
   ArrayResize(valTrades, valSize);
   ArrayResize(oosTrades, oosSize);

   for(int i = 0; i < trainSize; i++) trainTrades[i] = allTradesReturns[i];
   for(int i = 0; i < valSize; i++)   valTrades[i]   = allTradesReturns[trainSize + i];
   for(int i = 0; i < oosSize; i++)   oosTrades[i]   = allTradesReturns[trainSize + valSize + i];

   wfResult.trainingInSample   = SimulateChallenge(startingBalance, targetPct, maxDailyLossPct, maxOverallLossPct, ddModel, trainTrades, 3);
   wfResult.validationInSample = SimulateChallenge(startingBalance, targetPct, maxDailyLossPct, maxOverallLossPct, ddModel, valTrades, 3);
   wfResult.outOfSample         = SimulateChallenge(startingBalance, targetPct, maxDailyLossPct, maxOverallLossPct, ddModel, oosTrades, 3);

   if(wfResult.trainingInSample.netProfit > 0.0)
      wfResult.outOfSampleEfficiencyPercent = (wfResult.outOfSample.netProfit / wfResult.trainingInSample.netProfit) * 100.0;
   else
      wfResult.outOfSampleEfficiencyPercent = 0.0;

   return wfResult;
  }
