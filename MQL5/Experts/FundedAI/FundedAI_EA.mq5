//+------------------------------------------------------------------+
//|                                                 FundedAI_EA.mq5 |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property version   "1.00"
#property description "FUNDED AI EA - Rule-Aware Prop Firm Challenge Expert Advisor"
#property strict

//--- Include All Modular Engines
#include <FundedAI/Core/Constants.mqh>
#include <FundedAI/Core/Types.mqh>
#include <FundedAI/Core/StatePersist.mqh>
#include <FundedAI/Challenge/ChallengeProfile.mqh>
#include <FundedAI/Challenge/ChallengeGuard.mqh>
#include <FundedAI/Risk/PositionSizer.mqh>
#include <FundedAI/Risk/DynamicRiskManager.mqh>
#include <FundedAI/Portfolio/PortfolioManager.mqh>
#include <FundedAI/Utils/SymbolUtils.mqh>
#include <FundedAI/Strategy/StrategyManager.mqh>
#include <FundedAI/Execution/ExecutionEngine.mqh>
#include <FundedAI/TradeManagement/TradeManager.mqh>
#include <FundedAI/Dashboard/DashboardPanel.mqh>
#include <FundedAI/Sessions/SessionEngine.mqh>
#include <FundedAI/News/NewsFilterEngine.mqh>
#include <FundedAI/Alerts/AlertManager.mqh>
#include <FundedAI/Journal/TradeJournaler.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
input string                 Inp_Section1            = "=== CHALLENGE PROFILE ==="; // --- ACCOUNT & CHALLENGE ---
input double                 Inp_AccountBalance      = 100000.0;                   // Initial Challenge Balance ($)
input ENUM_CHALLENGE_PHASE   Inp_ChallengePhase      = CHALLENGE_PHASE_1;          // Evaluation Phase
input ENUM_DAILY_LOSS_MODE   Inp_DailyLossMode       = DAILY_LOSS_MODE_A_EQUITY;   // Daily Loss Calculation Mode
input ENUM_DRAWDOWN_MODEL    Inp_DrawdownModel       = DRAWDOWN_STATIC;            // Drawdown Model (Static / Trailing)
input double                 Inp_ProfitTarget        = 10.0;                       // Profit Target (%)
input double                 Inp_MaxDailyLoss        = 5.0;                        // Max Daily Loss Limit (%)
input double                 Inp_MaxOverallLoss      = 10.0;                       // Max Overall Drawdown (%)
input int                    Inp_MinTradingDays      = 4;                          // Minimum Required Trading Days
input bool                   Inp_AllowWeekendHolding = false;                      // Allow Weekend Holding
input bool                   Inp_AllowOvernightTrade = true;                       // Allow Overnight Holding

input string                 Inp_Section2            = "=== RISK CONTROL ===";     // --- RISK CONTROL ---
input ENUM_RISK_MODE         Inp_RiskMode            = RISK_MODE_BALANCED;         // Risk Strategy Mode
input double                 Inp_RiskPercent         = 0.25;                       // Risk per Trade (%)
input int                    Inp_MaxOpenPositions    = 3;                          // Max Open Positions
input double                 Inp_MaxPortfolioRisk    = 2.0;                        // Max Portfolio Risk (%)

input string                 Inp_Section3            = "=== TIMEFRAMES & STRATEGY ===";// --- TIMEFRAMES ---
input ENUM_TIMEFRAMES        Inp_HTFTimeframe        = PERIOD_H4;                  // Higher Timeframe Trend Bias
input ENUM_TIMEFRAMES        Inp_LTFTimeframe        = PERIOD_M15;                 // Lower Timeframe Entry
input int                    Inp_GMTOffsetHours      = 2;                          // Broker Server GMT Offset (Hours)

input string                 Inp_Section4            = "=== SAFETIES & SPREAD ==="; // --- SAFETY & EXECUTION ---
input int                    Inp_MaxSpreadPoints     = 30;                         // Max Allowed Spread (Points)
input int                    Inp_MaxSlippagePoints   = 10;                         // Max Allowed Slippage (Points)
input bool                   Inp_EnableNewsFilter    = true;                       // Enforce High Impact News Protection
input ulong                  Inp_MagicNumber         = FUNDED_AI_DEFAULT_MAGIC;    // Magic Number

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS                                                   |
//+------------------------------------------------------------------+
CChallengeProfile   g_profile;
CChallengeGuard     g_guard;
CDynamicRiskManager g_riskManager;
CPortfolioManager   g_portfolioManager;
CStrategyManager    g_strategyManager;
CExecutionEngine    g_executionEngine;
CTradeManager       g_tradeManager;
CDashboardPanel     g_dashboard;
CNewsFilterEngine   g_newsEngine;
CAlertManager       g_alertManager;
CTradeJournaler     g_journaler;
CStatePersist       g_statePersist;

