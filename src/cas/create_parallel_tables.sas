%macro create_parallel_tables(num_sessions=5, table_size_gb=2);

  /* Démarrage de la session CAS */
  cas mySession;

  /* Définition du code à exécuter dans chaque session parallèle */
  source pgm;
    /* Création d'une table volumineuse */
    data casuser.heavy_table_&i (promote=true);
      length text $200;
      /* Calcul du nombre d'observations nécessaires pour atteindre la taille cible */
      /* Une observation (1 entier + 1 chaîne de 200 caractères) ~ 208 octets */
      /* Nombre d'itérations = (Taille en Go * 1024^3) / 208 */
      do i = 1 to (&table_size_gb * 1024**3) / 208;
        num_var = i;
        text = repeat('SAS Viya', 25);
        output;
      end;
    run;

    /* Information sur la table créée */
    action table.tableInfo / name="heavy_table_&i", caslib="casuser";
  endsource;

  /* Lancement des sessions parallèles et exécution asynchrone du code */
  do i = 1 to &num_sessions;
    create_parallel_session mySession name="session_&i" code=pgm;
  end;

  /* Attente de la fin de toutes les sessions asynchrones */
  do i = 1 to &num_sessions;
    wait_for_next_action "session_&i";
  end;

  /* Affichage des tables chargées en mémoire */
  proc casutil;
    list tables;
  quit;

  /* Terminaison de la session CAS principale */
  cas mySession terminate;

%mend create_parallel_tables;

/* Exemple d'appel de la macro pour lancer 5 sessions créant chacune une table de 2 Go */
%create_parallel_tables(num_sessions=5, table_size_gb=2);
