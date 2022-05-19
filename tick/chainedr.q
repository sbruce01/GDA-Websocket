/ no dayend except 0#, can connect to tick.q or chainedtick.q tickerplant
/ q chainedr.q :5110 -p 5111 </dev/null >foo 2>&1 & 

/ q tick/chainedr.q [host]:port[:usr:pwd] [-p 5111] 

if[not "w"=first string .z.o;system "sleep 1"]

if[not system"p";system"p 5112"]

.agg.mapping:{x!y} . flip (
    (`trade;(`.trade.vwap`.trade.ohlcv));
    (`order;(enlist `.order.agg)));

 upd:{0N!(x;y);
// why are lists arriving? Only xpect tables from the TP.
    if[0=type y;0N!"SENT AS LIST";:()]
    x insert y; //insert incoming data
    delete from x where time < .z.n-0D00:11:00.00000000;    // trim data to save on memory
    .agg.mapping[x] @\: y
    }

//Why is binance the only trade exchange?
.trade.vwap:{
    .my.x:x;
    0N!x;
    tab:update 0f^vwap, 0f^accVol from vwap uj select latestVwap:size wavg price, latestAccVol: sum size by sym, time.minute, exchange from x;
    res:select sym, minute, exchange, vwap:((accVol*vwap)+(latestAccVol*latestVwap))%(accVol+latestAccVol),accVol:(latestAccVol) from tab;
    //update the vwaps table
    `vwap upsert res;
  //publish the result
    if[count to_send:select from vwap where 2 < (count;i) fby ([]sym;exchange),not i = (last;i) fby ([]sym;exchange);
        .u.pub[`vwap;0!to_send];
        delete from `vwap where  2 < (count;i) fby ([]sym;exchange),not i = (last;i) fby ([]sym;exchange)
    ];
 }

.trade.ohlcv:{
    .debug.ohlcv:x;
    tab2:update 0N^open, 0f^high, 0N^low, 0f^close, 0f^volume from (select latestOpen:first price, latestHigh:max price, latestLow:min price, latestClose:last price, latestVolume:sum size by sym,time.minute, exchange from x) lj ohlcv;
    //res2:select sym, minute, open, high, low, close from tab2;
    res2:select sym, minute, exchange, open: first latestOpen, high: max (latestHigh;high), low:min(0w ^latestLow;0w ^ low), close:latestClose, volume: sum(volume;latestVolume) from tab2;
    //res:select sym, minute, vwap:((accVol*vwap)+(latestAccVol*latestVwap))%(accVol+latestAccVol),accVol:(latestAccVol) from tab;
    //update the vwaps table
    `ohlcv upsert res2;
 
  //publish the result
    if[count to_send:select from ohlcv where not i = (last;i) fby ([]sym;exchange);
        .u.pub[`ohlcv;0!to_send];
        delete from `ohlcv where not i = (last;i) fby ([]sym;exchange)
    ];
  } 

.order.agg:{0N!"Calling Order Agg";0N!.debug.x:x};



/ get the chained ticker plant port, default is 5110
.u.x:.z.x,(count .z.x)_enlist":5000"
tph:hopen`$":",.u.x 0
.u.pub:{[t;x] neg[tph](`.u.upd;t;value flip x)}

/ end of day: clear ONLY
.u.end:{@[`.;.q.tables`.;@[;`sym;`g#]0#];}

/ init schema and sync up from log file
.u.rep:{(.[;();:;].)each x;if[null first y;:()];-11!y;}

/ connect to tickerplant or chained ticker plant for (schema;(logcount;log))
tp_data:(hopen`$":",.u.x 0)"(.u.sub[`;`];$[`m in key`.u;(`.u `m)\"`.u `i`L\";`.u `i`L])"
{(.[;();:;].)each x} tp_data 0
vwap:`sym`minute`exchange xkey vwap
ohlcv:`sym`minute`exchange xkey ohlcv
{if[null first x;:()];-11!x;} tp_data 1
