*--- Options globales pour le suivi des performances ---*;
OPTIONS FULLSTIMER;

*--- 1. Configuration de l'environnement et démarrage de la session CAS ---*;
CAS mySession SESSOPTS=(METRICS=TRUE TIMEOUT=900 LOCALE="fr_FR");
LIBNAME mycas CAS SESSREF=mySession;

*--- 2. Préparation des données de test (côté client SAS) ---*;
%LET nombre_observations = 10000000;
%LET nombre_variables_numeriques = 10;
%LET nombre_variables_caracteres = 5;

DATA work.benchmark_data_large;
    ARRAY nums_arr{&nombre_variables_numeriques};
    ARRAY chars_arr{&nombre_variables_caracteres} $20;
    DO i = 1 TO &nombre_observations;
        DO j = 1 TO &nombre_variables_numeriques;
            nums_arr{j} = RAND('UNIFORM') * 1000;
        END;
        DO k = 1 TO &nombre_variables_caracteres;
            chars_arr{k} = COMPRESS('Texte_Exemple_' || PUT(RAND('INTEGER', 1, 10000), Z5.));
        END;
        id_obs = _N_;
        OUTPUT;
    END;
    DROP i j k;
    RENAME nums_arr1-nums_arr&nombre_variables_numeriques=num1-num&nombre_variables_numeriques
           chars_arr1-chars_arr&nombre_variables_caracteres=char1-char&nombre_variables_caracteres;
RUN;

TITLE "Début du Benchmark du Moteur CAS sur Viya 4";
NOTE "Les temps d'exécution et les métriques seront visibles dans le journal SAS et dans le rapport final.";

*--- 3. Benchmark du chargement des données vers CAS ---*;
%let start_load = %sysfunc(datetime()); /* Démarrage du chronomètre */

PROC CASUTIL SESSREF=mySession;
    DROPTABLE CASDATA="benchmark_table_cas" INCASLIB="Public" QUIET; 
    LOAD DATA=work.benchmark_data_large
         CASOUT="benchmark_table_cas" 
         INCASLIB="Public" /* Utilisation de la caslib Public */
         PROMOTE REPLACE;
QUIT;

%let end_load = %sysfunc(datetime()); /* Arrêt du chronomètre */

*--- 4. Capture de la consommation mémoire de la table ---*;
PROC CAS SESSREF=mySession;
    /* Utilise l'action tableInfo pour obtenir les métadonnées de la table */
    table.tableInfo result=r / table={caslib="Public", name="benchmark_table_cas"};
RUN;

/* Extrait la taille (en octets) du résultat et la convertit en Mo dans une macro-variable */
DATA _NULL_;
    SET r.TableInfo; 
    mem_mb = DataSize / (1024*1024); 
    CALL SYMPUTX('table_memory_mb', mem_mb, 'G');
RUN;
QUIT;


*--- 5. Benchmark d'une étape DATA dans CAS ---*;
%let start_datastep = %sysfunc(datetime()); /* Démarrage du chronomètre */

PROC CAS SESSREF=mySession;
    DATastep.runCode /
    CODE = "
        /* Les tables d'entrée et de sortie sont dans la caslib Public */
        DATA Public.benchmark_data_transformed;
            SET Public.benchmark_table_cas;

            ARRAY nums_arr[*] num: ;
            sum_numeriques = SUM(OF nums_arr[*]);
            length_char1 = LENGTH(char1);

            IF MOD(id_obs, 100) = 0 THEN DO;
                new_var_conditionnelle = RAND('NORMAL', 50, 5);
            END;
            ELSE new_var_conditionnelle = .;
        RUN;
    ";
RUN;
QUIT;

%let end_datastep = %sysfunc(datetime()); /* Arrêt du chronomètre */

*--- 6. Benchmark d'une procédure analytique dans CAS (PROC MEANS) ---*;
%let start_procmeans = %sysfunc(datetime()); /* Démarrage du chronomètre */

PROC MEANS DATA=mycas.benchmark_table_cas(caslib="Public") /* Spécification de la caslib Public */
          NOPRINT SESSREF=mySession;
    VAR num1 num2 num3;
    OUTPUT OUT=mycas.summary_stats(caslib="Public" REPLACE=YES PROMOTE=YES); /* Sortie vers Public */
RUN;

%let end_procmeans = %sysfunc(datetime()); /* Arrêt du chronomètre */

*--- 7. Création et affichage du rapport final ---*;

/* Calcul des durées pour chaque étape */
%let load_duration = %sysevalf(&end_load - &start_load);
%let datastep_duration = %sysevalf(&end_datastep - &start_datastep);
%let procmeans_duration = %sysevalf(&end_procmeans - &start_procmeans);

/* Création de la table de rapport */
DATA work.final_report;
    LENGTH Etape $ 50 Valeur $ 50;
    
    Etape = "Chargement des données vers CAS (secondes)";
    Valeur = STRIP(PUT(&load_duration, 8.2));
    OUTPUT;

    Etape = "Étape DATA dans CAS (secondes)";
    Valeur = STRIP(PUT(&datastep_duration, 8.2));
    OUTPUT;

    Etape = "PROC MEANS dans CAS (secondes)";
    Valeur = STRIP(PUT(&procmeans_duration, 8.2));
    OUTPUT;

    Etape = "Consommation mémoire de la table (Mo)";
    Valeur = STRIP(PUT(&table_memory_mb, 8.2));
    OUTPUT;
RUN;

/* Affichage du rapport */
TITLE "Rapport Final du Benchmark";
PROC PRINT DATA=work.final_report NOOBS LABEL;
    LABEL Etape="Étape du Benchmark"
          Valeur="Résultat";
RUN;
TITLE;


*--- 8. Nettoyage ---*;
TITLE "Nettoyage des tables CAS";
PROC CASUTIL SESSREF=mySession;
    /* Suppression des tables dans la caslib Public */
    DROPTABLE CASDATA="benchmark_table_cas" INCASLIB="Public" QUIET;
    DROPTABLE CASDATA="benchmark_data_transformed" INCASLIB="Public" QUIET;
    DROPTABLE CASDATA="summary_stats" INCASLIB="Public" QUIET;
QUIT;
TITLE;

*--- Arrêt de la session CAS ---*;
CAS mySession TERMINATE;

OPTIONS NOFULLSTIMER;
