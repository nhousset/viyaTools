cas mysess sessopts=(caslib="casuser", metrics=true);

caslib _all_ assign;

data casuser.cars;
set sashelp.cars;
run;

PROC CAS;
    simple.summary / table={name="CARS" caslib="casuser"};
    print _Perf; /* Affiche le dictionnaire de performance */

    /* Accéder à une métrique spécifique */
    elapsed_time = _Perf;
    print "Temps écoulé:" elapsed_time;
RUN;
QUIT;

cas terminate;
