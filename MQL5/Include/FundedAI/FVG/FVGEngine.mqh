//+------------------------------------------------------------------+
//|                                                    FVGEngine.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Struct: Fair Value Gap Information                               |
//+------------------------------------------------------------------+
struct SFairValueGap
  {
   double   upperPrice;
   double   lowerPrice;
   datetime time;
   int      barIndex;
   bool     isBullish;
   bool     isFilled;
   bool     isPartiallyFilled;
  };

//+------------------------------------------------------------------+
//| Class CFVGEngine                                                 |
//| Detects 3-candle Fair Value Gaps (Imbalances), tracks gap fills, |
//| and identifies rejection/continuation entries.                    |
//+------------------------------------------------------------------+
class CFVGEngine
  {
private:
   SFairValueGap m_fvgs[20];
   int           m_fvgCount;

public:
                     CFVGEngine(void);
                    ~CFVGEngine(void);

   void              Reset(void);
   bool              DetectFVGs(const double &high[], const double &low[], const datetime &time[], int totalBars, double minGapPoints = 10.0, double pointSize = 0.00001);

   bool              GetLatestActiveBullishFVG(SFairValueGap &fvg) const;
   bool              GetLatestActiveBearishFVG(SFairValueGap &fvg) const;
   int               GetFVGCount(void) const { return m_fvgCount; }
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CFVGEngine::CFVGEngine(void)
  : m_fvgCount(0)
  {
   Reset();
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CFVGEngine::~CFVGEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Resets internal FVG array                                        |
//+------------------------------------------------------------------+
void CFVGEngine::Reset(void)
  {
   m_fvgCount = 0;
   ArrayInitialize(m_fvgs, 0);
  }

//+------------------------------------------------------------------+
//| Detects Bullish and Bearish Fair Value Gaps (3-candle imbalance) |
//+------------------------------------------------------------------+
bool CFVGEngine::DetectFVGs(const double &high[], const double &low[], const datetime &time[], int totalBars, double minGapPoints = 10.0, double pointSize = 0.00001)
  {
   Reset();
   if(totalBars < 4 || pointSize <= 0.0)
      return false;

   double minGapPrice = minGapPoints * pointSize;

   for(int i = 1; i < totalBars - 2 && m_fvgCount < 20; i++)
     {
      // Bullish FVG: Low of candle i-1 is strictly above High of candle i+1
      if(low[i - 1] - high[i + 1] >= minGapPrice)
        {
         m_fvgs[m_fvgCount].upperPrice  = low[i - 1];
         m_fvgs[m_fvgCount].lowerPrice  = high[i + 1];
         m_fvgs[m_fvgCount].time        = time[i];
         m_fvgs[m_fvgCount].barIndex    = i;
         m_fvgs[m_fvgCount].isBullish   = true;

         // Check fill status by current candle (0)
         if(low[0] <= m_fvgs[m_fvgCount].lowerPrice)
            m_fvgs[m_fvgCount].isFilled = true;
         else if(low[0] < m_fvgs[m_fvgCount].upperPrice)
            m_fvgs[m_fvgCount].isPartiallyFilled = true;

         m_fvgCount++;
        }

      // Bearish FVG: High of candle i-1 is strictly below Low of candle i+1
      if(m_fvgCount < 20 && high[i + 1] - low[i - 1] >= minGapPrice)
        {
         m_fvgs[m_fvgCount].upperPrice  = low[i + 1];
         m_fvgs[m_fvgCount].lowerPrice  = high[i - 1];
         m_fvgs[m_fvgCount].time        = time[i];
         m_fvgs[m_fvgCount].barIndex    = i;
         m_fvgs[m_fvgCount].isBullish   = false;

         // Check fill status by current candle (0)
         if(high[0] >= m_fvgs[m_fvgCount].upperPrice)
            m_fvgs[m_fvgCount].isFilled = true;
         else if(high[0] > m_fvgs[m_fvgCount].lowerPrice)
            m_fvgs[m_fvgCount].isPartiallyFilled = true;

         m_fvgCount++;
        }
     }

   return (m_fvgCount > 0);
  }

//+------------------------------------------------------------------+
//| Retrieves latest unfilled Bullish FVG                            |
//+------------------------------------------------------------------+
bool CFVGEngine::GetLatestActiveBullishFVG(SFairValueGap &fvg) const
  {
   for(int i = 0; i < m_fvgCount; i++)
     {
      if(m_fvgs[i].isBullish && !m_fvgs[i].isFilled)
        {
         fvg = m_fvgs[i];
         return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Retrieves latest unfilled Bearish FVG                            |
//+------------------------------------------------------------------+
bool CFVGEngine::GetLatestActiveBearishFVG(SFairValueGap &fvg) const
  {
   for(int i = 0; i < m_fvgCount; i++)
     {
      if(!m_fvgs[i].isBullish && !m_fvgs[i].isFilled)
        {
         fvg = m_fvgs[i];
         return true;
        }
     }
   return false;
  }
