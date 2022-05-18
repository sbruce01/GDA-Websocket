\l ws-client_0.2.2.q
/conda install -c jmcmurray ws-client ws-server
/.utl.require"ws-client";

h:@[hopen;(`$":localhost:5000";10000);0i];
pub:{$[h=0;
        neg[h](`upd   ;x;y);
        $[0h~type y;neg[h](`.u.upd;x;y);neg[h](`.u.upd;x;value flip y)]
        ]};

upd:upsert;

//initialise displaying tables
order: ([]`s#time:"n"$();`g#sym:`$();orderID:();side:`$();price:"f"$();size:"f"$();action:`$();orderType:`$();exchange:`$());
trade: ([]`s#time:"n"$();`g#sym:`$();orderID:();price:"f"$();tradeID:();side:`$();size:"f"$();exchange:`$());
connChkTbl:([]exchange:`$();`s#time:"p"$();feed:`$();rowCount:"j"$());

BuySellDict:("Buy";"Sell")!(`bid;`ask);
sideDict:0 1 2f!`unknown`bid`ask;
actionDict:0 1 2 3 4f!`unknown`skip`insert`remove`update;
orderTypeDict:0 1 2f!`unknown`limitOrder`marketOrder;
gdaExchgTopic:([]
    topic:(`bitfinex;`bybit;`coinbase);
    symbol:`BTCUSD`BTCUSD`BTCUSD);

//create the ws subscription table
hostsToConnect:([]hostQuery:();request:();exchange:`$();feed:`$();callbackFunc:());
//add all exchanges from gda
`hostsToConnect upsert {("ws://194.233.73.248:30205/";`op`exchange`feed!("subscribe";x;"normalised");x;`order;`.gdaNormalised.updExchg)}each exec topic from gdaExchgTopic;
`hostsToConnect upsert {("ws://194.233.73.248:30205/";`op`exchange`feed!("subscribe";x;"trades");x;`trade;`.gdaTrades.updExchg)}each exec topic from gdaExchgTopic;

//add record ID
hostsToConnect: update ws:1+til count i from hostsToConnect;
hostsToConnect:update callbackFunc:{` sv x} each `$string(callbackFunc,'ws) from hostsToConnect where callbackFunc like "*gda*";

//GDA orderbooks callback function 
.gdaNormalised.upd:{[incoming;exchange]
    d:.j.k incoming;.debug.gda.d:d; //0N!d;
    .debug.ordExchange:exchange;
    
    //capture the subscription sym
    if[`event`topic~key d;
        .debug.sub:d;
        .gdaNormalised.exchange: `$first "-" vs d[`topic];
        .gdaNormalised.subSym:first exec symbol from gdaExchgTopic where topic=.gdaNormalised.exchange;
        :()
    ];
    
    colVal: value d;
    
    //check the orderID data type, convert it to string if it's an int orderID
    orderIdCol:$[10h<>type colVal[2];string "j"$colVal[2];colVal[2]];
    
    //publish to TP - order table
    newOrder:(.z.n;.gdaNormalised.subSym;orderIdCol;sideDict colVal[4];colVal[5];colVal[6];actionDict colVal[7];orderTypeDict colVal[11];exchange);
    .debug.newOrder:newOrder;
    pub[`order;newOrder];
    };

//GDA trades callback function 
.gdaTrades.upd:{[incoming;exchange]
    d:.j.k incoming;.debug.gda.dt:d; //0N!d;
    .debug.trdExchange:exchange;

    //capture the subscription sym
    if[`event`topic~key d;
        .debug.subt:d;
        .gdaTrades.exchange: `$first "-" vs d[`topic];
        .gdaTrades.subSym:first exec symbol from gdaExchgTopic where topic=.gdaTrades.exchange;
        :()
    ];

    colVal: value d;
    newTrade: (.z.n;.gdaTrades.subSym;($[10h<>type colVal[0];string "j"$colVal[0];colVal[0]]);colVal[1];($[10h<>type colVal[2];string "j"$colVal[2];colVal[2]]);sideDict colVal[4];colVal[5];exchange);  
    .debug.gda.trade:newTrade;

    //publish to TP - trade table
    pub[`trade;newTrade];
    };

//establish the ws connection
establishWS:{
    .debug.x:x;
    hostQuery:x[`hostQuery];
    request:x[`request];
    callbackFunc:x[`callbackFunc];

    //pass the exchange value to the gda upd func
    if[request[`feed] like "normalised";
        callbackFunc set .gdaNormalised.upd[;request[`exchange]]
    ];

    if[request[`feed] like "trades";
        callbackFunc set .gdaTrades.upd[;request[`exchange]]
    ];

    currentExchange:$[`op`exchange`feed~key request;string request[`exchange];string (` vs callbackFunc)[1]];
    currentFeed:$[`op`exchange`feed~key request;request[`feed];$["" like request[`channel];request[`args];request[`channel]]];

    //connect to the websocket
    0N!"Connecting the ",currentExchange," ",currentFeed," websocket at ",string .z.z;
    handle: `$".ws.h",string x[`ws];
    handle set .ws.open[hostQuery;callbackFunc];

    //send request to the websocket
    if[0<count request; (get handle) .j.j request];
    0N!currentExchange," ",currentFeed," websocket is connected at ",string .z.z;
    };

//connect to the websockets
establishWS each hostsToConnect;

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

 
/ //connection check every 10 min
/ .z.ts:{connectionCheck[]};
/ \t 600000
