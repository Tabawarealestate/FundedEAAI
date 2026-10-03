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
#include <FundedAI/Challenge/ChallengeProfile.mqh>
#include <FundedAI/Challenge/ChallengeGuard.mqh>
#include <FundedAI/Risk/PositionSizer.mqh>
#include <FundedAI/Risk/DynamicRiskManager.mqh>
#include <FundedAI/Utils/SymbolUtils.mqh>
#include <FundedAI/Strategy/StrategyManager.mqh>
#include <FundedAI/Execution/ExecutionEngine.mqh>
#include <FundedAI/TradeManagement/TradeManager.mqh>
#include <FundedAI/Dashboard/DashboardPanel.mqh>
#include <FundedAI/Sessions/SessionEngine.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
input string               Inp_Section1            = "=== CHALLENGE PROFILE ==="; // --- ACCOUNT & CHALLENGE ---
input double               Inp_AccountBalance      = 100000.0;                   // Initial Challenge Balance ($)
input ENUM_CHALLENGE_PHASE Inp_ChallengePhase      = CHALLENGE_PHASE_1;          // Evaluation Phase
input double               Inp_ProfitTarget        = 10.0;                       // Profit Target (%)
input double               Inp_MaxDailyLoss        = 5.0;                        // Max Daily Loss Limit (%)
input double               Inp_MaxOverallLoss      = 10.0;                       // Max Overall Drawdown (%)

input string               Inp_Section2            = "=== RISK CONTROL ===";     // --- RISK CONTROL ---
input ENUM_RISK_MODE       Inp_RiskMode            = RISK_MODE_BALANCED;         // Risk Strategy Mode
input double               Inp_RiskPercent         = 0.25;                       // Risk per Trade (%)
input int                  Inp_MaxOpenPositions    = 3;                          // Max Open Positions

input string               Inp_Section3            = "=== SAFETIES & SPREAD ==="; // --- SAFETY & EXECUTION ---
input int                  Inp_MaxSpreadPoints     = 30;                         // Max Allowed Spread (Points)
input int                  Inp_MaxSlippagePoints   = 10;                         // Max Allowed Slippage (Points)
input ulong                Inp_MagicNumber         = FUNDED_AI_DEFAULT_MAGIC;    // Magic Number

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS                                                   |
//+------------------------------------------------------------------+
CChallengeProfile   g_profile;
CChallengeGuard     g_guard;
CDynamicRiskManager g_riskManager;
CStrategyManager    g_strategyManager;
CExecutionEngine    g_executionEngine;
CTradeManager       g_tradeManager;
CDashboardPanel     g_dashboard;

double              g_dailyStartingEquity = 0.0;
datetime            g_lastDayChecked      = 0;
datetime            g_lastBarTime         = 0;
int                 g_consecutiveLosses   = 0;
double              g_latestSetupScore    = 0.0;

