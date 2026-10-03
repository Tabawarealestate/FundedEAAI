//+------------------------------------------------------------------+
//|                                           MarketRegimeEngine.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Class CMarketRegimeEngine                                        |
//| Analyzes technical indicators (ATR, Moving Averages, Volatility)  |
//| and classifies current market regime to guide strategy selection.|
//+------------------------------------------------------------------+
class CMarketRegimeEngine
  {
private:
   ENUM_MARKET_REGIME m_currentRegime;
   double             m_currentATR;
   double             m_averageATR;
   double             m_fastMA;
   double             m_slowMA;

public:
                     CMarketRegimeEngine(void);
                    ~CMarketRegimeEngine(void);

   //--- Regime Detection
   ENUM_MARKET_REGIME ClassifyRegime(string symbol,
                                     ENUM_TIMEFRAMES timeframe,
                                     double fastMAVal,
                                     double slowMAVal,
                                     double atrVal,
                                     double avgATRVal,
                                     int currentSpreadPoints,
                                     int maxSpreadPoints);

   ENUM_MARKET_REGIME GetCurrentRegime(void) const { return m_currentRegime; }
   bool               IsTradingPermittedForRegime(void) const;
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMarketRegimeEngine::CMarketRegimeEngine(void)
  : m_currentRegime(REGIME_RANGE),
    m_currentATR(0.0),
    m_averageATR(0.0),
    m_fastMA(0.0),
    m_slowMA(0.0)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMarketRegimeEngine::~CMarketRegimeEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Classifies current market regime using price metrics             |
//| Current ATR is compared against a 100-period baseline Average ATR|
//+------------------------------------------------------------------+
ENUM_MARKET_REGIME CMarketRegimeEngine::ClassifyRegime(string symbol,
                                                       ENUM_TIMEFRAMES timeframe,
                                                       double fastMAVal,
                                                       double slowMAVal,
                                                       double atrVal,
                                                       double avgATRVal,
                                                       int currentSpreadPoints,
                                                       int maxSpreadPoints)
  {
   m_fastMA     = fastMAVal;
   m_slowMA     = slowMAVal;
   m_currentATR  = atrVal;
   m_averageATR = (avgATRVal > 0.0) ? avgATRVal : atrVal;

   // 1. Check for Abnormal Volatility or Excessive Spread
   if(maxSpreadPoints > 0 && currentSpreadPoints > maxSpreadPoints)
     {
      m_currentRegime = REGIME_ABNORMAL;
      return m_currentRegime;
     }

   if(m_averageATR > 0.0 && (m_currentATR / m_averageATR) >= 2.5)
     {
      m_currentRegime = REGIME_HIGH_VOLATILITY;
      return m_currentRegime;
     }

   // 2. Check for Low Volatility
   if(m_averageATR > 0.0 && (m_currentATR / m_averageATR) <= 0.4)
     {
      m_currentRegime = REGIME_LOW_VOLATILITY;
      return m_currentRegime;
     }

   // 3. Trend vs Range Classification
   double maDiff = MathAbs(m_fastMA - m_slowMA);
   double maDiffATRRatio = (m_currentATR > 0.0) ? (maDiff / m_currentATR) : 0.0;

   if(maDiffATRRatio >= 0.5)
     {
      if(m_fastMA > m_slowMA)
         m_currentRegime = REGIME_STRONG_BULL_TREND;
      else
         m_currentRegime = REGIME_STRONG_BEAR_TREND;
     }
   else if(maDiffATRRatio >= 0.2)
     {
      m_currentRegime = REGIME_WEAK_TREND;
     }
   else
     {
      m_currentRegime = REGIME_RANGE;
     }

   return m_currentRegime;
  }

//+------------------------------------------------------------------+
//| Validates whether trading should proceed under current regime    |
//+------------------------------------------------------------------+
bool CMarketRegimeEngine::IsTradingPermittedForRegime(void) const
  {
   if(m_currentRegime == REGIME_ABNORMAL)
      return false;
   return true;
  }
