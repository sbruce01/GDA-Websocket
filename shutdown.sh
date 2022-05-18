ps aux | grep tick.q | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {}
ps aux | grep hdb.q | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {}
ps aux | grep r.q | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {}
ps aux | grep feedhandler_gda.q | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {}
ps aux | grep chainedr.q | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {}