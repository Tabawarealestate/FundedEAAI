//+------------------------------------------------------------------+
//|                                               TradeJournaler.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Class CTradeJournaler                                            |
//| Detailed Trade Journaling and CSV File Exporter for Audit.       |
//+------------------------------------------------------------------+
class CTradeJournaler
  {
private:
   string m_filename;

public:
                     CTradeJournaler(void);
                    ~CTradeJournaler(void);

   void              Init(string filename = "FundedAI_Trade_Journal.csv");
   void              LogTrade(datetime time, string symbol, string direction, double entry, double sl, double tp, double lot, double riskPct, double score, string regime, string explanation);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeJournaler::CTradeJournaler(void)
  : m_filename("FundedAI_Trade_Journal.csv")
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeJournaler::~CTradeJournaler(void)
  {
  }

//+------------------------------------------------------------------+
//| Initializes trade journal CSV file                               |
//+------------------------------------------------------------------+
void CTradeJournaler::Init(string filename)
  {
   m_filename = filename;
   int handle = FileOpen(m_filename, FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON, ',');
   if(handle != INVALID_HANDLE)
     {
      if(FileSize(handle) == 0)
        {
         FileWrite(handle, "DateTime", "Symbol", "Direction", "Entry", "SL", "TP", "Lot", "RiskPct", "SetupScore", "Regime", "Explanation");
        }
      FileClose(handle);
     }
  }

//+------------------------------------------------------------------+
//| Logs trade entry event details to CSV file                       |
//+------------------------------------------------------------------+
void CTradeJournaler::LogTrade(datetime time, string symbol, string direction, double entry, double sl, double tp, double lot, double riskPct, double score, string regime, string explanation)
  {
   int handle = FileOpen(m_filename, FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON, ',');
   if(handle != INVALID_HANDLE)
     {
      FileSeek(handle, 0, SEEK_END);
      FileWrite(handle, TimeToString(time, TIME_DATE | TIME_SECONDS), symbol, direction, entry, sl, tp, lot, riskPct, score, regime, explanation);
      FileClose(handle);
     }
  }
