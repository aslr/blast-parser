# Taxonomy PostgresSQL database

The NCBI rankedlineage database dump file:

rankedlineage.dmp
-----------------

The PostgresSQL database has only the major taxonomic ranks, namely species, genus, family, order, class, phylum, kingdom, superkingdom.
Therefore, the database fields are:

    tax_id       -- node id
    tax_name     -- scientific name of the organism
    species      -- name of a species (coincide with organism name for species-level nodes)
    genus        -- genus name when available
    family       -- family name when available
    order        -- order name when available
    class        -- class name when available
    phylum       -- phylum name when available
    kingdom      -- kingdom name when available
    superkingdom -- superkingdom (domain) name when available


## Common commands:

### connect to the database using psql
(base) ➜  ~ psql -d taxonomy_ncbi -U *username*
psql (16.4 (Postgres.app))
Type "help" for help.

taxonomy_ncbi=> \d
         List of relations
 Schema |   Name   | Type  | Owner 
--------+----------+-------+-------
 public | taxonomy | table | test
(1 row)

### delete a table
taxonomy_ncbi=> DROP taxonomy;
ERROR:  syntax error at or near "taxonomy"
LINE 1: DROP taxonomy;
             ^
taxonomy_ncbi=> DROP TABLE taxonomy;
DROP TABLE
taxonomy_ncbi=> \d
Did not find any relations.
taxonomy_ncbi=> SELECT * FROM taxonomy_ncbi.pg_tables;
ERROR:  relation "taxonomy_ncbi.pg_tables" does not exist
LINE 1: SELECT * FROM taxonomy_ncbi.pg_tables;

### connect back to the database
taxonomy_ncbi=> \c taxonomy_ncbi
You are now connected to database "taxonomy_ncbi" as user "*username*".
taxonomy_ncbi=> \dt
Did not find any relations.

### list databases
taxonomy_ncbi=> \l
                                                         List of databases
     Name      |  Owner   | Encoding | Locale Provider |   Collate   |    Ctype    | ICU Locale | ICU Rules |   Access privileges   
---------------+----------+----------+-----------------+-------------+-------------+------------+-----------+-----------------------
 admin         | admin    | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 |            |           | 
 postgres      | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 |            |           | 
 taxonomy_ncbi | test     | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 |            |           | =Tc/test             +
               |          |          |                 |             |             |            |           | test=CTc/test
 template0     | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 |            |           | =c/postgres          +
               |          |          |                 |             |             |            |           | postgres=CTc/postgres
 template1     | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 |            |           | =c/postgres          +
               |          |          |                 |             |             |            |           | postgres=CTc/postgres
(5 rows)


taxonomy_ncbi=> SELECT * FROM pg_database;
taxonomy_ncbi=> SELECT datname FROM pg_database;
    datname    
---------------
 postgres
 admin
 template1
 template0
 taxonomy_ncbi
(5 rows)

taxonomy_ncbi=> SELECT * FROM pg_database;
taxonomy_ncbi=> SELECT usename AS role_name,
taxonomy_ncbi->   CASE 
taxonomy_ncbi->      WHEN usesuper AND usecreatedb THEN 
taxonomy_ncbi->    CAST('superuser, create database' AS pg_catalog.text)
taxonomy_ncbi->      WHEN usesuper THEN 
taxonomy_ncbi->     CAST('superuser' AS pg_catalog.text)
taxonomy_ncbi->      WHEN usecreatedb THEN 
taxonomy_ncbi->     CAST('create database' AS pg_catalog.text)
taxonomy_ncbi->      ELSE 
taxonomy_ncbi->     CAST('' AS pg_catalog.text)
taxonomy_ncbi->   END role_attributes
taxonomy_ncbi-> FROM pg_catalog.pg_user
taxonomy_ncbi-> ORDER BY role_name desc;
 role_name |      role_attributes       
-----------+----------------------------
 test      | create database
 postgres  | superuser, create database
 admin     | superuser, create database
(3 rows)

taxonomy_ncbi=> SELECT usename FROM pg_database;
ERROR:  column "usename" does not exist
LINE 1: SELECT usename FROM pg_database;
               ^
HINT:  Perhaps you meant to reference the column "pg_database.datname".
taxonomy_ncbi=> SELECT usename FROM pg_database.datname;
ERROR:  relation "pg_database.datname" does not exist
LINE 1: SELECT usename FROM pg_database.datname;
                            ^
taxonomy_ncbi=> SELECT datname FROM pg_database;
    datname    
---------------
 postgres
 admin
 template1
 template0
 taxonomy_ncbi
(5 rows)

taxonomy_ncbi=> SELECT
taxonomy_ncbi->  * 
taxonomy_ncbi-> FROM
taxonomy_ncbi->  pg_catalog.pg_user;
 usename  | usesysid | usecreatedb | usesuper | userepl | usebypassrls |  passwd  | valuntil | useconfig 
----------+----------+-------------+----------+---------+--------------+----------+----------+-----------
 admin    |    16384 | t           | t        | f       | f            | ******** |          | 
 postgres |       10 | t           | t        | t       | t            | ******** |          | 
 test     |    16390 | t           | f        | f       | f            | ******** |          | 
(3 rows)

taxonomy_ncbi=> select u.usename,
taxonomy_ncbi->        (select string_agg(d.datname, ',' order by d.datname) 
taxonomy_ncbi(>         from pg_database d 
taxonomy_ncbi(>         where has_database_privilege(u.usename, d.datname, 'CONNECT')) as allowed_databases
taxonomy_ncbi-> from pg_user u
taxonomy_ncbi-> order by u.usename;
 usename  |                allowed_databases                 
----------+--------------------------------------------------
 admin    | admin,postgres,taxonomy_ncbi,template0,template1
 postgres | admin,postgres,taxonomy_ncbi,template0,template1
 test     | admin,postgres,taxonomy_ncbi,template0,template1
(3 rows)

taxonomy_ncbi=> select d.datname,
taxonomy_ncbi->        (select string_agg(u.usename, ',' order by u.usename) 
taxonomy_ncbi(>         from pg_user u 
taxonomy_ncbi(>         where has_database_privilege(u.usename, d.datname, 'CONNECT')) as allowed_users
taxonomy_ncbi-> from pg_database d
taxonomy_ncbi-> order by d.datname;
    datname    |    allowed_users    
---------------+---------------------
 admin         | admin,postgres,test
 postgres      | admin,postgres,test
 taxonomy_ncbi | admin,postgres,test
 template0     | admin,postgres,test
 template1     | admin,postgres,test
(5 rows)

###counting the rows:
SELECT count(*) AS exact_count FROM public.taxonomy;

###make a query with a taxID:
SELECT * from taxonomy where tax_id = 10;


