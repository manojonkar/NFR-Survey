-- ============================================================
-- NFR PLATFORM — COMPLETE DATABASE SCHEMA
-- Run this in Supabase SQL Editor
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- COMPANIES (tenants)
-- ============================================================
CREATE TABLE companies (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          TEXT NOT NULL,
  slug          TEXT UNIQUE NOT NULL, -- used for subdomain: slug.nfrcompany.com
  logo_url      TEXT,
  email_domain  TEXT, -- e.g. "tata.com" for auto-verification
  admin_email   TEXT NOT NULL,
  plan          TEXT DEFAULT 'trial', -- trial | basic | pro
  trial_ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '3 months'),
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- USERS
-- ============================================================
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id    UUID REFERENCES companies(id) ON DELETE CASCADE,
  email         TEXT NOT NULL,
  phone         TEXT,
  full_name     TEXT NOT NULL,
  role          TEXT NOT NULL CHECK (role IN ('super_admin','company_admin','hr_head','supervisor','leader','rater')),
  is_active     BOOLEAN DEFAULT TRUE,
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(company_id, email)
);

-- ============================================================
-- SUPERVISOR → LEADER relationships
-- ============================================================
CREATE TABLE leader_supervisors (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id    UUID REFERENCES companies(id) ON DELETE CASCADE,
  leader_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  supervisor_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(leader_id, supervisor_id)
);

-- ============================================================
-- RATER ASSIGNMENTS (who rates whom)
-- ============================================================
CREATE TABLE rater_assignments (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id    UUID REFERENCES companies(id) ON DELETE CASCADE,
  leader_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  rater_id      UUID REFERENCES users(id) ON DELETE CASCADE,
  rater_role    TEXT NOT NULL, -- Supervisor, Peer, Team member, etc.
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(leader_id, rater_id)
);

-- ============================================================
-- SURVEY CAMPAIGNS (monthly)
-- ============================================================
CREATE TABLE survey_campaigns (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id    UUID REFERENCES companies(id) ON DELETE CASCADE,
  name          TEXT NOT NULL, -- e.g. "June 2026"
  month         INT NOT NULL,  -- 1-12
  year          INT NOT NULL,
  opens_at      TIMESTAMPTZ NOT NULL,
  closes_at     TIMESTAMPTZ NOT NULL,
  status        TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled','active','paused','closed')),
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(company_id, month, year)
);

-- ============================================================
-- CAMPAIGN EXTENSIONS (per rater, max 3 days)
-- ============================================================
CREATE TABLE campaign_extensions (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id   UUID REFERENCES survey_campaigns(id) ON DELETE CASCADE,
  rater_id      UUID REFERENCES users(id) ON DELETE CASCADE,
  extended_until TIMESTAMPTZ NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- SURVEY RESPONSES
-- ============================================================
CREATE TABLE survey_responses (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id   UUID REFERENCES survey_campaigns(id) ON DELETE CASCADE,
  leader_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  rater_id      UUID REFERENCES users(id) ON DELETE CASCADE,
  rater_role    TEXT NOT NULL,
  company_id    UUID REFERENCES companies(id) ON DELETE CASCADE,
  -- 5 question scores (-3 to +3)
  q1_score      INT CHECK (q1_score BETWEEN -3 AND 3), -- Proactive comms
  q2_score      INT CHECK (q2_score BETWEEN -3 AND 3), -- SLA adherence
  q3_score      INT CHECK (q3_score BETWEEN -3 AND 3), -- Delay communication
  q4_score      INT CHECK (q4_score BETWEEN -3 AND 3), -- Promise reliability
  q5_score      INT CHECK (q5_score BETWEEN -3 AND 3), -- Responsiveness
  nfr_declared  BOOLEAN, -- true = NFR confirmed, false = follow-up needed
  comment       TEXT,
  submitted_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(campaign_id, leader_id, rater_id)
);

-- ============================================================
-- AGGREGATED SCORES (computed after campaign closes)
-- ============================================================
CREATE TABLE leader_scores (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id     UUID REFERENCES survey_campaigns(id) ON DELETE CASCADE,
  leader_id       UUID REFERENCES users(id) ON DELETE CASCADE,
  company_id      UUID REFERENCES companies(id) ON DELETE CASCADE,
  avg_score       NUMERIC(4,2), -- overall average
  q1_avg          NUMERIC(4,2),
  q2_avg          NUMERIC(4,2),
  q3_avg          NUMERIC(4,2),
  q4_avg          NUMERIC(4,2),
  q5_avg          NUMERIC(4,2),
  nfr_pct         NUMERIC(5,2), -- % of raters who declared NFR
  raters_submitted INT,
  raters_total    INT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(campaign_id, leader_id)
);

-- ============================================================
-- ACTION PLANS
-- ============================================================
CREATE TABLE action_plans (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  leader_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  campaign_id   UUID REFERENCES survey_campaigns(id) ON DELETE CASCADE,
  company_id    UUID REFERENCES companies(id) ON DELETE CASCADE,
  commitment    TEXT NOT NULL,
  stakeholder   TEXT,
  due_date      DATE,
  status        TEXT DEFAULT 'not-started' CHECK (status IN ('not-started','in-progress','done')),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- NOTIFICATION LOG
-- ============================================================
CREATE TABLE notification_log (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id    UUID REFERENCES companies(id) ON DELETE CASCADE,
  recipient_id  UUID REFERENCES users(id) ON DELETE CASCADE,
  type          TEXT, -- invite | reminder | results | extension
  channel       TEXT, -- email | whatsapp | sms
  status        TEXT, -- sent | failed
  sent_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY — companies only see their own data
-- ============================================================
ALTER TABLE companies           ENABLE ROW LEVEL SECURITY;
ALTER TABLE users               ENABLE ROW LEVEL SECURITY;
ALTER TABLE leader_supervisors  ENABLE ROW LEVEL SECURITY;
ALTER TABLE rater_assignments   ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_campaigns    ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_responses    ENABLE ROW LEVEL SECURITY;
ALTER TABLE leader_scores       ENABLE ROW LEVEL SECURITY;
ALTER TABLE action_plans        ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_log    ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_extensions ENABLE ROW LEVEL SECURITY;

-- Allow anon/service role full access for now (tighten per-role later)
CREATE POLICY "allow_all" ON companies           FOR ALL USING (true);
CREATE POLICY "allow_all" ON users               FOR ALL USING (true);
CREATE POLICY "allow_all" ON leader_supervisors  FOR ALL USING (true);
CREATE POLICY "allow_all" ON rater_assignments   FOR ALL USING (true);
CREATE POLICY "allow_all" ON survey_campaigns    FOR ALL USING (true);
CREATE POLICY "allow_all" ON survey_responses    FOR ALL USING (true);
CREATE POLICY "allow_all" ON leader_scores       FOR ALL USING (true);
CREATE POLICY "allow_all" ON action_plans        FOR ALL USING (true);
CREATE POLICY "allow_all" ON notification_log    FOR ALL USING (true);
CREATE POLICY "allow_all" ON campaign_extensions FOR ALL USING (true);

-- ============================================================
-- SEED: NFR super-admin company
-- ============================================================
INSERT INTO companies (name, slug, admin_email, plan)
VALUES ('Management Innovations', 'mi-admin', 'admin@nfrcompany.com', 'super');
