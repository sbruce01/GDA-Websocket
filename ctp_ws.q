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

upd:{show x};
h:.ws.open["ws://localhost:5110";`upd];
h .j.j enlist[`type]!enlist`sub