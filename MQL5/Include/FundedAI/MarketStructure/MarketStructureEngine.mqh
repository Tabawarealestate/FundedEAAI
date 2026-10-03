//+------------------------------------------------------------------+
//|                                        MarketStructureEngine.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Enumeration: Market Structure Signal Type                        |
//+------------------------------------------------------------------+
enum ENUM_STRUCTURE_SIGNAL
  {
   STRUCTURE_NONE             = 0,
   STRUCTURE_BOS_BULLISH      = 1, // Break of Structure (Bullish continuation)
   STRUCTURE_BOS_BEARISH      = 2, // Break of Structure (Bearish continuation)
   STRUCTURE_CHOCH_BULLISH    = 3, // Change of Character (Bullish reversal)
   STRUCTURE_CHOCH_BEARISH    = 4, // Change of Character (Bearish reversal)
   STRUCTURE_MSS_BULLISH      = 5, // Market Structure Shift (Bullish)
   STRUCTURE_MSS_BEARISH      = 6  // Market Structure Shift (Bearish)
  };

//+------------------------------------------------------------------+
//| Struct: Swing Point Data                                         |
//+------------------------------------------------------------------+
struct SSwingPoint
  {
   double   price;
   datetime time;
   int      barIndex;
   bool     isHigh; // True = Swing High, False = Swing Low
  };

//+------------------------------------------------------------------+
//| Class CMarketStructureEngine                                     |
//| Detects Swing Highs/Lows, BOS, CHoCH, and MSS across timeframes. |
//+------------------------------------------------------------------+
class CMarketStructureEngine
  {
private:
   SSwingPoint m_recentHighs[10];
   SSwingPoint m_recentLows[10];
   int         m_highCount;
   int         m_lowCount;

public:
                     CMarketStructureEngine(void);
                    ~CMarketStructureEngine(void);

   //--- Core Analysis
   void              Reset(void);
   bool              FindSwingPoints(const double &high[], const double &low[], const datetime &time[], int totalBars, int swingDepth = 3);
   ENUM_STRUCTURE_SIGNAL AnalyzeStructure(const double &close[], const double &high[], const double &low[], int totalBars);

   bool              GetLatestSwingHigh(SSwingPoint &high) const;
   bool              GetLatestSwingLow(SSwingPoint &low) const;
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMarketStructureEngine::CMarketStructureEngine(void)
  : m_highCount(0),
    m_lowCount(0)
  {
   Reset();
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMarketStructureEngine::~CMarketStructureEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Resets internal swing arrays                                     |
//+------------------------------------------------------------------+
void CMarketStructureEngine::Reset(void)
  {
   m_highCount = 0;
   m_lowCount  = 0;
   ArrayInitialize(m_recentHighs, 0);
   ArrayInitialize(m_recentLows, 0);
  }

//+------------------------------------------------------------------+
//| Scans price series for fractal swing highs and swing lows        |
//+------------------------------------------------------------------+
bool CMarketStructureEngine::FindSwingPoints(const double &high[], const double &low[], const datetime &time[], int totalBars, int swingDepth = 3)
  {
   Reset();
   if(totalBars < (swingDepth * 2 + 1))
      return false;

   // Loop through historical bars (excluding current unclosed bar 0)
   for(int i = swingDepth; i < totalBars - swingDepth; i++)
     {
      bool isSwingHigh = true;
      bool isSwingLow  = true;

      for(int j = 1; j <= swingDepth; j++)
        {
         if(high[i] <= high[i - j] || high[i] <= high[i + j])
            isSwingHigh = false;
         if(low[i] >= low[i - j] || low[i] >= low[i + j])
            isSwingLow = false;
        }

      if(isSwingHigh && m_highCount < 10)
        {
         m_recentHighs[m_highCount].price    = high[i];
         m_recentHighs[m_highCount].time     = time[i];
         m_recentHighs[m_highCount].barIndex = i;
         m_recentHighs[m_highCount].isHigh   = true;
         m_highCount++;
        }

      if(isSwingLow && m_lowCount < 10)
        {
         m_recentLows[m_lowCount].price    = low[i];
         m_recentLows[m_lowCount].time     = time[i];
         m_recentLows[m_lowCount].barIndex = i;
         m_recentLows[m_lowCount].isHigh   = false;
         m_lowCount++;
        }
     }

   return (m_highCount > 0 && m_lowCount > 0);
  }

//+------------------------------------------------------------------+
//| Evaluates Break of Structure (BOS) / CHoCH / MSS                 |
//+------------------------------------------------------------------+
ENUM_STRUCTURE_SIGNAL CMarketStructureEngine::AnalyzeStructure(const double &close[], const double &high[], const double &low[], int totalBars)
  {
   if(m_highCount < 2 || m_lowCount < 2 || totalBars < 2)
      return STRUCTURE_NONE;

   double currentClose = close[0];
   double prevClose    = close[1];

   // Check Bullish BOS / CHoCH / MSS (Price closes above recent swing high)
   if(currentClose > m_recentHighs[0].price && prevClose <= m_recentHighs[0].price)
     {
      // If previous trend was lower high -> lower low, close above high is CHoCH / MSS
      if(m_recentHighs[0].price < m_recentHighs[1].price)
         return STRUCTURE_CHOCH_BULLISH;
      else
         return STRUCTURE_BOS_BULLISH;
     }

   // Check Bearish BOS / CHoCH / MSS (Price closes below recent swing low)
   if(currentClose < m_recentLows[0].price && prevClose >= m_recentLows[0].price)
     {
      // If previous trend was higher low -> higher high, close below low is CHoCH / MSS
      if(m_recentLows[0].price > m_recentLows[1].price)
         return STRUCTURE_CHOCH_BEARISH;
      else
         return STRUCTURE_BOS_BEARISH;
     }

   return STRUCTURE_NONE;
  }

//+------------------------------------------------------------------+
//| Returns latest swing high                                        |
//+------------------------------------------------------------------+
bool CMarketStructureEngine::GetLatestSwingHigh(SSwingPoint &high) const
  {
   if(m_highCount > 0)
     {
      high = m_recentHighs[0];
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Returns latest swing low                                         |
//+------------------------------------------------------------------+
bool CMarketStructureEngine::GetLatestSwingLow(SSwingPoint &low) const
  {
   if(m_lowCount > 0)
     {
      low = m_recentLows[0];
      return true;
     }
   return false;
  }
