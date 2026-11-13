# Worked example (anonymized) — TC API prep

**Scope:** User service `orders` API — 4 endpoints from OpenAPI  
**Outcome:** 13 manual API TC rows → CSV in workspace

## Inputs

- API spec: Confluence page (scope: CRUD + cancel)
- Swagger: `https://api.staging.example.com/openapi.json`
- Delivery: CSV only → `references/orders_API_TC.csv`

## Repro — agent steps (abbreviated)

1. **Phase A:** Fetched Swagger; noted `POST /orders`, `GET /orders/{id}`, `PATCH` status, `DELETE` soft-delete.
2. **Phase B:** User replied `default` columns. **Phase C:** CSV (`{SCOPE}` = `orders`).
3. **Phase D:** Designed happy + 401 + 400 validation per endpoint (12 rows).
4. **Phase E:** Caught missing 404 on `GET` — inserted it after the 400 validation rows (order: 2xx, 401/403, 400, 404) and renumbered so ids follow the row order. Coverage block: **Ready for draft: YES**.
5. **Phase F:** Draft in chat → user `approve`.
6. **Phase G1:** Wrote `references/orders_API_TC.md` + CSV via [csv-export-rules.md](../../../../references/csv-export-rules.md); G-verify: 13 rows + header.

## Output snippet

```text
Draft API test cases (not published yet)
**Coverage:** 4 endpoints / 13 test cases
**Columns:** default · **Priority rule:** default — High = write happy path and auth; Medium = validation; Low = read 404
| **Test Case ID** | **Module / Feature** | **Services Impacted** | **Test Title** | **Precondition** | **Test Data** | **Expected Result** | **Priority** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TC_API_Orders_01 | Orders | order-service | POST /orders happy path | Bearer token | POST /orders, body {...} | HTTP 201 + orderId in body | High |
```

## Lessons

- Swagger `security` scheme drove 401 cases — spec PDF alone was incomplete.
- NEVER deliver before Phase F approval.
