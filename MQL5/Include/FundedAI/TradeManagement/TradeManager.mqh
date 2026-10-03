//+------------------------------------------------------------------+
//|                                                 TradeManager.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include <Trade\Trade.mqh>
#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Class CTradeManager                                              |
//| Manages open positions, Break-Even, and Trailing Stop Loss.     |
//+------------------------------------------------------------------+
class CTradeManager
  {
private:
   CTrade   m_trade;
   ulong    m_magicNumber;

public:
                     CTradeManager(void);
                    ~CTradeManager(void);

   void              Init(ulong magicNumber);
   void              ManageOpenPositions(string symbol, double breakEvenRatio = 1.0, double trailingStopPoints = 200.0, double pointSize = 0.00001);
   int               GetConsecutiveLossCount(ulong magicNumber);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager(void)
  : m_magicNumber(FUNDED_AI_DEFAULT_MAGIC)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager(void)
  {
  }

//+------------------------------------------------------------------+
//| Initializes trade manager                                        |
//+------------------------------------------------------------------+
void CTradeManager::Init(ulong magicNumber)
  {
   m_magicNumber = magicNumber;
   m_trade.SetExpertMagicNumber(m_magicNumber);
  }

//+------------------------------------------------------------------+
//| Manages active positions: Break-Even & Trailing Stop             |
//+------------------------------------------------------------------+
void CTradeManager::ManageOpenPositions(string symbol, double breakEvenRatio, double trailingStopPoints, double pointSize)
  {
   if(pointSize <= 0.0)
      return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == (long)m_magicNumber && PositionGetString(POSITION_SYMBOL) == symbol)
        {
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double openPrice  = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentSL  = PositionGetDouble(POSITION_SL);
         double currentTP  = PositionGetDouble(POSITION_TP);
         double currentPrice = (posType == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);

         if(posType == POSITION_TYPE_BUY)
           {
            double profitPoints = (currentPrice - openPrice) / pointSize;
            double initialRiskPoints = (openPrice - currentSL) / pointSize;

            // 1. Move SL to Break-Even when profit reaches BreakEvenRatio * R
            if(initialRiskPoints > 0.0 && profitPoints >= (initialRiskPoints * breakEvenRatio) && currentSL < openPrice)
              {
               m_trade.PositionModify(ticket, openPrice + (5.0 * pointSize), currentTP);
              }

            // 2. Trailing Stop
            if(trailingStopPoints > 0.0 && profitPoints >= trailingStopPoints)
              {
               double newSL = currentPrice - (trailingStopPoints * pointSize);
               if(newSL > currentSL + (10.0 * pointSize))
                 {
                  m_trade.PositionModify(ticket, NormalizeDouble(newSL, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)), currentTP);
                 }
              }
           }
         else if(posType == POSITION_TYPE_SELL)
           {
            double profitPoints = (openPrice - currentPrice) / pointSize;
            double initialRiskPoints = (currentSL - openPrice) / pointSize;

            // 1. Move SL to Break-Even
            if(initialRiskPoints > 0.0 && profitPoints >= (initialRiskPoints * breakEvenRatio) && (currentSL > openPrice || currentSL == 0.0))
              {
               m_trade.PositionModify(ticket, openPrice - (5.0 * pointSize), currentTP);
              }

            // 2. Trailing Stop
            if(trailingStopPoints > 0.0 && profitPoints >= trailingStopPoints)
              {
               double newSL = currentPrice + (trailingStopPoints * pointSize);
               if(currentSL == 0.0 || newSL < currentSL - (10.0 * pointSize))
                 {
                  m_trade.PositionModify(ticket, NormalizeDouble(newSL, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)), currentTP);
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Scans closed trade history to count consecutive losses           |
//+------------------------------------------------------------------+
int CTradeManager::GetConsecutiveLossCount(ulong magicNumber)
  {
   int consecutiveLosses = 0;
   if(!HistorySelect(0, TimeCurrent()))
      return 0;

   int totalDeals = HistoryDealsTotal();
   for(int i = totalDeals - 1; i >= 0; i--)
     {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket > 0)
        {
         if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) == (long)magicNumber && HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
           {
            double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT) + HistoryDealGetDouble(dealTicket, DEAL_SWAP) + HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
            if(profit < 0.0)
               consecutiveLosses++;
            else if(profit > 0.0)
               break; // Winning trade breaks loss streak
           }
        }
     }
   return consecutiveLosses;
  }
