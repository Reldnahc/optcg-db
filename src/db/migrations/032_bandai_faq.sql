CREATE TABLE bandai_faq_documents (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  language   TEXT NOT NULL DEFAULT 'en',
  source_key TEXT NOT NULL,
  title      TEXT NOT NULL,
  pdf_url    TEXT NOT NULL,
  updated_on DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (language, source_key)
);

CREATE TABLE bandai_faq_entries (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES bandai_faq_documents(id) ON DELETE CASCADE,
  ordinal     INT NOT NULL,
  card_number TEXT NOT NULL,
  card_name   TEXT NOT NULL,
  question    TEXT NOT NULL,
  answer      TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (document_id, ordinal)
);

CREATE INDEX idx_bandai_faq_documents_language_updated
  ON bandai_faq_documents(language, updated_on DESC, source_key);

CREATE INDEX idx_bandai_faq_entries_card_number
  ON bandai_faq_entries(card_number);

CREATE INDEX idx_bandai_faq_entries_document_id
  ON bandai_faq_entries(document_id, ordinal);
