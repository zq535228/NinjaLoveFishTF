//+------------------------------------------------------------------+
//|                                              NinjaLoveFishTF.mq4 |
//|                                      Copyright @2019, renzhe.org |
//+------------------------------------------------------------------+
//发布前,要修改3个地方,1个是版本号,一个是DEBUG模式关闭.
//#define __DEBUG__

#define Version "1.12"
#define EAName "NinjaLoveFishTF"

#property strict
#property version Version
#property copyright "Copyright @2018, Qin Zhao"
#property link "https://www.mql5.com/en/users/zq535228"
#property icon "3232.ico"
#property description "NinjaLoveFish Trend SAR Follow EA."

#include <stderror.mqh>
#include <stdlib.mqh>
#include "comm.mqh"


#ifdef __DEBUG__
extern static string EA=EAName+" debug"+Version;
#else 
extern static string EA=EAName+" v"+Version;
#endif 

extern string            s1                   = ">>>>>>>>>>>>>>>>>>>>>>>>>>>>";
extern string            s2                   = ">>> General Setting";
extern int               MagicNumberBuy       = 12345;
extern int               MagicNumberSell      = 54321;

extern string            s3                   = ">>>>>>>>>>>>>>>>>>>>>>>>>>>>";
extern string            s4                   = ">>> Order Setting";
extern double            LotPercent           = 0.1;
extern double            MaxperLot            = 1000;
extern int               PendingHours         = 120;
extern ENUM_TIMEFRAMES   TradeRSIPeriod       = PERIOD_M5;
extern ENUM_TIMEFRAMES   FollowSARPeriod      = PERIOD_H4;

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

   ObjectCreate(0,"BUY",OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,"BUY",OBJPROP_XDISTANCE,x_distance/3);
   ObjectSetInteger(0,"BUY",OBJPROP_YDISTANCE,20);
   ObjectSetString(0,"BUY",OBJPROP_TEXT,"BUY");
   ObjectSetInteger(0,"BUY",OBJPROP_COLOR,clrBlack);
   ObjectSetInteger(0,"BUY",OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,"BUY",OBJPROP_XSIZE,70);
