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
//| Native MT5 Economic Calendar API Engine handling high-impact     |
//| macro news filtering, currency mapping, and explicit status logs. |
//+------------------------------------------------------------------+
class CNewsFilterEngine
  {
private:
   bool m_isNewsFilterEnabled;
   bool m_isCalendarAttached;
   bool m_allowTesterBypass;

public:
                     CNewsFilterEngine(void);
                    ~CNewsFilterEngine(void);

   void              SetEnabled(bool enabled) { m_isNewsFilterEnabled = enabled; }
   void              SetTesterBypass(bool allowBypass) { m_allowTesterBypass = allowBypass; }
   bool              IsNewsFilterActive(void) const { return m_isNewsFilterEnabled; }
   bool              IsNewsDataAvailable(void) const { return m_isCalendarAttached; }
   string            GetNewsStatusString(void) const;

   bool              IsHighImpactNewsImminent(string symbol, datetime timeCurrent, int bufferMinutes = 30);
   bool              ShouldBlockTradingForNews(string symbol = "EURUSD");

private:
   void              GetSymbolCurrencies(string symbol, string &baseCurr, string &marginCurr);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CNewsFilterEngine::CNewsFilterEngine(void)
  : m_isNewsFilterEnabled(true),
    m_isCalendarAttached(false),
    m_allowTesterBypass(true)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CNewsFilterEngine::~CNewsFilterEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Extracts currency exposure for a given symbol                    |
//+------------------------------------------------------------------+
void CNewsFilterEngine::GetSymbolCurrencies(string symbol, string &baseCurr, string &marginCurr)
  {
   baseCurr   = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
   marginCurr = SymbolInfoString(symbol, SYMBOL_CURRENCY_MARGIN);

   if(baseCurr == "")
      baseCurr = StringSubstr(symbol, 0, 3);
   if(marginCurr == "")
      marginCurr = StringSubstr(symbol, 3, 3);
  }

//+------------------------------------------------------------------+
//| Returns honest human-readable news status string                 |
//+------------------------------------------------------------------+
string CNewsFilterEngine::GetNewsStatusString(void) const
  {
   if(!m_isNewsFilterEnabled)
      return "NEWS FILTER DISABLED";
   if(MqlInfoInteger(MQL_TESTER))
     {
      if(m_allowTesterBypass)
         return "TESTER BYPASS: EXPLICITLY ENABLED";
      else
         return "TESTER: NEWS DATA UNAVAILABLE - TRADES BLOCKED";
     }
   if(!m_isCalendarAttached)
      return "LIVE: NEWS DATA UNAVAILABLE - TRADES BLOCKED";
   return "LIVE: NEWS FILTER ACTIVE";
  }

//+------------------------------------------------------------------+
//| Checks for imminent high-impact macro news using MT5 Calendar    |
//+------------------------------------------------------------------+
bool CNewsFilterEngine::IsHighImpactNewsImminent(string symbol, datetime timeCurrent, int bufferMinutes)
  {
   if(!m_isNewsFilterEnabled)
     {
      m_isCalendarAttached = true;
      return false;
     }

   // Honest Strategy Tester handling
   if(MqlInfoInteger(MQL_TESTER))
     {
      if(m_allowTesterBypass)
        {
         m_isCalendarAttached = false;
         return false; // Explicit tester bypass permitted
        }
      else
        {
         m_isCalendarAttached = false;
         return true; // Safe block in tester when bypass disabled
        }
     }

   string baseCurr, marginCurr;
   GetSymbolCurrencies(symbol, baseCurr, marginCurr);

   datetime fromTime = timeCurrent - (bufferMinutes * 60);
   datetime toTime   = timeCurrent + (bufferMinutes * 60);

   MqlCalendarValue values[];
   // Fetch calendar events using native MT5 CalendarValueHistory API
   int totalValues = CalendarValueHistory(values, fromTime, toTime, NULL, NULL);

   if(totalValues < 0)
     {
      // Calendar API unattached or unsupported by broker server -> FAIL SAFE CLOSED
      m_isCalendarAttached = false;
      return true; // Block trading safely when news feed is unavailable
     }

   m_isCalendarAttached = true;
   if(totalValues == 0)
      return false;

   for(int i = 0; i < totalValues; i++)
     {
      MqlCalendarEvent event;
      if(CalendarEventById(values[i].event_id, event))
        {
         // Filter for High Impact Events (Importance == CALENDAR_IMPORTANCE_HIGH)
         if(event.importance == CALENDAR_IMPORTANCE_HIGH)
           {
            MqlCalendarCountry country;
            if(CalendarCountryById(event.country_id, country))
              {
               if(country.currency == baseCurr || country.currency == marginCurr || country.currency == "USD")
                 {
                  return true; // High impact news event detected within buffer window
                 }
              }
           }
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Enforces safe trading blocks during high-impact news events      |
//+------------------------------------------------------------------+
bool CNewsFilterEngine::ShouldBlockTradingForNews(string symbol)
  {
   if(!m_isNewsFilterEnabled)
      return false;

   return IsHighImpactNewsImminent(symbol, TimeCurrent(), 30);
  }
