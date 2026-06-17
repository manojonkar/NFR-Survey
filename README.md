# NFR Platform v2 — Production Build
**www.nfrcompany.com** — Multi-tenant No Follow-up Required (NFR) 360° feedback platform

Built with: React 18 · Vite · Tailwind CSS · Supabase · Vercel

---

## 1. Supabase Setup (one-time)

1. Go to your Supabase project → **SQL Editor**
2. Open the file `supabase/schema.sql` from this repo
3. Paste the entire contents and click **Run**
4. This creates all 10 tables with row-level security

### Enable Supabase Auth
1. Supabase → **Authentication → Settings**
2. Set **Site URL** to `https://nfrcompany.com`
3. Add redirect URLs:
   - `https://nfrcompany.com/dashboard`
   - `https://nfr-survey.vercel.app/dashboard`

### Enable Storage (for company logos)
1. Supabase → **Storage → New bucket**
2. Name: `company-assets`
3. Set to **Public**

---

## 2. Local Development

```bash
unzip nfr-v2.zip
cd nfr-v2
npm install
npm run dev
# → http://localhost:5173
```

---

## 3. Deploy to Vercel

### Option A — Vercel Dashboard (recommended)
1. Push code to GitHub (new repo: `nfr-platform`)
2. Go to vercel.com → **New Project** → Import repo
3. Framework: **Vite** · Build: `npm run build` · Output: `dist`
4. Add Environment Variables:
   - `VITE_SUPABASE_URL` = `https://ldwmqcvngaedjsvifwai.supabase.co`
   - `VITE_SUPABASE_ANON_KEY` = your anon key
5. Click **Deploy**

### Option B — CLI
```bash
npm install -g vercel
vercel
vercel env add VITE_SUPABASE_URL
vercel env add VITE_SUPABASE_ANON_KEY
vercel --prod
```

---

## 4. Connect nfrcompany.com via DomainRacer

1. In **Vercel** → Project → **Settings → Domains**
2. Add: `nfrcompany.com` and `www.nfrcompany.com`
3. Vercel will show you DNS values to add

4. Log in to **DomainRacer** → My Domains → `nfrcompany.com` → **Manage DNS**
5. Add/update these records:

| Type  | Host/Name | Value                    | TTL  |
|-------|-----------|--------------------------|------|
| A     | @         | 76.76.21.21              | 3600 |
| CNAME | www       | cname.vercel-dns.com     | 3600 |

6. Save. DNS propagates in 5–60 minutes.
7. Vercel auto-issues free SSL certificate.

✅ Site live at **https://nfrcompany.com**

---

## 5. Project Structure

```
nfr-v2/
├── supabase/
│   └── schema.sql              ← Run this in Supabase SQL Editor
├── src/
│   ├── lib/
│   │   └── supabase.js         ← All DB queries
│   ├── hooks/
│   │   └── useAuth.js          ← Auth context
│   ├── pages/
│   │   ├── LandingPage.jsx     ← Public marketing page
│   │   ├── SignupPage.jsx      ← Company self-serve signup
│   │   ├── LoginPage.jsx       ← Sign in
│   │   ├── OnboardingPage.jsx  ← 4-step setup wizard
│   │   ├── DashboardShell.jsx  ← Sidebar + role-based routing
│   │   └── dashboard/
│   │       ├── AdminDashboard.jsx    ← KPIs + campaign control
│   │       ├── ManageUsers.jsx       ← Leaders, raters, CSV import
│   │       ├── ManageCampaigns.jsx   ← Create/pause/extend surveys
│   │       ├── SurveyPage.jsx        ← Live −3 to +3 survey
│   │       ├── ResultsPage.jsx       ← 3-trend scores + action plan
│   │       ├── AnalyticsPage.jsx     ← Org charts + leaderboard
│   │       └── NotificationsPage.jsx ← Reminders + log
│   ├── components/
│   │   └── UI.jsx              ← Shared components
│   ├── App.jsx
│   ├── main.jsx
│   └── index.css
├── .env                        ← Supabase keys (never commit this)
├── .env.example                ← Safe to commit
├── vercel.json
└── package.json
```

---

## 6. Database Tables

| Table                | Purpose |
|---------------------|---------|
| `companies`         | Multi-tenant isolation — one row per company |
| `users`             | All people (admin, HR, supervisor, leader, rater) |
| `leader_supervisors`| Who supervises whom |
| `rater_assignments` | Which raters rate which leaders |
| `survey_campaigns`  | Monthly campaigns with open/close dates |
| `campaign_extensions`| Per-rater deadline extensions (max 3 days) |
| `survey_responses`  | Individual survey answers (−3 to +3) |
| `leader_scores`     | Aggregated scores per leader per campaign |
| `action_plans`      | Leader's monthly improvement commitments |
| `notification_log`  | Email/WhatsApp notification history |

---

## 7. User Roles

| Role | Access |
|------|--------|
| `super_admin` | All companies (Management Innovations) |
| `company_admin` | Everything within their company |
| `hr_head` | All leaders' averaged scores + reports |
| `supervisor` | Own score + direct reports only |
| `leader` | Own averaged scores + trends |
| `rater` | Survey form only |

---

## 8. Phase 2 Roadmap (next build)

- [ ] PDF report generation (company logo + MI logo on every page)
- [ ] SendGrid email integration for automated reminders
- [ ] WhatsApp via Twilio
- [ ] Supabase Edge Functions for scheduled campaign auto-open/close
- [ ] Benchmark score vs company average
- [ ] Super-admin dashboard (your view across all companies)
- [ ] Billing / subscription management

---

## Support
Platform by **Management Innovations** · Vision to Implementation  
admin@nfrcompany.com
