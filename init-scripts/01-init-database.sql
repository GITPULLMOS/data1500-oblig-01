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

-- 1 lås kan ha maks 1 sykkel samtidig (for ikke-null laas_id)
CREATE UNIQUE INDEX uq_sykkel_laas_notnull
  ON sykkel(laas_id)
  WHERE laas_id IS NOT NULL;

CREATE TABLE utleie (
  utleie_id        BIGSERIAL PRIMARY KEY,
  kunde_id         BIGINT NOT NULL REFERENCES kunde(kunde_id),
  sykkel_id        BIGINT NOT NULL REFERENCES sykkel(sykkel_id),
  utlevert_tid     TIMESTAMPTZ NOT NULL,
  innlevert_tid    TIMESTAMPTZ NULL,
  start_stasjon_id BIGINT NOT NULL REFERENCES stasjon(stasjon_id),
  slutt_stasjon_id BIGINT NULL REFERENCES stasjon(stasjon_id),
  leiebelop        NUMERIC(10,2) NOT NULL,

  CONSTRAINT chk_utleie_tid
    CHECK (innlevert_tid IS NULL OR innlevert_tid >= utlevert_tid),

  CONSTRAINT chk_utleie_sluttinfo
    CHECK (
      (innlevert_tid IS NULL AND slutt_stasjon_id IS NULL)
      OR
      (innlevert_tid IS NOT NULL AND slutt_stasjon_id IS NOT NULL)
    ),

  CONSTRAINT chk_utleie_belop
    CHECK (leiebelop >= 0)
);


-- Sett inn testdata
-- 5 kunder
INSERT INTO kunde (mobilnummer, epost, fornavn, etternavn) VALUES
('90000001', 'ola.nordmann1@example.com', 'Ola', 'Nordmann'),
('90000002', 'kari.nordmann2@example.com', 'Kari', 'Nordmann'),
('90000003', 'per.hansen3@example.com', 'Per', 'Hansen'),
('90000004', 'anne.larsen4@example.com', 'Anne', 'Larsen'),
('90000005', 'mari.johansen5@example.com', 'Mari', 'Johansen');

-- 5 stasjoner
INSERT INTO stasjon (navn, adresse, breddegrad, lengdegrad) VALUES
('Sentrum',        'Storgata 1',     59.913900, 10.752200),
('Torg',           'Torget 2',       59.912300, 10.746100),
('Universitet',    'Campusveien 3',  59.918000, 10.734000),
('Parken',         'Parkgata 4',     59.920500, 10.760800),
('Stasjon Vest',   'Vestveien 5',    59.909800, 10.736900);

-- 100 låser (20 per stasjon)
INSERT INTO laas (stasjon_id, laasnr, aktiv)
SELECT s.stasjon_id, gs.laasnr, TRUE
FROM stasjon s
CROSS JOIN generate_series(1, 20) AS gs(laasnr)
ORDER BY s.stasjon_id, gs.laasnr;

-- 100 sykler: 1 sykkel per lås, sykkelen arver stasjon_id fra låsen
INSERT INTO sykkel (stasjon_id, laas_id, aktiv, modell)
SELECT l.stasjon_id, l.laas_id, TRUE,
       CASE WHEN (l.laas_id % 3) = 0 THEN 'CityBike'
            WHEN (l.laas_id % 3) = 1 THEN 'Urban'
            ELSE 'Classic'
       END
FROM laas l
ORDER BY l.laas_id
LIMIT 100;

-- 50 utleier (avsluttede)
INSERT INTO utleie (
  kunde_id, sykkel_id, utlevert_tid, innlevert_tid,
  start_stasjon_id, slutt_stasjon_id, leiebelop
)
SELECT
  ((i - 1) % 5) + 1 AS kunde_id,
  ((i - 1) % 100) + 1 AS sykkel_id,
  (now() - interval '40 days') + (i * interval '6 hours') AS utlevert_tid,
  (now() - interval '40 days') + (i * interval '6 hours')
    + interval '20 minutes'
    + ((i % 30) * interval '1 minute') AS innlevert_tid,
  s_start.stasjon_id AS start_stasjon_id,
  (((s_start.stasjon_id - 1 + (i % 5)) % 5) + 1) AS slutt_stasjon_id,
  (10 + (i % 25))::numeric(10,2) AS leiebelop
FROM generate_series(1, 50) AS g(i)
JOIN sykkel sy ON sy.sykkel_id = (((i - 1) % 100) + 1)
JOIN stasjon s_start ON s_start.stasjon_id = sy.stasjon_id;



-- DBA setninger (rolle: kunde, bruker: kunde_1)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'kunde') THEN
    CREATE ROLE kunde;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'kunde_1') THEN
    CREATE USER kunde_1 WITH PASSWORD 'kunde_1';
    GRANT kunde TO kunde_1;
  END IF;
END $$;

-- Gi rolle/bruker rettigheter til tabellene (enkelt oppsett for øving)
GRANT CONNECT ON DATABASE postgres TO kunde;
GRANT USAGE ON SCHEMA public TO kunde;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO kunde;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO kunde;

COMMIT;

-- Eventuelt: Opprett indekser for ytelse
CREATE INDEX IF NOT EXISTS idx_laas_stasjon_id ON laas(stasjon_id);
CREATE INDEX IF NOT EXISTS idx_sykkel_stasjon_id ON sykkel(stasjon_id);
CREATE INDEX IF NOT EXISTS idx_utleie_kunde_id ON utleie(kunde_id);
CREATE INDEX IF NOT EXISTS idx_utleie_sykkel_id ON utleie(sykkel_id);
CREATE INDEX IF NOT EXISTS idx_utleie_start_stasjon_id ON utleie(start_stasjon_id);
CREATE INDEX IF NOT EXISTS idx_utleie_slutt_stasjon_id ON utleie(slutt_stasjon_id);

-- Vis at initialisering er fullført (kan se i loggen fra "docker-compose log"
SELECT 'Database initialisert!' as status;