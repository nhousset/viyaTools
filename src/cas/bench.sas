/* ========================================================================
   BENCHMARK CAS POUR SAS VIYA 4 - VERSION AVANCÉE
   Description: Script de benchmark avec taille paramétrable et stats détaillées
   Date: 2025
   ======================================================================== */

/* ========================================================================
   PARAMÈTRES DE CONFIGURATION
   ======================================================================== */

/* Taille souhaitée du dataset en Mo */
%let dataset_size_mb = 100;

/* Autres paramètres */
%let timeout_cas = 3600;
%let caslib_work = casuser;

/* ========================================================================
   CALCUL DU NOMBRE DE LIGNES NÉCESSAIRE
   ======================================================================== */

/* Estimation de la taille par ligne (en octets) */
%let estimated_bytes_per_row = 120; /* Approximation basée sur les variables définies */

/* Calcul du nombre de lignes nécessaire */
%let target_bytes = %eval(&dataset_size_mb * 1024 * 1024);
%let nobs_target = %eval(&target_bytes / &estimated_bytes_per_row);

%put NOTE: ====================================================;
%put NOTE: PARAMÈTRES DE BENCHMARK;
%put NOTE: Taille cible: &dataset_size_mb Mo;
%put NOTE: Nombre de lignes estimé: &nobs_target;
%put NOTE: ====================================================;

/* Connexion à CAS */
cas mysession sessopts=(caslib=&caslib_work timeout=&timeout_cas locale="en_US");
caslib _all_ assign;

/* ========================================================================
   SECTION 1: GÉNÉRATION DES DONNÉES DE TEST
   ======================================================================== */

%let start_gen = %sysfunc(datetime());

data &caslib_work..benchmark_data;
    format start_time datetime20.;
    start_time = datetime();
    put "Début génération des données: " start_time datetime20.;
    put "Nombre de lignes à générer: &nobs_target";
    
    do i = 1 to &nobs_target;
        /* Variables numériques */
        customer_id = i;
        sales_amount = round(ranuni(789) * 10000, 0.01);
        quantity = ceil(ranuni(321) * 100);
        discount_rate = round(ranuni(654) * 0.3, 0.01);
        customer_age = 18 + ceil(ranuni(159) * 62);
        satisfaction_score = 1 + ceil(ranuni(753) * 10);
        profit_margin = round(ranuni(147) * 0.5, 0.01);
        
        /* Variables caractères */
        region = cats("Region_", ceil(ranuni(123) * 10));
        product_category = cats("Category_", ceil(ranuni(456) * 20));
        sales_channel = cats("Channel_", ceil(ranuni(258) * 5));
        customer_segment = cats("Segment_", ceil(ranuni(963) * 8));
        
        /* Variables dates */
        transaction_date = today() - ceil(ranuni(987) * 365);
        
        output;
        
        /* Affichage du progrès */
        if mod(i, 500000) = 0 then do;
            put "Progression: " i "lignes générées";
        end;
    end;
    
    format end_time datetime20.;
    end_time = datetime();
    put "Fin génération des données: " end_time datetime20.;
    put "Durée génération: " (end_time - start_time) "secondes";
run;

%let end_gen = %sysfunc(datetime());
%let gen_duration = %sysevalf(&end_gen - &start_gen);

/* Vérification de la taille réelle du dataset */
proc cas;
    table.fileInfo / caslib="&caslib_work" name="benchmark_data";
quit;

/* Chargement des données dans CAS */
%let start_load = %sysfunc(datetime());
proc casutil;
    load data=&caslib_work..benchmark_data outcaslib="&caslib_work" 
         casout="benchmark_data" replace;
quit;
%let end_load = %sysfunc(datetime());
%let load_duration = %sysevalf(&end_load - &start_load);

%put NOTE: Durée génération: &gen_duration secondes;
%put NOTE: Durée chargement CAS: &load_duration secondes;

/* ========================================================================
   SECTION 2: INITIALISATION DU SUIVI DÉTAILLÉ
   ======================================================================== */

