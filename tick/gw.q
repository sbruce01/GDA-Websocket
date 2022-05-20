/ no dayend except 0#, can connect to tick.q or chainedtick.q tickerplant
/ q gw.q localhost:5002 localhost:5008 -p 511 </dev/null >foo 2>&1 & 

if[not system"p";system"p 5005"]

runCommand:"l ",a:,[getenv`QHOME;"rest.q_"];

@[system;runCommand;{0N!x}]


hdbHandle:hopen`$":",.z.x 0;
rdbHandle:hopen `$":",.z.x 1;

getData:{[tbl;sd;ed;ids;exc]
  .debug.getData:`tbl`sd`ed`ids`exc!(tbl;sd;ed;ids;exc);
  hdb:hdbHandle(`selectFunc;tbl;sd;ed;ids;exc);
  rdb:rdbHandle(`selectFunc;tbl;sd;ed;ids;exc);
  hdb,rdb };
