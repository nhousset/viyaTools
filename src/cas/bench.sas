/* ========================================================================
   BENCHMARK CAS POUR SAS VIYA 4
   Description: Script de benchmark pour évaluer les performances de CAS
   Date: 2025
   ======================================================================== */

/* Connexion à CAS */
cas mysession sessopts=(caslib=casuser timeout=1800 locale="en_US");

/* Création de la caslib pour les données de test */
caslib _all_ assign;

/* ========================================================================
   SECTION 1: GÉNÉRATION DES DONNÉES DE TEST
   ======================================================================== */

/* Génération d'un grand dataset pour les tests */
data casuser.benchmark_data;
    format start_time datetime20.;
    start_time = datetime();
    put "Début génération des données: " start_time datetime20.;
    
    do i = 1 to 10000000; /* 10 millions d'observations */
        customer_id = i;
        region = cats("Region_", ceil(ranuni(123) * 10));
        product_category = cats("Category_", ceil(ranuni(456) * 20));
        sales_amount = round(ranuni(789) * 10000, 0.01);
        quantity = ceil(ranuni(321) * 100);
        discount_rate = round(ranuni(654) * 0.3, 0.01);
        transaction_date = today() - ceil(ranuni(987) * 365);
        customer_age = 18 + ceil(ranuni(159) * 62);
        satisfaction_score = 1 + ceil(ranuni(753) * 10);
        output;
    end;
    
    format end_time datetime20.;
    end_time = datetime();
    put "Fin génération des données: " end_time datetime20.;
    put "Durée génération: " (end_time - start_time) "secondes";
run;

/* Chargement des données dans CAS */
%let start_load = %sysfunc(datetime());
proc casutil;
    load data=casuser.benchmark_data outcaslib="casuser" 
         casout="benchmark_data" replace;
quit;
%let end_load = %sysfunc(datetime());

%put NOTE: Durée chargement CAS: %sysevalf(&end_load - &start_load) secondes;

/* ========================================================================
   SECTION 2: TESTS DE PERFORMANCE CAS
   ======================================================================== */

/* Macro pour mesurer le temps d'exécution */
%macro measure_time(test_name, code);
    %let start_time = %sysfunc(datetime());
    %put NOTE: === Début du test: &test_name ===;
    
    &code;
    
    %let end_time = %sysfunc(datetime());
    %let duration = %sysevalf(&end_time - &start_time);
    %put NOTE: === Fin du test: &test_name - Durée: &duration secondes ===;
    
    /* Enregistrement des résultats */
    data _temp_result;
        test_name = "&test_name";
        duration = &duration;
        timestamp = datetime();
        format timestamp datetime20.;
    run;
    
    proc append base=benchmark_results data=_temp_result force;
    run;
%mend;

/* Initialisation de la table des résultats */
data benchmark_results;
    length test_name $50;
    format timestamp datetime20.;
    delete;
run;

/* TEST 1: Agrégation simple */
%measure_time(
    Agregation_Simple,
    proc cas;
        simple.summary / 
            table={name="benchmark_data", caslib="casuser"}
            inputs={"sales_amount", "quantity"}
            subSet={"region"}
            casout={name="agg_results1", caslib="casuser", replace=true};
    quit;
);

/* TEST 2: Jointure */
%measure_time(
    Jointure_Auto,
    data casuser.benchmark_data_copy;
        set casuser.benchmark_data;
        join_key = customer_id;
    run;
    
    proc cas;
        datastep.runcode /
            code="
                data casuser.join_result;
                    merge casuser.benchmark_data(in=a) 
                          casuser.benchmark_data_copy(in=b rename=(sales_amount=sales_amount2));
                    by customer_id;
                    if a and b and customer_id <= 1000000;
                run;
            ";
    quit;
);

/* TEST 3: Tri de gros volume */
%measure_time(
    Tri_Gros_Volume,
    proc cas;
        simple.distinct /
            table={name="benchmark_data", caslib="casuser"}
            inputs={"region", "product_category", "customer_age"}
            casout={name="sorted_data", caslib="casuser", replace=true};
    quit;
);

/* TEST 4: Analyse statistique avancée */
%measure_time(
    Stats_Avancees,
    proc cas;
        simple.correlation /
            table={name="benchmark_data", caslib="casuser"}
            inputs={"sales_amount", "quantity", "discount_rate", "customer_age", "satisfaction_score"};
    quit;
);

/* TEST 5: Transformation de données */
%measure_time(
    Transformation_Donnees,
    proc cas;
        datastep.runcode /
            code="
                data casuser.transformed_data;
                    set casuser.benchmark_data;
                    
                    /* Transformations diverses */
                    log_sales = log(sales_amount + 1);
                    sales_per_unit = sales_amount / quantity;
                    discounted_sales = sales_amount * (1 - discount_rate);
                    age_category = case 
                        when customer_age < 30 then 'Young'
                        when customer_age < 50 then 'Middle'
                        else 'Senior'
                    end;
                    
                    /* Calculs conditionnels */
                    if satisfaction_score >= 8 then high_satisfaction = 1;
                    else high_satisfaction = 0;
                    
                    /* Formatage des dates */
                    year_transaction = year(transaction_date);
                    month_transaction = month(transaction_date);
                run;
            ";
    quit;
);

/* TEST 6: Analyse de fréquence */
%measure_time(
    Analyse_Frequence,
    proc cas;
        simple.freq /
            table={name="benchmark_data", caslib="casuser"}
            inputs={"region", "product_category"}
            includeMissing=false;
    quit;
);

/* TEST 7: Machine Learning - Régression */
%measure_time(
    ML_Regression,
    proc cas;
        regression.glm /
            table={name="benchmark_data", caslib="casuser"}
            model={depVar="sales_amount", 
                   effects={"quantity", "discount_rate", "customer_age", "satisfaction_score"}}
            output={casOut={name="regression_results", caslib="casuser", replace=true},
                    copyvars={"customer_id"}};
    quit;
);

/* ========================================================================
   SECTION 3: INFORMATIONS SYSTÈME ET CAS
   ======================================================================== */

/* Informations sur la session CAS */
proc cas;
    builtins.serverStatus;
    builtins.getCasLibInfo;
quit;

/* Informations sur les performances système */
proc cas;
    table.tableInfo / caslib="casuser";
quit;

/* ========================================================================
   SECTION 4: COMPILATION ET AFFICHAGE DES RÉSULTATS
   ======================================================================== */

/* Résumé des performances */
proc cas;
    simple.summary /
        table={name="benchmark_results"}
        inputs={"duration"}
        casout={name="perf_summary", caslib="casuser", replace=true};
quit;

/* Affichage des résultats détaillés */
proc print data=benchmark_results;
    title "Résultats détaillés du benchmark CAS";
    format timestamp datetime20. duration 8.2;
run;

/* Graphique des performances */
proc sgplot data=benchmark_results;
    title "Durée d'exécution par test CAS";
    hbar test_name / response=duration 
                     categoryorder=respdesc
                     fillattrs=(color=lightblue);
    xaxis label="Durée (secondes)" grid;
    yaxis label="Tests";
run;

/* Statistiques de synthèse */
proc means data=benchmark_results n mean std min max;
    title "Statistiques de synthèse des performances CAS";
    var duration;
run;

/* ========================================================================
   SECTION 5: NETTOYAGE
   ======================================================================== */

/* Suppression des tables temporaires */
proc cas;
    table.dropTable / name="benchmark_data" caslib="casuser" quiet=true;
    table.dropTable / name="benchmark_data_copy" caslib="casuser" quiet=true;
    table.dropTable / name="agg_results1" caslib="casuser" quiet=true;
    table.dropTable / name="join_result" caslib="casuser" quiet=true;
    table.dropTable / name="sorted_data" caslib="casuser" quiet=true;
    table.dropTable / name="transformed_data" caslib="casuser" quiet=true;
    table.dropTable / name="regression_results" caslib="casuser" quiet=true;
    table.dropTable / name="perf_summary" caslib="casuser" quiet=true;
quit;

/* Fermeture de la session CAS */
cas mysession terminate;

%put NOTE: ========================================================;
%put NOTE: BENCHMARK CAS TERMINÉ;
%put NOTE: Consultez les résultats dans la table benchmark_results;
%put NOTE: ========================================================;
