ps aux | grep tick.q | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {}
ps aux | grep hdb.q | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {}
ps aux | grep r.q | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {}
ps aux | grep feedhandler_gda.q | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {}
ps aux | grep chainedr.q | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {}
ps aux | grep wschaintick_0.2.2.q | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {}
ps aux | grep gw.q | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {}