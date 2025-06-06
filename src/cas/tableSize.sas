/******************************************************************/
/* DÉFINITION DES VARIABLES : Modifiez les valeurs ici              */
/******************************************************************/
%let ma_caslib_cible = MaCaslib;
%let ma_table_cible = MaTable;
/******************************************************************/


/* Étape 1 : Exécuter table.tableDetails en utilisant les variables macro */
proc cas;
  /* La table 'details_par_noeud' contiendra les résultats bruts de l'action */
  table.tableDetails result=details_par_noeud /
    caslib="&ma_caslib_cible" /* Utilisation de la variable pour la caslib */
    name="&ma_table_cible"   /* Utilisation de la variable pour le nom de la table */
    level="NODE";
quit;


/* Étape 2 : Utiliser une étape DATA pour convertir les octets en mégaoctets (MB) */
data details_en_mb;
  set work.details_par_noeud;

  /* Conversion des colonnes de taille en MB (1 MB = 1024 * 1024 octets) */
  DataSize_MB = DataSize / (1024*1024);
  MappedMem_MB = MappedMem / (1024*1024);
  AllocatedMem_MB = AllocatedMem / (1024*1024);

  /* Appliquer un format pour une meilleure lisibilité */
  format DataSize_MB MappedMem_MB AllocatedMem_MB comma12.2;

  /* Garder uniquement les colonnes utiles */
  keep Node DataSize_MB MappedMem_MB AllocatedMem_MB;
run;


/* Étape 3 : Afficher le résultat final avec un titre dynamique */
proc print data=details_en_mb noobs label;
  label Node="Nœud CAS"
        DataSize_MB="Taille Données (MB)"
        MappedMem_MB="Mémoire Mappée (MB)"
        AllocatedMem_MB="Mémoire Allouée (MB)";
  /* Le titre utilise aussi la variable macro pour être toujours à jour */
  title "Taille de la table '&ma_table_cible' par Nœud (en MB)";
run;
title; /* Nettoyer le titre après l'affichage */