//ObjectSetString(0,"BUY",OBJPROP_FONT,"Calibri"); 

   if(MarketInfo(Symbol(),MODE_SWAPLONG)>0)
     {
      ObjectSetInteger(0,"BUY",OBJPROP_BGCOLOR,clrChartreuse);
      ObjectSetString(0,"BUY",OBJPROP_TEXT,"BUY +"+DoubleToStr(MarketInfo(Symbol(),MODE_SWAPLONG),1));
     }
   else
     {
      ObjectSetInteger(0,"BUY",OBJPROP_BGCOLOR,clrLightSalmon);
      ObjectSetString(0,"BUY",OBJPROP_TEXT,"BUY "+DoubleToStr(MarketInfo(Symbol(),MODE_SWAPLONG),1));
     }

   ObjectCreate(0,"SELL",OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,"SELL",OBJPROP_XDISTANCE,x_distance/3+90);
   ObjectSetInteger(0,"SELL",OBJPROP_YDISTANCE,20);
   ObjectSetString(0,"SELL",OBJPROP_TEXT,"SELL");
   ObjectSetInteger(0,"SELL",OBJPROP_COLOR,clrBlack);
   ObjectSetInteger(0,"SELL",OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,"SELL",OBJPROP_XSIZE,70);

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

   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="BUY" && ObjectGetInteger(0,"BUY",OBJPROP_STATE))
     {
      //--- State of the button - pressed or not 
      bool selected1=ObjectGetInteger(0,"BUY",OBJPROP_STATE);
      //--- log a debug message 
      Print("BUY Button pressed = ",selected1);
      double BuySLLine=Bid-GetPointForSL();
      setLine("BuySLLine",BuySLLine,clrRed,1,true);

      double BuyLine=Bid-GetPointForTrade();
      setLine("BuyLine",BuyLine,clrChartreuse,1,true);

      _pendingTime=TimeCurrent();
      ObjectSetInteger(0,"BUY",OBJPROP_STATE,0);
     }

   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="SELL" && ObjectGetInteger(0,"SELL",OBJPROP_STATE))
     {
      //--- State of the button - pressed or not 
      bool selected2=ObjectGetInteger(0,"SELL",OBJPROP_STATE);
      //--- log a debug message 
      Print("SELL Button pressed = ",selected2);

      double SellSLLine=Ask+GetPointForSL();
      setLine("SellSLLine",SellSLLine,clrRed,1,true);

      double SellLine=Ask+GetPointForTrade();
      setLine("SellLine",SellLine,clrChartreuse,1,true);

      _pendingTime=TimeCurrent();
      ObjectSetInteger(0,"SELL",OBJPROP_STATE,0);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void start()
  {
//---
//如果不是新bar,那么直接返回.等待新bar
   if(!IsNewBar()) return;

//处理挂止损
   CheckPending();

//卖单处理。
   DealSell();

//买单处理。
   DealBuy();

//关闭订单
   DealClose();

//信息输出
   Comm();

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DealBuy()
  {
   if(CountOfOrders(MagicNumberBuy)!=0)
     {
      deleteObjects("BuyLine");
      if(Ask>GetSignalSAR())
        {
         modifySL(GetSignalSAR(),MagicNumberBuy);
        }
      else
        {
         modifySL(getLineValue("BuySLLine"),MagicNumberBuy);
        }
      deleteObjects("BuySLLine");
     }

   bool buy=true;
   if(!IsTesting())
     {
      buy=getLineValue("BuySLLine")!=0 && getLineValue("BuyLine")!=0 && Bid<getLineValue("BuyLine");
     }
   else
     {
      buy=Ask>GetSignalSAR();
     }

   if(buy && GetSignalRSI()==1 && CountOfOrders(MagicNumberBuy)==0)
     {
      openBuy(GetLotSize(),MagicNumberBuy);
      deleteObjects("BuyLine");
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DealSell()
  {
   if(CountOfOrders(MagicNumberSell)!=0)
     {
      deleteObjects("SellLine");
      if(Bid<GetSignalSAR())
        {
         modifySL(GetSignalSAR(),MagicNumberSell);
        }
      else
        {
         modifySL(getLineValue("SellSLLine"),MagicNumberSell);
        }
      deleteObjects("SellSLLine");
     }

   bool sell=true;
   if(!IsTesting())
     {
      sell=getLineValue("SellSLLine")!=0 && getLineValue("SellLine")!=0 && Ask>getLineValue("SellLine");
     }
   else
     {
      sell=Bid<GetSignalSAR();
     }

   if(sell && GetSignalRSI()==-1 && CountOfOrders(MagicNumberSell)==0)
     {
      openSell(GetLotSize(),MagicNumberSell);
      deleteObjects("SellLine");
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DealClose()
  {
   double r=iRSI(Symbol(),PERIOD_H4,8,PRICE_CLOSE,0);
   if(r>90 && CountOfOrders(MagicNumberBuy)>0)
     {
      closeAll(MagicNumberBuy);
     }
   if(r<10 && CountOfOrders(MagicNumberSell)>0)
     {
      closeAll(MagicNumberSell);
     }

  }
//进行挂单的清除,如果到时间的话.
void CheckPending()
  {
   if(_pendingTime>0 && (TimeCurrent()-_pendingTime)/3600>PendingHours)
     {
      ObjectDelete("BuySLLine");
      ObjectDelete("SellSLLine");
      //挂单清除提示。
      dump(Symbol()+"has been deleted ,over than "+IntegerToString(PendingHours));
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetSignalSAR()
  {
   double s=iSAR(Symbol(),FollowSARPeriod,0.02,0.2,0);
   return s;
  }
//+------------------------------------------------------------------+
int GetSignalRSI()
  {
   int re=0;

   if(iRSI(Symbol(),TradeRSIPeriod,8,PRICE_CLOSE,0)<30)
     {
      re=1;//buy
     }
   if(iRSI(Symbol(),TradeRSIPeriod,8,PRICE_CLOSE,0)>70)
     {
      re=-1;//sell
     }
   return re;
  }
//+------------------------------------------------------------------+

//获取手动单的距离Point
double GetPointForSL()
  {
   double re=iCustom(Symbol(),PERIOD_M5,"ATR",14,0,0)*15;
   return(re);
  }
//获取手动单的距离Point
double GetPointForTrade()
  {
   double re=iCustom(Symbol(),PERIOD_M5,"ATR",14,0,0)*5;
   return(re);
  }
//

double GetLotSize()
  {
   double re=0.01;
   if(!IsTesting())
     {
      double Expectedprofit=AccountBalance()*LotPercent/100;
      double re1=Expectedprofit/((MathAbs(getLineValue("SellSLLine")-Bid)/MarketInfo(Symbol(),MODE_TICKSIZE))*MarketInfo(Symbol(),MODE_TICKVALUE));
      double re2=Expectedprofit/((MathAbs(getLineValue("BuySLLine")-Bid)/MarketInfo(Symbol(),MODE_TICKSIZE))*MarketInfo(Symbol(),MODE_TICKVALUE));
      re=IIFd(re1>re2,re1,re2);
     }
   double lotper001=AccountBalance()*0.01/MaxperLot;
   re = IIFd( re>lotper001,lotper001,re);//取最小
   return re;
  }
//+------------------------------------------------------------------+

void Comm()
  {
   double rsi=iRSI(Symbol(),TradeRSIPeriod,8,PRICE_CLOSE,0);
   double re = NormalizeDouble(IIFd(GetLotSize()<0.01,0.01,GetLotSize()),2);

   Comment(
           "\n",
           "LotSize : "+(string)re+"\n",
           "TradeRSI : "+DoubleToStr(rsi,2)+"\n",
           "FollowSAR : "+DoubleToStr(GetSignalSAR(),_Digits)+"\n"
           );

  }
//+------------------------------------------------------------------+
