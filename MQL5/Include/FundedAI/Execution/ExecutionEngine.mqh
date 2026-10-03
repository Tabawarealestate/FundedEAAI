//+------------------------------------------------------------------+
//|                                              ExecutionEngine.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include <Trade\Trade.mqh>
#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"
#include "../Utils/SymbolUtils.mqh"

//+------------------------------------------------------------------+
//| Struct: Order Execution Result Details                           |
//+------------------------------------------------------------------+
struct SExecutionResult
  {
   bool     isSuccess;          // True if order placed/closed successfully
   ulong    ticket;             // Position / Order Ticket Number
   double   executedPrice;      // Filled Execution Price
   double   executedLot;        // Filled Lot Size
   uint     retcode;            // MT5 Trade Server Return Code
   string   errorMessage;       // Human-readable error description
  };

//+------------------------------------------------------------------+
//| Class CExecutionEngine                                           |
//| Native MQL5 Order Execution Engine handling trade sending,      |
//| slippage/spread safeguards, failover retries, and error logs.    |
//+------------------------------------------------------------------+
class CExecutionEngine
  {
private:
   CTrade   m_trade;
   ulong    m_magicNumber;
   int      m_maxSlippagePoints;
   int      m_maxRetries;

public:
                     CExecutionEngine(void);
                    ~CExecutionEngine(void);

   void              Init(ulong magicNumber, int maxSlippagePoints = 10, int maxRetries = 3);

   //--- Execution Methods
   SExecutionResult  OpenMarketOrder(string symbol, ENUM_ORDER_TYPE orderType, double lotSize, double stopLoss, double takeProfit, string comment = "");
   bool              ClosePositionByTicket(ulong ticket);
   bool              CloseAllPositions(string symbol = "");

   //--- Error Handler
   static string     GetRetcodeDescription(uint retcode);

private:
   ENUM_ORDER_TYPE_FILLING GetOptimalFillingType(string symbol);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CExecutionEngine::CExecutionEngine(void)
  : m_magicNumber(FUNDED_AI_DEFAULT_MAGIC),
    m_maxSlippagePoints(DEFAULT_MAX_SLIPPAGE),
    m_maxRetries(3)
  {
   Init(FUNDED_AI_DEFAULT_MAGIC, DEFAULT_MAX_SLIPPAGE, 3);
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CExecutionEngine::~CExecutionEngine(void)
  {
  }

//+------------------------------------------------------------------+
//| Initializes trade settings                                       |
//+------------------------------------------------------------------+
void CExecutionEngine::Init(ulong magicNumber, int maxSlippagePoints, int maxRetries)
  {
   m_magicNumber       = magicNumber;
   m_maxSlippagePoints = maxSlippagePoints;
   m_maxRetries        = maxRetries;

   m_trade.SetExpertMagicNumber(m_magicNumber);
   m_trade.SetDeviationInPoints(m_maxSlippagePoints);
  }

//+------------------------------------------------------------------+
//| Auto-detects supported filling mode for broker symbol            |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING CExecutionEngine::GetOptimalFillingType(string symbol)
  {
   uint fillingMode = (uint)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
   if((fillingMode & SYMBOL_FILLING_FOK) != 0)
      return ORDER_FILLING_FOK;
   if((fillingMode & SYMBOL_FILLING_IOC) != 0)
      return ORDER_FILLING_IOC;
   return ORDER_FILLING_RETURN;
  }

//+------------------------------------------------------------------+
//| Executes a market order with failover retries and safeguards      |
//+------------------------------------------------------------------+
SExecutionResult CExecutionEngine::OpenMarketOrder(string symbol, ENUM_ORDER_TYPE orderType, double lotSize, double stopLoss, double takeProfit, string comment)
  {
   SExecutionResult result;
   result.isSuccess     = false;
   result.ticket        = 0;
   result.executedPrice = 0.0;
   result.executedLot   = 0.0;
   result.retcode       = 0;
   result.errorMessage  = "";

   if(lotSize <= 0.0)
     {
      result.errorMessage = "INVALID LOT SIZE: Calculated volume <= 0";
      return result;
     }

   SSymbolSpecification spec;
   if(!CSymbolUtils::GetSymbolSpec(symbol, spec))
     {
      result.errorMessage = "SYMBOL ERROR: Could not fetch symbol specs";
      return result;
     }

   if(!spec.isTradeAllowed)
     {
      result.errorMessage = "TRADE BLOCKED: Broker disabled trading for symbol";
      return result;
     }

   // Set optimal filling mode dynamically
   m_trade.SetTypeFilling(GetOptimalFillingType(symbol));

   // Retry Loop for Execution Robustness
   for(int attempt = 1; attempt <= m_maxRetries; attempt++)
     {
      bool success = false;
      if(orderType == ORDER_TYPE_BUY)
         success = m_trade.Buy(lotSize, symbol, 0.0, stopLoss, takeProfit, comment);
      else if(orderType == ORDER_TYPE_SELL)
         success = m_trade.Sell(lotSize, symbol, 0.0, stopLoss, takeProfit, comment);

      result.retcode = m_trade.ResultRetcode();

      if(success && result.retcode == TRADE_RETCODE_DONE)
        {
         result.isSuccess     = true;
         result.ticket        = m_trade.ResultOrder();
         result.executedPrice = m_trade.ResultPrice();
         result.executedLot   = m_trade.ResultVolume();
         result.errorMessage  = "ORDER EXECUTED SUCCESSFULLY";
         return result;
        }

      result.errorMessage = StringFormat("Attempt %d failed: %s (Code: %u)", attempt, GetRetcodeDescription(result.retcode), result.retcode);
      Sleep(200 * attempt); // Pause before retry
     }

   return result;
  }

//+------------------------------------------------------------------+
//| Closes position by ticket                                        |
//+------------------------------------------------------------------+
bool CExecutionEngine::ClosePositionByTicket(ulong ticket)
  {
   return m_trade.PositionClose(ticket);
  }

//+------------------------------------------------------------------+
//| Emergency Liquidator: Closes all open EA positions               |
//+------------------------------------------------------------------+
bool CExecutionEngine::CloseAllPositions(string symbol)
  {
   bool allClosed = true;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         if(PositionGetInteger(POSITION_MAGIC) == (long)m_magicNumber)
           {
            if(symbol == "" || PositionGetString(POSITION_SYMBOL) == symbol)
              {
               if(!m_trade.PositionClose(ticket))
                  allClosed = false;
              }
           }
        }
     }
   return allClosed;
  }

