\l ws-client_0.2.2.q;

/ TP_PORT:first "J"$getenv`TP_PORT;
/ h:@[hopen;(`$":localhost:",string TP_PORT;10000);0i];
h:@[hopen;(`$":localhost:5000";10000);0i];
pub:{$[h=0;
        neg[h](`upd   ;x;y);
        neg[h](`.u.upd;x;value flip y)
        ]};

upd:upsert;

//initialise displaying tables
order: ([]`s#time:"n"$();`g#sym:`$();orderID:();side:`$();price:"f"$();size:"f"$();action:`$();orderType:`$();exchange:`$());
book: ([]`s#time:"n"$();`g#sym:`$();bids:();bidsizes:();asks:();asksizes:());
lastBookBySym:enlist[`]!enlist `bidbook`askbook!(()!();()!());
trade: ([]`s#time:"n"$();`g#sym:`$();orderID:();price:"f"$();tradeID:();side:`$();size:"f"$();exchange:`$());
connChkTbl:([]exchange:`$();`s#time:"p"$();feed:`$();rowCount:"j"$());

BuySellDict:("Buy";"Sell";"buy";"sell")!(`bid;`ask;`bid;`ask);
coinbaseTypeDict:("received";"match";"open";"done")!(`insert;`insert;`update;`remove);

gdaExchgTopic:([]
    topic:(`bitfinex;`bybit;`coinbase);
    symbol:`BTCUSDT`BTCUSD`BTCUSD);

//create the ws subscription table
hostsToConnect:([]hostQuery:();request:();exchange:`$();feed:`$();callbackFunc:());
//add all exchanges from gda
`hostsToConnect upsert {("ws://194.233.73.248:30205/";`op`exchange`feed!("subscribe";x;"normalised");x;`order;`.gdaNormalised.updExchg)}each exec topic from gdaExchgTopic;
`hostsToConnect upsert {("ws://194.233.73.248:30205/";`op`exchange`feed!("subscribe";x;"trades");x;`trade;`.gdaTrades.updExchg)}each exec topic from gdaExchgTopic;

//add record ID
hostsToConnect: update ws:1+til count i from hostsToConnect;
hostsToConnect:update callbackFunc:{` sv x} each `$string(callbackFunc,'ws) from hostsToConnect where callbackFunc like "*gda*";

bookbuilder:{[x;y]
    .debug.xy:(x;y);
    $[not y 0;x;
        $[
            `insert=y 4;
                x,enlist[y 1]! enlist y 2 3;
            `update=y 4;
                $[any (y 1) in key x;
                    [
                        //update size
                        a:.[x;(y 1;1);:;y 3];
                        //update price if the price col is not null
                        $[0n<>y 2;.[a;(y 1;0);:;y 2];a]
                    ];
                    x,enlist[y 1]! enlist y 2 3
                ];  
            `remove=y 4;
                $[any (y 1) in key x;
                    enlist[y 1] _ x;
                    x];
            x
        ]
    ]
    };

generateOrderbook:{[newOrder]
    .debug.newOrder:newOrder;

    //create the books based on the last book state
    books:update bidbook:bookbuilder\[lastBookBySym[first sym]`bidbook;flip (side like "bid";orderID;price;size;action)],askbook:bookbuilder\[lastBookBySym[first sym]`askbook;flip (side like "ask";orderID;price;size;action)] by sym from newOrder;

    //store the latest book state
    .debug.books1:books;
    lastBookBySym,:exec last bidbook,last askbook by sym from books;

    //generate the orderbook 
    books:select time,sym,bids:(value each bidbook)[;;0],bidsizes:(value each bidbook)[;;1],asks:(value each askbook)[;;0],asksizes:(value each askbook)[;;1] from books;
    books:update bids:desc each distinct each bids,bidsizes:{sum each x group y}'[bidsizes;bids] @' desc each distinct each bids,asks:asc each distinct each asks,asksizes:{sum each x group y}'[asksizes;asks] @' asc each distinct each asks from books

    };

//GDA orderbooks callback function 
.gdaNormalised.upd:{[incoming]
    d:.j.k incoming;.debug.gda.d:d; //0N!d;
    /.debug.ordExchange:exchange;
    
    //capture the subscription sym
    if[`event`topic~key d;
        .debug.sub:d;
        .gdaNormalised.exchange: `$first "-" vs d[`topic];
        .gdaNormalised.subSym:first exec symbol from gdaExchgTopic where topic=.gdaNormalised.exchange;
        :()
    ];

    //coinbase raw
    size:"F"$$[any ("open";"done") like d[`type];d[`remaining_size];d[`size]];
    
    //Action Mapping 
    //received, match (action:insert) - A valid order has been received and is now active
    //open (action:update) - The order is now open on the order book. This message is only sent for orders that are not fully filled immediately 
    //done (action:remove)- The order is no longer on the order book (reason: filled or cancelled) 
    action:coinbaseTypeDict d[`type];

    //modify the action to `update if the size>0 (size indicates how much of the order went unfilled; this is 0 for filled orders)
    if[("filled" like d[`reason]) and size>0;action:`update];
    
    //publish to TP - order table
    newOrder:("N"$-1_("T" vs d[`time])[1];.gdaNormalised.subSym;d[`order_id];BuySellDict[d`side];"F"$d[`price];size;action;$[0<count d[`order_type];`$d[`order_type];`unknown];.gdaNormalised.exchange);
    pub[`order;newOrder];

    neworderTbl: enlist(cols order)!newOrder;
    .debug.gda.order:neworderTbl;
    
    //generate orderbook based on the order transactions
    books:generateOrderbook[neworderTbl];
    .debug.gda.books2:books;

    //publish to TP - book
    pub[`book;books];
    };

/ //GDA trades callback function 
/ .gdaTrades.upd:{[incoming]
/     d:.j.k incoming;.debug.gda.dt:d; //0N!d;
/     /.debug.trdExchange:exchange;

/     //capture the subscription sym
/     if[`event`topic~key d;
/         .debug.subt:d;
/         .gdaTrades.exchange: `$first "-" vs d[`topic];
/         .gdaTrades.subSym:first exec symbol from gdaExchgTopic where topic=.gdaTrades.exchange;
/         :()
/     ];

/     colVal: value d;
/     newTrade:();

/     if[10h~type d[`timestamp];
/         /coinbase
/         newTrade: (("N"$(last "T" vs colVal[3])[til 15]);.gdaTrades.subSym;($[10h<>type colVal[0];string "j"$colVal[0];colVal[0]]);colVal[1];($[10h<>type colVal[2];string "j"$colVal[2];colVal[2]]);sideDict colVal[4];colVal[5];exchange)
/     ];
 
/     if[-9h~type d[`timestamp];   
/         /bitfinex,bybit,ftx,huobi,kraken,dydx
/         //convert currentTimeMillis to timestamp
/         f:{`datetime$(x%(prd 24 60 60 1000j))-(0-1970.01.01)};
/         newTrade: ($[(t<.z.p-1D) or .z.p<t:"p"$f colVal[3];.z.n;"n"$t];.gdaTrades.subSym;($[10h<>type colVal[0];string "j"$colVal[0];colVal[0]]);colVal[1];($[10h<>type colVal[2];string "j"$colVal[2];colVal[2]]);sideDict colVal[4];colVal[5];exchange)
/     ];

/     .debug.gda.trade:newTrade;

/     //publish the trades table
/     pub[`trade;newTrade];
/     };


/ //establish the ws connection
/ establishWS:{
/     .debug.x:x;
/     hostQuery:x[`hostQuery];
/     request:x[`request];
/     callbackFunc:x[`callbackFunc];

/     //pass the exchange value to the gda upd func
/     if[request[`feed] like "normalised";
/         callbackFunc set .gdaNormalised.upd[;request[`exchange]]
/     ];

/     if[request[`feed] like "trades";
/         callbackFunc set .gdaTrades.upd[;request[`exchange]]
/     ];

/     currentExchange:$[`op`exchange`feed~key request;string request[`exchange];string (` vs callbackFunc)[1]];
/     currentFeed:$[`op`exchange`feed~key request;request[`feed];$["" like request[`channel];request[`args];request[`channel]]];

/     //connect to the websocket
/     0N!"Connecting the ",currentExchange," ",currentFeed," websocket at ",string .z.z;
/     handle: `$".ws.h",string x[`ws];
/     handle set .ws.open[hostQuery;callbackFunc];

/     //send request to the websocket
/     if[0<count request; (get handle) .j.j request];
/     0N!currentExchange," ",currentFeed," websocket is connected at ",string .z.z;
/     };

/ //open the websocket and check the connection status 
/ connectionCheck:{[]
/     0N!"Checking the websocket connection status"; 
/     upsert[`connChkTbl;(0!select time:.z.p,feed:`order,rowCount:count i by exchange from order)];
/     upsert[`connChkTbl;(0!select time:.z.p,feed:`trade,rowCount:count i by exchange from trade)];

/     //check the gdaOrder and gdaTrades tables count by 10 mins time bucket 
/     temp:select secondLastCount:{x[-2+count x]}rowCount,lastCount:last rowCount by timeBucket:10 xbar time.minute,feed,exchange from connChkTbl;
/     recordchk:update diff:lastCount-secondLastCount from select last secondLastCount, last lastCount by feed,exchange from temp;
/     reconnectList:select from recordchk where diff = 0;

/     if[0<count reconnectList;
/         feedList: exec feed from reconnectList;
/         exchangeList: exec exchange from reconnectList;
/         hostToReconnect:select from hostsToConnect where feed in feedList,exchange in exchangeList;
/         {0N!x[0]," ",x[1]," WS Not connected!.. Reconnecting at ",string .z.z}each string (exec exchange from hostToReconnect),'(exec feed from hostToReconnect);
/         establishWS each hostToReconnect
/     ];
    
/     if[0~count reconnectList;
/         0N!"Websocket connections are all secure"
/     ];
/     };

/ //connect to the websockets
/ establishWS each hostsToConnect;
 
/ //connection check every 10 min
/ .z.ts:{connectionCheck[]};
/ \t 600000


//test
//establish the normalised order ws connection
establishNormalisedWS:{[]
    0N!"Connecting the GDA normalised order websocket at ",string .z.z;
    .gdaNormalised.h:.ws.open["ws://194.233.73.248:30205/";`.gdaNormalised.upd];
    .gdaNormalised.h .j.j `op`exchange`feed!("subscribe";"coinbase";"raw");
    0N!"GDA normalised order websocket is connected at ",string .z.z;
    };

establishNormalisedWS[];
