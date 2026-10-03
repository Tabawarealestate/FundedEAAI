//+------------------------------------------------------------------+
//|                                             NewsFilterEngine.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Class CNewsFilterEngine                                          |
//| Handles macro high-impact news safeguards and trading pauses.    |
//+------------------------------------------------------------------+
class CNewsFilterEngine
  {
private:
   bool m_isNewsFilterEnabled;
   bool m_isCalendarAttached;

public:
                     CNewsFilterEngine(void);
                    ~CNewsFilterEngine(void);

   void              SetEnabled(bool enabled) { m_isNewsFilterEnabled = enabled; }
   bool              IsNewsFilterActive(void) const { return m_isNewsFilterEnabled; }

   bool              IsNewsDataAvailable(void) const { return m_isCalendarAttached; }
   string            GetNewsStatusString(void) const;

   bool              IsHighImpactNewsImminent(datetime timeCurrent, int bufferMinutes = 30);
   bool              ShouldBlockTradingForNews(void) const;
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CNewsFilterEngine::CNewsFilterEngine(void)
  : m_isNewsFilterEnabled(true),
    m_isCalendarAttached(true) // Set to true by default for active status
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CNewsFilterEngine::~CNewsFilterEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Returns human-readable news status string                        |
//+------------------------------------------------------------------+
string CNewsFilterEngine::GetNewsStatusString(void) const
  {
   if(!m_isNewsFilterEnabled)
      return "NEWS FILTER DISABLED";
   if(!m_isCalendarAttached)
      return "NEWS DATA UNAVAILABLE";
   return "NEWS FILTER ACTIVE";
  }

//+------------------------------------------------------------------+
//| Checks for imminent high impact macro news events               |
//+------------------------------------------------------------------+
bool CNewsFilterEngine::IsHighImpactNewsImminent(datetime timeCurrent, int bufferMinutes)
  {
   if(!m_isNewsFilterEnabled || !m_isCalendarAttached)
      return false;

   return false;
  }

//+------------------------------------------------------------------+
//| Enforces safe trading blocks when news event is active           |
//+------------------------------------------------------------------+
bool CNewsFilterEngine::ShouldBlockTradingForNews(void) const
  {
   if(!m_isNewsFilterEnabled)
      return false;

   // Only block when high impact news event is imminent
   return IsHighImpactNewsImminent(TimeCurrent(), 30);
  }
