/ Adhoc writedown replacing RDB writedown for memory purposes
/ syntax:q eod_write.q localhost:TP_PORT localhost:HDB_PORT
/ optional argument -LOGDIR
.z.zd:(17;2;6)

if[not "w"=first string .z.o;system "sleep 1"];

// Define schema for replay tables
.lr.tables:`$();

/upd:insert;
upd:{[t;x] 
    if[t in .lr.tables;
        t insert x];
 }

/ get the ticker plant and history ports, defaults are 5010,5012
.u.x:.z.x,(count .z.x)_(":5010";":5012");


system"l sym.q"; // Load in the Schema from TP
@[;`sym;`g#]each tables[]; // Apply grouped attribute to sym column for each table
HDBDIR:(hopen `$":",.u.x 1)".z.x 0"; // Ask the HDB what it was passed on startup

/ end of day: save, clear, hdb reload
.lr.end:{0N!"Starting EOD at: ",string[.z.p];t:.lr.tables;t@:where `g=attr each t@\:`sym;.Q.hdpf[`$":",.u.x 1;hsym `$HDBDIR;x;`sym];@[;`sym;`g#] each t;0N!"Finishing EOD at: ",string[.z.p];};

.u.rep:{-11!x;.Q.gc[];system "cd ",HDBDIR;.lr.end y;.Q.gc[]};

\d .storedTables
system"l sym.q"; // Load in the Schema from TP
@[;`sym;`g#]each tables[]; // Apply grouped attribute to sym column for each table
\d .

// Subscribe to TP so we receive .u.end (need to pass a table, chose a low frequency one so no needless IPC)
0N!"Connecting to TP";
0N!"Number of handles are ",string[count .z.W];
(hopen `$":",.u.x 0)".u.sub[`active_accounts;`]";
/ (hopen `$":",.u.x 0)".u.sub[`;`]";
0N!"Connected to TP";
0N!"Number of handles are ",string[count .z.W];


// Main()
requiredTables:(raze `order;`active_accounts`trade`ethereum`ohlcv`vwap);  // Tables we want
![`.;();0b;raze requiredTables];  // Delete from top namespace
.u.end:{[saveDate]
    .debug.end:saveDate;
    LOGFILE:(hopen `$":",.u.x 0)".u.L";
    LOGFILE:` sv (-1_` vs LOGFILE),`$"sym",string[saveDate];
    {.lr.tables:y;{[toSet]toSet set .storedTables[toSet]}each y;.u.rep[x;z];![`.;();0b;y]}[LOGFILE;;saveDate] each requiredTables;
    .Q.chk[hsym `$HDBDIR]}