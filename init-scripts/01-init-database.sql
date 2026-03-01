-- ============================================================================
-- DATA1500 - Oblig 1: Arbeidskrav I våren 2026
-- Initialiserings-skript for PostgreSQL
-- ============================================================================

-- Opprett grunnleggende tabeller
BEGIN;

DROP TABLE IF EXISTS utleie CASCADE;
DROP TABLE IF EXISTS sykkel CASCADE;
DROP TABLE IF EXISTS laas CASCADE;
DROP TABLE IF EXISTS stasjon CASCADE;
DROP TABLE IF EXISTS kunde CASCADE;

CREATE TABLE kunde (
  kunde_id    BIGSERIAL PRIMARY KEY,
  mobilnummer TEXT NOT NULL,
  epost       TEXT NOT NULL,
  fornavn     TEXT NOT NULL,
  etternavn   TEXT NOT NULL,

  CONSTRAINT chk_kunde_mobil
    CHECK (mobilnummer ~ '^[0-9]{8,15}$'),

  CONSTRAINT chk_kunde_epost
    CHECK (epost ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),

  CONSTRAINT chk_kunde_fornavn
    CHECK (length(trim(fornavn)) > 0),

  CONSTRAINT chk_kunde_etternavn
    CHECK (length(trim(etternavn)) > 0),

  CONSTRAINT uq_kunde_mobil UNIQUE (mobilnummer),
  CONSTRAINT uq_kunde_epost UNIQUE (epost)
);



-- Sett inn testdata



-- DBA setninger (rolle: kunde, bruker: kunde_1)



-- Eventuelt: Opprett indekser for ytelse



-- Vis at initialisering er fullført (kan se i loggen fra "docker-compose log"
SELECT 'Database initialisert!' as status;