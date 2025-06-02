*--- Options globales pour le suivi des performances ---*;
OPTIONS FULLSTIMER;

*--- 1. Configuration de l'environnement et démarrage de la session CAS ---*;
CAS mySession SESSOPTS=(METRICS=TRUE TIMEOUT=900 LOCALE="fr_FR");
LIBNAME mycas CAS SESSREF=mySession;

* Affiche les informations sur la session CAS (optionnel) *;
PROC CAS;
   SESSIONSTATUS SESSREF=mySession;
RUN;
QUIT;

*--- 2. Préparation des données de test (côté client SAS) ---*;
%LET nombre_observations = 10000000; /* 10 millions d'observations */
%LET nombre_variables_numeriques = 10;
%LET nombre_variables_caracteres = 5;

DATA work.benchmark_data_large;
    ARRAY nums_arr{&nombre_variables_numeriques} (num1-num&nombre_variables_numeriques);
    ARRAY chars_arr{&nombre_variables_caracteres} $20 (char1-char&nombre_variables_caracteres);
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
RUN;

TITLE "Début du Benchmark du Moteur CAS";
NOTE "Les temps d'exécution et les métriques seront visibles dans le journal SAS.";

*--- 3. Benchmark du chargement des données vers CAS ---*;
PROC CASUTIL SESSREF=mySession;
    DROPTABLE CASDATA="benchmark_table_cas" INCASLIB="casuser" QUIET; /* Supprimer si elle existe déjà */
    LOAD DATA=work.benchmark_data_large
         CASOUT="benchmark_table_cas" INCASLIB="casuser" PROMOTE REPLACE;
QUIT;
TITLE;
NOTE;

*--- 4. Benchmark d'une étape DATA dans CAS ---*;
TITLE "Benchmark: Étape DATA dans CAS";
PROC CAS SESSREF=mySession;
    DATastep.runCode /
    CODE = "
        DATA casuser.benchmark_data_transformed;
            SET casuser.benchmark_table_cas;
            BY id_obs; /* Exemple de clause BY, assurez-vous que c'est pertinent pour vos tests */

            /* Exemple de transformations */
            sum_numeriques = 0;
            ARRAY nums_arr[*] num: ; /* Référencer les variables numériques commençant par 'num' */
            DO over nums_arr;
                sum_numeriques = sum_numeriques + nums_arr;
            END;

            length_char1 = LENGTH(char1);

            IF MOD(id_obs, 100) = 0 THEN DO;
                /* Simulation d'une logique plus complexe pour certaines observations */
                new_var_conditionnelle = RAND('NORMAL', 50, 5);
            END;
            ELSE new_var_conditionnelle = .;

            DROP sum_numeriques length_char1; /* Optionnel: ne garder que les variables nécessaires */
        RUN;
    ";
RUN;
QUIT;
TITLE;

*--- 5. Benchmark d'une procédure analytique dans CAS (exemple avec PROC MEANS) ---*;
TITLE "Benchmark: PROC MEANS dans CAS";
PROC MEANS DATA=mycas.benchmark_table_cas NOPRINT SESSREF=mySession;
    VAR num1 num2 num3;
    OUTPUT OUT=mycas.summary_stats (REPLACE=YES PROMOTE=YES);
RUN;
TITLE;

* Vérification des résultats (optionnel) *;
/*
PROC PRINT DATA=mycas.summary_stats (OBS=10);
TITLE "Premières 10 observations des statistiques agrégées";
RUN;
TITLE;
*/

*--- 6. Nettoyage ---*;
TITLE "Nettoyage des tables CAS";
PROC CASUTIL SESSREF=mySession;
    DROPTABLE CASDATA="benchmark_table_cas" INCASLIB="casuser" QUIET;
    DROPTABLE CASDATA="benchmark_data_transformed" INCASLIB="casuser" QUIET;
    DROPTABLE CASDATA="summary_stats" INCASLIB="casuser" QUIET;
QUIT;
TITLE;

*--- Arrêt de la session CAS ---*;
CAS mySession TERMINATE;

OPTIONS NOFULLSTIMER;