/* Macro pour mesurer le temps et les ressources */
%macro measure_cas_action(test_name, cas_action, description, code);
    %local start_time end_time duration;
    
    %let start_time = %sysfunc(datetime());
    %put NOTE: === Début: &test_name (&cas_action) ===;
    
    /* Capture des statistiques système avant */
    proc cas;
        builtins.serverStatus / result=r_before;
    quit;
    
    /* Exécution du code de test */
    &code;
    
    /* Capture des statistiques système après */
    proc cas;
        builtins.serverStatus / result=r_after;
    quit;
    
    %let end_time = %sysfunc(datetime());
    %let duration = %sysevalf(&end_time - &start_time);
    
    %put NOTE: === Fin: &test_name - Durée: &duration secondes ===;
    
    /* Enregistrement des résultats détaillés */
    data _temp_detailed_result;
        length test_name $50 cas_action $30 description $100 status $20;
        format timestamp datetime20.;
        
        test_name = "&test_name";
        cas_action = "&cas_action";
        description = "&description";
        duration = &duration;
        timestamp = datetime();
        dataset_size_mb = &dataset_size_mb;
        nobs_processed = &nobs_target;
        
        /* Calcul de métriques de performance */
        if duration > 0 then do;
            rows_per_second = &nobs_target / duration;
            mb_per_second = &dataset_size_mb / duration;
        end;
        else do;
            rows_per_second = .;
            mb_per_second = .;
        end;
        
        /* Classification des performances */
        if duration < 1 then status = "Excellent";
        else if duration < 5 then status = "Bon";
        else if duration < 15 then status = "Moyen";
        else if duration < 30 then status = "Lent";
        else status = "Très lent";
        
        /* Efficacité relative */
        if rows_per_second > 1000000 then efficiency = "Très efficace";
        else if rows_per_second > 500000 then efficiency = "Efficace";
        else if rows_per_second > 100000 then efficiency = "Modéré";
        else if rows_per_second > 50000 then efficiency = "Faible";
        else efficiency = "Très faible";
    run;
    
    proc append base=detailed_benchmark_results data=_temp_detailed_result force;
    run;
%mend;

/* Initialisation de la table des résultats détaillés */
data detailed_benchmark_results;
    length test_name $50 cas_action $30 description $100 status $20 efficiency $20;
    format timestamp datetime20.;
    delete;
run;

/* ========================================================================
   SECTION 3: TESTS DE PERFORMANCE CAS DÉTAILLÉS
   ======================================================================== */

/* TEST 1: Agrégation simple */
%measure_cas_action(
    test_name=Agregation_Base,
    cas_action=simple.summary,
    description=Agrégation basique avec groupement par région,
    code=%str(
        proc cas;
            simple.summary / 
                table={name="benchmark_data", caslib="&caslib_work"}
                inputs={"sales_amount", "quantity", "profit_margin"}
                subSet={"region"}
                casout={name="agg_base", caslib="&caslib_work", replace=true};
        quit;
    )
);

/* TEST 2: Agrégation complexe */
%measure_cas_action(
    test_name=Agregation_Complexe,
    cas_action=simple.summary,
    description=Agrégation avec multiples groupements et statistiques,
    code=%str(
        proc cas;
            simple.summary / 
                table={name="benchmark_data", caslib="&caslib_work"}
                inputs={"sales_amount", "quantity", "discount_rate", "profit_margin"}
                subSet={"region", "product_category", "sales_channel"}
                casout={name="agg_complex", caslib="&caslib_work", replace=true};
        quit;
    )
);

/* TEST 3: Jointure auto (self-join) */
%measure_cas_action(
    test_name=Jointure_Auto,
    cas_action=datastep.runcode,
    description=Auto-jointure pour test de performance des jointures,
    code=%str(
        proc cas;
            datastep.runcode /
                code="
                    data &caslib_work..join_result;
                        merge &caslib_work..benchmark_data(in=a) 
                              &caslib_work..benchmark_data(in=b 
                                  rename=(sales_amount=sales_amount_2
                                         quantity=quantity_2)
                                  where=(customer_id <= %eval(&nobs_target/2)));
                        by customer_id;
                        if a and b;
                        total_sales = sales_amount + sales_amount_2;
                        total_quantity = quantity + quantity_2;
                    run;
                ";
        quit;
    )
);

/* TEST 4: Tri et déduplication */
%measure_cas_action(
    test_name=Tri_Deduplication,
    cas_action=simple.distinct,
    description=Tri avec déduplication sur plusieurs variables,
    code=%str(
        proc cas;
            simple.distinct /
                table={name="benchmark_data", caslib="&caslib_work"}
                inputs={"region", "product_category", "customer_segment", "sales_channel"}
                casout={name="distinct_data", caslib="&caslib_work", replace=true};
        quit;
    )
);

