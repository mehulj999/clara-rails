# Clara — (Rails + React)

A local-first app to upload contract PDFs, auto-parse key fields, and manage upcoming obligations across countries (Germany 🇩🇪 and India 🇮🇳).

## Tech Stack

- **Backend:** Ruby on Rails (API), PostgreSQL, Active Storage
- **Frontend:** React + TypeScript (Vite), Axios auth (JWT)
- **Parsing:** Background job reads PDF text and applies country/provider parsers to populate contracts

## Scope

Contracts (mobile/internet/gym/insurance).
Statements can be added later with the same pattern.

---

## Features

- Upload a PDF, compute SHA-256, store once (de-dupe).
- Auto-parse contracts (DE providers: O2, Lebara, Vodafone Internet).
- Country-aware parsing (DE/IN) with hints or auto-detection.
- Link documents ↔ contracts; view parse status.
- Contract CRUD scoped to the signed-in user via Person.

---

## Data Model (simplified)

```
User ──< Person ──< Contract ──< Document (Active Storage file)
```


### contracts

| Column           | Description                                    |
|:-----------------|:-----------------------------------------------|
| id               | Contract ID                                    |
| person_id        | Linked person                                  |
| contract_type    | mobile / gym / insurance / internet            |
| provider         | e.g. "Telekom"                                 |
| category         | Optional category                              |
| plan_name        | Plan name                                      |
| contract_number  | Contract number                                |
| customer_number  | Customer number                                |
| msisdn           | Phone number                                   |
| start_date       | Contract start date                            |
| end_date         | Contract end date                              |
| min_term_months  | Minimum term (months)                          |
| notice_period_days| Notice period (days)                          |
| monthly_fee      | Monthly fee (standard)                         |
| promo_monthly_fee| Promotional fee                                |
| promo_end_date   | End of promo period                            |
| currency         | Currency code                                  |
| country_code     | "DE" or "IN"                                   |
| notes            | Free text notes                                |
| discarded_at     | Soft-delete timestamp                          |
| timestamps       | Created/updated at                             |

contract_type ∈ mobile | gym | insurance | internet (no STI usage).

### documents

| Column          | Description                                   |
|:----------------|:----------------------------------------------|
| id              | Document ID                                   |
| contract_id     | Linked contract ID                            |
| sha256          | Unique doc hash                               |
| content_type    | MIME type                                     |
| size_bytes      | File size                                     |
| status          | parsing status (pending|parsed|failed)         |
| parser_name     | parser used                                   |
| parsed_at       | When parsed                                   |
| parse_error     | error message                                 |
| country_code    | Optional hint                                 |
| uploaded_by_id  | User ID (who uploaded)                        |
| timestamps      | Created/updated                               |
| file            | Attachment: Active Storage                    |

---

## API Overview

All routes are JWT protected and scoped to current_user.

### Contracts

| Method | Route                       | Note                |
| ------ | --------------------------- | ------------------- |
| GET    | /api/v1/contracts           | List                |
| POST   | /api/v1/contracts           | Create              |
| GET    | /api/v1/contracts/:id       | Show                |
| PATCH  | /api/v1/contracts/:id       | Update              |
| DELETE | /api/v1/contracts/:id       | Soft delete         |

**Create payload**
```{
  "contract": {
    "person_id": 1,
    "contract_type": "mobile",
    "provider": "Telekom",
    "currency": "EUR",
    "country_code": "DE"
  }
}
```

### Documents

| Method | Route                        | Note                       |
| ------ | ---------------------------- | --------------------------|
| GET    | /api/v1/documents            | List                       |
| GET    | /api/v1/documents/:id        | Show                       |
| POST   | /api/v1/documents            | Upload (multipart/formdata)|

**Upload fields (multipart):**
- file (required): the PDF
- contract_id (recommended): link parsed result to this contract

Optional parsing hints:
- country (DE|IN)
- domain (contract)
- subtype (mobile|internet|gym|insurance)
- provider (o2|lebara|vodafone …)

**Response example**
```{
"id": 42,
"sha256": "…",
"status": "pending",
"parser_name": null,
"parsed_at": null,
"parse_error": null,
"content_type": "application/pdf",
"size_bytes": 123456,
"contract_id": 7,
"created_at": "2025-09-23T09:00:00Z"
}```


---

## Parsing Flow

