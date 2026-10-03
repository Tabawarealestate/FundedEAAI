//+------------------------------------------------------------------+
//|                                               DashboardPanel.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Class CDashboardPanel                                            |
//| Creates and updates the MT5 On-Chart Graphical Status Dashboard. |
//+------------------------------------------------------------------+
class CDashboardPanel
  {
private:
   string m_prefix;

public:
                     CDashboardPanel(void);
                    ~CDashboardPanel(void);

   void              Init(string prefix = "FundedAI_Dash_");
   void              Destroy(void);
   void              Update(const SChallengeAccountStatus &status, ENUM_EA_STATUS eaStatus, ENUM_MARKET_REGIME regime, double setupScore, string statusReason);

private:
   void              CreateLabel(string name, string text, int x, int y, color clr, int fontSize = 9);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CDashboardPanel::CDashboardPanel(void)
  : m_prefix("FundedAI_Dash_")
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CDashboardPanel::~CDashboardPanel(void)
  {
   Destroy();
  }

//+------------------------------------------------------------------+
//| Initializes Dashboard                                            |
//+------------------------------------------------------------------+
void CDashboardPanel::Init(string prefix)
  {
   m_prefix = prefix;
  }

//+------------------------------------------------------------------+
//| Cleans up dashboard objects                                      |
//+------------------------------------------------------------------+
void CDashboardPanel::Destroy(void)
  {
   ObjectsDeleteAll(0, m_prefix);
  }

//+------------------------------------------------------------------+
//| Renders/Updates On-Chart Dashboard Panel                         |
//+------------------------------------------------------------------+
void CDashboardPanel::Update(const SChallengeAccountStatus &status, ENUM_EA_STATUS eaStatus, ENUM_MARKET_REGIME regime, double setupScore, string statusReason)
  {
   int x = 20;
   int y = 30;

   CreateLabel(m_prefix + "Title", "=== FUNDED AI EA (PROP CHALLENGE GUARD) ===", x, y, clrGold, 10);
   y += 20;

   color statusColor = (eaStatus == EA_STATUS_ACTIVE) ? clrLime : ((eaStatus == EA_STATUS_DEFENSIVE) ? clrOrange : clrRed);
   CreateLabel(m_prefix + "Status", StringFormat("EA STATUS: %s | %s", EnumToString(eaStatus), statusReason), x, y, statusColor, 9);
   y += 18;

   CreateLabel(m_prefix + "Equity", StringFormat("Equity: $%.2f | Balance: $%.2f | Today P/L: $%.2f", status.currentEquity, status.currentBalance, status.dailyPL), x, y, clrWhite, 9);
   y += 18;

   CreateLabel(m_prefix + "Drawdown", StringFormat("Daily Drawdown: %.2f%% | Total Drawdown: %.2f%%", status.currentDailyDrawdownPercent, status.currentOverallDrawdownPercent), x, y, (status.currentDailyDrawdownPercent > 2.0) ? clrOrange : clrLime, 9);
   y += 18;

   CreateLabel(m_prefix + "Target", StringFormat("Target Progress: %.1f%% | Remaining Daily Allowance: $%.2f", status.targetProgressPercent, status.remainingDailyLossAllowance), x, y, clrAqua, 9);
   y += 18;

   CreateLabel(m_prefix + "Regime", StringFormat("Market Regime: %s | Latest Setup Score: %.0f/100", EnumToString(regime), setupScore), x, y, clrYellow, 9);

   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Helper method to create chart text labels                        |
//+------------------------------------------------------------------+
void CDashboardPanel::CreateLabel(string name, string text, int x, int y, color clr, int fontSize)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
     }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
  }
