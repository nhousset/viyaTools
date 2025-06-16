cas;

PROC CAS;
    builtins.actionSetInfo result=r;
    print r.setinfo;
RUN;
QUIT;

PROC CAS;
    /* Lister toutes les actions dans l'ensemble d'actions 'simple' */
    builtins.help / actionSet="simple";

    /* Obtenir l'aide détaillée pour l'action 'summary' */
    builtins.help / action="simple.summary";
RUN;
QUIT;

cas terminate;
