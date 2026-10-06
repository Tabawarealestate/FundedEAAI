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
//| Analyzes market sessions, trading hours, and GMT/DST filters.    |
//+------------------------------------------------------------------+
class CSessionEngine
  {
public:
                     CSessionEngine(void);
                    ~CSessionEngine(void);

   static datetime             GetBrokerGMTTime(datetime timeCurrent, int gmtOffsetHours, bool autoDst = true);
   static ENUM_TRADING_SESSION GetCurrentSession(datetime timeCurrent, int gmtOffsetHours = 2, bool autoDst = true);
   static bool                 IsOptimalTradingSession(datetime timeCurrent, int gmtOffsetHours = 2, bool autoDst = true);
   static bool                 IsWeekend(datetime timeCurrent);
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
//| Calculates GMT time with Daylight Saving Time (DST) adjustment   |
//+------------------------------------------------------------------+
datetime CSessionEngine::GetBrokerGMTTime(datetime timeCurrent, int gmtOffsetHours, bool autoDst)
  {
   int totalOffsetHours = gmtOffsetHours;
   if(autoDst)
     {
      MqlDateTime dt;
      TimeToStruct(timeCurrent, dt);
      // US/Europe DST approximate range: March (month 3) to November (month 11)
      if(dt.mon >= 3 && dt.mon <= 10)
         totalOffsetHours += 1;
     }
   return timeCurrent - (totalOffsetHours * 3600);
  }

//+------------------------------------------------------------------+
//| Returns current active trading session adjusted for GMT/DST      |
//+------------------------------------------------------------------+
ENUM_TRADING_SESSION CSessionEngine::GetCurrentSession(datetime timeCurrent, int gmtOffsetHours, bool autoDst)
  {
   datetime gmtTime = GetBrokerGMTTime(timeCurrent, gmtOffsetHours, autoDst);
   MqlDateTime dt;
   TimeToStruct(gmtTime, dt);

   if(dt.hour >= 13 && dt.hour < 16)
      return SESSION_OVERLAP;
   if(dt.hour >= 8 && dt.hour < 16)
      return SESSION_LONDON;
   if(dt.hour >= 13 && dt.hour < 21)
      return SESSION_NEW_YORK;

   return SESSION_ASIAN;
  }

//+------------------------------------------------------------------+
//| Evaluates if current hour falls within London or NY sessions     |
//+------------------------------------------------------------------+
bool CSessionEngine::IsOptimalTradingSession(datetime timeCurrent, int gmtOffsetHours, bool autoDst)
  {
   datetime gmtTime = GetBrokerGMTTime(timeCurrent, gmtOffsetHours, autoDst);
   MqlDateTime dt;
   TimeToStruct(gmtTime, dt);

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