- **Upload:** POST /api/v1/documents saves file (Active Storage), computes sha256, inserts documents.status='pending', enqueues job.
- **Job:** `ParseDocumentJob` opens the PDF, extracts text with pdf-reader, and calls `DocumentParser.parse(io, hints)`.
- **Routing:** `DocumentParser` → `Parsers::Contracts::Registry` → country registry → provider parser (e.g. DE::O2MobileParser).
- **Extract:** Parser returns a normalized attribute hash (plan, msisdn, dates, fees…). Currency default is derived from country (DE→EUR, IN→INR) if missing.
- **Persist:** The job merges parsed values into the linked contract (fills blanks only), and updates documents.status.

---

## Frontend (React + TS)

**Axios instance**
```
// src/lib/api.ts
import axios from "axios";
export const api = axios.create({
baseURL: import.meta.env.VITE_API_URL || "http://localhost:3000",
headers: { Accept: "application/json" },
});
api.interceptors.request.use((config) => {
const token = localStorage.getItem("jwt");
if (token) config.headers.Authorization = Bearer ${token};
return config;
});
```

**Upload helper**

```
// src/lib/api-documents.ts
import { api } from "./api";
export async function uploadDocument(file: File, contractId?: number, hints?: {
country?: "DE"|"IN"; domain?: "contract"; subtype?: string; provider?: string;
}) {
const form = new FormData();
form.append("file", file);
if (contractId) form.append("contract_id", String(contractId));
if (hints?.country) form.append("country", hints.country);
if (hints?.domain) form.append("domain", hints.domain);
if (hints?.subtype) form.append("subtype", hints.subtype);
if (hints?.provider) form.append("provider", hints.provider);
const res = await api.post("/api/v1/documents", form);
return res.data;
}
```
**New Contract page (snippet)**

```
// after creating the contract, optionally upload and hint:
await uploadDocument(file, contractId, {
country: countryCode, // "DE" or "IN"
domain: "contract",
subtype: contractType, // e.g. "mobile"
provider: provider.toLowerCase()
});
```


---

## Services & Jobs

```
app/services/
document_parser.rb
parsers/
base.rb
contracts/
base_contract_parser.rb
registry.rb
providers/
de/
o2_mobile_parser.rb
lebara_mobile_parser.rb
vodafone_internet_parser.rb
in/
jio_mobile_parser.rb
airtel_mobile_parser.rb

app/jobs/
parse_document_job.rb
```



---

## Setup

### 1) Backend

- Ruby 3.x, Rails 7.x, PostgreSQL

**Gems**


```
gem "pg"
gem "devise"
gem "pdf-reader"
gem "discard"
gem "pagy"
```


**Active Storage**
```
bin/rails active_storage:install
```

**Migrations**
- Add metadata columns to documents (sha256, status, parser fields, etc.).
- Ensure contracts.contract_type (not type) and add country_code (default "DE").

**DB**
```
bin/rails db:create db:migrate
```

**Job adapter**
- Configure Active Job (e.g., Async in dev, Sidekiq in prod):
config/application.rb or environments

```
# config/application.rb or environments
config.active_job.queue_adapter = :async
# or :sidekiq
```

### 2) Frontend

- Node 18+, pnpm/yarn/npm
- `.env` for Vite:

```
VITE_API_URL=http://localhost:3000
```

**Install deps & run:**
```
npm install
npm dev
```


---

## Environment Variables (examples)

- RAILS_MASTER_KEY — Rails credentials
- DATABASE_URL / PG* — Postgres
- ACTIVE_STORAGE_SERVICE — local, amazon, etc.
- JWT_SECRET — if using JWT auth

---

## Security & Privacy

- All endpoints authenticated; data is tenant-scoped via Person.user_id.
- Only last4/msisdn types of identifiers are stored where needed; avoid full PANs.
- No external calls during parsing; everything happens locally.

---

## Development Tips

- Don’t set Content-Type manually on multipart uploads; let Axios/browser choose (boundary needed).
- Idempotency: uploading the same file returns the existing Document (sha256 unique).
- Merging behavior: parsed fields only fill blanks on the contract (no overwrite).
- Observability: documents.status, parser_name, parse_error tell you what happened.

---

## Roadmap

- Add statement domain (issuer, period, due, transactions) using the same registry pattern.
- OCR fallback for scanned PDFs (Tesseract).
- More providers (DE/IN) and categories (insurance, gym).
- “Upcoming” view (due dates, min-term ends) powered by SQL.
- Webhooks/notifications for parsed results.

---

## License

MIT (or your choice). Contributions welcome.






