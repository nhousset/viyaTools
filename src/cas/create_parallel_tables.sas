/* Ajouter des mesures de temps et un rapport sur les tables créées */
%let nb_sessions = 5;
%let table_size_gb = 2;
%let rows_per_gb = 1000000;
%let nrows = %eval(&table_size_gb * &rows_per_gb);
 
/* Tableau pour stocker les timings */
data timings;
  length session $10 start_time end_time duration 8.;
  stop;
run;
%macro terminate_session(session_id);
                cas cas_session_&session_id terminate;
%mend;
 
 
%macro terminate_all_session(nb_sessions);
  %do i = 1 %to &nb_sessions;
    %terminate_session(&i)
  %end;
 
%mend;
%macro create_and_load(session_id);
  %let start_time = %sysfunc(datetime());
  cas cas_session_&session_id;
  caslib _all_ assign;
 
  data casuser.session_&session_id._table;
    length id 8 value $20;
    do i = 1 to &nrows;
      id = i;
      value = cats("val_", put(i, 8.));
      output;
    end;
  run;
 
  proc cas;
   table.tableInfo / caslib="casuser", name="session_&session_id._table";
   table.tableExists result=tbl / caslib="casuser", name="session_&session_id._table";
   if tbl.exists then
      print "Table session_&session_id._table is loaded in memory.";
  quit;
 
  /*cas cas_session_&session_id terminate;*/
 
  %let end_time = %sysfunc(datetime());
  %let duration = %sysevalf(&end_time - &start_time);
 
  data timings;
    set timings
        work._timing;
  run;
 
  data work._timing;
    session = "&session_id";
    start_time = &start_time;
    end_time = &end_time;
    duration = &duration;
  run;
 
%mend;
 
%macro parallel_create_load(nb_sessions);
  %do i = 1 %to &nb_sessions;
    %create_and_load(&i)
  %end;

  /* Affichage du rapport de timing */
  proc print data=timings;

    title "Temps de création des tables CAS";

run;
%mend;

%parallel_create_load(&nb_sessions);

cas;

proc cas;
    accessControl.assumeRole / adminRole="superuser";      
    builtins.getCacheInfo result=results;
    describe results;
run;
print results.diskCacheInfo;
run;
quit;

cas terminate;

%terminate_all_session(&nb_sessions)
