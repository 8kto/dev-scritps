# Dump DB structure with dump-db-structure.php script 

## Dump views and functions/procedures
See script's help docs: where do arguments come: pass, username, database name etc.
```
./dump-db-structure.php --routines --output-dir /tmp/ --table-prefix pfx_     
```

## Dump tables' structure
```
./dump-db-structure.php --tables --output-dir /tmp/ --table-prefix pfx_   
```

## How to see differences between dumps
CLI way:
```
sdiff -l routines-v2.6.3.sql routines-v2.6.5.sql
```
                                                  
GUI way (`Meld` tool must be installed: https://meldmerge.org/)
```
meld routines-v2.6.3.sql routines-v2.6.5.sql
```
