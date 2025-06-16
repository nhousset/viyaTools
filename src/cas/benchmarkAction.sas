%macro benchmarkAction(
    action=,        /* Action CAS à exécuter (ex: simple.summary) */
    params=,        /* Paramètres de l'action (ex: table={...} inputs={...}) */
    result_var=r    /* Variable CASL pour stocker le résultat (optionnel) */
);
    %local start_time end_time elapsed_time;
    %let start_time = %sysfunc(time());

    /* --- Début du bloc de test --- */
    proc cas;
        /* Affichage de l'action testée */
        print "--- Benchmarking Action: &action ---";

        /* Exécution de l'action en capturant le statut et les métriques de performance */
        &action result=&result_var status=cas_status / &params;

        /* Capture des métriques de performance */
        bm_perf = _Perf;
        
        /* Vérification du statut de l'exécution */
        if cas_status.severity > 1 then do;
            print "ERROR: L'action a échoué. Statut:";
            print cas_status;
        end;
        else do;
            print "SUCCESS: L'action s'est terminée.";
            print "--- Performance Metrics ---";
            print bm_perf;
        end;
    run;
    quit;
    /* --- Fin du bloc de test --- */

    %let end_time = %sysfunc(time());
    %let elapsed_time = %sysevalf(&end_time - &start_time, F);

    %put &=elapsed_time;
    %put NOTE: Le benchmark complet de l'action a pris &elapsed_time secondes.;
%mend benchmarkAction;

cas  sessopts=(caslib="casuser", metrics=true);

caslib _all_ assign;

/* --- Utilisation de la macro corrigée --- */
%benchmarkAction(
    action     = simple.summary,
    result_var = r,
    params     = table={name="CARS", caslib="CASUSER"}
                 inputs={"MSRP", "Invoice"}
);

/* Afficher les résultats capturés */
%put &=BM_ELAPSED_TIME;
%put &=BM_CPU_USER_TIME;

cas terminate;
