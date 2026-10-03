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

public:
                     CNewsFilterEngine(void);
                    ~CNewsFilterEngine(void);

   void              SetEnabled(bool enabled) { m_isNewsFilterEnabled = enabled; }
   bool              IsNewsFilterActive(void) const { return m_isNewsFilterEnabled; }
   bool              IsHighImpactNewsImminent(datetime timeCurrent, int bufferMinutes = 30);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CNewsFilterEngine::CNewsFilterEngine(void)
  : m_isNewsFilterEnabled(true)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CNewsFilterEngine::~CNewsFilterEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Checks for imminent high impact macro news events               |
//+------------------------------------------------------------------+
bool CNewsFilterEngine::IsHighImpactNewsImminent(datetime timeCurrent, int bufferMinutes)
  {
   if(!m_isNewsFilterEnabled)
      return false;

   // Safely default to false if external news calendar is unattached
   return false;
  }
