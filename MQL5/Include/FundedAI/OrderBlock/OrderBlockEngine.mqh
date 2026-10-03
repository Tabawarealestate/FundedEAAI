//+------------------------------------------------------------------+
//|                                             OrderBlockEngine.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Struct: Order Block Information                                  |
//+------------------------------------------------------------------+
struct SOrderBlock
  {
   double   highPrice;
   double   lowPrice;
   datetime time;
   int      barIndex;
   bool     isBullish;
   bool     isMitigated;
   bool     isFresh;
  };

//+------------------------------------------------------------------+
//| Class COrderBlockEngine                                          |
//| Detects Bullish / Bearish Order Blocks, tracks freshness, and   |
//| identifies mitigated OB zones.                                   |
//+------------------------------------------------------------------+
class COrderBlockEngine
  {
private:
   SOrderBlock m_orderBlocks[20];
   int         m_obCount;

public:
                     COrderBlockEngine(void);
                    ~COrderBlockEngine(void);

   void              Reset(void);
   bool              DetectOrderBlocks(const double &open[], const double &high[], const double &low[], const double &close[], const datetime &time[], int totalBars);

   bool              GetLatestFreshBullishOB(SOrderBlock &ob) const;
   bool              GetLatestFreshBearishOB(SOrderBlock &ob) const;
   int               GetOBCount(void) const { return m_obCount; }
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
COrderBlockEngine::COrderBlockEngine(void)
  : m_obCount(0)
  {
   Reset();
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
COrderBlockEngine::~COrderBlockEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Resets internal OB array                                         |
//+------------------------------------------------------------------+
void COrderBlockEngine::Reset(void)
  {
   m_obCount = 0;
   ArrayInitialize(m_orderBlocks, 0);
  }

//+------------------------------------------------------------------+
//| Detects fresh and mitigated Order Blocks from bar series        |
//+------------------------------------------------------------------+
bool COrderBlockEngine::DetectOrderBlocks(const double &open[], const double &high[], const double &low[], const double &close[], const datetime &time[], int totalBars)
  {
   Reset();
   if(totalBars < 5)
      return false;

   for(int i = 2; i < totalBars - 2 && m_obCount < 20; i++)
     {
      // Bullish OB: Last down candle before strong upward expansion (i+1 was down candle, i was strong up)
      if(close[i + 1] < open[i + 1] && close[i] > open[i] && (close[i] - open[i]) > (open[i + 1] - close[i + 1]) * 1.5)
        {
         m_orderBlocks[m_obCount].highPrice   = high[i + 1];
         m_orderBlocks[m_obCount].lowPrice    = low[i + 1];
         m_orderBlocks[m_obCount].time        = time[i + 1];
         m_orderBlocks[m_obCount].barIndex    = i + 1;
         m_orderBlocks[m_obCount].isBullish   = true;

         // Mitigation occurs only if price breaks below the OB invalidation low boundary
         bool mitigated = false;
         for(int k = i - 1; k >= 0; k--)
           {
            if(low[k] < m_orderBlocks[m_obCount].lowPrice)
              {
               mitigated = true;
               break;
              }
           }
         m_orderBlocks[m_obCount].isMitigated = mitigated;
         m_orderBlocks[m_obCount].isFresh     = !mitigated;
         m_obCount++;
        }

      // Bearish OB: Last up candle before strong downward expansion (i+1 was up candle, i was strong down)
      if(m_obCount < 20 && close[i + 1] > open[i + 1] && close[i] < open[i] && (open[i] - close[i]) > (close[i + 1] - open[i + 1]) * 1.5)
        {
         m_orderBlocks[m_obCount].highPrice   = high[i + 1];
         m_orderBlocks[m_obCount].lowPrice    = low[i + 1];
         m_orderBlocks[m_obCount].time        = time[i + 1];
         m_orderBlocks[m_obCount].barIndex    = i + 1;
         m_orderBlocks[m_obCount].isBullish   = false;

         // Mitigation occurs only if price breaks above the OB invalidation high boundary
         bool mitigated = false;
         for(int k = i - 1; k >= 0; k--)
           {
            if(high[k] > m_orderBlocks[m_obCount].highPrice)
              {
               mitigated = true;
               break;
              }
           }
         m_orderBlocks[m_obCount].isMitigated = mitigated;
         m_orderBlocks[m_obCount].isFresh     = !mitigated;
         m_obCount++;
        }
     }

   return (m_obCount > 0);
  }

//+------------------------------------------------------------------+
//| Retrieves the most recent fresh Bullish OB                       |
//+------------------------------------------------------------------+
bool COrderBlockEngine::GetLatestFreshBullishOB(SOrderBlock &ob) const
  {
   for(int i = 0; i < m_obCount; i++)
     {
      if(m_orderBlocks[i].isBullish && m_orderBlocks[i].isFresh)
        {
         ob = m_orderBlocks[i];
         return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Retrieves the most recent fresh Bearish OB                       |
//+------------------------------------------------------------------+
bool COrderBlockEngine::GetLatestFreshBearishOB(SOrderBlock &ob) const
  {
   for(int i = 0; i < m_obCount; i++)
     {
      if(!m_orderBlocks[i].isBullish && m_orderBlocks[i].isFresh)
        {
         ob = m_orderBlocks[i];
         return true;
        }
     }
   return false;
  }
