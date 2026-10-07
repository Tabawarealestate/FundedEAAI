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
   double   medianNetProfit;
   double   bestNetProfit;
   double   worstNetProfit;
   double   maxOverallDrawdownPercent;
   double   probDailyLossViolationPercent;
   double   probOverallLossViolationPercent;
   double   probTargetReachedPercent;
   double   profitFactor;
   string   monteCarloModeUsed;
  };

//+------------------------------------------------------------------+
//| Struct: Single Rolling WFO Window Metric                         |
//+------------------------------------------------------------------+
struct SWFOWindow
  {
   int               windowIndex;
   datetime          trainStart;
   datetime          trainEnd;
   datetime          valStart;
   datetime          valEnd;
   datetime          oosStart;
   datetime          oosEnd;
   SSimulationResult trainResult;
   SSimulationResult valResult;
   SSimulationResult oosResult;
  };

//+------------------------------------------------------------------+
//| Struct: Rolling Walk-Forward Optimization Full Result            |
//+------------------------------------------------------------------+
struct SWalkForwardResult
  {
   int               totalWindowsExecuted;
   double            aggregateOOSEfficiencyPercent;
   double            aggregateOOSNetProfit;
   int               passedOOSWindows;
   int               failedOOSWindows;
   bool              isSufficientData;
   string            summaryReport;
  };