//+------------------------------------------------------------------+
//| Translates MT5 trade return code into descriptive string          |
//+------------------------------------------------------------------+
string CExecutionEngine::GetRetcodeDescription(uint retcode)
  {
   switch(retcode)
     {
      case TRADE_RETCODE_DONE:             return "Trade done";
      case TRADE_RETCODE_REJECT:           return "Request rejected";
      case TRADE_RETCODE_CANCEL:           return "Request canceled";
      case TRADE_RETCODE_PLACED:           return "Order placed";
      case TRADE_RETCODE_ERROR:            return "Common error";
      case TRADE_RETCODE_TIMEOUT:          return "Request timeout";
      case TRADE_RETCODE_INVALID:          return "Invalid request";
      case TRADE_RETCODE_INVALID_VOLUME:   return "Invalid volume";
      case TRADE_RETCODE_INVALID_PRICE:    return "Invalid price";
      case TRADE_RETCODE_INVALID_STOPS:    return "Invalid stops";
      case TRADE_RETCODE_TRADE_DISABLED:   return "Trading disabled";
      case TRADE_RETCODE_MARKET_CLOSED:    return "Market closed";
      case TRADE_RETCODE_NO_MONEY:         return "Insufficient funds";
      case TRADE_RETCODE_PRICE_CHANGED:    return "Price changed";
      case TRADE_RETCODE_PRICE_OFF:        return "Off quotes";
      case TRADE_RETCODE_REQUOTE:          return "Requote";
      case TRADE_RETCODE_TOO_MANY_REQUESTS:return "Too many requests";
      default:                             return StringFormat("Unknown code %u", retcode);
     }
  }
