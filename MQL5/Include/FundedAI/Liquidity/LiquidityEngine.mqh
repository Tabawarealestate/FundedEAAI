//+------------------------------------------------------------------+
//|                                              LiquidityEngine.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Enumeration: Liquidity Sweep Type                                |
//+------------------------------------------------------------------+
enum ENUM_LIQUIDITY_SWEEP
  {
   SWEEP_NONE              = 0,
   SWEEP_BUY_SIDE_LIQUIDITY = 1, // Price swept above high and closed below (BSL Sweep)
   SWEEP_SELL_SIDE_LIQUIDITY= 2  // Price swept below low and closed above (SSL Sweep)
  };

//+------------------------------------------------------------------+
//| Class CLiquidityEngine                                           |
//| Detects Buy-Side Liquidity (BSL), Sell-Side Liquidity (SSL),     |
//| liquidity sweeps, and equal highs / equal lows clusters.         |
//+------------------------------------------------------------------+
class CLiquidityEngine
  {
private:
   double m_prevSessionHigh;
   double m_prevSessionLow;

public:
                     CLiquidityEngine(void);
                    ~CLiquidityEngine(void);

   //--- Analysis Methods
   void              SetSessionLiquidity(double prevHigh, double prevLow);
   ENUM_LIQUIDITY_SWEEP DetectSweep(const double &open[], const double &high[], const double &low[], const double &close[], double levelHigh, double levelLow);

   bool              DetectEqualHighs(const double &high[], int totalBars, double thresholdPoints = 5.0, double pointSize = 0.00001);
   bool              DetectEqualLows(const double &low[], int totalBars, double thresholdPoints = 5.0, double pointSize = 0.00001);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLiquidityEngine::CLiquidityEngine(void)
  : m_prevSessionHigh(0.0),
    m_prevSessionLow(0.0)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLiquidityEngine::~CLiquidityEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Sets session reference liquidity levels                          |
//+------------------------------------------------------------------+
void CLiquidityEngine::SetSessionLiquidity(double prevHigh, double prevLow)
  {
   m_prevSessionHigh = prevHigh;
   m_prevSessionLow  = prevLow;
  }

//+------------------------------------------------------------------+
//| Detects BSL / SSL liquidity sweeps on completed bar index 1      |
//+------------------------------------------------------------------+
ENUM_LIQUIDITY_SWEEP CLiquidityEngine::DetectSweep(const double &open[], const double &high[], const double &low[], const double &close[], double levelHigh, double levelLow)
  {
   // BSL Sweep: Completed bar 1 high breaks above key resistance/liquidity, but Close drops back below
   if(levelHigh > 0.0 && high[1] > levelHigh && close[1] < levelHigh)
      return SWEEP_BUY_SIDE_LIQUIDITY;

   // SSL Sweep: Completed bar 1 low pierces below key support/liquidity, but Close recovers back above
   if(levelLow > 0.0 && low[1] < levelLow && close[1] > levelLow)
      return SWEEP_SELL_SIDE_LIQUIDITY;

   return SWEEP_NONE;
  }

//+------------------------------------------------------------------+
//| Detects Equal Highs (EQH - Buy-Side Liquidity Pool)              |
//+------------------------------------------------------------------+
bool CLiquidityEngine::DetectEqualHighs(const double &high[], int totalBars, double thresholdPoints, double pointSize)
  {
   if(totalBars < 10)
      return false;

   double maxThreshold = thresholdPoints * pointSize;

   for(int i = 1; i < totalBars - 5; i++)
     {
      for(int j = i + 3; j < totalBars - 1; j++)
        {
         if(MathAbs(high[i] - high[j]) <= maxThreshold)
            return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Detects Equal Lows (EQL - Sell-Side Liquidity Pool)              |
//+------------------------------------------------------------------+
bool CLiquidityEngine::DetectEqualLows(const double &low[], int totalBars, double thresholdPoints, double pointSize)
  {
   if(totalBars < 10)
      return false;

   double maxThreshold = thresholdPoints * pointSize;

   for(int i = 1; i < totalBars - 5; i++)
     {
      for(int j = i + 3; j < totalBars - 1; j++)
        {
         if(MathAbs(low[i] - low[j]) <= maxThreshold)
            return true;
        }
     }
   return false;
  }
