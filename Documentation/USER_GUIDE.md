# FUNDED AI EA — USER GUIDE

## Overview
The **FUNDED AI EA** is a rule-aware MetaTrader 5 Expert Advisor designed to assist traders during prop-firm challenge evaluation phases and funded accounts.

## Core Philosophy
**SURVIVE FIRST. TRADE SECOND. PROFIT THIRD.**
The system prioritizes account preservation, strict drawdown compliance, and multi-factor Smart Money Concepts (SMC) entry confirmation over aggressive profit chasing.

## Installation
1. Copy `FundedAI_EA.mq5` into `MQL5/Experts/FundedAI/`.
2. Copy the entire `Include/FundedAI/` directory into `MQL5/Include/FundedAI/`.
3. Open MetaTrader 5, press `F4` to launch MetaEditor, and compile `FundedAI_EA.mq5`.
4. Attach `FundedAI_EA` to any M15 chart (e.g. `EURUSD` or `XAUUSD`).
5. Ensure "Allow Algo Trading" is checked in MT5 Terminal settings.

## On-Chart Dashboard
The live visual panel displays:
- Account Equity, Balance, and High-Water Mark (HWM).
- Daily and Overall Drawdown % used against configured thresholds.
- Challenge Target Progress %, Active Trading Days, and Portfolio Risk %.
- News Filter Status & Active Session Name.
- Setup Quality Score (0–100) and Market Regime.
