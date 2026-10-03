//+------------------------------------------------------------------+
//|                                                 StatePersist.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "Constants.mqh"
#include "Types.mqh"

//+------------------------------------------------------------------+
//| Class CStatePersist                                              |
//| Persists and recovers challenge state using MT5 GlobalVariables  |
//| across EA / terminal restarts or chart removals.                 |
//+------------------------------------------------------------------+
class CStatePersist
  {
private:
   string m_prefix;

public:
                     CStatePersist(void);
                    ~CStatePersist(void);

   void              Init(ulong magicNumber);

   //--- Save & Load Methods
   void              SaveState(double startBalance, double dailyStartEquity, double dailyStartBalance, double highWaterMark, int activeDays);
   bool              LoadState(double &startBalance, double &dailyStartEquity, double &dailyStartBalance, double &highWaterMark, int &activeDays);
   void              ClearState(void);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CStatePersist::CStatePersist(void)
  : m_prefix("FAI_State_")
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CStatePersist::~CStatePersist(void)
  {
  }

//+------------------------------------------------------------------+
//| Initializes state persistence prefix                             |
//+------------------------------------------------------------------+
void CStatePersist::Init(ulong magicNumber)
  {
   m_prefix = StringFormat("FAI_State_%llu_", magicNumber);
  }

//+------------------------------------------------------------------+
//| Saves challenge parameters into MT5 GlobalVariables             |
//+------------------------------------------------------------------+
void CStatePersist::SaveState(double startBalance, double dailyStartEquity, double dailyStartBalance, double highWaterMark, int activeDays)
  {
   GlobalVariableSet(m_prefix + "StartBalance", startBalance);
   GlobalVariableSet(m_prefix + "DailyEquity", dailyStartEquity);
   GlobalVariableSet(m_prefix + "DailyBalance", dailyStartBalance);
   GlobalVariableSet(m_prefix + "HighWaterMark", highWaterMark);
   GlobalVariableSet(m_prefix + "ActiveDays", (double)activeDays);
   GlobalVariableSet(m_prefix + "LastSaveTime", (double)TimeCurrent());
  }

//+------------------------------------------------------------------+
//| Recovers challenge state from MT5 GlobalVariables               |
//+------------------------------------------------------------------+
bool CStatePersist::LoadState(double &startBalance, double &dailyStartEquity, double &dailyStartBalance, double &highWaterMark, int &activeDays)
  {
   string key = m_prefix + "StartBalance";
   if(!GlobalVariableCheck(key))
      return false;

   startBalance      = GlobalVariableGet(m_prefix + "StartBalance");
   dailyStartEquity  = GlobalVariableGet(m_prefix + "DailyEquity");
   dailyStartBalance = GlobalVariableGet(m_prefix + "DailyBalance");
   highWaterMark     = GlobalVariableGet(m_prefix + "HighWaterMark");
   activeDays        = (int)GlobalVariableGet(m_prefix + "ActiveDays");

   if(startBalance <= 0.0)
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| Clears stored state variables                                    |
//+------------------------------------------------------------------+
void CStatePersist::ClearState(void)
  {
   GlobalVariableDel(m_prefix + "StartBalance");
   GlobalVariableDel(m_prefix + "DailyEquity");
   GlobalVariableDel(m_prefix + "DailyBalance");
   GlobalVariableDel(m_prefix + "HighWaterMark");
   GlobalVariableDel(m_prefix + "ActiveDays");
   GlobalVariableDel(m_prefix + "LastSaveTime");
  }
