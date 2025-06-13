%let nb_sessions = 5; /* nombre de sessions à lancer */
%let table_size_gb = 2; /* taille approximative de chaque table en Go */
%let rows_per_gb = 1000000; /* estimation du nombre de lignes par Go */
%let nrows = %eval(&table_size_gb * &rows_per_gb);

/* Créer une macro pour générer des données et les charger en mémoire */
%macro create_and_load(session_id);
  cas cas_session_&session_id;

  /* Génération des données directement dans casuser */
  data session_&session_id._table;
    length id 8 value $20;
    do i = 1 to &nrows;
      id = i;
      value = cats("val_", put(i, 8.));
      output;
    end;
  run;

  /* Vérification de la table chargée en mémoire */
  proc cas;
    table.tableExists result=tbl / caslib="casuser", name="session_&session_id._table";
    if tbl.exists then
      print "Table session_&session_id._table is loaded in memory.";
  quit;

  /* Fin de la session */
  cas cas_session_&session_id terminate;
%mend;

/* Lancer les sessions en parallèle (via rsubmit si multi-session possible) */
%macro parallel_create_load(nb_sessions);
  %do i = 1 %to &nb_sessions;
    /* Utiliser systask ou un scheduler si vrai parallélisme souhaité */
    %create_and_load(&i)
  %end;
%mend;

/* Exécution */
%parallel_create_load(&nb_sessions);