double              g_dailyStartingEquity  = 0.0;
double              g_dailyStartingBalance = 0.0;
datetime            g_lastDayChecked       = 0;
datetime            g_lastBarTime          = 0;
int                 g_consecutiveLosses    = 0;
int                 g_activeTradingDays    = 0;
double              g_latestSetupScore     = 0.0;
ENUM_MARKET_REGIME  g_latestRegime         = REGIME_RANGE;

//+------------------------------------------------------------------+
//| Helper Function: Calculate Unique Traded Days From History        |
//| Uses Dynamic Array to prevent array overflow errors              |
//+------------------------------------------------------------------+
int CountUniqueTradingDaysFromHistory(ulong magicNumber)
  {
   int uniqueDays = 0;
   if(!HistorySelect(0, TimeCurrent()))
      return 0;

   int totalDeals = HistoryDealsTotal();
   if(totalDeals <= 0)
      return 0;

   datetime tradedDates[];
   ArrayResize(tradedDates, totalDeals);
   int dateCount = 0;

   for(int i = 0; i < totalDeals; i++)
     {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket > 0 && HistoryDealGetInteger(dealTicket, DEAL_MAGIC) == (long)magicNumber)
        {
         datetime dealTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
         MqlDateTime dt;
         TimeToStruct(dealTime, dt);
         datetime dayTimestamp = StructToTime(dt) - (dt.hour * 3600 + dt.min * 60 + dt.sec);

         bool exists = false;
         for(int k = 0; k < dateCount; k++)
           {
            if(tradedDates[k] == dayTimestamp)
              {
               exists = true;
               break;
              }
           }
         if(!exists)
           {
            tradedDates[dateCount] = dayTimestamp;
            dateCount++;
           }
        }
     }
   return dateCount;
  }

