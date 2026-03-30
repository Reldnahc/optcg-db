ALTER TABLE scan_ingest_files
ALTER COLUMN s3_key DROP NOT NULL;

ALTER TABLE scan_ingest_files
ALTER COLUMN public_url DROP NOT NULL;
