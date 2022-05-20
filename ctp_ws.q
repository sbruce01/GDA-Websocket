\l ws-client_0.2.2.q
/conda install -c jmcmurray ws-client ws-server
/.utl.require"ws-server"
/.utl.require"ws-client"

/h:@[hopen;(`$":localhost:5110";10000);0i];
/ pub:{$[h=0;
/         neg[h](`upd   ;x;y);
/         $[0h~type y;neg[h](`.u.upd;x;y);neg[h](`.u.upd;x;value flip y)]
/         ]};

/ upd:upsert;

/h .j.j enlist[`type]!enlist`sub

upd:{[jsonIncoming;table;instrument;st;et]
    .debug.incoming: incoming:.j.k jsonIncoming;

    //data type check
    meta incoming[1];

    if[table like incoming[0];
        tb:update time:"N"$time from incoming[1];
        :select from tb where time>st,time<et,sym like instrument
    ]
};

connFunc:{[table;intrument;st;et]
    0N!"Open the websocket";
    h:.ws.open["ws://localhost:5110";upd[;table;instrument;st;et]];
}

