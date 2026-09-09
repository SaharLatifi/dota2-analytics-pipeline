-- ============================================================
-- Match Processing Status Table
-- Purpose: track which rows in raw.public_matches have had their
--          full match detail + player detail fetched.
--
-- This is a pipeline bookkeeping table, NOT raw source data —
-- unlike raw.public_matches / raw.matches / raw.players, this
-- table IS allowed to be updated (Decision 4 does not apply here).
--
-- Keyed by dlt_id (unique per row in raw.public_matches), not
-- match_id, since the same match_id can legitimately appear in
-- multiple batches (append-only raw layer).
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.control_match_processing_status (
    id                   NUMBER          AUTOINCREMENT START 1 INCREMENT 1,
    dlt_id               VARCHAR(50)     NOT NULL,   -- FK to raw.public_matches._dlt_id
    match_id             NUMBER          NOT NULL,   -- for readability / joins, not unique alone
    status               VARCHAR(20)     NOT NULL DEFAULT 'pending',  -- pending | success | failed
    attempts             NUMBER          NOT NULL DEFAULT 0,
    last_error           VARCHAR(1000)   NULL,
    created_at           TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    updated_at           TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT pk_match_processing_status PRIMARY KEY (id),
    CONSTRAINT uq_match_processing_status_dlt_id UNIQUE (dlt_id)
);