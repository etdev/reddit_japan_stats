--- schema (postgres)
CREATE TYPE thread_type AS ENUM ('complaint', 'praise');
CREATE TABLE threads (
  id SERIAL,
  date date NOT NULL,
  type thread_type,
  author varchar(20),
  CONSTRAINT "threads_pkey" PRIMARY KEY ("id")
);
CREATE INDEX idx_date ON threads (date);
CREATE INDEX idx_type ON threads (type);
CREATE INDEX idx_author ON threads (author);

CREATE TABLE comments (
  id SERIAL,
  thread_id integer references threads(id) NOT NULL,
  body text NOT NULL,
  url varchar(128) NOT NULL,
  CONSTRAINT "comments_pkey" PRIMARY KEY ("id")
);

