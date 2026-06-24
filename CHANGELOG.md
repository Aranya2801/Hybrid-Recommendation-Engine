# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Analytics Dashboard and Admin Panel pages (frontend) — see `frontend/README.md` roadmap section
- DeepFM model (`recsys/deep/`) alongside the existing NCF / Wide&Deep / Autoencoder implementations
- Terraform modules for `deployment/aws/` and `deployment/gcp/`
- Postgres-backed `DataStore` implementation as an alternative to the in-memory default

## [0.1.0] — 2026-06-20

### Added
- Initial release of the hybrid recommendation engine core library
  (`recsys/`): collaborative filtering (ALS + item-item CF), content-based
  filtering (TF-IDF), deep learning (NCF, Wide & Deep, Autoencoder),
  knowledge-graph reasoning (NetworkX + random-walk embeddings),
  session-based recommendations (Markov chain + optional SASRec-style
  Transformer), an RL feedback loop (LinUCB contextual bandit),
  trending detection with popularity-bias correction, the weighted
  hybrid combiner, an explainability module, and offline evaluation
  metrics (Precision@K, Recall@K, MAP@K, NDCG@K, CTR).
- FastAPI backend (`backend/`) exposing `/recommend`, `/trending`,
  `/similar`, `/explain`, `/feedback`, `/profile`, `/search`, and
  `/auth/token`, with JWT auth, Redis caching (in-memory fallback),
  rate limiting, and Prometheus metrics at `/metrics`.
- Next.js + TypeScript + Tailwind frontend (`frontend/`) with Home,
  Explore, Trending, and Profile pages.
- Training (`scripts/train.py`) and evaluation (`scripts/evaluate.py`)
  CLI scripts with MLflow experiment tracking.
- A/B testing framework (`research/ab_testing/`) and Bayesian
  hyperparameter optimization for hybrid weights via Optuna
  (`research/benchmarks/optimize_weights.py`).
- Docker, Docker Compose, and Kubernetes manifests; deployment notes for
  Render, Railway, Hugging Face Spaces, AWS, and GCP.
- Prometheus + Grafana monitoring configuration.
- GitHub Actions CI/CD: lint, test (core/backend/deep-learning paths),
  security scanning (bandit, pip-audit, CodeQL), Docker build & push,
  scheduled weekly retraining, and release automation.
- Full test suite: 27 unit tests for the core library, 13 integration
  tests for the API.
- Documentation: README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY,
  architecture/API/dataset docs.

[Unreleased]: https://github.com/your-org/hybrid-recommendation-engine/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/your-org/hybrid-recommendation-engine/releases/tag/v0.1.0