//+------------------------------------------------------------------+
//| Class CChallengeSimulator                                         |
//| Genuine Rolling WFO, Mode A/B Monte Carlo, and Timestamp-based   |
//| date boundary challenge simulation.                             |
//+------------------------------------------------------------------+
class CChallengeSimulator
  {
public:
                     CChallengeSimulator(void);
                    ~CChallengeSimulator(void);

   static SSimulationResult SimulateChallengeTimestamped(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, int minDays, ENUM_DRAWDOWN_MODEL ddModel, const SSimulatedTrade &trades[]);
   static SMonteCarloResult RunMonteCarloSimulation(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, int minDays, ENUM_DRAWDOWN_MODEL ddModel, const SSimulatedTrade &trades[], int iterations = 100, bool useDayBlockMode = true);
   static SWalkForwardResult RunRollingWalkForward(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, int minDays, ENUM_DRAWDOWN_MODEL ddModel, const SSimulatedTrade &allTrades[], int trainMonths = 6, int valMonths = 2, int oosMonths = 2, int stepMonths = 2);

private:
   static int        GetDateKey(datetime t);
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
//| Generates reliable year-month-day integer key (e.g. 20261007)     |
//+------------------------------------------------------------------+
int CChallengeSimulator::GetDateKey(datetime t)
  {
   MqlDateTime dt;
   TimeToStruct(t, dt);
   return (dt.year * 10000) + (dt.mon * 100) + dt.day;
  }

//+------------------------------------------------------------------+
//| Real Timestamp-Based Challenge Simulator                         |
//| Evaluates daily drawdown across actual year-month-day boundaries  |
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

   int currentDayKey     = -1;
   int tradedDaysCount   = 0;

   for(int i = 0; i < result.totalTrades; i++)
     {
      int tradeDateKey = GetDateKey(trades[i].timestamp);

      if(tradeDateKey != currentDayKey)
        {
         currentDayKey = tradeDateKey;
         tradedDaysCount++;
         dailyStartingEquity = currentEquity; // Reset daily baseline at new calendar day boundary
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
      double baseBalance = (ddModel == DRAWDOWN_STATIC_BALANCE || ddModel == DRAWDOWN_STATIC_EQUITY) ? startingBalance : peakEquity;
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
//| Monte Carlo Engine with Mode A (Sequence) & Mode B (Day-Block)   |
//+------------------------------------------------------------------+
SMonteCarloResult CChallengeSimulator::RunMonteCarloSimulation(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, int minDays, ENUM_DRAWDOWN_MODEL ddModel, const SSimulatedTrade &trades[], int iterations, bool useDayBlockMode)
  {
   SMonteCarloResult mcResult;
   mcResult.totalSimulations               = (iterations > 0) ? iterations : 100;
   mcResult.passedSimulations              = 0;
   mcResult.failedSimulations              = 0;
   mcResult.passPercentage                 = 0.0;
   mcResult.averageNetProfit               = 0.0;
   mcResult.medianNetProfit                = 0.0;
   mcResult.bestNetProfit                  = -999999999.0;
   mcResult.worstNetProfit                 = 999999999.0;
   mcResult.maxOverallDrawdownPercent      = 0.0;
   mcResult.probDailyLossViolationPercent  = 0.0;
   mcResult.probOverallLossViolationPercent= 0.0;
   mcResult.probTargetReachedPercent      = 0.0;
   mcResult.profitFactor                   = 0.0;
   mcResult.monteCarloModeUsed             = useDayBlockMode ? "MODE B: TRADING-DAY BLOCK SHUFFLE" : "MODE A: TRADE SEQUENCE SHUFFLE";

   int tradeCount = ArraySize(trades);
   if(tradeCount == 0)
      return mcResult;

   double netProfits[];
   ArrayResize(netProfits, mcResult.totalSimulations);

   int dailyViolations = 0;
   int overallViolations = 0;
   int targetReachedCount = 0;
   double totalNetProfitSum = 0.0;

   if(!useDayBlockMode)
     {
      // --- MODE A: Trade Sequence Shuffle (Preserves Original Trade Timestamps) ---
      SSimulatedTrade shuffledTrades[];
      ArrayResize(shuffledTrades, tradeCount);

      for(int iter = 0; iter < mcResult.totalSimulations; iter++)
        {
         ArrayCopy(shuffledTrades, trades);

         // Fisher-Yates Shuffle of P/L outcomes while maintaining timestamp slots
         for(int i = tradeCount - 1; i > 0; i--)
           {
            int j = MathRand() % (i + 1);
            double tempGross = shuffledTrades[i].grossPL;
            double tempComm  = shuffledTrades[i].commission;
            double tempSwap  = shuffledTrades[i].swap;

            shuffledTrades[i].grossPL    = shuffledTrades[j].grossPL;
            shuffledTrades[i].commission = shuffledTrades[j].commission;
            shuffledTrades[i].swap       = shuffledTrades[j].swap;

            shuffledTrades[j].grossPL    = tempGross;
            shuffledTrades[j].commission = tempComm;
            shuffledTrades[j].swap       = tempSwap;
           }

         SSimulationResult res = SimulateChallengeTimestamped(startingBalance, targetPct, maxDailyLossPct, maxOverallLossPct, minDays, ddModel, shuffledTrades);
         netProfits[iter] = res.netProfit;
         totalNetProfitSum += res.netProfit;

         if(res.netProfit > mcResult.bestNetProfit)   mcResult.bestNetProfit  = res.netProfit;
         if(res.netProfit < mcResult.worstNetProfit)  mcResult.worstNetProfit = res.netProfit;
         if(res.maxOverallDrawdownPercent > mcResult.maxOverallDrawdownPercent) mcResult.maxOverallDrawdownPercent = res.maxOverallDrawdownPercent;

         if(res.violationReason == "DAILY LOSS LIMIT BREACHED") dailyViolations++;
         if(res.violationReason == "OVERALL DRAWDOWN LIMIT BREACHED") overallViolations++;
         if(res.isTargetPassed) targetReachedCount++;

         if(res.isTargetPassed && res.isMinDaysMet && !res.isRuleViolated)
            mcResult.passedSimulations++;
         else
            mcResult.failedSimulations++;
        }
     }
   else
     {
      // --- MODE B: Trading-Day Block Monte Carlo Shuffle ---
      // 1. Group Trades By Calendar Day Key
      int uniqueDays = 0;
      int dayKeys[];
      for(int i = 0; i < tradeCount; i++)
        {
         int dk = GetDateKey(trades[i].timestamp);
         bool exists = false;
         for(int k = 0; k < uniqueDays; k++)
           {
            if(dayKeys[k] == dk) { exists = true; break; }
           }
         if(!exists)
           {
            ArrayResize(dayKeys, uniqueDays + 1);
            dayKeys[uniqueDays] = dk;
            uniqueDays++;
           }
        }

      // 2. Perform Block Shuffling across unique day indices
      int dayIndices[];
      ArrayResize(dayIndices, uniqueDays);

      SSimulatedTrade shuffledDayTrades[];
      ArrayResize(shuffledDayTrades, tradeCount);

      for(int iter = 0; iter < mcResult.totalSimulations; iter++)
        {
         for(int d = 0; d < uniqueDays; d++) dayIndices[d] = d;

         // Shuffle day index blocks
         for(int d = uniqueDays - 1; d > 0; d--)
           {
            int j = MathRand() % (d + 1);
            int tmp = dayIndices[d];
            dayIndices[d] = dayIndices[j];
            dayIndices[j] = tmp;
           }

         // Reconstruct trade sequence from day blocks
         int writeIdx = 0;
         datetime simulatedDayTime = trades[0].timestamp;

         for(int d = 0; d < uniqueDays; d++)
           {
            int targetDayKey = dayKeys[dayIndices[d]];
            for(int i = 0; i < tradeCount; i++)
              {
               if(GetDateKey(trades[i].timestamp) == targetDayKey)
                 {
                  shuffledDayTrades[writeIdx] = trades[i];
                  shuffledDayTrades[writeIdx].timestamp = simulatedDayTime; // Assign sequential day timestamp
                  writeIdx++;
                 }
              }
            simulatedDayTime += 86400; // Increment calendar day
           }

         SSimulationResult res = SimulateChallengeTimestamped(startingBalance, targetPct, maxDailyLossPct, maxOverallLossPct, minDays, ddModel, shuffledDayTrades);
         netProfits[iter] = res.netProfit;
         totalNetProfitSum += res.netProfit;

         if(res.netProfit > mcResult.bestNetProfit)   mcResult.bestNetProfit  = res.netProfit;
         if(res.netProfit < mcResult.worstNetProfit)  mcResult.worstNetProfit = res.netProfit;
         if(res.maxOverallDrawdownPercent > mcResult.maxOverallDrawdownPercent) mcResult.maxOverallDrawdownPercent = res.maxOverallDrawdownPercent;

         if(res.violationReason == "DAILY LOSS LIMIT BREACHED") dailyViolations++;
         if(res.violationReason == "OVERALL DRAWDOWN LIMIT BREACHED") overallViolations++;
         if(res.isTargetPassed) targetReachedCount++;

         if(res.isTargetPassed && res.isMinDaysMet && !res.isRuleViolated)
            mcResult.passedSimulations++;
         else
            mcResult.failedSimulations++;
        }
     }

   // 3. Compute Aggregates & Median
   ArraySort(netProfits);
   int mid = mcResult.totalSimulations / 2;
   mcResult.medianNetProfit = netProfits[mid];

   mcResult.passPercentage                  = ((double)mcResult.passedSimulations / mcResult.totalSimulations) * 100.0;
   mcResult.averageNetProfit                = totalNetProfitSum / mcResult.totalSimulations;
   mcResult.probDailyLossViolationPercent   = ((double)dailyViolations / mcResult.totalSimulations) * 100.0;
   mcResult.probOverallLossViolationPercent = ((double)overallViolations / mcResult.totalSimulations) * 100.0;
   mcResult.probTargetReachedPercent       = ((double)targetReachedCount / mcResult.totalSimulations) * 100.0;

   return mcResult;
  }

//+------------------------------------------------------------------+
//| Genuine Rolling Walk-Forward Optimization (WFO) Engine           |
//+------------------------------------------------------------------+
SWalkForwardResult CChallengeSimulator::RunRollingWalkForward(double startingBalance, double targetPct, double maxDailyLossPct, double maxOverallLossPct, int minDays, ENUM_DRAWDOWN_MODEL ddModel, const SSimulatedTrade &allTrades[], int trainMonths, int valMonths, int oosMonths, int stepMonths)
  {
   SWalkForwardResult wfResult;
   wfResult.totalWindowsExecuted          = 0;
   wfResult.aggregateOOSEfficiencyPercent = 0.0;
   wfResult.aggregateOOSNetProfit         = 0.0;
   wfResult.passedOOSWindows              = 0;
   wfResult.failedOOSWindows              = 0;
   wfResult.isSufficientData              = false;
   wfResult.summaryReport                 = "";

   int totalTrades = ArraySize(allTrades);
   if(totalTrades < 20)
     {
      wfResult.summaryReport = "INSUFFICIENT DATA FOR ROLLING WALK-FORWARD: Minimum 20 trade records required.";
      return wfResult;
     }

   datetime firstTime = allTrades[0].timestamp;
   datetime lastTime  = allTrades[totalTrades - 1].timestamp;

   int secondsPerMonth = 30 * 86400;
   int trainSec = trainMonths * secondsPerMonth;
   int valSec   = valMonths * secondsPerMonth;
   int oosSec   = oosMonths * secondsPerMonth;
   int stepSec  = stepMonths * secondsPerMonth;

   int requiredTotalSec = trainSec + valSec + oosSec;

   if((lastTime - firstTime) < requiredTotalSec)
     {
      wfResult.summaryReport = StringFormat("INSUFFICIENT DATA FOR ROLLING WALK-FORWARD: Dataset span (%.1f months) smaller than required window span (%d months).", (double)(lastTime - firstTime) / secondsPerMonth, trainMonths + valMonths + oosMonths);
      return wfResult;
     }

   datetime currentWindowStart = firstTime;
   double totalTrainProfit = 0.0;
   double totalOOSProfit   = 0.0;

   while((currentWindowStart + requiredTotalSec) <= lastTime)
     {
      datetime trainEnd = currentWindowStart + trainSec;
      datetime valEnd   = trainEnd + valSec;
      datetime oosEnd   = valEnd + oosSec;

      SSimulatedTrade trainSet[], valSet[], oosSet[];
      int trCnt = 0, valCnt = 0, oosCnt = 0;

      for(int i = 0; i < totalTrades; i++)
        {
         datetime t = allTrades[i].timestamp;
         if(t >= currentWindowStart && t < trainEnd)
           {
            ArrayResize(trainSet, trCnt + 1);
            trainSet[trCnt] = allTrades[i];
            trCnt++;
           }
         else if(t >= trainEnd && t < valEnd)
           {
            ArrayResize(valSet, valCnt + 1);
            valSet[valCnt] = allTrades[i];
            valCnt++;
           }
         else if(t >= valEnd && t <= oosEnd)
           {
            ArrayResize(oosSet, oosCnt + 1);
            oosSet[oosCnt] = allTrades[i];
            oosCnt++;
           }
        }

      SSimulationResult resTrain = SimulateChallengeTimestamped(startingBalance, targetPct, maxDailyLossPct, maxOverallLossPct, minDays, ddModel, trainSet);
      SSimulationResult resVal   = SimulateChallengeTimestamped(startingBalance, targetPct, maxDailyLossPct, maxOverallLossPct, minDays, ddModel, valSet);
      SSimulationResult resOOS   = SimulateChallengeTimestamped(startingBalance, targetPct, maxDailyLossPct, maxOverallLossPct, minDays, ddModel, oosSet);

      wfResult.totalWindowsExecuted++;
      totalTrainProfit += resTrain.netProfit;
      totalOOSProfit   += resOOS.netProfit;

      if(resOOS.isTargetPassed && resOOS.isMinDaysMet && !resOOS.isRuleViolated)
         wfResult.passedOOSWindows++;
      else
         wfResult.failedOOSWindows++;

      currentWindowStart += stepSec; // Slide window forward by step
     }

   wfResult.isSufficientData       = (wfResult.totalWindowsExecuted > 0);
   wfResult.aggregateOOSNetProfit  = totalOOSProfit;
   wfResult.aggregateOOSEfficiencyPercent = (totalTrainProfit > 0.0) ? (totalOOSProfit / totalTrainProfit) * 100.0 : 0.0;
   wfResult.summaryReport          = StringFormat("ROLLING WFO COMPLETED: Executed %d sliding windows. OOS Pass Rate: %.1f%% | OOS Net Profit: $%.2f | WFO Efficiency: %.1f%%", wfResult.totalWindowsExecuted, ((double)wfResult.passedOOSWindows / wfResult.totalWindowsExecuted) * 100.0, totalOOSProfit, wfResult.aggregateOOSEfficiencyPercent);

   return wfResult;
  }
