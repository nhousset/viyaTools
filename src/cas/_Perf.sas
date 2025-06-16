cas;

PROC CAS;
    simple.summary / table={name="CARS"};
    print _Perf; /* Affiche le dictionnaire de performance */

    /* Accéder à une métrique spécifique */
    elapsed_time = _Perf;
    print "Temps écoulé:" elapsed_time;
RUN;
QUIT;

cas terminate;
