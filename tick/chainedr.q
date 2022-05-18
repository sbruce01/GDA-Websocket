/ no dayend except 0#, can connect to tick.q or chainedtick.q tickerplant
/ q chainedr.q :5110 -p 5111 </dev/null >foo 2>&1 & 

/ q tick/chainedr.q [host]:port[:usr:pwd] [-p 5111] 

if[not "w"=first string .z.o;system "sleep 1"]

if[not system"p";system"p 5112"]

.agg.mapping:`trade`order!`.trade.agg`.order.agg;

.trade.agg:{
    vwaps:select accVol:sum size, vwap:size wavg price, trades:count i by sym, 1 xbar time.minute from trade where sym = `BTCUSDT; // vwap based on trimmed data
    tab:update 0f^vwap, 0^accVol from (select latestVwap:size wavg price, latestAccVol: sum size by sym, time.minute from x where sym = `BTCUSDT) lj vwaps;
    :select sym, minute, vwap:((accVol*vwap)+(latestAccVol*latestVwap))%(accVol+latestAccVol),accVol:(latestAccVol) from tab
 };

.order.agg:{0N!"Calling Order Agg";0N!x};

upd:{0N!(x;y);
    x insert y; //insert incoming data
    delete from x where time < .z.n-0D00:11:00.00000000;    // trim data to save on memory
    aggregation:.agg.mapping[x];
    .my.res:@[aggregation;y];
    }

/ get the chained ticker plant port, default is 5110
.u.x:.z.x,(count .z.x)_enlist":5000"

/ end of day: clear ONLY
.u.end:{@[`.;.q.tables`.;@[;`sym;`g#]0#];}

/ init schema and sync up from log file
.u.rep:{(.[;();:;].)each x;if[null first y;:()];-11!y;}

/ connect to tickerplant or chained ticker plant for (schema;(logcount;log))
.u.rep .(hopen`$":",.u.x 0)"(.u.sub[`;`];$[`m in key`.u;(`.u `m)\"`.u `i`L\";`.u `i`L])"