/* TEST 5: Calculs statistiques avancés */
%measure_cas_action(
    test_name=Stats_Correlation,
    cas_action=simple.correlation,
    description=Matrice de corrélation sur variables numériques,
    code=%str(
        proc cas;
            simple.correlation /
                table={name="benchmark_data", caslib="&caslib_work"}
                inputs={"sales_amount", "quantity", "discount_rate", 
                       "customer_age", "satisfaction_score", "profit_margin"};
        quit;
    )
);

/* TEST 6: Transformation de données complexe */
%measure_cas_action(
    test_name=Transformation_Avancee,
    cas_action=datastep.runcode,
    description=Transformations multiples et calculs conditionnels,
    code=%str(
        proc cas;
            datastep.runcode /
                code="
                    data &caslib_work..transformed_data;
                        set &caslib_work..benchmark_data;
                        
                        /* Transformations mathématiques */
                        log_sales = log(sales_amount + 1);
                        sqrt_quantity = sqrt(quantity);
                        sales_per_unit = sales_amount / quantity;
                        discounted_sales = sales_amount * (1 - discount_rate);
                        profit_amount = sales_amount * profit_margin;
                        
                        /* Catégorisations */
                        if customer_age < 25 then age_group = 'Young';
                        else if customer_age < 40 then age_group = 'Adult';
                        else if customer_age < 60 then age_group = 'Middle';
                        else age_group = 'Senior';
                        
                        if sales_amount < 1000 then sales_tier = 'Low';
                        else if sales_amount < 5000 then sales_tier = 'Medium';
                        else sales_tier = 'High';
                        
                        /* Indicateurs binaires */
                        high_satisfaction = (satisfaction_score >= 8);
                        high_discount = (discount_rate >= 0.15);
                        profitable = (profit_margin >= 0.2);
                        
                        /* Calculs de dates */
                        transaction_year = year(transaction_date);
                        transaction_month = month(transaction_date);
                        days_since_transaction = today() - transaction_date;
                    run;
                ";
        quit;
    )
);

/* TEST 7: Analyse de fréquence détaillée */
%measure_cas_action(
    test_name=Frequence_Croisee,
    cas_action=simple.freq,
    description=Analyse de fréquence avec croisements multiples,
    code=%str(
        proc cas;
            simple.freq /
                table={name="benchmark_data", caslib="&caslib_work"}
                inputs={"region", "product_category", "sales_channel", "customer_segment"}
                includeMissing=false;
        quit;
    )
);

/* TEST 8: Machine Learning - Régression linéaire */
%measure_cas_action(
    test_name=ML_Regression_Lineaire,
    cas_action=regression.glm,
    description=Modèle de régression linéaire multiple,
    code=%str(
        proc cas;
            regression.glm /
                table={name="benchmark_data", caslib="&caslib_work"}
                model={depVar="sales_amount", 
                       effects={"quantity", "discount_rate", "customer_age", 
                               "satisfaction_score", "profit_margin"}}
                output={casOut={name="regression_results", caslib="&caslib_work", replace=true},
                        copyvars={"customer_id", "region"}};
        quit;
    )
);

/* TEST 9: Opérations de groupement avancées */
%measure_cas_action(
    test_name=Groupement_Avance,
    cas_action=simple.groupby,
    description=Groupement avec multiples agrégations,
    code=%str(
        proc cas;
            simple.groupby /
                table={name="benchmark_data", caslib="&caslib_work"}
                inputs={"sales_amount", "quantity", "discount_rate", "profit_margin"}
                groupby={"region", "product_category"}
                casout={name="grouped_data", caslib="&caslib_work", replace=true};
        quit;
    )
);

/* ========================================================================
   SECTION 4: INFORMATIONS SYSTÈME ET RESSOURCES
   ======================================================================== */

/* Capture des informations système */
proc cas;
    builtins.serverStatus / result=r_system;
    builtins.getCasLibInfo / result=r_caslib;
    table.tableInfo / caslib="&caslib_work" result=r_tables;
quit;

/* ========================================================================
   SECTION 5: COMPILATION ET AFFICHAGE DES RÉSULTATS DÉTAILLÉS
   ======================================================================== */

/* Ajout des métriques globales */
data benchmark_summary;
    dataset_size_mb = &dataset_size_mb;
    nobs_total = &nobs_target;
    generation_time = &gen_duration;
    loading_time = &load_duration;
    total_setup_time = &gen_duration + &load_duration;
    format timestamp datetime20.;
    timestamp = datetime();
run;

