//+------------------------------------------------------------------+
//|                                              NinjaLoveFishEA.mq4 |
//|                                      Copyright @2018, renzhe.org |
//+------------------------------------------------------------------+
//发布前,要修改3个地方,1个是版本号,一个是DEBUG模式关闭.
//#define __DEBUG__

#define Version "1.01"
#define EAName "NinjaLoveFishTF"

#property strict
#property version Version
#property copyright "Copyright @2018, Qin Zhao"
#property link "https://www.mql5.com/en/users/zq535228"
#property icon "3232.ico"
#property description "This EA contains two modes, automatic and manual mode,welcome to download.\nIt's recommended to test the EA in the Strategy Tester before using the live account."
#include <stderror.mqh>
#include <stdlib.mqh>
#include "comm.mqh"


#ifdef __DEBUG__
extern static string EA=EAName+" debug"+Version;
#else 
extern static string EA=EAName+" v"+Version;
#endif 

int    MagicNumberBuy                              = 12345;
int    MagicNumberSell                             = 54321;

datetime _pendingTime;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   long x_distance;
   long y_distance;
//--- set window size 
   if(!ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,x_distance))
     {
      Print("Failed to get the chart width! Error code = ",GetLastError());
     }
   if(!ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,y_distance))
     {
      Print("Failed to get the chart height! Error code = ",GetLastError());
     }
   ObjectCreate(0,"SELL",OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,"SELL",OBJPROP_XDISTANCE,x_distance/3+250);
   ObjectSetInteger(0,"SELL",OBJPROP_YDISTANCE,20);
   ObjectSetString(0,"SELL",OBJPROP_TEXT,"SELL");
   ObjectSetInteger(0,"SELL",OBJPROP_BGCOLOR,clrTomato);
   ObjectSetInteger(0,"SELL",OBJPROP_COLOR,clrBlack);
   ObjectSetInteger(0,"SELL",OBJPROP_FONTSIZE,8);

   if(MarketInfo(Symbol(),MODE_SWAPSHORT)>0)
     {
      ObjectSetInteger(0,"SELL",OBJPROP_BGCOLOR,clrChartreuse);
      ObjectSetString(0,"SELL",OBJPROP_TEXT,"SELL +"+DoubleToStr(MarketInfo(Symbol(),MODE_SWAPSHORT),1));
     }
   else
     {
      ObjectSetInteger(0,"SELL",OBJPROP_BGCOLOR,clrLightSalmon);
      ObjectSetString(0,"SELL",OBJPROP_TEXT,"SELL "+DoubleToStr(MarketInfo(Symbol(),MODE_SWAPSHORT),1));
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   double h=0;

   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="SELL" && ObjectGetInteger(0,"SELL",OBJPROP_STATE))
     {
      //--- State of the button - pressed or not 
      bool selected2=ObjectGetInteger(0,"SELL",OBJPROP_STATE);
      //--- log a debug message 
      Print("SELL Button pressed = ",selected2);
      double np=Ask+GetPointForFirstManualOrder();
      setLine("SellSLLine",np,clrRed,1,true);
      dump("I will open the sell order and the SL at the price of "+DoubleToStr(np,5));
      _pendingTime=TimeCurrent();
      ObjectSetInteger(0,"SELL",OBJPROP_STATE,0);
     }

  }
//  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void start()
  {
//---
   if(!IsNewBar()) return;//如果不是新bar,那么直接返回.等待新bar

   if(GetSignalRSI()==-1 && Bid<GetSignalSAR() && CountOfOrders(MagicNumberSell)==0)
     {
      openSell(0.01,MagicNumberSell);
     }
   if(CountOfOrders(MagicNumberSell)!=0 && Bid<GetSignalSAR())
     {
      modifySL(GetSignalSAR(),MagicNumberSell);
     }

  }
//+------------------------------------------------------------------+

double GetSignalSAR()
  {
   double s=iSAR(Symbol(),PERIOD_H1,0.02,0.2,0);
   return s;
  }
//+------------------------------------------------------------------+
int GetSignalRSI()
  {
   int re=0;

   if(iRSI(Symbol(),PERIOD_M5,8,PRICE_CLOSE,0)<30)
     {
      re=1;//buy
     }
   if(iRSI(Symbol(),PERIOD_M5,8,PRICE_CLOSE,0)>70)
     {
      re=-1;//sell
     }
   return re;
  }
//+------------------------------------------------------------------+

//获取手动单的距离Point
double GetPointForFirstManualOrder()
  {
   double re=iCustom(Symbol(),PERIOD_M5,"ATR",14,0,0)*5;
   return(re);
  }
//
