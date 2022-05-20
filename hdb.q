/Sample usage:
/q hdb.q C:/OnDiskDB/sym -p 5002
if[1>count .z.x;show"Supply directory of historical database";exit 0];
hdb:.z.x 0
/Mount the Historical Date Partitioned Database
@[{system"l ",x};hdb;{show "Error message - ",x;exit 0}]

selectFunc:{[tbl;sd;ed;ids;exc]
    .debug.selectFunc:`tbl`sd`ed`ids`exc!(tbl;sd;ed;ids;exc);
    .[selectFuncAPI;(tbl;sd;ed;ids;exc);{-2!"Error selecting data: ",x;()}]
 };

selectFuncAPI:{[tbl;sd;ed;ids;exc]
  wClause:();
  if[not all null (sd;ed); wClause,:enlist(within;`time;(enlist;sd;ed))];
  if[not all null ids;wClause,:enlist(in;`sym;enlist (),ids)]
  if[not all null exc; wClause,:enlist(in;`exchange;enlist (),exc)];
  $[`date in cols tbl;
  [wClause:enlist(within;`date;(enlist;`sd.date;`ed.date)),wClause;
      ?[tbl;wClause;0b;()]];
  [res:$[.z.D within (`date$sd;`date$ed); ?[tbl;wClause;0b;()];0#value tbl];
    `date xcols update date:.z.D from res]] }