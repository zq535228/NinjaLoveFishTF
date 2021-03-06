//+------------------------------------------------------------------+
//|                                                         comm.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//直线 SetLine("Low Line", Period_Low_Line, Blue);
//https://docs.mql4.com/constants/objectconstants/webcolors
void setLine(string text,double level,color col1=clrSandyBrown,int width=1,bool selectable=false)
  {
   string linename=text;

   if(ObjectFind(linename)<0)
     {
      ObjectCreate(linename,OBJ_HLINE,0,Time[0],level);
      ObjectSet(linename,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSet(linename,OBJPROP_LEVELWIDTH,5);
      ObjectSet(linename,OBJPROP_COLOR,col1);
      ObjectSetInteger(0,linename,OBJPROP_WIDTH,width);
      ObjectSet(linename,OBJPROP_SELECTABLE,selectable);

     }
   else
     {
      if(level>0) ObjectMove(linename,0,Time[0],level);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getLineValue(string str)
  {
   double re;
   re=ObjectGetDouble(0,str,OBJPROP_PRICE);
   return re;

  }
//+------------------------------------------------------------------+
void deleteObjects(string text)
  {
   string linename=text;

   int objs=ObjectsTotal();
   string name;
   for(int cnt=ObjectsTotal()-1;cnt>=0;cnt--)
     {
      name=ObjectName(cnt);
      if(StringFind(name,linename,0)>-1) ObjectDelete(name);
      WindowRedraw();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void deletePending()
  {
   deleteObjects("BuyLine");   
   deleteObjects("SellLine");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void clearLines()
  {
   deleteObjects("AvgLine");
   deleteObjects("SLLine");
   deleteObjects("NextLine");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void clearAll()
  {
   clearLines();
   deleteObjects("CLOSE");
   deleteObjects("C_ALL");
   deleteObjects("SELL");
   deleteObjects("BUY");
   deleteObjects("Cback");
   deletePending();
   ObjectsDeleteAll(0,OBJ_VLINE);
  }
//关闭所有持有订单。   
int closeAll(int MagicNumber)
  {
   bool cg=false;
   int cnt,total;
   total=OrdersTotal();
   if(total==0)
     {
      return(0);
     }
   double hh = 0;
   double ll = 999;
   for(cnt=0;cnt<total;cnt++)
     {
      cg=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);

      if(OrderSymbol()==Symbol() && OrderType()==OP_BUY && OrderMagicNumber()==MagicNumber)
        {
         RefreshRates();
         if(ll>OrderOpenPrice()){ll=OrderOpenPrice();}
         cg=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),3,Magenta);
         if(cg=false)
           {
            dump("closeAll :"+OrderComment()+" failed :"+IntegerToString(GetLastError()));
           }
        }
      if(OrderSymbol()==Symbol() && OrderType()==OP_SELL && OrderMagicNumber()==MagicNumber)
        {
         RefreshRates();
         if(hh<OrderOpenPrice()){hh=OrderOpenPrice();}
         cg=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),3,Magenta);
         if(cg=false)
           {
            dump("closeAll :"+OrderComment()+" failed :"+IntegerToString(GetLastError()));
           }
        }
     }

   if(hh!=0)
     {
      dump("sell hh distance : "+DoubleToStr((hh-Bid)/Point,0));
     }
   if(ll!=999)
     {
      dump("buy ll distance : "+DoubleToStr((ll-Bid)/Point,0));
     }

   return(0);
  }
//+------------------------------------------------------------------+
//传入货币兑名称,和magicnumber,返回目前持仓的数量,例如传入USDCAD,如果你持有EURCAD和CADJPY,那么返回2,因为你想开仓CAD,已经有2个持仓了
//+------------------------------------------------------------------+
int GetPositionExistNum(string existsymbol,int mn)
  {
   if(IsTesting()) return 0;
   bool cg=false;
   int cnt,total,IsExist=0;
   total=OrdersTotal();
   if(total==0) return 0;

   string sym1 = StringSubstr(existsymbol,0,3);
   string sym2 = StringSubstr(existsymbol,3,6);
   for(cnt=0;cnt<total;cnt++)
     {
      cg=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if((OrderType()==OP_SELL || OrderType()==OP_BUY) && OrderMagicNumber()==mn && (StringFind(OrderSymbol(),sym1)!=-1 || StringFind(OrderSymbol(),sym2)!=-1))
        {
         IsExist++;
        }
     }

   return IsExist;
  }
//根据symbol来关闭挂单。  
void closeAllPendingIfExist(string existsymbol,int existNum,int mn)
  {
   bool cg=false;
   int cnt,total,IsExist=0;
   total=OrdersTotal();
   if(total==0) return;

   string sym1 = StringSubstr(existsymbol,0,3);
   string sym2 = StringSubstr(existsymbol,3,6);
   for(cnt=0;cnt<total;cnt++)
     {
      cg=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if((OrderType()==OP_SELL || OrderType()==OP_BUY) && OrderMagicNumber()==mn && (StringFind(OrderSymbol(),sym1)!=-1 || StringFind(OrderSymbol(),sym2)!=-1))
        {
         IsExist++;
        }
     }
   if(IsExist>=existNum)
     {
      deletePending();
     }

   return;
  }
//根据symbol来关闭挂单。  
void closeAllPending()
  {
   deletePending();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime getLastOpenTime(int MagicNumber=0)
  {
   bool cg=false;
   int total,cnt;
   datetime dt=0;
   total=OrdersTotal();
   if(total==0)
     {
      return(0);
     }

   for(cnt=0;cnt<total;cnt++)
     {
      cg=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderOpenTime()>dt && OrderMagicNumber()==MagicNumber)
        {
         dt=OrderOpenTime();
        }
     }

   return dt;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime getFirstOpenTime(int MagicNumber=0)
  {
   bool cg=false;
   int total,cnt;
   datetime dt=TimeCurrent();
   total=OrdersTotal();
   if(total==0)
     {
      return(0);
     }

   for(cnt=0;cnt<total;cnt++)
     {
      cg=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderOpenTime()<dt && OrderMagicNumber()==MagicNumber)
        {
         dt=OrderOpenTime();
        }
     }

   return dt;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getFirstOpenBar(int Magic)
  {

   datetime dt=getFirstOpenTime(Magic);
   for(int m=0;m<Bars;m++)
     {
      if(Time[m]<=dt)
        {
         return m;
        }
     }
   return 99999;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime getLastHistoryOpenTime(int MagicNumber=0)
  {
   bool cg=false;
   int total,cnt;
   datetime dt=0;
   total=OrdersTotal();
   if(total==0)
     {
      return(0);
     }

   for(cnt=0;cnt<total;cnt++)
     {
      cg=OrderSelect(cnt,SELECT_BY_POS,MODE_HISTORY);
      if(OrderSymbol()==Symbol() && OrderOpenTime()>dt && OrderMagicNumber()==MagicNumber)
        {
         dt=OrderOpenTime();
        }
     }

   return dt;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getLastOpenPrice(int MagicNumber=0)
  {
   bool cg=false;
   int total,cnt;
   datetime dt=0;
   total=OrdersTotal();
   double re=0;
   if(total==0)
     {
      return(0);
     }

   for(cnt=0;cnt<total;cnt++)
     {
      cg=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderOpenTime()>dt && OrderMagicNumber()==MagicNumber)
        {
         dt=OrderOpenTime();
         re= OrderOpenPrice();
        }
     }

   return re;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getFirstOpenPrice(int MagicNumber=0)
  {
   bool cg=false;
   int total,cnt;
   datetime dt=TimeCurrent();
   total=OrdersTotal();
   double re=0;
   if(total==0)
     {
      return(0);
     }

   for(cnt=0;cnt<total;cnt++)
     {
      cg=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderOpenTime()<dt && OrderMagicNumber()==MagicNumber)
        {
         dt=OrderOpenTime();
         re= OrderOpenPrice();
        }
     }

   return re;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getOrdersCount(int OP=999,int MagicNumber=0)
  {
   bool cg=false;
   int cnt,total,xcnt,re,SellNums=0,BuyNums=0;

   total=OrdersTotal();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(total==0)
     {
      return(0);
     }

   xcnt=0;

   for(cnt=0;cnt<total;cnt++)
     {
      cg=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
        {
         xcnt++;
         if(OrderType()==OP_SELL)
           {
            SellNums++;
           }
         if(OrderType()==OP_BUY)
           {
            BuyNums++;
           }
        }
     } // for

   re=xcnt;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(OP_SELL==OP)
     {
      re=SellNums;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(OP_BUY==OP)
     {
      re=BuyNums;
     }
   return(re);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getTotalLots(int MagicNumber=0)
  {
   double totals=0.0;
   double lots=0.0;
   int total=OrdersTotal();
   int cnt;
   if(total>0)
     {
      for(cnt=0;cnt<total;cnt++)
        {
         int h=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
           {
            totals+=OrderLots();
           }
        }
     }

   return totals;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getAvgPrice(int MagicNumber=0)
  {
   double avg=0;
   double totals=0.0;
   double lots=0.0;
   int total=OrdersTotal();
   int cnt;
   if(total>0)
     {
      for(cnt=0;cnt<total;cnt++)
        {
         int h=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
           {
            totals+=OrderOpenPrice()*OrderLots();
            lots+=OrderLots();
           }
        }
      if(lots>0)
        {
         avg=NormalizeDouble(totals/lots,Digits);
        }
     }

   return avg;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getLots(int lot001)
  {
   double MaxL=MarketInfo(Symbol(),MODE_MAXLOT)/10;
   double MinL=MarketInfo(Symbol(),MODE_MINLOT);

   double Lot=AccountBalance()/lot001*0.01;
   Lot=(NormalizeDouble((Lot),2));

/*if(TotalNum>baseGridNum-1)
     {
      Lots=NormalizeDouble(Lot*MathPow(lotMutiple,TotalNum+1-baseGridNum),2);
     }
   else
     {
      Lots=Lot;
     }*/
   if(Lot<MinL){Lot=MinL;}
   if(Lot>MaxL){Lot=MaxL;}
   return Lot;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getLotsPlus(int lotsPer001,double baseGridNum,double lotMutiple,int magicmunber)
  {
   double re=0;

   double Lot=AccountBalance()/lotsPer001*0.01;
   Lot=(NormalizeDouble((Lot),2));

   int oc=getOrdersCount(999,magicmunber);

   if(oc>baseGridNum-1)
     {
      re=NormalizeDouble(Lot+lotMutiple*(oc+1-baseGridNum),2);
     }
   else
     {
      re=Lot;
     }
   return (re);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckMoneyForTrade(string symb,double lots,int type)
  {
   if(lots<=0) return false;
   double free_margin=AccountFreeMarginCheck(symb,type,lots);
//-- 如果资金不够
   if(free_margin<0)
     {
      Print("money not enough! errorno:",GetLastError());
      return(false);
     }
//--- 检验成功
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNewOrderAllowed()
  {
//--- 取得账户中允许设置的挂单数量
   int max_allowed_orders=(int)AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);

//--- 如果没有限制，返回 true; 您可以发送一个订单
   if(max_allowed_orders==0) return(true);

//--- 如果我们达到这一行，说明有限制; 找出已经设置了多少挂单
   int orders=OrdersTotal();

//--- 返回比较结果
   return(orders<max_allowed_orders);
  }
//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
double CheckVolumeValue(double volume)
  {
   double re=volume;
   string description="";

//--- get minimal step of volume changing
   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                               volume_step,ratio*volume_step);
      //Print(description);
      re=ratio*volume_step;
     }

//--- minimal allowed volume for trade operations
   double min_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(volume<min_volume)
     {
      description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      //Print(description);
      re=min_volume;
     }

//--- maximal allowed volume of trade operations
   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      //Print(description);
      re=max_volume;
     }

   re=NormalizeDouble(re,Digits);
   return(re);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Check_Takeprofit(int type,double _tp,double _sl)
  {
//--- get the SYMBOL_TRADE_STOPS_LEVEL level
   int stops_level=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   if(stops_level!=0)
     {
      //PrintFormat("SYMBOL_TRADE_STOPS_LEVEL=%d: StopLoss and TakeProfit must not be nearer than %d points from the closing price",stops_level,stops_level);
     }
//---
   bool SL_check=true,TP_check=true;
//--- check only two order types
   switch(type)
     {
      //--- Buy operation
      case  OP_BUY:
        {
         //--- check the TakeProfit
         if(_tp>0) TP_check = (_tp-Bid>stops_level*_Point);
         if(_sl>0) SL_check = (Bid-_sl>stops_level*_Point);
         //if(!TP_check)
         //PrintFormat("For order %s TakeProfit=%.5f must be greater than %.5f (Bid=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d points)",                        (type),TP,Bid+stops_level*_Point,Bid,stops_level);
         //--- return the result of checking
         return(TP_check && SL_check);
        }
      //--- Sell operation
      case  OP_SELL:
        {
         //--- check the TakeProfit
         if(_tp>0) TP_check=(Ask-_tp>stops_level*_Point);
         if(_sl>0) SL_check=(_sl-Ask>stops_level*_Point);
         //if(!TP_check)
         //PrintFormat("For order %s TakeProfit=%.5f must be less than %.5f (Ask=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d points)",                        (type),TP,Ask-stops_level*_Point,Ask,stops_level);
         //--- return the result of checking
         return(TP_check && SL_check);
        }
      break;
     }
//--- a slightly different function is required for pending orders
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool getTimeFilter(double gridSplitSec,int magicmunber)
  {

   bool re=TimeCurrent()-getLastOpenTime(magicmunber)>gridSplitSec;
   return re;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool getHistoryTimeFilter(double gridSplitHour,int magicmunber)
  {
   bool re=TimeCurrent()-getLastHistoryOpenTime(magicmunber)>gridSplitHour;

   return re;
  }
//+------------------------------------------------------------------+

double getProfit(int MagicNumber=0)
  {
   int cnt=0,cg;
   double myprofit=0;
   for(cnt=0;cnt<OrdersTotal();cnt++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      cg=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
        {
         myprofit+=OrderProfit();
        }
     }
   return myprofit;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getNextLine(int CMD=OP_BUY,int DynamicStepPip=30,int MagicNumber=0)
  {
   double price=0.0,nextp;
   double tmp=0.0;
   int total=OrdersTotal();
   int cnt;

   double myPoint=1;
   if(Digits==3 || Digits==5) myPoint=Point*10;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(CMD==OP_BUY)
     {
      price=10000;

      for(cnt=0;cnt<total;cnt++)
        {
         bool re=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY && OrderMagicNumber()==MagicNumber)
           {
            tmp=OrderOpenPrice();
            if(tmp<price)
              {
               price=tmp;
              }
           }
        }
      nextp=price-myPoint*DynamicStepPip;
     }
   else
     {
      price=0;
      for(cnt=0;cnt<total;cnt++)
        {
         bool ret=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELL && OrderMagicNumber()==MagicNumber)
           {
            tmp=OrderOpenPrice();
            if(tmp>price)
              {
               price=tmp;
              }
           }
        }
      nextp=price+myPoint*DynamicStepPip;
     }
   return nextp;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int openBuy(double lots,int magicmunber)
  {
   RefreshRates();
   lots=CheckVolumeValue(lots);
   if(lots==0) return 0;
   if(!IsNewOrderAllowed()) return 0;
   if(!CheckMoneyForTrade(Symbol(),lots,OP_BUY)) return 0;
   int ticket=OrderSend(Symbol(),OP_BUY,lots,Ask,3,0,0,"NinjaLoveFishTF/"+Symbol(),magicmunber,0,LimeGreen);
   if(ticket>0)
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice());
     }
   else
     {
      Print("Error opening BUY order : ",GetLastError());
     }
   return ticket;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int openBuyStop(double lots,double p,int magicmunber)
  {
   RefreshRates();
   lots=CheckVolumeValue(lots);
   if(lots==0) return 0;
   if(!IsNewOrderAllowed()) return 0;
   if(!CheckMoneyForTrade(Symbol(),lots,OP_BUY)) return 0;
   int ticket=OrderSend(Symbol(),OP_BUYSTOP,lots,p,3,0,0,"NinjaLoveFishBR/"+Symbol(),magicmunber,0,LimeGreen);
   if(ticket>0)
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice());
     }
   else
     {
      Print("Error opening BUY order : ",GetLastError());
     }
   return ticket;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int openBuy(double lots,int magicmunber,string comment)
  {
   RefreshRates();
   lots=CheckVolumeValue(lots);
   if(lots==0) return 0;
   if(!IsNewOrderAllowed()) return 0;
   if(!CheckMoneyForTrade(Symbol(),lots,OP_BUY)) return 0;
   int ticket=OrderSend(Symbol(),OP_BUY,lots,Ask,3,0,0,comment,magicmunber,0,LimeGreen);
   if(ticket>0)
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice()," "+comment);
     }
   else
     {
      Print("Error opening BUY order : ",GetLastError());
     }
   return ticket;
  }
//+------------------------------------------------------------------+
//|根据PIP计算后挂单。                                                                  |
//+------------------------------------------------------------------+
int openBuyLimit(double lots,int step,int magicmunber)
  {
   RefreshRates();
   lots=CheckVolumeValue(lots);
   if(lots==0) return 0;
   if(!IsNewOrderAllowed()) return 0;
   if(!CheckMoneyForTrade(Symbol(),lots,OP_BUY)) return 0;
   double myPoint=1;
   if(Digits==3 || Digits==5) myPoint=Point*10;
   double p=Bid-myPoint*step;

   int ticket=OrderSend(Symbol(),OP_BUYLIMIT,lots,p,3,0,0,"NinjaLoveFishTF/"+Symbol()+"|0",magicmunber,TimeCurrent()+48*60*60*3,LimeGreen);
   if(ticket>0)
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice());
     }
   else
     {
      Print("Error opening BUY order : ",GetLastError());
     }
   return ticket;
  }
//根据价格直接挂单  
int openBuyLimit2(double lots,double p,int magicmunber)
  {
   RefreshRates();
   lots=CheckVolumeValue(lots);
   if(lots==0) return 0;
   if(!IsNewOrderAllowed()) return 0;

   int ticket=OrderSend(Symbol(),OP_BUYLIMIT,lots,p,3,0,0,"NinjaLoveFishTF/"+Symbol()+"|0",magicmunber,TimeCurrent()+48*60*60*3,LimeGreen);
   if(ticket>0)
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice());
     }
   else
     {
      Print("Error opening BUY order : ",GetLastError());
     }
   return ticket;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int openSell(double lots,int magicmunber)
  {
   RefreshRates();
   lots=CheckVolumeValue(lots);
   if(lots==0) return 0;
   if(!IsNewOrderAllowed()) return 0;
   if(!CheckMoneyForTrade(Symbol(),lots,OP_SELL)) return 0;
   int ticket=OrderSend(Symbol(),OP_SELL,lots,Bid,3,0,0,"NinjaLoveFishTF/"+Symbol(),magicmunber,0,LimeGreen);
   if(ticket>0)
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELL order opened : ",OrderOpenPrice());
     }
   else
     {
      Print("Error opening SELL order : ",GetLastError());
     }
   return ticket;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int openSell(double lots,int magicmunber,string comment)
  {
   RefreshRates();
   lots=CheckVolumeValue(lots);
   if(lots==0) return 0;
   if(!IsNewOrderAllowed()) return 0;
   if(!CheckMoneyForTrade(Symbol(),lots,OP_SELL)) return 0;
   int ticket=OrderSend(Symbol(),OP_SELL,lots,Bid,3,0,0,comment,magicmunber,0,LimeGreen);
   if(ticket>0)
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELL order opened : ",OrderOpenPrice()," "+comment);
     }
   else
     {
      Print("Error opening SELL order : ",GetLastError());
     }
   return ticket;
  }
//+------------------------------------------------------------------+
//|根据PIP计算后挂单。                                                                  |
//+------------------------------------------------------------------+
int openSellLimit(double lots,int step,int magicmunber)
  {
   RefreshRates();
   lots=CheckVolumeValue(lots);
   if(lots==0) return 0;
   if(!IsNewOrderAllowed()) return 0;
   if(!CheckMoneyForTrade(Symbol(),lots,OP_SELL)) return 0;
   double myPoint=1;
   if(Digits==3 || Digits==5) myPoint=Point*10;
   double p=Ask+myPoint*step;

   int ticket=OrderSend(Symbol(),OP_SELLLIMIT,lots,p,3,0,0,"NinjaLoveFishTF/"+Symbol()+"|0",magicmunber,TimeCurrent()+24*60*60*3,LimeGreen);
   if(ticket>0)
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELL order opened : ",OrderOpenPrice());
     }
   else
     {
      Print("Error opening SELL order : ",GetLastError());
     }
   return ticket;
  }
//+------------------------------------------------------------------+
//|直接根据价格挂单。                                                                  |
//+------------------------------------------------------------------+
int openSellLimit2(double lots,double p,int magicmunber)
  {
   RefreshRates();
   lots=CheckVolumeValue(lots);
   if(lots==0) return 0;
   if(!IsNewOrderAllowed()) return 0;
   if(!CheckMoneyForTrade(Symbol(),lots,OP_SELL)) return 0;

   int ticket=OrderSend(Symbol(),OP_SELLLIMIT,lots,p,3,0,0,"NinjaLoveFishTF/"+Symbol()+"|0",magicmunber,TimeCurrent()+24*60*60*3,LimeGreen);
   if(ticket>0)
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELL order opened : ",OrderOpenPrice());
     }
   else
     {
      Print("Error opening SELL order : ",GetLastError());
     }
   return ticket;
  }
//+------------------------------------------------------------------+
// 修改订单根据PIP |
//+------------------------------------------------------------------+
void modify(int ticket,double _sl,double _tp)
  {
   if(_tp!=0) _tp=OrderOpenPrice()-10*_tp*Point;
   if(_sl!=0) _sl=OrderOpenPrice()+10*_sl*Point;
   int h=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   int re=OrderModify(ticket,OrderOpenPrice(),_sl,_tp,0,Green);
  }
//+------------------------------------------------------------------+
//|修改订单根据price                                                                  |
//+------------------------------------------------------------------+
void modifyByPrice(int ticket,double _sl,double _tp)
  {
   int h=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   int re=OrderModify(ticket,OrderOpenPrice(),_sl,_tp,0,Green);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void modifySL(double price,int MagicNumber)
  {
   if (price == 0) return;
   price=NormalizeDouble(price,Digits);
   for(int pos=OrdersTotal()-1; pos>=0; pos--)
     {
      if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES))
        {
         RefreshRates();
         string osy = OrderSymbol();
         int omn = OrderMagicNumber();
         double osl = OrderStopLoss();
         bool ck = Check_Takeprofit(OrderType(),OrderTakeProfit(),price);
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && price!=OrderStopLoss() && Check_Takeprofit(OrderType(),OrderTakeProfit(),price))
           {

            int re=OrderModify(OrderTicket(),OrderOpenPrice(),price,OrderTakeProfit(),0,0);
            
            if(!re)
              {
               Print("Error in modifySL.price=",price," Error code=",GetLastError());
              }
            else
              {
               Print("Order modifySL successfully.");
              }
           }

        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void modifyTP(double price,int MagicNumber)
  {
   price=NormalizeDouble(price,Digits);
   for(int pos=OrdersTotal()-1; pos>=0; pos--)
     {
      if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES))
        {
         RefreshRates();
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && price!=OrderTakeProfit() && Check_Takeprofit(OrderType(),price,OrderStopLoss()))
           {
            bool re=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),price,0,0);
            if(!re)
               Print("Error in modifyTP. Error code=",GetLastError());
            else
               Print(OrderComment()," modifyTP successfully.");
           }

        }
     }
  }
