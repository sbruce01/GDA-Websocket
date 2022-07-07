/Sample usage:
/q hdb.q C:/OnDiskDB/sym -p 5002
if[1>count .z.x;show"Supply directory of historical database";exit 0];
hdb:.z.x 0
/Mount the Historical Date Partitioned Database
@[{system"l ",x};hdb;{show "Error message - ",x;exit 0}]

// Define a function to call the select function API in an error trap
selectFunc:{[tbl;sd;ed;ids;exc]
    .[selectFuncAPI;(tbl;sd;ed;ids;exc);{0N!x;:()}]
 };
// Define a function to select from RDB and HDB based upon filters passed through the GET call
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
    [res:$[.z.d within (`date$sd;`date$ed); ?[tbl;wClause;0b;()];0#value tbl]; // Otherwise, we are in the RDB, if the date is not todays date in the RDB return an empty table, otherwise apply filters
    `date xcols update date:.z.d from res]] };  // Create a date column if in the RDB so the schemas match

getStats:{[myDate]
    tableList:key ` sv (`:/data/KX_DATA/sym;`$string myDate);
    res:raze {columns:a where not (a:key ` sv (`:/data/KX_DATA/sym;`$string y;x)) like "*#*" or "*.*";stats:{b:-21!hsym ` sv (`:/data/KX_DATA/sym;`$string z;y;x)}[;x;y] each columns;select sum compressedLength, sum uncompressedLength, x from stats}[;myDate]each tableList;
    res:update date:myDate from res;
    res:`table xcol `x`date`rowCount`uncompressedLength xcols update rowCount:(raze {?[x;enlist(in;`date;y);0b;enlist[`x]!enlist(#:;`i)]}[;myDate]each exec x from res)`x from res;
    :update uncompressedLength%1000000, compressedLength%1000000, compressionRatio:uncompressedLength%compressedLength from res;
    };

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