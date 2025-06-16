%macro benchmarkAction(action_call);
    PROC CAS;
        /* Exécuter l'action passée en paramètre */
        &action_call;

        /* Capturer les métriques de performance depuis _Perf */
        perf_dict = _Perf;
        elapsed = perf_dict;
        cpu_user = perf_dict;
        cpu_sys = perf_dict;
        memory = perf_dict["Memory"];
        
        /* Promouvoir les métriques vers des variables macro */
        call symputx('BM_ELAPSED_TIME', elapsed, 'G');
        call symputx('BM_CPU_USER_TIME', cpu_user, 'G');
        call symputx('BM_CPU_SYSTEM_TIME', cpu_sys, 'G');
        call symputx('BM_MEMORY', memory, 'G');
        
        /* Afficher un résumé */
        print "--- Benchmark Results ---";
        print "Elapsed Time: " |
| put(elapsed, 8.4);
        print "CPU Time (User): " |
| put(cpu_user, 8.4);
        print "Memory: " |
| put(memory, best12.);
        print "-------------------------";
    RUN;
    QUIT;

    %put NOTE: Benchmark complete. Results available in macro variables BM_ELAPSED_TIME, etc.;
%mend benchmarkAction;

cas  sessopts=(caslib="casuser", metrics=true);

caslib _all_ assign;

/* --- Utilisation de la macro --- */
%benchmarkAction(
    action_call = simple.summary result=r / 
                  table={name="CARS", caslib="CASUSER"} 
                  inputs={"MSRP", "Invoice"};
);

/* Afficher les résultats capturés */
%put &=BM_ELAPSED_TIME;
%put &=BM_CPU_USER_TIME;

cas terminate;
