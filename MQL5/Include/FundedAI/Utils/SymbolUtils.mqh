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
   bool     isHedgingAccount;   // True if account mode is hedging, false if netting
   uint     executionFillingMode; // Detected filling mode (FOK, IOC, RETURN)
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

   //--- Spec Detection & Discovery
   static bool       GetSymbolSpec(string symbol, SSymbolSpecification &spec, int maxStaleSeconds = 10);
   static bool       ValidateMarketData(string symbol, int maxAllowedSpreadPoints, int maxStaleSeconds = 10);
   static string     DiscoverBrokerSymbol(string baseSymbol);
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
//| Auto-discovers broker specific symbol variants (prefixes/suffixes)|
//+------------------------------------------------------------------+
string CSymbolUtils::DiscoverBrokerSymbol(string baseSymbol)
  {
   // 1. Direct check
   if(SymbolInfoInteger(baseSymbol, SYMBOL_SELECT))
      return baseSymbol;

   // 2. Scan active symbols in market watch
   int totalSymbols = SymbolsTotal(false);
   for(int i = 0; i < totalSymbols; i++)
     {
      string currSymbol = SymbolName(i, false);
      if(StringFind(currSymbol, baseSymbol) >= 0)
        {
         SymbolSelect(currSymbol, true);
         return currSymbol;
        }
     }
   return baseSymbol;
  }

//+------------------------------------------------------------------+
//| Detects broker specifications for any given symbol               |
//+------------------------------------------------------------------+
bool CSymbolUtils::GetSymbolSpec(string symbol, SSymbolSpecification &spec, int maxStaleSeconds)
  {
   string actualSymbol = DiscoverBrokerSymbol(symbol);

   if(!SymbolInfoInteger(actualSymbol, SYMBOL_SELECT))
      SymbolSelect(actualSymbol, true);

   spec.symbolName          = actualSymbol;
   spec.digits              = (int)SymbolInfoInteger(actualSymbol, SYMBOL_DIGITS);
   spec.pointSize           = SymbolInfoDouble(actualSymbol, SYMBOL_POINT);
   spec.tickSize            = SymbolInfoDouble(actualSymbol, SYMBOL_TRADE_TICK_SIZE);
   spec.tickValue           = SymbolInfoDouble(actualSymbol, SYMBOL_TRADE_TICK_VALUE);
   spec.contractSize        = SymbolInfoDouble(actualSymbol, SYMBOL_TRADE_CONTRACT_SIZE);
   spec.minLot              = SymbolInfoDouble(actualSymbol, SYMBOL_VOLUME_MIN);
   spec.maxLot              = SymbolInfoDouble(actualSymbol, SYMBOL_VOLUME_MAX);
   spec.lotStep             = SymbolInfoDouble(actualSymbol, SYMBOL_VOLUME_STEP);
   spec.stopLevel           = (int)SymbolInfoInteger(actualSymbol, SYMBOL_TRADE_STOPS_LEVEL);
   spec.freezeLevel         = (int)SymbolInfoInteger(actualSymbol, SYMBOL_TRADE_FREEZE_LEVEL);

   // Account Mode Detection (Hedging vs Netting)
   ENUM_ACCOUNT_MARGIN_MODE marginMode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   spec.isHedgingAccount    = (marginMode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);

   // Filling Mode Detection
   uint fillFlags = (uint)SymbolInfoInteger(actualSymbol, SYMBOL_FILLING_MODE);
   if((fillFlags & SYMBOL_FILLING_FOK) != 0)
      spec.executionFillingMode = ORDER_FILLING_FOK;
   else if((fillFlags & SYMBOL_FILLING_IOC) != 0)
      spec.executionFillingMode = ORDER_FILLING_IOC;
   else
      spec.executionFillingMode = ORDER_FILLING_RETURN;

   long spread = 0;
   SymbolInfoInteger(actualSymbol, SYMBOL_SPREAD, spread);
   spec.currentSpreadPoints = (int)spread;

   ENUM_SYMBOL_TRADE_MODE tradeMode = (ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(actualSymbol, SYMBOL_TRADE_MODE);
   spec.isTradeAllowed      = (tradeMode == SYMBOL_TRADE_MODE_FULL);

   // Verify tick freshness
   datetime lastTickTime = (datetime)SymbolInfoInteger(actualSymbol, SYMBOL_TIME);
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
