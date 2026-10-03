//+------------------------------------------------------------------+
//|                                                PositionSizer.mqh |
//|                                  Copyright 2025, FUNDED AI EA    |
//|                                     https://www.fundedai-ea.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, FUNDED AI EA"
#property link      "https://www.fundedai-ea.com"
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Class CPositionSizer                                             |
//| Calculates risk-adjusted lot sizes based on stop loss distance,  |
//| account equity, symbol specifications, and broker lot limits.    |
//+------------------------------------------------------------------+
class CPositionSizer
  {
public:
                     CPositionSizer(void);
                    ~CPositionSizer(void);

   //--- Lot Calculation Method
   static double     CalculateLotSize(double accountEquity,
                                      double riskPercent,
                                      double riskMultiplier,
                                      double stopLossPoints,
                                      double tickValue,
                                      double tickSize,
                                      double pointSize,
                                      double minLot,
                                      double maxLot,
                                      double lotStep);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPositionSizer::CPositionSizer(void)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPositionSizer::~CPositionSizer(void)
  {
  }

//+------------------------------------------------------------------+
//| Calculates exact position size in lots                           |
//+------------------------------------------------------------------+
double CPositionSizer::CalculateLotSize(double accountEquity,
                                        double riskPercent,
                                        double riskMultiplier,
                                        double stopLossPoints,
                                        double tickValue,
                                        double tickSize,
                                        double pointSize,
                                        double minLot,
                                        double maxLot,
                                        double lotStep)
  {
   // Sanity checks
   if(accountEquity <= 0.0 || riskPercent <= 0.0 || stopLossPoints <= 0.0)
      return 0.0;

   if(tickValue <= 0.0 || pointSize <= 0.0 || lotStep <= 0.0)
      return 0.0;

   // 1. Calculate Dollar Risk Amount
   double effectiveRiskPercent = riskPercent * riskMultiplier;
   if(effectiveRiskPercent <= 0.0)
      return 0.0;

   double riskAmountDollars = accountEquity * (effectiveRiskPercent / 100.0);

   // 2. Calculate Monetary Value per Point per 1.0 Lot
   double tickToPointRatio = (tickSize > 0.0) ? (pointSize / tickSize) : 1.0;
   double pointValuePerLot = tickValue * tickToPointRatio;

   if(pointValuePerLot <= 0.0)
      return 0.0;

   // 3. Compute Raw Lot Size: Risk Dollars / (SL Points * Point Value)
   double rawLot = riskAmountDollars / (stopLossPoints * pointValuePerLot);

   // 4. Round down to nearest Lot Step with floating-point epsilon protection
   double stepLots = MathFloor((rawLot / lotStep) + 1e-7) * lotStep;

   // 5. Clamp between Broker Min and Max Lot Boundaries
   if(stepLots < minLot)
      stepLots = 0.0; // Lot size below broker minimum -> unsafe to enter
   if(maxLot > 0.0 && stepLots > maxLot)
      stepLots = maxLot;

   // Derive decimal precision from lotStep
   int lotDigits = 2;
   if(lotStep < 0.01)
      lotDigits = 3;

   return NormalizeDouble(stepLots, lotDigits);
  }
