# Security Policy

## Supported Versions

This project follows a rolling-release model on `main`. Security fixes
are applied to the latest release only.

| Version | Supported |
| ------- | --------- |
| latest (`main`) | ✅ |
| older tags | ❌ |

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Instead:

1. Use GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability)
   feature on this repository ("Security" tab → "Report a vulnerability"), or
2. Email the maintainers directly (see the repository's profile for a
   contact address) with a description of the issue, steps to reproduce,
   and potential impact.

You should expect an initial response within **5 business days**. We'll
work with you to understand and validate the report, agree on a
disclosure timeline, and credit you in the release notes (unless you'd
prefer to stay anonymous).

## Scope

In scope:

* The `recsys/` core library
* The `backend/` FastAPI application
* The `frontend/` Next.js application
* Supplied Docker/Kubernetes/CI configuration, where a vulnerability
  would affect a deployment that follows this repo's defaults

Out of scope:

* Vulnerabilities in third-party dependencies — please report those
  upstream (we do run `pip-audit` and CodeQL in CI to catch known CVEs,
  see `.github/workflows/ci.yml` and `codeql.yml`)
* Issues that require physical access to a deployed instance's host
  machine
* The demo/synthetic data mode (`backend/app/services/recommender_service.py`'s
  `_load_synthetic_demo`) — it's intentionally insecure-by-default sample
  data, not a security boundary

## Known Security Notes for Deployers

* **Change `JWT_SECRET`** before any non-local deployment — the default
  in `.env.example` is a placeholder. See `deployment/k8s/secret.yaml`.
* The demo user (`demo` / `demo1234`, in
  `backend/app/core/security.py`) is for local development only —
  remove or replace the in-memory user store before deploying publicly.
* Rate limiting (`backend/app/core/rate_limit.py`) defaults to 60
  requests/minute per IP — tune `RATE_LIMIT_PER_MINUTE` for your traffic.
* CORS origins (`CORS_ORIGINS`) default to `http://localhost:3000` —
  set this explicitly in production; don't use `*`.
