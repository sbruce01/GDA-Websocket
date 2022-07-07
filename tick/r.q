/q tick/r.q [host]:port[:usr:pwd] [host]:port[:usr:pwd]
/2008.09.09 .k ->.q
.z.zd:(17;2;6)
if[not "w"=first string .z.o;system "sleep 1"];

upd:insert;

/ get the ticker plant and history ports, defaults are 5010,5012
.u.x:.z.x,(count .z.x)_(":5010";":5012");

/ end of day: save, clear, hdb reload
/ .u.end:{0N!"Starting EOD at: ",string[.z.p];t:tables`.;t@:where `g=attr each t@\:`sym;.Q.hdpf[`$":",.u.x 1;`:.;x;`sym];@[;`sym;`g#] each t;0N!"Finishing EOD at: ",string[.z.p];};
.u.end:{0N!"Clearing tables at", string[.z.p];{x set 0#value x} each tables[];.Q.gc[]};

/ init schema and sync up from log file;cd to hdb(so client save can run)
.u.rep:{(.[;();:;].)each x;if[null first y;:()];-11!y;system "cd ",1_-10_string first reverse y};
/ HARDCODE \cd if other than logdir/db

/ connect to ticker plant for (schema;(logcount;log))
.u.rep .(hopen `$":",.u.x 0)"(.u.sub[`;`];`.u `i`L)";

selectFunc:{[tbl;sd;ed;ids;exc]
    .debug.selectFunc:`tbl`sd`ed`ids`exc!(tbl;sd;ed;ids;exc);
    .[selectFuncAPI;(tbl;sd;ed;ids;exc);{-2!"Error selecting data: ",x;()}]
 };

selectFuncAPI:{[tbl;sd;ed;ids;exc]
  wClause:(); // Initialize empty where clause
  if[not all null ids;wClause,:enlist(in;`sym;enlist (),ids)];  // If we have a filter based on symbols add it to the where clause
  $["u"~(meta tbl)[`time]`t;
        $[`date in cols tbl;
            if[not all null (sd;ed);wClause,:enlist(within;(+;`time;`date);(enlist;sd;ed))]; // If time is of minute type and we are in the hdb, add date to time
            if[not all null (sd;ed);wClause,:enlist(within;(+;`time;.z.d);(enlist;sd;ed))] // If time is of minute type and we are in the rdb, add .z.d to time
            ]; 
        if[not all null (sd;ed);wClause,:enlist(within;`time;(enlist;sd;ed))] // Otherwise our time is of type timestamp, the logic of which works regardless
    ];
  if[not all null exc; wClause,:enlist(in;`exchange;enlist (),exc)]; // If we have a filter based on exchange add it to the where clause
  $[`date in cols tbl;    // If we are in the HDB
  [wClause:(enlist(within;`date;(enlist;`date$sd;`date$ed))),wClause; // Add date check to the where clause to select the date partition
      ?[tbl;wClause;0b;()]];  // Select from the table applying the conditions of the where clause
  [res:$[.z.D within (`date$sd;`date$ed); ?[tbl;wClause;0b;()];0#value tbl]; // Otherwise, we are in the RDB, if the date is not todays date in the RDB return an empty table, otherwise apply filters
  `date xcols update date:.z.D from res]] }

  selectFuncWithCols:{[tbl;sd;ed;ids;exc;columns]
    .debug.selectFuncWithCols:`tbl`sd`ed`ids`exc`columns!(tbl;sd;ed;ids;exc;columns);
    .[selectFuncWithColsAPI;(tbl;sd;ed;ids;exc;columns);{0N!x;:()}]
 };

 selectFuncWithColsAPI:{[tbl;sd;ed;ids;exc;columns]
  wClause:(); // Initialize empty where clause
  $[not count columns; colClause:();colClause:(columns except `date)!columns except `date]; // If no filters selected return all columns
  if[not all null ids;wClause,:enlist(in;`sym;enlist (),ids)];  // If we have a filter based on symbols add it to the where clause
  $["u"~(meta tbl)[`time]`t;
        $[`date in cols tbl;
            if[not all null (sd;ed);wClause,:enlist(within;(+;`time;`date);(enlist;sd;ed))]; // If time is of minute type and we are in the hdb, add date to time
            if[not all null (sd;ed);wClause,:enlist(within;(+;`time;.z.d);(enlist;sd;ed))] // If time is of minute type and we are in the rdb, add .z.d to time
            ]; 
        if[not all null (sd;ed);wClause,:enlist(within;`time;(enlist;sd;ed))] // Otherwise our time is of type timestamp, the logic of which works regardless
    ];
  if[not all null exc; wClause,:enlist(in;`exchange;enlist (),exc)]; // If we have a filter based on exchange add it to the where clause
  $[`date in cols tbl;    // If we are in the HDB
  [wClause:(enlist(within;`date;(enlist;`date$sd;`date$ed))),wClause; // Add date check to the where clause to select the date partition
      ?[tbl;wClause;0b;colClause]];  // Select from the table applying the conditions of the where clause
  [res:$[.z.d within (`date$sd;`date$ed); ?[tbl;wClause;0b;colClause];0#value tbl];
    :$[`date in columns;`date xcols update date:.z.d from res;res]]] };