//+------------------------------------------------------------------+
//| Helper Function: New Bar Detection                               |
//+------------------------------------------------------------------+
bool IsNewBar(void)
  {
   datetime currentBarTime = iTime(_Symbol, Inp_LTFTimeframe, 0);
   if(currentBarTime != g_lastBarTime)
     {
      g_lastBarTime = currentBarTime;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // 1. Initialize Challenge Profile
   SChallengeProfileConfig config;
   config.profileName               = "Configured Prop Profile";
   config.initialBalance            = Inp_AccountBalance;
   config.phase                     = Inp_ChallengePhase;
   config.dailyLossMode             = Inp_DailyLossMode;
   config.drawdownModel             = Inp_DrawdownModel;
   config.profitTargetPercent     = Inp_ProfitTarget;
   config.maxDailyLossPercent       = Inp_MaxDailyLoss;
   config.maxOverallLossPercent     = Inp_MaxOverallLoss;
   config.minTradingDays            = Inp_MinTradingDays;
   config.maxTradingDays            = 0;
   config.allowWeekendHolding       = Inp_AllowWeekendHolding;
   config.allowNewsTrading          = !Inp_EnableNewsFilter;
   config.allowOvernightTrading     = Inp_AllowOvernightTrade;
   config.maxOpenPositions          = Inp_MaxOpenPositions;
   config.maxPortfolioRiskPercent   = Inp_MaxPortfolioRisk;
   config.maxLotSize                = 0.0;
   config.gmtOffsetHours            = Inp_GMTOffsetHours;
   config.customRulesDescription    = "Live Rule-Aware Enforcement";

   config.dailyLossWarningPercent   = Inp_MaxDailyLoss * 0.60;
   config.dailyLossSoftStopPercent  = Inp_MaxDailyLoss * 0.80;
   config.dailyLossEmergencyPercent = Inp_MaxDailyLoss * 0.90;
   config.maxLossWarningPercent     = Inp_MaxOverallLoss * 0.75;
   config.maxLossEmergencyPercent   = Inp_MaxOverallLoss * 0.85;

   g_profile.Configure(config);
   g_guard.SetProfile(&g_profile);

   // 2. Initialize Engines & Persistence
   g_riskManager.SetRiskMode(Inp_RiskMode, Inp_RiskPercent);
   g_portfolioManager.Init(Inp_MagicNumber);
   g_executionEngine.Init(Inp_MagicNumber, Inp_MaxSlippagePoints, 3);
   g_tradeManager.Init(Inp_MagicNumber);
   g_dashboard.Init("FundedAI_Dash_");
   g_newsEngine.SetEnabled(Inp_EnableNewsFilter);
   g_alertManager.Init(true, true, true);
   g_journaler.Init("FundedAI_Trade_Journal.csv");
   g_statePersist.Init(Inp_MagicNumber);

   // 3. Recover Account History Traded Days & High-Water Mark State
   g_activeTradingDays = CountUniqueTradingDaysFromHistory(Inp_MagicNumber);

   double savedStartBal = 0.0, savedDailyEq = 0.0, savedDailyBal = 0.0, savedHWM = 0.0;
   int savedDays = 0;
   if(g_statePersist.LoadState(savedStartBal, savedDailyEq, savedDailyBal, savedHWM, savedDays))
     {
      g_dailyStartingEquity  = savedDailyEq;
      g_dailyStartingBalance = savedDailyBal;
      g_profile.SetHighWaterMark(savedHWM); // Restore recovered High-Water Mark into profile
      Print("RECOVERED PERSISTED STATE: Daily Equity = $", savedDailyEq, " HWM = $", savedHWM, " History Days = ", g_activeTradingDays);
     }
   else
     {
      g_dailyStartingEquity  = AccountInfoDouble(ACCOUNT_EQUITY);
      g_dailyStartingBalance = AccountInfoDouble(ACCOUNT_BALANCE);
     }

   g_lastDayChecked = TimeCurrent();

   EventSetTimer(1);
   Print("FUNDED AI EA initialized successfully. Daily Loss Mode: ", EnumToString(Inp_DailyLossMode), " Drawdown Model: ", EnumToString(Inp_DrawdownModel));
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   SChallengeAccountStatus status = g_profile.GetStatus();
   g_statePersist.SaveState(status.startingBalance, g_dailyStartingEquity, g_dailyStartingBalance, status.highWaterMark, g_activeTradingDays);
   g_dashboard.Destroy();
   Print("FUNDED AI EA deinitialized and state persisted. Reason: ", reason);
  }

//+------------------------------------------------------------------+
//| Timer event function (Continuous Guard Check & Dashboard Render) |
//+------------------------------------------------------------------+
void OnTimer()
  {
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   // Detect New Trading Day (Midnight Reset)
   MqlDateTime lastDt;
   TimeToStruct(g_lastDayChecked, lastDt);
   if(dt.day != lastDt.day)
     {
      g_activeTradingDays    = CountUniqueTradingDaysFromHistory(Inp_MagicNumber);
      g_dailyStartingEquity  = AccountInfoDouble(ACCOUNT_EQUITY);
      g_dailyStartingBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      g_lastDayChecked       = now;
      Print("NEW TRADING DAY DETECTED. History Active Day Count: #", g_activeTradingDays, " Daily starting equity: $", DoubleToString(g_dailyStartingEquity, 2));
     }

   // Evaluate Safety Guard State
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   ENUM_EA_STATUS status = g_guard.EvaluateState(balance, equity, g_dailyStartingEquity, g_dailyStartingBalance, g_activeTradingDays);

   // Update consecutive loss tracker from closed trade deals
   g_consecutiveLosses = g_tradeManager.GetConsecutiveLossCount(Inp_MagicNumber);

   // Weekend Holding Rule Enforcement (Close trades Friday evening if holding prohibited)
   if(!Inp_AllowWeekendHolding && dt.day_of_week == 5 && dt.hour >= 21)
     {
      g_executionEngine.CloseAllPositions(""); // Account-wide weekend liquidation
      g_alertManager.SendRiskAlert("WEEKEND RULE ENFORCED", "Closing all trades before weekend market close.");
     }

   // Overnight Holding Rule Enforcement (Close trades before midnight if holding prohibited)
   if(!Inp_AllowOvernightTrade && dt.hour >= 23)
     {
      g_executionEngine.CloseAllPositions(""); // Account-wide overnight liquidation
      g_alertManager.SendRiskAlert("OVERNIGHT RULE ENFORCED", "Closing all trades before overnight market rollover.");
     }

   // Update Dashboard Visual Panel
   double portRisk = g_portfolioManager.GetTotalPortfolioRiskPercent(equity);
   ENUM_TRADING_SESSION currentSess = CSessionEngine::GetCurrentSession(now, Inp_GMTOffsetHours);
   string sessStr = EnumToString(currentSess);
   string newsStr = g_newsEngine.GetNewsStatusString();

   g_dashboard.Update(g_profile.GetStatus(), status, g_latestRegime, g_latestSetupScore, g_guard.GetStatusReason(), newsStr, sessStr, portRisk);

   // Save State
   SChallengeAccountStatus accStatus = g_profile.GetStatus();
   g_statePersist.SaveState(accStatus.startingBalance, g_dailyStartingEquity, g_dailyStartingBalance, accStatus.highWaterMark, g_activeTradingDays);

   // Emergency Liquidation if Safety Guard triggers Lockdown
   if(g_guard.ShouldCloseAllPositions())
     {
      g_executionEngine.CloseAllPositions(""); // Account-wide emergency liquidation across all symbols
     }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Always manage open positions (Break-Even & Trailing SL) on every tick
   SSymbolSpecification spec;
   if(CSymbolUtils::GetSymbolSpec(_Symbol, spec, 10))
     {
      g_tradeManager.ManageOpenPositions(_Symbol, 1.0, 200.0, spec.pointSize);
     }

   // Evaluate Guard State
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   ENUM_EA_STATUS status = g_guard.EvaluateState(balance, equity, g_dailyStartingEquity, g_dailyStartingBalance, g_activeTradingDays);

   if(!g_guard.CanOpenNewTrade())
      return; // Block entry scanning if paused or stopped

   // News Protection Rule: Block entries if news protection enabled but feed unattached
   if(g_newsEngine.ShouldBlockTradingForNews())
      return;

   // Overnight Rule Entry Block: Do not open new entries late at night if overnight trading disabled
   MqlDateTime currentDt;
   TimeToStruct(TimeCurrent(), currentDt);
   if(!Inp_AllowOvernightTrade && currentDt.hour >= 22)
      return;

   // Prevent tick-spamming: only scan for new entry signals on a NEW BAR
   if(!IsNewBar())
      return;

   // Validate Market Data & Spread
   if(!CSymbolUtils::ValidateMarketData(_Symbol, Inp_MaxSpreadPoints, 10))
      return;

   // Check Max Open Position & Max Portfolio Risk Limits (With Selected Ticket Selection)
   int openCount = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong posTicket = PositionGetTicket(i);
      if(posTicket > 0)
        {
         if(PositionGetInteger(POSITION_MAGIC) == (long)Inp_MagicNumber)
            openCount++;
        }
     }
   if(openCount >= Inp_MaxOpenPositions)
      return;

   if(g_portfolioManager.GetTotalPortfolioRiskPercent(equity) >= Inp_MaxPortfolioRisk)
      return;

   if(g_portfolioManager.IsCurrencyExposureAtLimit(_Symbol, 2))
      return;

   // Fetch Lower Timeframe Bar Data for Setup
   double close[], high[], low[], open[];
   datetime time[];

   int copied = CopyClose(_Symbol, Inp_LTFTimeframe, 0, 100, close);
   CopyHigh(_Symbol, Inp_LTFTimeframe, 0, 100, high);
   CopyLow(_Symbol, Inp_LTFTimeframe, 0, 100, low);
   CopyOpen(_Symbol, Inp_LTFTimeframe, 0, 100, open);
   CopyTime(_Symbol, Inp_LTFTimeframe, 0, 100, time);

   if(copied < 50)
      return;

   // Correct MQL5 series array ordering AFTER Copy function calls
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(time, true);

   // Evaluate Multi-Timeframe Setup Signal
   STradeSignal signal = g_strategyManager.EvaluateMarket(_Symbol, Inp_HTFTimeframe, Inp_LTFTimeframe, close, high, low, open, time, copied, Inp_MaxSpreadPoints, MIN_SETUP_SCORE_THRESHOLD);
   g_latestSetupScore = signal.scoreResult.totalScore;
   g_latestRegime     = signal.detectedRegime;

   if(signal.hasSignal && signal.scoreResult.totalScore >= MIN_SETUP_SCORE_THRESHOLD)
     {
      // Calculate Dynamic Position Sizing
      SChallengeAccountStatus statusData = g_profile.GetStatus();
      double riskMult = g_riskManager.CalculateRiskMultiplier(status, g_consecutiveLosses, statusData.targetProgressPercent, statusData.currentDailyDrawdownPercent, Inp_MaxDailyLoss);

      double slPoints = MathAbs(signal.suggestedEntry - signal.stopLossPrice) / spec.pointSize;
      double lot = CPositionSizer::CalculateLotSize(equity, g_riskManager.GetBaseRiskPercent(), riskMult, slPoints, spec.tickValue, spec.tickSize, spec.pointSize, spec.minLot, spec.maxLot, spec.lotStep);

      if(lot > 0.0)
        {
         ENUM_ORDER_TYPE orderType = signal.isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
         string dirStr = signal.isBuy ? "BUY" : "SELL";

         SExecutionResult res = g_executionEngine.OpenMarketOrder(_Symbol, orderType, lot, signal.stopLossPrice, signal.takeProfitPrice, "FUNDED_AI_ENTRY");

         if(res.isSuccess)
           {
            g_alertManager.SendTradeAlert(_Symbol, dirStr, signal.suggestedEntry, signal.stopLossPrice, signal.takeProfitPrice, signal.scoreResult.totalScore);
            g_journaler.LogTrade(TimeCurrent(), _Symbol, dirStr, signal.suggestedEntry, signal.stopLossPrice, signal.takeProfitPrice, lot, g_riskManager.GetBaseRiskPercent() * riskMult, signal.scoreResult.totalScore, EnumToString(signal.detectedRegime), signal.scoreResult.explanation);
           }
        }
     }
  }
