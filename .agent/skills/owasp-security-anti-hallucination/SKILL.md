---
name: owasp-security-anti-hallucination
description: Enforce OWASP security standards (Top 10 Web, Mobile, and API) and strict anti-hallucination verification rules during code generation, security audits, architecture reviews, and technical Q&A. Use whenever writing backend/frontend/mobile code, reviewing repositories, configuring databases or authentication, or answering technical questions where accuracy and security are critical.
---

# OWASP Security and Anti-Hallucination Guardrails

This skill enforces strict adherence to OWASP security best practices alongside verifiable anti-hallucination protocols so generated code, audits, and technical answers are secure, grounded in real evidence, and free of fabricated APIs or assumptions.

## When to Use

- Writing, refactoring, or reviewing backend, frontend, mobile (e.g., Flutter/Dart), or database code (e.g., PostgreSQL, Supabase, SQL migrations).
- Designing or auditing authentication, authorization, role-based access control (RBAC), row-level security (RLS), or API endpoints.
- Performing security reviews, threat modeling, or vulnerability assessments.
- Answering technical or project-specific questions where inventing libraries, methods, file paths, or configuration details would cause errors.

## Part 1: OWASP Security Enforcement

Apply these controls by default whenever generating code, schemas, or architectural recommendations:

### 1. Access Control and Authorization (OWASP A01 / API1 / API5)
- Enforce deny-by-default access policies. Never rely solely on client-side route guards or UI hiding to protect data.
- Require server-side or database-level authorization checks (such as Supabase Row-Level Security policies or middleware) on every query, mutation, and endpoint.
- Validate resource ownership (prevent IDOR/BOLA) so users can only access or modify records belonging to their authenticated role and tenant/account.

### 2. Cryptographic Failures and Secrets Management (OWASP A02 / M9)
- Never hardcode API keys, tokens, passwords, private keys, or connection strings in source code, client apps, or version control.
- Use environment variables or secure platform storage (e.g., Android Keystore, iOS Keychain) for sensitive tokens.
- Enforce TLS/HTTPS for all network communications and avoid weak hashes (MD5, SHA-1) or insecure random number generators for security tokens.

### 3. Injection Prevention (OWASP A03 / M7)
- Always use parameterized queries, prepared statements, or safe ORM query builders. Never concatenate user input directly into SQL, NoSQL, OS commands, or dynamic filters.
- Validate, sanitize, and type-check all external inputs (forms, query params, headers, deep links, GPS coordinates, file uploads) using strict schemas and allowlists.

### 4. Insecure Design and Business Logic Integrity (OWASP A04 / API6)
- Enforce business constraints on the backend (e.g., seat/capacity limits, state transitions, rate limits, anti-replay protections) rather than trusting client payloads.
- Apply the principle of least privilege across database roles, service accounts, and API keys.

### 5. Security Misconfiguration and Data Exposure (OWASP A05 / API3)
- Return minimal data required by the client; never expose internal stack traces, debug flags, raw database errors, or overly verbose user objects in production responses.
- Disable permissive CORS wildcards (`*`) with credentials and ensure debug/demo credentials are isolated from production builds.

### 6. Authentication, Biometrics, and Session Management (OWASP A07 / M1 / M4)
- Validate session tokens and expiration on every privileged operation.
- When handling sensitive data such as biometrics, location tracking, or PII, minimize retention, require explicit consent, and process or store hashes/templates securely rather than raw sensitive media when possible.

### 7. Logging, Monitoring, and Vulnerable Components (OWASP A06 / A09)
- Log security-relevant events (failed logins, role changes, access denials) without logging passwords, tokens, or sensitive PII.
- Recommend only well-maintained, verified dependencies and flag outdated or unpinned packages.

## Part 2: Anti-Hallucination Protocol

Follow these verification steps before outputting technical claims, code, or project analysis:

### 1. Grounding in Verified Context
- Base claims about an existing codebase, file structure, database schema, or project state strictly on provided files, logs, or tool outputs.
- If a file path, table name, column, or configuration is not present in the context, state explicitly what is unknown rather than guessing or inventing names.

### 2. API, Package, and Syntax Verification
- Only use classes, methods, flags, and package versions that actually exist in the target language or framework SDK.
- If uncertain about a specific library signature, version compatibility, or external specification, flag the uncertainty explicitly and advise checking official documentation rather than fabricating syntax.

### 3. Distinction Between Fact and Recommendation
- Clearly separate **Verified Facts** (directly observed in code, docs, or specifications) from **Assumptions or Recommendations** (proposed fixes, architectural patterns, or inferred behavior).
- Never claim that code was executed, tested, or scanned unless an execution or analysis tool actually ran and returned that output.

### 4. Self-Audit Checklist Before Responding
Before finalizing any technical response or code block, verify:
1. Are all database queries parameterized and protected by server-side authorization/RLS?
2. Are all secrets excluded from client-side code?
3. Are every referenced file, table, dependency, and API method verified against the provided context or official SDK standards?
4. Have any unverified assumptions been explicitly labeled as such?

## Gotchas

- **Client-only security illusion:** Adding a route guard in frontend frameworks (like `go_router` or React Router) improves UX, but does not secure data. Always pair frontend guards with backend/database policies.
- **Hallucinated SDK methods:** Do not invent convenience methods on third-party packages (such as Supabase, Flutter plugins, or OSRM clients) when standard documented methods are required.
- **Over-assuming schema details:** When writing SQL migrations or queries for an existing project, ask for or inspect the exact table/column names if they are not explicitly provided.