/* Statistiques par action CAS */
proc cas;
    simple.summary /
        table={name="detailed_benchmark_results"}
        inputs={"duration", "rows_per_second", "mb_per_second"}
        subSet={"cas_action"}
        casout={name="perf_by_action", caslib="&caslib_work", replace=true};
quit;

/* Résultats détaillés avec formatage */
title1 "BENCHMARK CAS - RÉSULTATS DÉTAILLÉS";
title2 "Taille du dataset: &dataset_size_mb Mo (&nobs_target lignes)";

proc print data=detailed_benchmark_results;
    var test_name cas_action description duration rows_per_second mb_per_second status efficiency;
    format duration 8.2 rows_per_second comma12.0 mb_per_second 8.2 timestamp datetime20.;
run;

/* Graphiques de performance */
title "Performance par Action CAS";
proc sgplot data=detailed_benchmark_results;
    hbar cas_action / response=duration 
                     categoryorder=respdesc
                     fillattrs=(color=lightblue)
                     datalabel=duration;
    xaxis label="Durée (secondes)" grid;
    yaxis label="Actions CAS";
    format duration 8.1;
run;

title "Débit de traitement par Action CAS";
proc sgplot data=detailed_benchmark_results;
    hbar cas_action / response=rows_per_second 
                     categoryorder=respdesc
                     fillattrs=(color=lightgreen)
                     datalabel=rows_per_second;
    xaxis label="Lignes par seconde" grid;
    yaxis label="Actions CAS";
    format rows_per_second comma12.0;
run;

/* Tableau de synthèse par action */
title "Synthèse des performances par Action CAS";
proc tabulate data=detailed_benchmark_results;
    class cas_action;
    var duration rows_per_second mb_per_second;
    table cas_action,
          duration*(mean*f=8.2 min*f=8.2 max*f=8.2) 
          rows_per_second*(mean*f=comma12.0)
          mb_per_second*(mean*f=8.2) / rts=20;
run;

/* Distribution des performances */
title "Distribution des statuts de performance";
proc freq data=detailed_benchmark_results;
    tables status efficiency / plots=all;
run;

/* Corrélations entre métriques */
title "Corrélations entre métriques de performance";
proc corr data=detailed_benchmark_results;
    var duration rows_per_second mb_per_second nobs_processed;
run;

/* Statistiques globales */
title "Statistiques globales du benchmark";
proc means data=detailed_benchmark_results n mean std min max;
    var duration rows_per_second mb_per_second;
    output out=global_stats;
run;

/* ========================================================================
   SECTION 6: RAPPORT FINAL
   ======================================================================== */

title "RAPPORT FINAL - BENCHMARK CAS";
data _null_;
    set benchmark_summary;
    put "========================================================";
    put "RAPPORT DE BENCHMARK CAS - " timestamp datetime20.;
    put "========================================================";
    put "Configuration:";
    put "  - Taille du dataset: " dataset_size_mb "Mo";
    put "  - Nombre de lignes: " nobs_total comma12.0;
    put "  - Temps de génération: " generation_time 8.2 "secondes";
    put "  - Temps de chargement: " loading_time 8.2 "secondes";
    put "  - Temps total setup: " total_setup_time 8.2 "secondes";
    put "========================================================";
run;

/* ========================================================================
   SECTION 7: NETTOYAGE
   ======================================================================== */

/* Suppression des tables temporaires */
proc cas;
    table.dropTable / name="benchmark_data" caslib="&caslib_work" quiet=true;
    table.dropTable / name="agg_base" caslib="&caslib_work" quiet=true;
    table.dropTable / name="agg_complex" caslib="&caslib_work" quiet=true;
    table.dropTable / name="join_result" caslib="&caslib_work" quiet=true;
    table.dropTable / name="distinct_data" caslib="&caslib_work" quiet=true;
    table.dropTable / name="transformed_data" caslib="&caslib_work" quiet=true;
    table.dropTable / name="regression_results" caslib="&caslib_work" quiet=true;
    table.dropTable / name="grouped_data" caslib="&caslib_work" quiet=true;
    table.dropTable / name="perf_by_action" caslib="&caslib_work" quiet=true;
quit;

/* Fermeture de la session CAS */
cas mysession terminate;

%put NOTE: ========================================================;
%put NOTE: BENCHMARK CAS TERMINÉ;
%put NOTE: Résultats détaillés dans: detailed_benchmark_results;
%put NOTE: ========================================================;