//+------------------------------------------------------------------+
//| Helper Function: New Bar Detection                               |
//+------------------------------------------------------------------+
bool IsNewBar(void)
  {
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
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
   config.profileName               = "User Configured Profile";
   config.initialBalance            = Inp_AccountBalance;
   config.phase                     = Inp_ChallengePhase;
   config.profitTargetPercent     = Inp_ProfitTarget;
   config.maxDailyLossPercent       = Inp_MaxDailyLoss;
   config.maxOverallLossPercent     = Inp_MaxOverallLoss;
   config.minTradingDays            = 4;
   config.maxTradingDays            = 0;
   config.allowWeekendHolding       = false;
   config.allowNewsTrading          = false;
   config.allowOvernightTrading     = true;
   config.maxOpenPositions          = Inp_MaxOpenPositions;
   config.maxLotSize                = 0.0;
   config.customRulesDescription    = "Live MT5 Challenge Enforcement";

   config.dailyLossWarningPercent   = Inp_MaxDailyLoss * 0.60;
   config.dailyLossSoftStopPercent  = Inp_MaxDailyLoss * 0.80;
   config.dailyLossEmergencyPercent = Inp_MaxDailyLoss * 0.90;
   config.maxLossWarningPercent     = Inp_MaxOverallLoss * 0.75;
   config.maxLossEmergencyPercent   = Inp_MaxOverallLoss * 0.85;

   g_profile.Configure(config);
   g_guard.SetProfile(&g_profile);

   // 2. Initialize Risk, Execution, Trade Manager & Dashboard
   g_riskManager.SetRiskMode(Inp_RiskMode, Inp_RiskPercent);
   g_executionEngine.Init(Inp_MagicNumber, Inp_MaxSlippagePoints, 3);
   g_tradeManager.Init(Inp_MagicNumber);
   g_dashboard.Init("FundedAI_Dash_");

   // 3. Initialize Starting Equity
   g_dailyStartingEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_lastDayChecked      = TimeCurrent();

   EventSetTimer(1); // Set 1-second timer for continuous guard evaluation & dashboard update
   Print("FUNDED AI EA initialized successfully. Mode: ", EnumToString(Inp_RiskMode));
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   g_dashboard.Destroy();
   Print("FUNDED AI EA deinitialized. Reason: ", reason);
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
      g_dailyStartingEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_lastDayChecked      = now;
      Print("NEW TRADING DAY DETECTED. Reset daily starting equity to: $", DoubleToString(g_dailyStartingEquity, 2));
     }

   // Evaluate Safety Guard State
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   ENUM_EA_STATUS status = g_guard.EvaluateState(balance, equity, g_dailyStartingEquity);

   // Update consecutive loss tracker from closed trade deals
   g_consecutiveLosses = g_tradeManager.GetConsecutiveLossCount(Inp_MagicNumber);

   // Update Dashboard Visual Panel
   g_dashboard.Update(g_profile.GetStatus(), status, REGIME_STRONG_BULL_TREND, g_latestSetupScore, g_guard.GetStatusReason());

   // Emergency Liquidation if Safety Guard triggers Lockdown
   if(g_guard.ShouldCloseAllPositions())
     {
      g_executionEngine.CloseAllPositions(_Symbol);
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
   ENUM_EA_STATUS status = g_guard.EvaluateState(balance, equity, g_dailyStartingEquity);

   if(!g_guard.CanOpenNewTrade())
      return; // Block entry scanning if paused or stopped

   // Prevent tick-spamming: only scan for new entry signals on a NEW BAR
   if(!IsNewBar())
      return;

   // Validate Market Data & Spread
   if(!CSymbolUtils::ValidateMarketData(_Symbol, Inp_MaxSpreadPoints, 10))
      return;

   // Check Max Position Limit
   int openCount = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetInteger(POSITION_MAGIC) == (long)Inp_MagicNumber)
         openCount++;
     }
   if(openCount >= Inp_MaxOpenPositions)
      return;

   // Fetch Bar Data
   double close[], high[], low[], open[];
   datetime time[];
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(time, true);

   int copied = CopyClose(_Symbol, _Period, 0, 100, close);
   CopyHigh(_Symbol, _Period, 0, 100, high);
   CopyLow(_Symbol, _Period, 0, 100, low);
   CopyOpen(_Symbol, _Period, 0, 100, open);
   CopyTime(_Symbol, _Period, 0, 100, time);

   if(copied < 50)
      return;

   // Evaluate Multi-Timeframe Setup Signal
   STradeSignal signal = g_strategyManager.EvaluateMarket(_Symbol, PERIOD_H1, _Period, close, high, low, open, time, copied, Inp_MaxSpreadPoints, MIN_SETUP_SCORE_THRESHOLD);
   g_latestSetupScore = signal.scoreResult.totalScore;

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
         SExecutionResult res = g_executionEngine.OpenMarketOrder(_Symbol, orderType, lot, signal.stopLossPrice, signal.takeProfitPrice, "FUNDED_AI_ENTRY");

         if(res.isSuccess)
           {
            Print("TRADE EXECUTED: ", res.errorMessage, " Ticket: ", res.ticket, " AI Score: ", signal.scoreResult.totalScore);
           }
        }
     }
  }