//判断是否存在TP值，如果不存在可能是由于Modify的时候未能成功，所以要用程序进一步判断是否止盈。
//如果有TP值，就返回True，如果没有返回False。  
bool hasTPValue(int MagicNumber)
  {
   bool h=true;
   for(int pos=OrdersTotal()-1; pos>=0; pos--)
     {
      if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderTakeProfit()==0)
           {
            h=false;
            break;
           }
        }
     }
   return h;
  }
//+------------------------------------------------------------------+
void dump(double d)
  {
   Print(EA+" :  ",d);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void dump(int d)
  {
   Print(EA+" :  ",d);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void dump(string avg)
  {
   Print(EA+" :  ",avg);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void dump(string str,string avg)
  {
   Print(EA+" :  ",str," , ",avg);
  }
//+------------------------------------------------------------------+

double getPipValue(double pips,double lot)
  {
   double myPoint;
   if(Digits==3 || Digits==5) myPoint=Point*10;

   string sy= Symbol();
   double x = 0,re=0;

   if(sy=="AUDCAD") x=7.94;
   if(sy=="AUDCHF") x=10.38;
   if(sy=="AUDJPY") x=9.30;
   if(sy=="AUDNZD") x=7.38;
   if(sy=="AUDUSD") x=10.00;
   if(sy=="CADJPY") x=9.30;
   if(sy=="CHFJPY") x=9.30;
   if(sy=="EURAUD") x=7.78;
   if(sy=="EURCAD") x=7.94;
   if(sy=="EURCHF") x=10.38;
   if(sy=="EURGBP") x=14.22;
   if(sy=="EURJPY") x=9.30;
   if(sy=="EURNZD") x=7.38;
   if(sy=="EURUSD") x=10.00;
   if(sy=="GBPAUD") x=7.78;
   if(sy=="GBPCAD") x=7.94;
   if(sy=="GBPCHF") x=10.38;
   if(sy=="GBPJPY") x=9.30;
   if(sy=="GBPNZD") x=7.38;
   if(sy=="GBPUSD") x=10.00;
   if(sy=="NZDJPY") x=9.30;
   if(sy=="NZDUSD") x=10.00;
   if(sy=="USDBRL") x=2.93;
   if(sy=="USDCAD") x=7.94;
   if(sy=="USDCHF") x=10.38;
   if(sy=="USDCNY") x=1.59;
   if(sy=="USDINR") x=0.15;
   if(sy=="USDJPY") x=9.30;
   if(sy=="USDRUB") x=0.16;
   if(sy=="USDTRY") x=2.44;
   if(sy=="XAUUSD"|| sy=="GLOD") x=10;

   re = pips*lot*x;
   re = NormalizeDouble(re,2);
   return re;
  }
//+------------------------------------------------------------------+

double ZigZagPrice(int ne=0)
  {
   double zz;
   int ke=0;
   for(int m=0; m<iBars(Symbol(),PERIOD_M15); m++)
     {
      zz=iCustom(Symbol(),0,"ZigZag",12,5,3,0,m);
      if(zz!=0)
        {
         ke++;
         if(ke>ne)
           {
            return(zz);
           }
        }
     }
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ZigZagPrice(string sy,int tf,int ne=0)
  {
   double zz;
   int k=iBars(sy,tf),ke=0;
   for(int m=0; m<k; m++)
     {
      zz=iCustom(sy,tf,"ZigZag",12,5,3,0,m);
      if(zz!=0)
        {
         ke++;
         if(ke>ne)
           {
            Print("zz::::::::::",zz);
            return(zz);
           }
        }
     }
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double RzigZagDistancePoint(ENUM_TIMEFRAMES timef,int zBars,string loworhigh)
  {
   double zz=0;
   int ll=iLowest(Symbol(),timef,MODE_LOW,zBars,1);
   int hh=iHighest(Symbol(),timef,MODE_HIGH,zBars,1);

   if(hh ==-1 || ll ==-1) return 0;

   double llpip = MathAbs(Low[ll]-Ask)/Point;
   double hhpip = MathAbs(High[hh]-Bid)/Point;

   if(loworhigh=="sell")
     {
      return llpip;
     }
   if(loworhigh=="buy")
     {
      //dump(hhpip);
      return hhpip;
     }

   return zz;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckRzzBreakOut(int tbars,double pdis,int magic)
  {
   bool zz=false;
   bool tmpbar=getFirstOpenBar(magic)<tbars;
   double priceb=getFirstOpenPrice(magic);
   bool tmpp=MathAbs(Bid-priceb)/Point>pdis;

   if(tmpbar)
     {
      setLine("SL1",priceb-pdis*Point,clrAliceBlue,2);
      setLine("SL2",priceb+pdis*Point,clrRed,2);
     }
   else
     {
      deleteObjects("SL1");
      deleteObjects("SL2");
     }

   if(tmpbar && tmpp)
     {
      zz=true;
     }

   return zz;
  }
//===================================================================================================================================================
//===================================================================================================================================================
int CountOfOrders(int mNumber)
  {
   int count=0;
   for(int k=0; k<OrdersTotal(); k++)
      if(OrderSelect(k,SELECT_BY_POS,MODE_TRADES))
         if((OrderSymbol()==Symbol()) && (OrderMagicNumber()==mNumber))
            if((OrderType()==OP_SELL) || (OrderType()==OP_BUY))
               count++;

   return(count);
  }
//===================================================================================================================================================
//===================================================================================================================================================
int CountOfOrders()//计算总单量，判断总单量小于StopOpenNewPair的时候用到的。
  {
   int count=0;
   for(int k=0; k<OrdersTotal(); k++)
      if(OrderSelect(k,SELECT_BY_POS,MODE_TRADES))
         if((OrderType()==OP_SELL) || (OrderType()==OP_BUY))
            count++;
   return(count);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckDebug()
  {
#ifdef __DEBUG__
   return true;
#else 
   return false;
#endif 
//return IsTesting() || IsOptimization();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckTest()
  {
   return IsTesting() || IsOptimization();
  }

//判断是否为新bar，在1分钟的图表中。
datetime tmptime=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   bool re=false;
   ENUM_TIMEFRAMES tm=PERIOD_M1;
   if(CheckTest()) tm=PERIOD_M5;

   if(tmptime!=iTime(Symbol(),tm,0))
     {
      tmptime=iTime(Symbol(),tm,0);
      re=true;
     }
   return re;
  }
//--------------------------------------------------------
// Function: Time Of trade
//--------------------------------------------------------
bool CheckTime(string StartHour,string StopHour)
  {
//------------------------------------------------------------------
   bool AllowTrade=true;
//------------------------------------------------------------------
   if(StartHour<StopHour)
     {
      bool h1 = TimeToStr(TimeCurrent(),TIME_MINUTES)<StartHour;
      bool h2 =  TimeToStr(TimeCurrent(),TIME_MINUTES)>StopHour;
      if(h1 || h2)
         AllowTrade=false;
     }
   else
     {
      dump("TimeStart must less than TimeEnd");
     }
   return (AllowTrade);
//------------------------------------------------------------------
  }
//+------------------------------------------------------------------+

string Offset(datetime dt)
  {
   int tmp=TimeHour(dt)-TimeHour(TimeGMT());
   if(tmp<0) tmp=tmp+24;
   return IntegerToString(tmp);
  }
//+------------------------------------------------------------------+
//计算当前的滑点是否小于传入的滑点。
bool CheckSpread(double point)
  {
   return (int)MarketInfo(Symbol(),MODE_SPREAD)<point;
  }
//+------------------------------------------------------------------+

// Make a screenshoot / printscreen
void screenshot(string par_sx="")
  {
   static int local_no=0;
   local_no++;
   string fn="SnapShot"+Symbol()+DoubleToStr(Period())+"\\"+IntegerToString(Year())+"-"+timestring(Month(),2)+"-"+timestring(Day(),2)+" "+timestring(Hour(),2)+"_"+timestring(Minute(),2)+"_"+timestring(Seconds(),2)+" "+IntegerToString(local_no)+par_sx+".gif";
   if(!ScreenShot(fn,640,480))
     {
      Print("ScreenShot error: ",GetLastError());
     }
   else
     {
      dump("The Screenshoot has been saved in '\\MQL4\\Files\\' folder. ");
     }
  }
// add leading zeros that the resulting string has 'digits' length.
string timestring(int par_number,int par_digits)
  {
   string local_result;

   local_result=DoubleToStr(par_number,0);
   while(StringLen(local_result)<par_digits)
      local_result="0"+local_result;

   return (local_result);
  }
//+------------------------------------------------------------------+

double IIFd(bool condition,double ifTrue,double ifFalse)
  {
   if(condition) return(ifTrue); else return(ifFalse);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string IIFs(bool condition,string ifTrue,string ifFalse)
  {
   if(condition) return(ifTrue); else return(ifFalse);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
color IIFc(bool condition,color ifTrue,color ifFalse)
  {
   if(condition) return(ifTrue); else return(ifFalse);
  }
//+------------------------------------------------------------------+
bool RectangleCreate(const long            chart_ID=0,        // chart's ID 
                     const string          name="Rectangle",  // rectangle name 
                     const int             sub_window=0,      // subwindow index  
                     datetime              time1=0,           // first point time 
                     double                price1=0,          // first point price 
                     datetime              time2=0,           // second point time 
                     double                price2=0,          // second point price 
                     const color           clr=clrRed,        // rectangle color 
                     const ENUM_LINE_STYLE style=STYLE_SOLID, // style of rectangle lines 
                     const int             width=1,           // width of rectangle lines 
                     const bool            fill=false,        // filling rectangle with color 
                     const bool            back=false,        // in the background 
                     const bool            selection=true,    // highlight to move 
                     const bool            hidden=true,       // hidden in the object list 
                     const long            z_order=0)         // priority for mouse click 
  {
//--- set anchor points' coordinates if they are not set 
   ChangeRectangleEmptyPoints(time1,price1,time2,price2);
//--- reset the error value 
   ResetLastError();
//--- create a rectangle by the given coordinates 
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE,sub_window,0,0,30,30))
     {
      Print(__FUNCTION__,
            ": failed to create a rectangle! Error code = ",GetLastError());
      return(false);
     }
//--- set rectangle color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set the style of rectangle lines 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set width of the rectangle lines 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of highlighting the rectangle for moving 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Inside this method, selection parameter 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeRectangleEmptyPoints(datetime &time1,double &price1,
                                datetime &time2,double &price2)
  {
//--- if the first point's time is not set, it will be on the current bar 
   if(!time1)
      time1=TimeCurrent();
//--- if the first point's price is not set, it will have Bid value 
   if(!price1)
      price1=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- if the second point's time is not set, it is located 9 bars left from the second one 
   if(!time2)
     {
      //--- array for receiving the open time of the last 10 bars 
      datetime temp[10];
      CopyTime(Symbol(),Period(),time1,10,temp);
      //--- set the second point 9 bars left from the first one 
      time2=temp[0];
     }
//--- if the second point's price is not set, move it 300 points lower than the first one 
   if(!price2)
      price2=price1-300*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
  }
//+------------------------------------------------------------------+
