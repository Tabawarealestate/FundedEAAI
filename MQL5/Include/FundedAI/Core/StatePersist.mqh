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
//| Binary file state persistence and crash recovery engine.          |
//+------------------------------------------------------------------+
class CStatePersist
  {
private:
   string m_fileName;
   ulong  m_magicNumber;

public:
                     CStatePersist(void);
                    ~CStatePersist(void);

   void              Init(ulong magicNumber);
   bool              SaveState(const SChallengeStatePersist &state);
   bool              LoadState(SChallengeStatePersist &state);
   void              DeleteStateFile(void);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CStatePersist::CStatePersist(void)
  : m_magicNumber(FUNDED_AI_DEFAULT_MAGIC),
    m_fileName("FundedAI_State_888999.bin")
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CStatePersist::~CStatePersist(void)
  {
  }

//+------------------------------------------------------------------+
//| Sets Magic Number & constructs unique filename                  |
//+------------------------------------------------------------------+
void CStatePersist::Init(ulong magicNumber)
  {
   m_magicNumber = magicNumber;
   m_fileName    = StringFormat("FundedAI_State_%I64u.bin", m_magicNumber);
  }

//+------------------------------------------------------------------+
//| Saves challenge state struct to binary file                     |
//+------------------------------------------------------------------+
bool CStatePersist::SaveState(const SChallengeStatePersist &state)
  {
   int fileHandle = FileOpen(m_fileName, FILE_WRITE | FILE_BIN);
   if(fileHandle == INVALID_HANDLE)
     {
      Print("ERROR: Could not open state file for writing: ", m_fileName);
      return false;
     }

   FileWriteString(fileHandle, state.profileID, 64);
   FileWriteInteger(fileHandle, state.configVersion);
   FileWriteInteger(fileHandle, (int)state.phase);
   FileWriteInteger(fileHandle, (long)state.challengeStartTime);
   FileWriteDouble(fileHandle, state.startingBalance);
   FileWriteDouble(fileHandle, state.dailyStartingBalance);
   FileWriteDouble(fileHandle, state.dailyStartingEquity);
   FileWriteDouble(fileHandle, state.highWaterMark);
   FileWriteInteger(fileHandle, (int)state.hwmSource);
   FileWriteInteger(fileHandle, (int)state.drawdownModel);
   FileWriteInteger(fileHandle, state.unrealizedMovesHWM ? 1 : 0);
   FileWriteInteger(fileHandle, state.lastDailyResetDateKey);
   FileWriteInteger(fileHandle, state.activeTradingDays);
   FileWriteInteger(fileHandle, (long)TimeCurrent());

   FileClose(fileHandle);
   return true;
  }

//+------------------------------------------------------------------+
//| Loads challenge state struct from binary file                   |
//+------------------------------------------------------------------+
bool CStatePersist::LoadState(SChallengeStatePersist &state)
  {
   if(!FileIsExist(m_fileName))
      return false;

   int fileHandle = FileOpen(m_fileName, FILE_READ | FILE_BIN);
   if(fileHandle == INVALID_HANDLE)
      return false;

   state.profileID             = FileReadString(fileHandle, 64);
   state.configVersion         = (int)FileReadInteger(fileHandle);
   state.phase                 = (ENUM_CHALLENGE_PHASE)FileReadInteger(fileHandle);
   state.challengeStartTime    = (datetime)FileReadInteger(fileHandle);
   state.startingBalance       = FileReadDouble(fileHandle);
   state.dailyStartingBalance  = FileReadDouble(fileHandle);
   state.dailyStartingEquity   = FileReadDouble(fileHandle);
   state.highWaterMark         = FileReadDouble(fileHandle);
   state.hwmSource             = (ENUM_HWM_SOURCE)FileReadInteger(fileHandle);
   state.drawdownModel         = (ENUM_DRAWDOWN_MODEL)FileReadInteger(fileHandle);
   state.unrealizedMovesHWM    = (FileReadInteger(fileHandle) == 1);
   state.lastDailyResetDateKey = (int)FileReadInteger(fileHandle);
   state.activeTradingDays     = (int)FileReadInteger(fileHandle);
   state.lastStateSaveTime     = (datetime)FileReadInteger(fileHandle);

   FileClose(fileHandle);

   if(state.startingBalance <= 0.0 || state.highWaterMark <= 0.0)
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| Deletes state persistence file                                   |
//+------------------------------------------------------------------+
void CStatePersist::DeleteStateFile(void)
  {
   if(FileIsExist(m_fileName))
      FileDelete(m_fileName);
  }
