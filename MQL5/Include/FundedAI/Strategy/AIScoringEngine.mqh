//+------------------------------------------------------------------+
//|                                              AIScoringEngine.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Struct: AI Setup Evaluation Inputs                               |
//+------------------------------------------------------------------+
struct SAISetupInput
  {
   bool   hasStructureSignal;    // BOS/CHoCH/MSS present (20%)
   bool   hasLiquiditySweep;     // BSL/SSL Liquidity Sweep (15%)
   bool   hasOrderBlockOrFVG;    // Fresh OB or Active FVG aligned (15%)
   bool   isHTFAligned;          // D1/H4/H1 Higher Timeframe Trend Alignment (15%)
   bool   isMomentumConfirmed;   // RSI / Moving Average confirmation (10%)
   bool   isVolatilityNormal;    // ATR within normal bounds (10%)
   bool   isSessionOptimal;      // London / New York session (5%)
   bool   isSpreadExecutionGood; // Spread <= max threshold (5%)
   double riskRewardRatio;       // R:R >= 2.0 (5%)
  };

//+------------------------------------------------------------------+
//| Struct: AI Setup Score Output                                    |
//+------------------------------------------------------------------+
struct SAISetupScoreResult
  {
   double               totalScore;       // Final aggregated score (0 - 100)
   ENUM_SETUP_QUALITY   qualityCategory;  // VERY_STRONG, QUALIFIED, WATCHLIST, REJECTED
   string               explanation;      // Rule-based explanation
  };

//+------------------------------------------------------------------+
//| Class CAIScoringEngine                                           |
//| Rule-Based AI Setup Scoring Engine aggregating trade evidence    |
//| into a 0 - 100 score to ensure high-probability trade selection. |
//+------------------------------------------------------------------+
class CAIScoringEngine
  {
public:
                     CAIScoringEngine(void);
                    ~CAIScoringEngine(void);

   static SAISetupScoreResult EvaluateSetup(const SAISetupInput &input);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CAIScoringEngine::CAIScoringEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CAIScoringEngine::~CAIScoringEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Evaluates trade setup using weighted rule-based scoring model    |
//+------------------------------------------------------------------+
SAISetupScoreResult CAIScoringEngine::EvaluateSetup(const SAISetupInput &input)
  {
   SAISetupScoreResult result;
   double score = 0.0;

   // 1. Market Structure (20 Points)
   if(input.hasStructureSignal)
      score += 20.0;

   // 2. Liquidity Sweep (15 Points)
   if(input.hasLiquiditySweep)
      score += 15.0;

   // 3. Order Block / FVG (15 Points)
   if(input.hasOrderBlockOrFVG)
      score += 15.0;

   // 4. Higher Timeframe Alignment (15 Points)
   if(input.isHTFAligned)
      score += 15.0;

   // 5. Momentum Confirmation (10 Points)
   if(input.isMomentumConfirmed)
      score += 10.0;

   // 6. Volatility Quality (10 Points)
   if(input.isVolatilityNormal)
      score += 10.0;

   // 7. Session Quality (5 Points)
   if(input.isSessionOptimal)
      score += 5.0;

   // 8. Spread / Execution Quality (5 Points)
   if(input.isSpreadExecutionGood)
      score += 5.0;

   // 9. Risk/Reward Ratio (5 Points)
   if(input.riskRewardRatio >= 2.0)
      score += 5.0;

   result.totalScore = score;

   // Classify Setup Category
   if(score >= 85.0)
      result.qualityCategory = SETUP_VERY_STRONG;
   else if(score >= 70.0)
      result.qualityCategory = SETUP_QUALIFIED;
   else if(score >= 55.0)
      result.qualityCategory = SETUP_WATCHLIST;
   else
      result.qualityCategory = SETUP_REJECTED;

   // Generate Rule-Based AI Explanation
   result.explanation = StringFormat("RULE-BASED AI SCORE: %.0f/100 | Struct:%s | Liq:%s | OB/FVG:%s | HTF:%s | R:R:1:%.1f",
                                     score,
                                     input.hasStructureSignal ? "OK" : "NO",
                                     input.hasLiquiditySweep ? "OK" : "NO",
                                     input.hasOrderBlockOrFVG ? "OK" : "NO",
                                     input.isHTFAligned ? "OK" : "NO",
                                     input.riskRewardRatio);

   return result;
  }
