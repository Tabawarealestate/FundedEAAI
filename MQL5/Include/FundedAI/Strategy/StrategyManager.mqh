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
#include "../Utils/SymbolUtils.mqh"
#include "../Sessions/SessionEngine.mqh"
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
   ENUM_MARKET_REGIME   detectedRegime;  // Current Market Regime
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
                                              double minScoreThreshold)
  {
   STradeSignal signal;
   signal.hasSignal       = false;
   signal.isBuy           = false;
   signal.suggestedEntry  = 0.0;
   signal.stopLossPrice   = 0.0;
   signal.takeProfitPrice = 0.0;
   signal.riskRewardRatio = 0.0;
   signal.detectedRegime  = REGIME_RANGE;

   if(totalBars < 50)
      return signal;

   SSymbolSpecification spec;
   CSymbolUtils::GetSymbolSpec(symbol, spec);

   // 1. Calculate Current ATR (14) vs Baseline Average ATR (50)
   double atr14  = CIndicatorEngine::CalculateATR(high, low, close, 14);
   double atr100 = CIndicatorEngine::CalculateATR(high, low, close, 50);
   double fastEMA = CIndicatorEngine::CalculateEMA(close, 10, totalBars);
   double slowEMA = CIndicatorEngine::CalculateEMA(close, 30, totalBars);

   signal.detectedRegime = m_regimeEngine.ClassifyRegime(symbol, ltfTimeframe, fastEMA, slowEMA, atr14, atr100, spec.currentSpreadPoints, maxSpreadPoints);
   if(!m_regimeEngine.IsTradingPermittedForRegime())
      return signal; // Block trading under abnormal volatility / spread

   // 2. Fetch True Higher Timeframe (D1/H4/H1) Trend Bias Data
   double htfClose[];
   ArraySetAsSeries(htfClose, true);
   int htfCopied = CopyClose(symbol, htfTimeframe, 0, 50, htfClose);
   bool isHTFBullish = false;
   bool isHTFBearish = false;
   if(htfCopied >= 30)
     {
      double htfFastEMA = CIndicatorEngine::CalculateEMA(htfClose, 10, htfCopied);
      double htfSlowEMA = CIndicatorEngine::CalculateEMA(htfClose, 30, htfCopied);
      isHTFBullish = (htfFastEMA > htfSlowEMA);
      isHTFBearish = (htfFastEMA < htfSlowEMA);
     }

   // 3. Run SMC Strategy Analysis Engines
   m_structureEngine.FindSwingPoints(high, low, time, totalBars, 3);
   ENUM_STRUCTURE_SIGNAL structSignal = m_structureEngine.AnalyzeStructure(close, high, low, totalBars);

   m_orderBlockEngine.DetectOrderBlocks(open, high, low, close, time, totalBars);
   m_fvgEngine.DetectFVGs(high, low, time, totalBars, 10.0, spec.pointSize);

   SSwingPoint latestHigh, latestLow;
   m_structureEngine.GetLatestSwingHigh(latestHigh);
   m_structureEngine.GetLatestSwingLow(latestLow);
   ENUM_LIQUIDITY_SWEEP sweep = m_liquidityEngine.DetectSweep(open, high, low, close, latestHigh.price, latestLow.price);

   // 4. Prepare Real AI Scoring Input with Tight OB/FVG Proximity Validation
   SAISetupInput aiInput;
   aiInput.hasStructureSignal    = (structSignal != STRUCTURE_NONE);
   aiInput.hasLiquiditySweep     = (sweep != SWEEP_NONE);

   SOrderBlock bullOB, bearOB;
   SFairValueGap bullFVG, bearFVG;
   bool hasBullOB  = m_orderBlockEngine.GetLatestFreshBullishOB(bullOB);
   bool hasBearOB  = m_orderBlockEngine.GetLatestFreshBearishOB(bearOB);
   bool hasBullFVG = m_fvgEngine.GetLatestActiveBullishFVG(bullFVG);
   bool hasBearFVG = m_fvgEngine.GetLatestActiveBearishFVG(bearFVG);

   // OB / FVG Tight Proximity Verification: Price must be testing within 0.25 ATR of zone boundary
   double currentPrice = close[1]; // Use completed candle index 1
   double tightRange   = 0.25 * atr14;
   bool isNearBullOB  = (hasBullOB && currentPrice >= bullOB.lowPrice - tightRange && currentPrice <= bullOB.highPrice + tightRange);
   bool isNearBearOB  = (hasBearOB && currentPrice >= bearOB.lowPrice - tightRange && currentPrice <= bearOB.highPrice + tightRange);
   bool isNearBullFVG = (hasBullFVG && currentPrice >= bullFVG.lowerPrice - tightRange && currentPrice <= bullFVG.upperPrice + tightRange);
   bool isNearBearFVG = (hasBearFVG && currentPrice >= bearFVG.lowerPrice - tightRange && currentPrice <= bearFVG.upperPrice + tightRange);

   aiInput.hasOrderBlockOrFVG    = (isNearBullOB || isNearBearOB || isNearBullFVG || isNearBearFVG);

   // Real Higher Timeframe Alignment Check
   bool isSignalBullish = (structSignal == STRUCTURE_BOS_BULLISH || structSignal == STRUCTURE_CHOCH_BULLISH || structSignal == STRUCTURE_MSS_BULLISH);
   aiInput.isHTFAligned          = (isSignalBullish && isHTFBullish) || (!isSignalBullish && isHTFBearish);

   double rsi = CIndicatorEngine::CalculateRSI(close, 14);
   aiInput.isMomentumConfirmed   = (rsi >= 40.0 && rsi <= 60.0) || (structSignal == STRUCTURE_CHOCH_BULLISH && rsi > 50.0);
   aiInput.isVolatilityNormal    = (signal.detectedRegime != REGIME_HIGH_VOLATILITY && signal.detectedRegime != REGIME_ABNORMAL);

   // Real Active Session Filter Check
   aiInput.isSessionOptimal      = CSessionEngine::IsOptimalTradingSession(time[1], spec.gmtOffsetHours);
   aiInput.isSpreadExecutionGood = (spec.currentSpreadPoints <= maxSpreadPoints);
   aiInput.riskRewardRatio       = 2.5;

   // 5. Compute AI Setup Score
   signal.scoreResult = CAIScoringEngine::EvaluateSetup(aiInput);

   // 6. Validate Signal against Minimum Setup Score Threshold
   if(signal.scoreResult.totalScore >= minScoreThreshold && aiInput.hasStructureSignal)
     {
      signal.hasSignal       = true;
      signal.isBuy           = isSignalBullish;
      signal.suggestedEntry  = close[1]; // Use completed candle 1 close price

      // Symbol-Agnostic ATR-Based Stop Loss Fallback
      double minSLDist = (atr14 > 0.0) ? (1.5 * atr14) : (200.0 * spec.pointSize);

      if(signal.isBuy)
        {
         signal.stopLossPrice   = (latestLow.price > 0.0 && latestLow.price < close[1]) ? latestLow.price : (close[1] - minSLDist);
         double slDist          = close[1] - signal.stopLossPrice;
         if(slDist < minSLDist)
            signal.stopLossPrice = close[1] - minSLDist;

         slDist                 = close[1] - signal.stopLossPrice;
         signal.takeProfitPrice = close[1] + (slDist * 2.5);
        }
      else
        {
         signal.stopLossPrice   = (latestHigh.price > 0.0 && latestHigh.price > close[1]) ? latestHigh.price : (close[1] + minSLDist);
         double slDist          = signal.stopLossPrice - close[1];
         if(slDist < minSLDist)
            signal.stopLossPrice = close[1] + minSLDist;

         slDist                 = signal.stopLossPrice - close[1];
         signal.takeProfitPrice = close[1] - (slDist * 2.5);
        }

      signal.riskRewardRatio = 2.5;
     }

   return signal;
  }
