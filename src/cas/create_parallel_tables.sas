%macro create_parallel_tables_v2(num_sessions=5, table_size_gb=2);

  proc cas;
    session mySession;

    /* 1. Définir le code comme une chaîne de caractères (string).
       Notez l'utilisation de 'i' et 'table_size_gb' comme des variables normales. */
    pgm_code = "
      data casuser.heavy_table_' || i || ' (promote=yes);
        length text $200;
        do k = 1 to (table_size_gb * 1024**3) / 208;
          num_var = k;
          text = repeat('SAS Viya', 25);
          output;
        end;
      run;

      action table.tableInfo / name='heavy_table_' || i, caslib='casuser';
    ";

    /* 2. Boucle pour lancer les sessions */
    do i = 1 to &num_sessions;
      /* 3. Lancer la session, exécuter le code de la variable 'pgm_code'
            et passer les valeurs nécessaires via le paramètre 'vars'. */
      create_parallel_session session=mySession name="session_" || i
          code=pgm_code
          vars={i=i, table_size_gb=&table_size_gb};
    end;

    /* Attente de la fin de toutes les sessions */
    do i = 1 to &num_sessions;
      wait_for_next_action "session_" || i;
    end;

    /* Vérification */
    action table.tableInfo / caslib='casuser';
    run;
  quit;

%mend create_parallel_tables_v2;


/* === EXEMPLE D'APPEL === */
/* Lancer 3 sessions, chacune créant une table de 1 Go */
%create_parallel_tables_v2(num_sessions=3, table_size_gb=1);
