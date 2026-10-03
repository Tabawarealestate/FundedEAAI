//+------------------------------------------------------------------+
//|                                             PortfolioManager.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Class CPortfolioManager                                          |
//| Tracks portfolio exposure, currency exposure, and maximum risk.|
//+------------------------------------------------------------------+
class CPortfolioManager
  {
private:
   ulong m_magicNumber;

public:
                     CPortfolioManager(void);
                    ~CPortfolioManager(void);

   void              Init(ulong magicNumber);
   double            GetTotalPortfolioRiskPercent(double accountEquity);
   bool              IsCurrencyExposureAtLimit(string symbol, int maxCorrelatedPositions = 2);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPortfolioManager::CPortfolioManager(void)
  : m_magicNumber(FUNDED_AI_DEFAULT_MAGIC)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPortfolioManager::~CPortfolioManager(void)
  {
  }

//+------------------------------------------------------------------+
//| Initializes Portfolio Manager                                    |
//+------------------------------------------------------------------+
void CPortfolioManager::Init(ulong magicNumber)
  {
   m_magicNumber = magicNumber;
  }

//+------------------------------------------------------------------+
//| Calculates total active open risk percentage across portfolio    |
//+------------------------------------------------------------------+
double CPortfolioManager::GetTotalPortfolioRiskPercent(double accountEquity)
  {
   if(accountEquity <= 0.0)
      return 0.0;

   double totalRiskDollars = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == (long)m_magicNumber)
        {
         double openPrice  = PositionGetDouble(POSITION_PRICE_OPEN);
         double slPrice    = PositionGetDouble(POSITION_SL);
         double volume     = PositionGetDouble(POSITION_VOLUME);
         string symbol     = PositionGetString(POSITION_SYMBOL);
         double tickValue  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
         double tickSize   = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
         double pointSize  = SymbolInfoDouble(symbol, SYMBOL_POINT);

         if(slPrice > 0.0 && tickSize > 0.0 && pointSize > 0.0)
           {
            double tickToPointRatio = pointSize / tickSize;
            double pointValuePerLot = tickValue * tickToPointRatio;
            double slPoints         = MathAbs(openPrice - slPrice) / pointSize;
            double posRisk          = slPoints * pointValuePerLot * volume;
            totalRiskDollars += posRisk;
           }
        }
     }

   return (totalRiskDollars / accountEquity) * 100.0;
  }

//+------------------------------------------------------------------+
//| Checks currency correlation exposure for Forex pairs only        |
//+------------------------------------------------------------------+
bool CPortfolioManager::IsCurrencyExposureAtLimit(string symbol, int maxCorrelatedPositions)
  {
   string profitCurr = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
   string marginCurr = SymbolInfoString(symbol, SYMBOL_CURRENCY_MARGIN);

   // Return false (not applicable) for non-Forex instruments
   if(profitCurr == "" || marginCurr == "")
      return false;

   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == (long)m_magicNumber)
        {
         string posSymbol = PositionGetString(POSITION_SYMBOL);
         string posProfit = SymbolInfoString(posSymbol, SYMBOL_CURRENCY_PROFIT);
         string posMargin = SymbolInfoString(posSymbol, SYMBOL_CURRENCY_MARGIN);

         if(posProfit == profitCurr || posMargin == marginCurr || posProfit == marginCurr || posMargin == profitCurr)
            count++;
        }
     }

   return (count >= maxCorrelatedPositions);
  }
