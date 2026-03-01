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

CREATE TABLE stasjon (
  stasjon_id  BIGSERIAL PRIMARY KEY,
  navn        TEXT NOT NULL,
  adresse     TEXT NOT NULL,
  breddegrad  NUMERIC(9,6),
  lengdegrad  NUMERIC(9,6),

  CONSTRAINT chk_stasjon_navn
    CHECK (length(trim(navn)) > 0),

  CONSTRAINT chk_stasjon_adresse
    CHECK (length(trim(adresse)) > 0),

  CONSTRAINT chk_stasjon_breddegrad
    CHECK (breddegrad IS NULL OR breddegrad BETWEEN -90 AND 90),

  CONSTRAINT chk_stasjon_lengdegrad
    CHECK (lengdegrad IS NULL OR lengdegrad BETWEEN -180 AND 180)
);

CREATE TABLE laas (
  laas_id    BIGSERIAL PRIMARY KEY,
  stasjon_id BIGINT NOT NULL REFERENCES stasjon(stasjon_id) ON DELETE CASCADE,
  laasnr     INTEGER NOT NULL,
  aktiv      BOOLEAN NOT NULL DEFAULT TRUE,

  CONSTRAINT chk_laasnr_pos CHECK (laasnr > 0),
  CONSTRAINT uq_laas_per_stasjon UNIQUE (stasjon_id, laasnr)
);

CREATE TABLE sykkel (
  sykkel_id  BIGSERIAL PRIMARY KEY,
  stasjon_id BIGINT NULL REFERENCES stasjon(stasjon_id),
  laas_id    BIGINT NULL REFERENCES laas(laas_id),
  aktiv      BOOLEAN NOT NULL DEFAULT TRUE,
  modell     TEXT NULL,

  -- Enten utleid (begge NULL) eller parkert (begge NOT NULL)
  CONSTRAINT chk_sykkel_plassering
    CHECK (
      (stasjon_id IS NULL AND laas_id IS NULL)
      OR
      (stasjon_id IS NOT NULL AND laas_id IS NOT NULL)
    ),

  CONSTRAINT chk_sykkel_modell
    CHECK (modell IS NULL OR length(trim(modell)) > 0)
);

-- Eventuelt: Opprett indekser for ytelse



-- Vis at initialisering er fullført (kan se i loggen fra "docker-compose log"
SELECT 'Database initialisert!' as status;