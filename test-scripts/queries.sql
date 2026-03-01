-- ============================================================================
-- TEST-SKRIPT FOR OBLIG 1
-- ============================================================================

-- Kjør med: docker-compose exec postgres psql -h -U admin -d data1500_db -f test-scripts/queries.sql

-- Oppgave 5.1: Vis alle sykler
SELECT *
FROM sykkel;


-- Oppgave 5.2
SELECT etternavn, fornavn, mobilnummer
FROM kunde
ORDER BY etternavn ASC;


-- Oppgave 5.3
SELECT DISTINCT s.*
FROM sykkel s
JOIN utleie u ON s.sykkel_id = u.sykkel_id
WHERE u.utlevert_tid > DATE '2026-01-01';


-- Oppgave 5.4
SELECT COUNT(*) AS antall_kunder
FROM kunde;


-- Oppgave 5.5
SELECT k.kunde_id,
       k.fornavn,
       k.etternavn,
       COUNT(u.utleie_id) AS antall_utleier
FROM kunde k
LEFT JOIN utleie u ON k.kunde_id = u.kunde_id
GROUP BY k.kunde_id, k.fornavn, k.etternavn
ORDER BY k.kunde_id;


-- Oppgave 5.6
SELECT k.*
FROM kunde k
LEFT JOIN utleie u ON k.kunde_id = u.kunde_id
WHERE u.utleie_id IS NULL;


-- Oppgave 5.7
SELECT s.*
FROM sykkel s
LEFT JOIN utleie u ON s.sykkel_id = u.sykkel_id
WHERE u.utleie_id IS NULL;


-- Oppgave 5.8
SELECT s.sykkel_id,
       k.kunde_id,
       k.fornavn,
       k.etternavn,
       u.utlevert_tid
FROM utleie u
JOIN sykkel s ON u.sykkel_id = s.sykkel_id
JOIN kunde k ON u.kunde_id = k.kunde_id
WHERE u.innlevert_tid IS NULL
  AND u.utlevert_tid < NOW() - INTERVAL '1 day';

-- En test med en SQL-spørring mot metadata i PostgreSQL (kan slettes fra din script)
select nspname as schema_name from pg_catalog.pg_namespace;
