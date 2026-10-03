//+------------------------------------------------------------------+
//|                                                  SymbolUtils.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Struct: Broker Symbol Specifications                             |
//+------------------------------------------------------------------+
struct SSymbolSpecification
  {
   string   symbolName;         // Exact broker symbol name
   int      digits;             // Price digits (e.g. 5 for EURUSD, 2 for XAUUSD)
   double   pointSize;          // Point value (e.g. 0.00001)
   double   tickSize;           // Tick size
   double   tickValue;          // Tick value in deposit currency
   double   contractSize;       // Contract size (e.g. 100000 for Forex, 100 for Gold)
   double   minLot;             // Minimum lot size
   double   maxLot;             // Maximum lot size
   double   lotStep;            // Lot step increment
   int      stopLevel;          // Minimum SL/TP distance in points
   int      freezeLevel;        // Freeze level in points
   int      currentSpreadPoints;// Current spread in points
   bool     isTradeAllowed;     // True if trading permitted on symbol
   bool     isDataFresh;        // True if tick data is fresh
  };

//+------------------------------------------------------------------+
//| Class CSymbolUtils                                               |
//| Auto-detects symbol specifications and verifies market data.     |
//+------------------------------------------------------------------+
class CSymbolUtils
  {
public:
                     CSymbolUtils(void);
                    ~CSymbolUtils(void);

   //--- Spec Detection
   static bool       GetSymbolSpec(string symbol, SSymbolSpecification &spec, int maxStaleSeconds = 10);
   static bool       ValidateMarketData(string symbol, int maxAllowedSpreadPoints, int maxStaleSeconds = 10);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSymbolUtils::CSymbolUtils(void)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSymbolUtils::~CSymbolUtils(void)
  {
  }

//+------------------------------------------------------------------+
//| Detects broker specifications for any given symbol               |
//+------------------------------------------------------------------+
bool CSymbolUtils::GetSymbolSpec(string symbol, SSymbolSpecification &spec, int maxStaleSeconds)
  {
   if(!SymbolInfoInteger(symbol, SYMBOL_SELECT))
      SymbolSelect(symbol, true);

   spec.symbolName          = symbol;
   spec.digits              = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   spec.pointSize           = SymbolInfoDouble(symbol, SYMBOL_POINT);
   spec.tickSize            = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   spec.tickValue           = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   spec.contractSize        = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   spec.minLot              = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   spec.maxLot              = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   spec.lotStep             = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   spec.stopLevel           = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   spec.freezeLevel         = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL);

   long spread = 0;
   SymbolInfoInteger(symbol, SYMBOL_SPREAD, spread);
   spec.currentSpreadPoints = (int)spread;

   ENUM_SYMBOL_TRADE_MODE tradeMode = (ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
   spec.isTradeAllowed      = (tradeMode == SYMBOL_TRADE_MODE_FULL);

   // Verify tick freshness
   datetime lastTickTime = (datetime)SymbolInfoInteger(symbol, SYMBOL_TIME);
   datetime currentTime  = TimeCurrent();
   spec.isDataFresh         = ((currentTime - lastTickTime) <= maxStaleSeconds);

   if(spec.pointSize <= 0.0 || spec.tickValue <= 0.0 || spec.lotStep <= 0.0)
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| Checks spread limits and data freshness                          |
//+------------------------------------------------------------------+
bool CSymbolUtils::ValidateMarketData(string symbol, int maxAllowedSpreadPoints, int maxStaleSeconds)
  {
   SSymbolSpecification spec;
   if(!GetSymbolSpec(symbol, spec, maxStaleSeconds))
      return false;

   if(!spec.isTradeAllowed)
      return false;

   if(!spec.isDataFresh)
      return false;

   if(maxAllowedSpreadPoints > 0 && spec.currentSpreadPoints > maxAllowedSpreadPoints)
      return false;

   return true;
  }
