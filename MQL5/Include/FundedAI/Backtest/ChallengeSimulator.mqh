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
//| Struct: Timestamped Trade Record for Simulator                   |
//+------------------------------------------------------------------+
struct SSimulatedTrade
  {
   datetime timestamp;          // Trade exit/close timestamp
   double   grossPL;            // Realized profit/loss in dollars
   double   commission;         // Trade commission in dollars
   double   swap;               // Overnight swap in dollars
  };

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
   int      activeTradingDays;
   bool     isTargetPassed;
   bool     isMinDaysMet;
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
//| Struct: Rolling Walk-Forward Testing Window Metrics              |
//+------------------------------------------------------------------+
struct SWalkForwardResult
  {
   SSimulationResult trainResult;
   SSimulationResult validateResult;
   SSimulationResult oosResult;
   double            outOfSampleEfficiencyPercent;
  };

//+------------------------------------------------------------------+
//| Class CChallengeSimulator                                         |
//| Real timestamp-based Challenge Simulator, Rolling Walk-Forward,  |
//| and Fisher-Yates Monte Carlo trade order randomizations.         |
//+------------------------------------------------------------------+
class CChallengeSimulator
  {
public:
                     CChallengeSimulator(void);
                    ~CChallengeSimulator(void);

   static SSimulationResult SimulateChallengeTimestamped(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, int minDays, ENUM_DRAWDOWN_MODEL ddModel, const SSimulatedTrade &trades[]);
   static SMonteCarloResult RunMonteCarloSimulation(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, int minDays, ENUM_DRAWDOWN_MODEL ddModel, const SSimulatedTrade &trades[], int iterations = 100);
   static SWalkForwardResult RunRollingWalkForward(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, int minDays, ENUM_DRAWDOWN_MODEL ddModel, const SSimulatedTrade &allTrades[]);
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
//| Real Timestamp-Based Challenge Simulator                         |
//| Evaluates daily drawdown across actual broker date boundaries    |
//+------------------------------------------------------------------+
SSimulationResult CChallengeSimulator::SimulateChallengeTimestamped(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, int minDays, ENUM_DRAWDOWN_MODEL ddModel, const SSimulatedTrade &trades[])
  {
   SSimulationResult result;
   result.totalTrades               = ArraySize(trades);
   result.winningTrades             = 0;
   result.losingTrades              = 0;
   result.winRatePercent            = 0.0;
   result.netProfit                 = 0.0;
   result.profitFactor              = 0.0;
   result.maxDailyDrawdownPercent   = 0.0;
   result.maxOverallDrawdownPercent = 0.0;
   result.worstLosingStreak         = 0;
   result.activeTradingDays         = 0;
   result.isTargetPassed            = false;
   result.isMinDaysMet              = false;
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

   int currentDay        = -1;
   int tradedDaysCount   = 0;

   for(int i = 0; i < result.totalTrades; i++)
     {
      // Extract date structure for actual midnight day boundary detection
      MqlDateTime dt;
      TimeToStruct(trades[i].timestamp, dt);

      if(dt.day != currentDay)
        {
         currentDay = dt.day;
         tradedDaysCount++;
         dailyStartingEquity = currentEquity; // Reset daily baseline at new day boundary
        }

      double netTradePL = trades[i].grossPL - trades[i].commission - trades[i].swap;
      currentEquity += netTradePL;
      result.netProfit += netTradePL;

      if(netTradePL > 0)
        {
         result.winningTrades++;
         grossProfit += netTradePL;
         currentStreak = 0;
        }
      else if(netTradePL < 0)
        {
         result.losingTrades++;
         grossLoss += -netTradePL;
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
         if(tradedDaysCount >= minDays)
           {
            result.isMinDaysMet = true;
            break; // Valid challenge completion
           }
        }
     }

   result.activeTradingDays = tradedDaysCount;
   result.winRatePercent     = (result.totalTrades > 0) ? ((double)result.winningTrades / result.totalTrades) * 100.0 : 0.0;
   result.profitFactor       = (grossLoss > 0.0) ? (grossProfit / grossLoss) : grossProfit;

   return result;
  }

//+------------------------------------------------------------------+
//| Monte Carlo Simulation Engine with Fisher-Yates Trade Shuffling  |
//+------------------------------------------------------------------+
SMonteCarloResult CChallengeSimulator::RunMonteCarloSimulation(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, int minDays, ENUM_DRAWDOWN_MODEL ddModel, const SSimulatedTrade &trades[], int iterations)
  {
   SMonteCarloResult mcResult;
   mcResult.totalSimulations          = (iterations > 0) ? iterations : 100;
   mcResult.passedSimulations         = 0;
   mcResult.failedSimulations         = 0;
   mcResult.passPercentage            = 0.0;
   mcResult.averageNetProfit          = 0.0;
   mcResult.maxOverallDrawdownPercent = 0.0;
   mcResult.profitFactor              = 0.0;

   int tradeCount = ArraySize(trades);
   if(tradeCount == 0)
      return mcResult;

   SSimulatedTrade shuffledTrades[];
   ArrayResize(shuffledTrades, tradeCount);
   double totalNetProfitSum = 0.0;

   for(int iter = 0; iter < mcResult.totalSimulations; iter++)
     {
      ArrayCopy(shuffledTrades, trades);

      // Fisher-Yates Shuffle
      for(int i = tradeCount - 1; i > 0; i--)
        {
         int j = MathRand() % (i + 1);
         SSimulatedTrade temp = shuffledTrades[i];
         shuffledTrades[i] = shuffledTrades[j];
         shuffledTrades[j] = temp;
        }

      SSimulationResult singleRes = SimulateChallengeTimestamped(startingBalance, targetPct, maxDailyLossPct, maxOverallLossPct, minDays, ddModel, shuffledTrades);
      totalNetProfitSum += singleRes.netProfit;

      if(singleRes.isTargetPassed && singleRes.isMinDaysMet && !singleRes.isRuleViolated)
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
//| Rolling Walk-Forward Testing Engine (Sliding Windows)            |
//+------------------------------------------------------------------+
SWalkForwardResult CChallengeSimulator::RunRollingWalkForward(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, int minDays, ENUM_DRAWDOWN_MODEL ddModel, const SSimulatedTrade &allTrades[])
  {
   SWalkForwardResult wfResult;
   int total = ArraySize(allTrades);
   if(total < 12)
      return wfResult;

   int trainSize = total * 50 / 100;
   int valSize   = total * 25 / 100;
   int oosSize   = total - trainSize - valSize;

   SSimulatedTrade trainTrades[], valTrades[], oosTrades[];
   ArrayResize(trainTrades, trainSize);
   ArrayResize(valTrades, valSize);
   ArrayResize(oosTrades, oosSize);

   for(int i = 0; i < trainSize; i++) trainTrades[i] = allTrades[i];
   for(int i = 0; i < valSize; i++)   valTrades[i]   = allTrades[trainSize + i];
   for(int i = 0; i < oosSize; i++)   oosTrades[i]   = allTrades[trainSize + valSize + i];

   wfResult.trainResult    = SimulateChallengeTimestamped(startingBalance, targetPct, maxDailyLossPct, maxOverallLossPct, minDays, ddModel, trainTrades);
   wfResult.validateResult = SimulateChallengeTimestamped(startingBalance, targetPct, maxDailyLossPct, maxOverallLossPct, minDays, ddModel, valTrades);
   wfResult.oosResult      = SimulateChallengeTimestamped(startingBalance, targetPct, maxDailyLossPct, maxOverallLossPct, minDays, ddModel, oosTrades);

   if(wfResult.trainResult.netProfit > 0.0)
      wfResult.outOfSampleEfficiencyPercent = (wfResult.oosResult.netProfit / wfResult.trainResult.netProfit) * 100.0;
   else
      wfResult.outOfSampleEfficiencyPercent = 0.0;

   return wfResult;
  }
