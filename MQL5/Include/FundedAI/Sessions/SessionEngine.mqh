//+------------------------------------------------------------------+
//|                                                SessionEngine.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Enumeration: Trading Session Types                               |
//+------------------------------------------------------------------+
enum ENUM_TRADING_SESSION
  {
   SESSION_ASIAN    = 1, // Asian Session (00:00 - 08:00 GMT)
   SESSION_LONDON   = 2, // London Session (08:00 - 16:00 GMT)
   SESSION_NEW_YORK = 3, // New York Session (13:00 - 21:00 GMT)
   SESSION_OVERLAP  = 4  // London / NY Overlap (13:00 - 16:00 GMT)
  };

//+------------------------------------------------------------------+
//| Class CSessionEngine                                             |
//| Analyzes market sessions, trading hours, and time filters.       |
//+------------------------------------------------------------------+
class CSessionEngine
  {
public:
                     CSessionEngine(void);
                    ~CSessionEngine(void);

   static bool       IsOptimalTradingSession(datetime timeCurrent);
   static bool       IsWeekend(datetime timeCurrent);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSessionEngine::CSessionEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSessionEngine::~CSessionEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Evaluates if current hour falls within London or NY sessions     |
//+------------------------------------------------------------------+
bool CSessionEngine::IsOptimalTradingSession(datetime timeCurrent)
  {
   MqlDateTime dt;
   TimeToStruct(timeCurrent, dt);

   // London & New York Active Trading Window (07:00 to 20:00 UTC)
   if(dt.hour >= 7 && dt.hour <= 20)
      return true;

   return false;
  }

//+------------------------------------------------------------------+
//| Checks if current day is weekend                                 |
//+------------------------------------------------------------------+
bool CSessionEngine::IsWeekend(datetime timeCurrent)
  {
   MqlDateTime dt;
   TimeToStruct(timeCurrent, dt);
   return (dt.day_of_week == 0 || dt.day_of_week == 6);
  }
