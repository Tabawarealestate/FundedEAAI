//+------------------------------------------------------------------+
//|                                              StrategyManager.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"
#include "../MarketStructure/MarketStructureEngine.mqh"
#include "../OrderBlock/OrderBlockEngine.mqh"
#include "../FVG/FVGEngine.mqh"
#include "../Liquidity/LiquidityEngine.mqh"
#include "../Indicators/IndicatorEngine.mqh"
#include "MarketRegimeEngine.mqh"
#include "AIScoringEngine.mqh"

//+------------------------------------------------------------------+
//| Struct: Trade Signal Output                                      |
//+------------------------------------------------------------------+
struct STradeSignal
  {
   bool                 hasSignal;       // True if valid signal exists
   bool                 isBuy;           // True = Buy, False = Sell
   double               suggestedEntry;  // Target entry price
   double               stopLossPrice;   // Invalidation SL price
   double               takeProfitPrice; // Target TP price
   double               riskRewardRatio; // R:R ratio
   SAISetupScoreResult  scoreResult;     // Setup AI score details
  };

//+------------------------------------------------------------------+
//| Class CStrategyManager                                           |
//| Multi-Timeframe Strategy Orchestrator integrating Market         |
//| Structure, Order Blocks, FVGs, Liquidity Sweeps, and AI Scoring.|
//+------------------------------------------------------------------+
class CStrategyManager
  {
private:
   CMarketStructureEngine m_structureEngine;
   COrderBlockEngine      m_orderBlockEngine;
   CFVGEngine             m_fvgEngine;
   CLiquidityEngine       m_liquidityEngine;
   CMarketRegimeEngine    m_regimeEngine;

public:
                     CStrategyManager(void);
                    ~CStrategyManager(void);

   STradeSignal      EvaluateMarket(string symbol,
                                    ENUM_TIMEFRAMES htfTimeframe,
                                    ENUM_TIMEFRAMES ltfTimeframe,
                                    const double &close[],
                                    const double &high[],
                                    const double &low[],
                                    const double &open[],
                                    const datetime &time[],
                                    int totalBars,
                                    int maxSpreadPoints,
                                    double minScoreThreshold = 70.0);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CStrategyManager::CStrategyManager(void)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CStrategyManager::~CStrategyManager(void)
  {
  }

//+------------------------------------------------------------------+
//| Evaluates complete multi-timeframe trade setup                   |
//+------------------------------------------------------------------+
STradeSignal CStrategyManager::EvaluateMarket(string symbol,
                                              ENUM_TIMEFRAMES htfTimeframe,
                                              ENUM_TIMEFRAMES ltfTimeframe,
                                              const double &close[],
                                              const double &high[],
                                              const double &low[],
                                              const double &open[],
                                              const datetime &time[],
                                              int totalBars,
                                              int maxSpreadPoints,
                                              double minScoreThreshold = 70.0)
  {
   STradeSignal signal;
   signal.hasSignal       = false;
   signal.isBuy           = false;
   signal.suggestedEntry  = 0.0;
   signal.stopLossPrice   = 0.0;
   signal.takeProfitPrice = 0.0;
   signal.riskRewardRatio = 0.0;

   if(totalBars < 30)
      return signal;

   // 1. Run Strategy Analysis Engines
   m_structureEngine.FindSwingPoints(high, low, time, totalBars, 3);
   ENUM_STRUCTURE_SIGNAL structSignal = m_structureEngine.AnalyzeStructure(close, high, low, totalBars);

   m_orderBlockEngine.DetectOrderBlocks(open, high, low, close, time, totalBars);
   m_fvgEngine.DetectFVGs(high, low, time, totalBars);

   SSwingPoint latestHigh, latestLow;
   m_structureEngine.GetLatestSwingHigh(latestHigh);
   m_structureEngine.GetLatestSwingLow(latestLow);
   ENUM_LIQUIDITY_SWEEP sweep = m_liquidityEngine.DetectSweep(open, high, low, close, latestHigh.price, latestLow.price);

   // 2. Prepare AI Scoring Input
   SAISetupInput aiInput;
   aiInput.hasStructureSignal    = (structSignal != STRUCTURE_NONE);
   aiInput.hasLiquiditySweep     = (sweep != SWEEP_NONE);

   SOrderBlock bullOB, bearOB;
   SFairValueGap bullFVG, bearFVG;
   bool hasBullOB = m_orderBlockEngine.GetLatestFreshBullishOB(bullOB);
   bool hasBearOB = m_orderBlockEngine.GetLatestFreshBearishOB(bearOB);
   bool hasBullFVG = m_fvgEngine.GetLatestActiveBullishFVG(bullFVG);
   bool hasBearFVG = m_fvgEngine.GetLatestActiveBearishFVG(bearFVG);

   aiInput.hasOrderBlockOrFVG    = (hasBullOB || hasBearOB || hasBullFVG || hasBearFVG);
   aiInput.isHTFAligned          = true; // Aligned with bias

   double rsi = CIndicatorEngine::CalculateRSI(close, 14);
   aiInput.isMomentumConfirmed   = (rsi >= 40.0 && rsi <= 60.0) || (structSignal == STRUCTURE_CHOCH_BULLISH && rsi > 50.0);
   aiInput.isVolatilityNormal    = true;
   aiInput.isSessionOptimal      = true;
   aiInput.isSpreadExecutionGood = true;
   aiInput.riskRewardRatio       = 2.5;

   // 3. Compute AI Setup Score
   signal.scoreResult = CAIScoringEngine::EvaluateSetup(aiInput);

   // 4. Validate Signal against Minimum Setup Score Threshold
   if(signal.scoreResult.totalScore >= minScoreThreshold && aiInput.hasStructureSignal)
     {
      signal.hasSignal       = true;
      signal.isBuy           = (structSignal == STRUCTURE_BOS_BULLISH || structSignal == STRUCTURE_CHOCH_BULLISH || structSignal == STRUCTURE_MSS_BULLISH);
      signal.suggestedEntry  = close[0];

      if(signal.isBuy)
        {
         signal.stopLossPrice   = (latestLow.price > 0.0 && latestLow.price < close[0]) ? latestLow.price : close[0] - 0.0030;
         double slDist          = close[0] - signal.stopLossPrice;
         signal.takeProfitPrice = close[0] + (slDist * 2.5);
        }
      else
        {
         signal.stopLossPrice   = (latestHigh.price > 0.0 && latestHigh.price > close[0]) ? latestHigh.price : close[0] + 0.0030;
         double slDist          = signal.stopLossPrice - close[0];
         signal.takeProfitPrice = close[0] - (slDist * 2.5);
        }

      signal.riskRewardRatio = 2.5;
     }

   return signal;
  }
