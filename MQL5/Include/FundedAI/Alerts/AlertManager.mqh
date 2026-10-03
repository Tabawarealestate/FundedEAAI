//+------------------------------------------------------------------+
//|                                                 AlertManager.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Class CAlertManager                                              |
//| Multi-channel alert system for MT5 popup, push, sound, and logs. |
//+------------------------------------------------------------------+
class CAlertManager
  {
private:
   bool m_enablePopup;
   bool m_enablePush;
   bool m_enableSound;

public:
                     CAlertManager(void);
                    ~CAlertManager(void);

   void              Init(bool popup = true, bool push = true, bool sound = true);
   void              SendTradeAlert(string symbol, string action, double price, double sl, double tp, double score);
   void              SendRiskAlert(string title, string message);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CAlertManager::CAlertManager(void)
  : m_enablePopup(true),
    m_enablePush(true),
    m_enableSound(true)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CAlertManager::~CAlertManager(void)
  {
  }

//+------------------------------------------------------------------+
//| Initializes alert channels                                       |
//+------------------------------------------------------------------+
void CAlertManager::Init(bool popup, bool push, bool sound)
  {
   m_enablePopup = popup;
   m_enablePush  = push;
   m_enableSound = sound;
  }

//+------------------------------------------------------------------+
//| Sends trade entry/exit notifications                             |
//+------------------------------------------------------------------+
void CAlertManager::SendTradeAlert(string symbol, string action, double price, double sl, double tp, double score)
  {
   string msg = StringFormat("[%s] %s %s @ %.5f | SL: %.5f | TP: %.5f | AI Score: %.0f",
                             FUNDED_AI_NAME, action, symbol, price, sl, tp, score);

   Print(msg);
   if(m_enablePopup)
      Alert(msg);
   if(m_enablePush)
      SendNotification(msg);
   if(m_enableSound)
      PlaySound("expert.wav");
  }

//+------------------------------------------------------------------+
//| Sends risk warning notifications                                 |
//+------------------------------------------------------------------+
void CAlertManager::SendRiskAlert(string title, string message)
  {
   string msg = StringFormat("[%s - RISK WARNING] %s: %s", FUNDED_AI_NAME, title, message);

   Print(msg);
   if(m_enablePopup)
      Alert(msg);
   if(m_enablePush)
      SendNotification(msg);
   if(m_enableSound)
      PlaySound("timeout.wav");
  }
