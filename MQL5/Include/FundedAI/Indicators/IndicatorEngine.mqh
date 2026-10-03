//+------------------------------------------------------------------+
//|                                              IndicatorEngine.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Struct: Technical Confirmation Indicators                        |
//+------------------------------------------------------------------+
struct SIndicatorMetrics
  {
   double   rsiValue;       // Relative Strength Index (e.g. 14 period)
   double   atrValue;       // Average True Range (Current)
   double   avgATRValue;    // Average ATR (20 period average of ATR)
   double   adxValue;       // Average Directional Index (Trend strength)
   double   fastEMA;        // Fast Exponential Moving Average
   double   slowEMA;        // Slow Exponential Moving Average
   bool     isBullishEMA;   // True if Fast EMA > Slow EMA
   bool     isStrongTrend;  // True if ADX >= 25.0
  };

//+------------------------------------------------------------------+
//| Class CIndicatorEngine                                           |
//| Handles indicator calculation and momentum confirmation.         |
//+------------------------------------------------------------------+
class CIndicatorEngine
  {
public:
                     CIndicatorEngine(void);
                    ~CIndicatorEngine(void);

   static double     CalculateRSI(const double &close[], int period = 14);
   static double     CalculateATR(const double &high[], const double &low[], const double &close[], int period = 14);
   static double     CalculateEMA(const double &price[], int period, int totalBars);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CIndicatorEngine::CIndicatorEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CIndicatorEngine::~CIndicatorEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Calculates RSI value from close price array                      |
//+------------------------------------------------------------------+
double CIndicatorEngine::CalculateRSI(const double &close[], int period = 14)
  {
   int total = ArraySize(close);
   if(total < period + 1)
      return 50.0;

   double gainSum = 0.0;
   double lossSum = 0.0;

   for(int i = 0; i < period; i++)
     {
      double diff = close[i] - close[i + 1];
      if(diff > 0.0)
         gainSum += diff;
      else
         lossSum += -diff;
     }

   double avgGain = gainSum / period;
   double avgLoss = lossSum / period;

   if(avgLoss == 0.0)
      return 100.0;

   double rs = avgGain / avgLoss;
   return 100.0 - (100.0 / (1.0 + rs));
  }

//+------------------------------------------------------------------+
//| Calculates ATR value from high, low, close arrays                |
//+------------------------------------------------------------------+
double CIndicatorEngine::CalculateATR(const double &high[], const double &low[], const double &close[], int period = 14)
  {
   int total = ArraySize(high);
   if(total < period + 1)
      return 0.0;

   double trSum = 0.0;
   for(int i = 0; i < period; i++)
     {
      double tr1 = high[i] - low[i];
      double tr2 = MathAbs(high[i] - close[i + 1]);
      double tr3 = MathAbs(low[i] - close[i + 1]);
      double tr  = MathMax(tr1, MathMax(tr2, tr3));
      trSum += tr;
     }

   return trSum / period;
  }

//+------------------------------------------------------------------+
//| Calculates EMA value from price array                            |
//+------------------------------------------------------------------+
double CIndicatorEngine::CalculateEMA(const double &price[], int period, int totalBars)
  {
   if(totalBars < period)
      return 0.0;

   double k = 2.0 / (period + 1.0);
   double ema = price[totalBars - 1];

   for(int i = totalBars - 2; i >= 0; i--)
     {
      ema = (price[i] * k) + (ema * (1.0 - k));
     }

   return ema;
  }
