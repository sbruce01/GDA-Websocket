\l ./websocket/ws-client_0.2.2.q
/conda install -c jmcmurray ws-client ws-server
/.utl.require"ws-client";

h:@[hopen;(`$":localhost:5000";10000);0i];
pub:{$[h=0;
        neg[h](`upd   ;x;y);
        $[0h~type y;neg[h](`.u.upd;x;y);neg[h](`.u.upd;x;value flip y)]
        ]};

upd:upsert;

//initialise displaying tables
order: ([]`s#time:"p"$();`g#sym:`$();orderID:();side:`$();price:"f"$();size:"f"$();action:`$();orderType:`$();exchange:`$());
trade: ([]`s#time:"p"$();`g#sym:`$();orderID:();price:"f"$();tradeID:();side:`$();size:"f"$();exchange:`$());
connChkTbl:([exchange:`$();feed:`$()]`s#time:"p"$());

BuySellDict:("Buy";"Sell")!(`bid;`ask);
sideDict:0 1 2f!`unknown`bid`ask;
actionDict:0 1 2 3 4f!`unknown`skip`insert`remove`update;
orderTypeDict:0 1 2f!`unknown`limitOrder`marketOrder;
bitmexSymbolDict:(enlist"XBTUSD")!enlist("BTCUSD");
gdaExchgTopic:([]
    topic:(`binance;`bybit;`coinbase);
    symbol:`BTCUSDT`BTCUSD`BTCUSD);

//create the ws subscription table
hostsToConnect:([]hostQuery:();request:();exchange:`$();feed:`$();callbackFunc:());
//add all exchanges from gda
`hostsToConnect upsert {("ws://194.233.73.248:30205/";`op`exchange`feed!("subscribe";x;"normalised");x;`order;`.gdaNormalised.updExchg)}each exec topic from gdaExchgTopic;
`hostsToConnect upsert {("ws://194.233.73.248:30205/";`op`exchange`feed!("subscribe";x;"trades");x;`trade;`.gdaTrades.updExchg)}each exec topic from gdaExchgTopic;
//add BitMEX websocket 
/`hostsToConnect upsert("wss://ws.bitmex.com/realtime";`op`args!("subscribe";"trade:XBTUSD");`bitmex;`trade;`.bitmex.upd);
//add record ID
hostsToConnect:update ws:1+til count i from hostsToConnect;
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

    //set the receive timestamp as the time if the event timestamp is empty
    d[`event_timestamp]: $[-1f~colVal[8];colVal[10];colVal[8]];
    
    //check the orderID data type, convert it to string if it's an int orderID
    orderIdCol:$[10h<>type colVal[2];string "j"$colVal[2];colVal[2]];
    
    if[10h~type d[`event_timestamp];
        /coinbase
        newOrder:("p"$"Z"$d[`event_timestamp];.gdaNormalised.subSym;orderIdCol;sideDict colVal[4];colVal[5];colVal[6];actionDict colVal[7];orderTypeDict colVal[11];exchange)
    ];

    if[-9h~type d[`event_timestamp];   
        /bitfinex,bybit,ftx,huobi,kraken
        /convert currentTimeMillis to timestamp
        f:{`datetime$(x%(prd 24 60 60 1000j))-(0-1970.01.01)};
        newOrder:($[1D<abs .z.p - t:("p"$f d[`event_timestamp]);.z.p;t];.gdaNormalised.subSym;orderIdCol;sideDict colVal[4];colVal[5];colVal[6];actionDict colVal[7];orderTypeDict colVal[11];exchange)
    ];

    //publish to TP - order table
    .debug.newOrder:newOrder;
    pub[`order;newOrder];

    //update record in the connection check table
    upsert[`connChkTbl;(exchange;`order;.z.p)];
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

    if[10h~type d[`timestamp];
        /coinbase
        newTrade: ("p"$"Z"$d[`event_timestamp];.gdaTrades.subSym;($[10h<>type colVal[0];string "j"$colVal[0];colVal[0]]);colVal[1];($[10h<>type colVal[2];string "j"$colVal[2];colVal[2]]);sideDict colVal[4];colVal[5];exchange)
    ];
 
    if[-9h~type d[`timestamp];   
        /bitfinex,bybit,ftx,huobi,kraken,dydx
        //convert currentTimeMillis to timestamp
        f:{`datetime$(x%(prd 24 60 60 1000j))-(0-1970.01.01)};
        newTrade: ($[1D<abs .z.p - t:"p"$f colVal[3];.z.p;t];.gdaTrades.subSym;($[10h<>type colVal[0];string "j"$colVal[0];colVal[0]]);colVal[1];($[10h<>type colVal[2];string "j"$colVal[2];colVal[2]]);sideDict colVal[4];colVal[5];exchange)
    ];

    //publish to TP - trade table
    .debug.gda.trade:newTrade;
    pub[`trade;newTrade];

    //update record in the connection check table
    upsert[`connChkTbl;(exchange;`trade;.z.p)];
    };

//bitmex trades callback function
.bitmex.upd:{
    d:.j.k x;.debug.bitmex.d:d; //0N!d;
      if[d[`table] like "trade";
          $[d[`action] like "insert";
              [.debug.bitmex.trade.i:d;
                newTrade:select time:"p"$"Z"$timestamp,sym:sym:`$({$["" like bitmexSymbolDict x;x;bitmexSymbolDict x]} each symbol),orderID:" ",price,tradeID:trdMatchID,side:BuySellDict[side],"f"$size,exchange:`bitmex from d`data;
                .debug.bitmex.newTrade:newTrade;
                pub[`trade;newTrade];
                //update record in the connection check table
                upsert[`connChkTbl;(`bitmex;`trade;.z.p)]
                ];
            d[`action] like "partial";
              .debug.bitmex.trade.p:d;
              .debug.bitmex.trade.a:d;
          ];
        ]
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

//open the websocket and check the connection status 
connectionCheck:{[]
    0N!"Checking the websocket connection status";
    //Reconnect after 10 minutes if no new records are being updated
    reconnectList: select from connChkTbl where time<(.z.p-00:10:00); 
    if[0<count reconnectList;
        feedList: exec feed from reconnectList;
        exchangeList: exec exchange from reconnectList;
        hostToReconnect:select from hostsToConnect where feed in feedList,exchange in exchangeList;
        {0N!x[0]," ",x[1]," WS Not connected!.. Reconnecting at ",string .z.z}each string (exec exchange from hostToReconnect),'(exec feed from hostToReconnect);
        establishWS each hostToReconnect
    ];
    
    if[0~count reconnectList;
        0N!"Websocket connections are all secure"
    ];
    };

/connection check every 10 min
.z.ts:{connectionCheck[]};
\t 600000
