%let nb_sessions = 5; /* nombre de sessions à lancer */
%let table_size_gb = 2; /* taille approximative de chaque table en Go */
%let rows_per_gb = 1000000; /* estimation du nombre de lignes par Go */
%let nrows = %eval(&table_size_gb * &rows_per_gb);

/* Créer une macro pour générer des données et les charger en mémoire */
%macro create_and_load(session_id);
  cas cas_session_&session_id;

  /* Création de la session CAS */
  caslib mycaslib datasource=(srctype="path") path="/tmp/casdata/session_&session_id";

  /* Génération des données */
  data caslib.session_&session_id._table promote;
    length id 8 value $20;
    do i = 1 to &nrows;
      id = i;
      value = cats("val_", put(i, 8.));
      output;
    end;
  run;

  /* Monter la table en mémoire */
  proc cas;
    table.loadTable /
      path="session_&session_id._table.sashdat",
      caslib="mycaslib",
      casout={name="session_&session_id._inmem", promote=true};
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
