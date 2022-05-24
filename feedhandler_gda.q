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
rawbinance:([]raw:());
rawbybit:([]raw:());
rawcoinbase:([]raw:());

BuySellDict:("Buy";"Sell")!(`bid;`ask);
sideDict:0 1 2f!`unknown`bid`ask;
actionDict:0 1 2 3 4f!`unknown`skip`insert`remove`update;
orderTypeDict:0 1 2f!`unknown`limitOrder`marketOrder;
bitmexSymbolDict:(enlist"XBTUSD")!enlist("BTCUSD");
gdaExchgTopic:([]
    topic:(`binance;`bybit;`coinbase);
    symbol:`BTCUSDT`BTCUSD`BTCUSD);

//cast time in millis to timestamp
millisToTS:{`timestamp$`datetime$(x%(prd 24 60 60 1000j))-(0-1970.01.01)};
.time.trade.binance:{@[x;`timestamp;millisToTS]}; 
.time.trade.coinbase:{@[x;`timestamp;"p"$"Z"$]}; 
.time.trade.bybit:{@[x;`timestamp;millisToTS]};

// Exchange specific Order mapping
.order.binance:{update millisToTS event_timestamp from x};
.order.bybit:{update millisToTS event_timestamp from x};
.order.coinbase:{.debug.order.coinbase:x;update ?[-9h~type event_timestamp;millisToTS;"p"$"Z"$] event_timestamp from x};

// Exchange specific Order mapping
.trade.binance:{update millisToTS timestamp from x};
.trade.bybit:{update millisToTS timestamp from x};
.trade.coinbase:{.debug.trade.coinbase:x;update ?[-9h~type timestamp;millisToTS;"p"$"Z"$] timestamp from x};

//create the ws subscription table
hostsToConnect:([]hostQuery:();request:();exchange:`$();feed:`$();callbackFunc:());
//add all normalised exchanges from gda
`hostsToConnect upsert {("ws://194.233.73.248:30205/";`op`exchange`feed!("subscribe";x;"normalised");x;`order;`.gdaNormalised.updExchg)}each exec topic from gdaExchgTopic;
`hostsToConnect upsert {("ws://194.233.73.248:30205/";`op`exchange`feed!("subscribe";x;"trades");x;`trade;`.gdaTrades.updExchg)}each exec topic from gdaExchgTopic;
//add raw exchanges from gda
`hostsToConnect upsert {("ws://194.233.73.248:30205/";`op`exchange`feed!("subscribe";x;"raw");x;`raw;`.gdaRaw.updExchg)}each exec topic from gdaExchgTopic;
//add BitMEX websocket 
/`hostsToConnect upsert("wss://ws.bitmex.com/realtime";`op`args!("subscribe";"trade:XBTUSD");`bitmex;`trade;`.bitmex.upd);
//add record ID
hostsToConnect:update ws:1+til count i from hostsToConnect;
hostsToConnect:update callbackFunc:{` sv x} each `$string(callbackFunc,'ws) from hostsToConnect where callbackFunc like "*gda*";

//GDA orderbooks callback function 
.gdaNormalised.upd:{[incoming;exchange]
    d:.j.k incoming;.debug.gda.d:d; //0N!d;
    .debug.ordExchange:exchange;

    if[`event`topic~key d;
        .debug.sub:d;
        :()
    ];

    //capture the subscription sym
    subSym:exec first symbol from gdaExchgTopic where topic=exchange;
    d:d,(`sym`exchange)!(subSym;exchange);
    
    //perform generic mapping
    d:update event_timestamp:?[(0=count event_timestamp) or any (0f;-1f)~\:event_timestamp;receive_timestamp;event_timestamp], 
                order_id:?[10h<>type order_id;string "j"$order_id;order_id],
                sideDict side,
                actionDict lob_action,
                orderTypeDict order_type from d;

    //perform Exchange specific mapping
    d:.order[exchange] d;

    //publish to TP - order table
    newOrder:d`event_timestamp`sym`order_id`side`price`size`lob_action`order_type`exchange;
    .debug.newOrder:newOrder;
    pub[`order;newOrder];

    //update record in the connection check table
    upsert[`connChkTbl;(exchange;`order;.z.p)];
    };

//GDA trades callback function 
.gdaTrades.upd:{[incoming;exchange]
    d:.j.k incoming;.debug.gda.dt:d; //0N!d;
    .debug.trdExchange:exchange;
    
    if[`event`topic~key d;
        .debug.subt:d;
        :()
    ];

    //capture the subscription sym
    subSym:exec first symbol from gdaExchgTopic where topic=exchange;
    d:d,(`sym`exchange)!(subSym;exchange);
    
    //perform generic mapping
    d:update timestamp:?[(0=count timestamp) or any (0f;-1f)~\:timestamp;.z.p;timestamp], 
                order_id:?[10h<>type order_id;string "j"$order_id;order_id],
                trade_id:?[10h<>type trade_id;string "j"$trade_id;trade_id],
                sideDict side
                from d;
    
    //perform Exchange specific mapping
    d:$[-12h<>type d[`timestamp];.trade[exchange] d;d];
   
    //publish to TP - trade table
    newTrade:d`timestamp`sym`order_id`price`trade_id`side`size`exchange;
    .debug.gda.trade:newTrade;
    pub[`trade;newTrade];

    //update record in the connection check table
    upsert[`connChkTbl;(exchange;`trade;.z.p)];
    };

//bitmex trades callback function
.bitmex.upd:{
    d:.j.k x;.debug.bitmex.d:d; //0N!d;
    if[not 99h~type d;:()];

    $[d[`action] like "insert";
        [.debug.bitmex.trade.i:d;
        newTrade:select time:"p"$"Z"$timestamp,sym:`$({$["" like bitmexSymbolDict x;x;bitmexSymbolDict x]} each symbol),orderID:enlist" ","f"$price,tradeID:trdMatchID,side:BuySellDict[side],"f"$size,exchange:`bitmex from d`data;
        .debug.bitmex.newTrade:newTrade;
        pub[`trade;newTrade];
        //update record in the connection check table
        upsert[`connChkTbl;(`bitmex;`trade;.z.p)]
        ];
        :()
    ];       
  };

.gdaRaw.upd:{[incoming;exchange]
    .debug.raw:incoming;
    .debug.rawExchange:exchange;
    tableName:`$ssr[(string ` sv (`raw;exchange));".";""];
    //publish to TP - raw exchange table
    pub[tableName;(.z.p;`BTCUSD;enlist incoming)];
    
    //update record in the connection check table
    upsert[`connChkTbl;(exchange;`raw;.z.p)];
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

    if[request[`feed] like "raw";
        callbackFunc set .gdaRaw.upd[;request[`exchange]]
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
