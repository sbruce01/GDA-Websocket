/ no dayend except 0#, can connect to tick.q or chainedtick.q tickerplant
/ q gw.q localhost:5002 localhost:5008 -p 511 </dev/null >foo 2>&1 & 

if[not system"p";system"p 5005"]

runCommand:"l ",a:,[getenv`QHOME;"rest.q_"];

@[system;runCommand;{0N!x}]

hdbHandle:hopen`$":",.z.x 0;
rdbHandle:hopen `$":",.z.x 1;

getData:{[tbl;sd;ed;ids;exc]
  hdb:hdbHandle(`selectFunc;tbl;sd;ed;ids;exc);
  rdb:rdbHandle(`selectFunc;tbl;sd;ed;ids;exc);
  hdb,rdb };

.db.getDataREST:{
  .debug.x:x;
  tbl:x[`arg;`tbl];
  sd:x[`arg;`sd];
  ed:x[`arg;`ed];
  ids:x[`arg;`ids];
  exc:x[`arg;`exc];
  hdb:hdbHandle(`selectFunc;tbl;sd;ed;ids;exc);
  rdb:rdbHandle(`selectFunc;tbl;sd;ed;ids;exc);
  hdb,rdb };

/ Alias namespace for convenience, typically once at beginning of file
.rest:.com_kx_rest

.rest.init enlist[`autoBind]!enlist[1b] / Initialize

.rest.register[`get;
  "/getData";
  "API with format of getData";
  .db.getDataREST;
  .rest.reg.data[`tbl;-11h;0b;`order;"Table to Query"],
    .rest.reg.data[`sd;-12h;0b;.z.p-00:01:00.000000000;"Start Date"],
        .rest.reg.data[`ed;-12h;0b;.z.p;"End Date"],
            .rest.reg.data[`ids;-11h;0b;`;"Instruments to subscribe to"],
                .rest.reg.data[`exc;-11h;0b;`;"Exchange to subscribe to"]]