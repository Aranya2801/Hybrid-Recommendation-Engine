# Contributing to Hybrid Recommendation Engine

Thanks for considering a contribution. This document covers the basics
of getting set up and the conventions the project follows.

## Getting started

```bash
git clone https://github.com/<your-org>/hybrid-recommendation-engine.git
cd hybrid-recommendation-engine
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt   # or requirements-minimal.txt to skip PyTorch
pre-commit install                # optional, see below
pytest tests/ backend/tests/
```

For the frontend:

```bash
cd frontend
npm install
npm run dev
```

## Project layout

See `docs/architecture.md` for the full breakdown. The short version:

* `recsys/` — the core ML library (collaborative, content, deep,
  knowledge_graph, session, rl, trending, hybrid, explain, evaluation).
  Framework-agnostic, importable on its own.
* `backend/` — FastAPI application that wires `recsys/` into an HTTP API.
* `frontend/` — Next.js UI.
* `scripts/` — CLI entrypoints (train, evaluate, download data).
* `research/` — A/B testing framework and hyperparameter optimization.
* `deployment/` — Docker, Kubernetes, and platform-specific deploy configs.
* `monitoring/` — Prometheus + Grafana configuration.

## Development workflow

1. **Open an issue first** for anything beyond a trivial fix, so we can
   discuss approach before you invest time.
2. **Branch from `main`**, name it `feat/...`, `fix/...`, or `docs/...`.
3. **Write tests.** New `recsys/` modules need unit tests in `tests/`;
   new API endpoints need integration tests in `backend/tests/`.
4. **Run the full check locally** before opening a PR:
   ```bash
   ruff check .
   ruff format --check .
   pytest tests/ backend/tests/ -v
   bandit -r recsys backend scripts -ll
   ```
5. **Open a PR against `main`.** CI (`.github/workflows/ci.yml`) re-runs
   all of the above, plus a frontend build and a CodeQL scan.

## Commit style

We use [Conventional Commits](https://www.conventionalcommits.org/)
(`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`) — it makes the
changelog and release notes easier to generate, though it isn't
mechanically enforced yet (a good first contribution would be adding a
commitlint GitHub Action).

## Adding a new scoring component

The hybrid engine is intentionally pluggable (see
`recsys/hybrid/engine.py`). To add a new component:

1. Create `recsys/<your_component>/your_model.py` implementing
   `score_user(user_id, candidate_items) -> list[ScoredItem]`.
2. Add unit tests in `tests/test_<your_component>.py` using the shared
   `synthetic_store` fixture from `tests/conftest.py`.
3. Register it in `backend/app/services/recommender_service.py`'s
   `fit_all()`, with a default weight in
   `recsys/hybrid/engine.py`'s `DEFAULT_WEIGHTS`.
4. Add it to the explanation labels in `recsys/explain/explainer.py`'s
   `COMPONENT_LABELS`, and to the frontend's `CHANNEL_COLORS` /
   `CHANNEL_LABELS` in `frontend/lib/api.ts` if you want it to show up
   in the channel-strip UI.

## Reporting bugs

Open a GitHub issue with: what you expected, what happened instead, and
steps to reproduce (a minimal `recsys` snippet is ideal — see
`tests/conftest.py`'s `synthetic_store` for a pattern to copy).

## Reporting security issues

Please don't open a public issue — see `SECURITY.md`.

## Code style

* Python: `ruff` (config in `pyproject.toml`), type hints encouraged
  (`from __future__ import annotations` is used throughout for forward
  references).
* TypeScript: `next lint` (ESLint config in `frontend/.eslintrc.json`).
* Docstrings: every module/class should explain *why*, not just *what* —
  see existing modules in `recsys/` for the expected tone (cite the
  relevant paper/technique where applicable).

## License

By contributing, you agree your contributions will be licensed under the
project's [MIT License](LICENSE).
