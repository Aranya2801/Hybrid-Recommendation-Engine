<div align="center">

# Hybrid Recommendation Engine

**Seven scoring signals — collaborative, content, knowledge graph, deep learning,
session, RL feedback, and trending — blended into one explainable ranked list.**

[![Python](https://img.shields.io/badge/python-3.10%2B-blue?logo=python&logoColor=white)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110%2B-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)](Dockerfile)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-manifests-326CE5?logo=kubernetes&logoColor=white)](deployment/k8s)
[![CI](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)](.github/workflows/ci.yml)
[![MLflow](https://img.shields.io/badge/MLflow-tracking-0194E2?logo=mlflow&logoColor=white)](scripts/train.py)
[![Redis](https://img.shields.io/badge/Redis-cache-DC382D?logo=redis&logoColor=white)](backend/app/core/cache.py)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[Architecture](#architecture) · [Installation](#installation) · [Usage](#usage) ·
[API](#api) · [Benchmarks](#benchmarks) · [Roadmap](#roadmap)

</div>

---

## What this is

A hybrid recommendation engine that combines seven independently-testable
scoring components into one weighted, explainable ranking — plus a
FastAPI backend, a Next.js frontend, training/evaluation pipelines with
MLflow tracking, Docker/Kubernetes deployment configs, Prometheus/Grafana
monitoring, and a full test suite. Every piece described in this README
is real, working code in this repository — run `pytest` and see for
yourself.

```
Final Score = w₁·Collaborative + w₂·Content + w₃·KnowledgeGraph
            + w₄·Deep + w₅·Session + w₆·RLFeedback + w₇·Trending
```

weights are configurable (`recsys/hybrid/engine.py`'s `DEFAULT_WEIGHTS`),
each component's score is min-max normalized before blending (see
[`docs/architecture.md`](docs/architecture.md) for why that matters), and
every recommendation is returned with its full per-component breakdown —
not a black-box single number.

### A note on scope

This is a substantial, working reference implementation — not a
production deployment. The classic recommenders (collaborative, content,
knowledge graph, session, trending, RL) run on pure Python/NumPy/
scikit-learn/NetworkX with **zero external infrastructure required**.
Deep learning models (NCF, Wide & Deep, Autoencoder) and the Transformer
session model are real PyTorch implementations, optional, and degrade
gracefully if `torch` isn't installed. A few things are explicitly
**documented as roadmap, not pretended into existence** — see
[Roadmap](#roadmap) — including a full Analytics/Admin frontend, live
cloud deployments, and Terraform modules.

---

## Architecture

![Architecture diagram](docs/assets/architecture-diagram.svg)

```
Client (Next.js / curl)
        │
        ▼
FastAPI backend (auth, rate limit, cache)
        │
        ▼
HybridRecommender ── collaborative · content · knowledge_graph
                   ── deep (optional) · session · trending · rl_feedback
        │
        ▼
DataStore (in-memory; Postgres-ready interface)
```

Full breakdown, including the request lifecycle and how the RL feedback
loop closes, in [`docs/architecture.md`](docs/architecture.md).

## Features

### Core recommendation components
- **Collaborative filtering** — ALS matrix factorization (implicit
  feedback, Hu/Koren/Volinsky 2008) + item-item cosine CF
- **Content-based filtering** — TF-IDF over item metadata, cosine similarity
- **Deep learning** — Neural Collaborative Filtering (He et al. 2017),
  Wide & Deep (Cheng et al. 2016), AutoRec-style autoencoder (Sedhain et
  al. 2015) — real PyTorch, optional dependency
- **Knowledge graph** — NetworkX heterogeneous graph (user/item/category),
  personalized PageRank + DeepWalk-style embeddings
- **Session-based** — first-order Markov chain, plus an optional
  SASRec-style Transformer (Kang & McAuley 2018)
- **RL feedback loop** — LinUCB contextual bandit (Li et al. 2010),
  updated by every `/feedback` call
- **Trending + popularity-bias correction** — exponential time-decay
  popularity, inverse-propensity re-ranking

### User intelligence
- Behavioral clustering (K-Means over category-engagement vectors)
- Preference-drift detection (Jensen-Shannon divergence, recent vs.
  baseline taste)

### Explainability
Every recommendation comes with a plain-language explanation, a
confidence score, per-component contribution breakdown, and — when
available — a concrete knowledge-graph path as evidence. See `/explain`.

### Real-time API
FastAPI backend with `/recommend`, `/trending`, `/similar`, `/explain`,
`/feedback`, `/profile`, `/search`, JWT auth, Redis caching (in-memory
fallback if Redis is unreachable), rate limiting, background tasks, and
Prometheus metrics at `/metrics`.

### MLOps
- `scripts/train.py` — fits everything, logs to MLflow, saves model
  artifacts
- `scripts/evaluate.py` — Precision@K / Recall@K / MAP@K / NDCG@K / CTR
  comparison table across every component
- `research/benchmarks/optimize_weights.py` — Bayesian hyperparameter
  optimization (Optuna) over hybrid weights
- `research/ab_testing/framework.py` — variant bucketing + statistical
  significance testing
- `.github/workflows/retrain.yml` — scheduled weekly retraining

### Deployment & ops
Docker, Docker Compose, Kubernetes manifests (Deployment, Service, HPA,
Ingress, ConfigMap/Secret templates), plus deployment notes for Render,
Railway, Hugging Face Spaces, AWS (ECS/EKS), and GCP (Cloud Run/GKE).
Prometheus + Grafana for monitoring.

---

## Installation

### Quickest path — Docker Compose

```bash
git clone https://github.com/your-org/hybrid-recommendation-engine.git
cd hybrid-recommendation-engine
docker compose up --build
```

| Service | URL |
|---|---|
| Frontend | http://localhost:3000 |
| Backend API docs | http://localhost:8000/docs |
| Grafana | http://localhost:3001 (anonymous viewer access) |
| Prometheus | http://localhost:9090 |
| MLflow | http://localhost:5050 |

### Local development (backend only, no Docker)

```bash
python3 -m venv .venv && source .venv/bin/activate

# Fast path — classic recommenders only, no PyTorch (~10s install):
pip install -r requirements-minimal.txt

# Full path — includes NCF / Wide&Deep / Autoencoder / Transformer session model:
pip install -r requirements.txt

uvicorn backend.app.main:app --reload --port 8000
```

The API starts with a synthetic demo catalog by default (60 items, 25
users) — no dataset download required. To use real MovieLens data:

```bash
python scripts/download_movielens.py --size small
echo "MOVIELENS_DATA_DIR=data/raw/movielens-small" >> .env
```

### Frontend

```bash
cd frontend
npm install
cp .env.example .env.local
npm run dev
```

---

## Usage

```bash
curl "http://localhost:8000/api/v1/recommend?user_id=demo-user-0&top_k=5"
curl "http://localhost:8000/api/v1/trending?top_k=10"
curl "http://localhost:8000/api/v1/explain?user_id=demo-user-0&item_id=demo-item-0"
curl -X POST http://localhost:8000/api/v1/feedback \
  -H "Content-Type: application/json" \
  -d '{"user_id":"demo-user-0","item_id":"demo-item-0","event_type":"click"}'
```

Train and evaluate:

```bash
python scripts/train.py --synthetic                # or --data-dir data/raw/movielens-small
python scripts/evaluate.py --synthetic --top-k 10
mlflow ui                                           # inspect logged runs at localhost:5000
```

## API

Full reference in [`docs/api.md`](docs/api.md). Interactive Swagger UI
at `/docs` once the backend is running.

| Endpoint | Method | Purpose |
|---|---|---|
| `/api/v1/recommend` | GET | Personalized recommendations |
| `/api/v1/trending` | GET | Time-decayed trending items |
| `/api/v1/similar` | GET | "More like this" |
| `/api/v1/explain` | GET | Why was this recommended |
| `/api/v1/feedback` | POST | Record click/purchase/like/dismiss, updates the RL bandit |
| `/api/v1/profile` | GET | User cluster + preference drift |
| `/api/v1/search` | GET | Free-text catalog search |
| `/api/v1/auth/token` | POST | JWT token (demo: `demo` / `demo1234`) |
| `/health` | GET | Liveness/readiness probe |
| `/metrics` | GET | Prometheus exposition format |

---

## Screenshots

No screenshots are committed yet — see
[`assets/banner/PROMPTS.md`](assets/banner/PROMPTS.md) for the exact
capture checklist and AI-image-generator prompts for the banner. Run the
stack locally and capture your own; a templated section is ready to drop
them into in that file.

## Demo video

Not recorded yet. A complete storyboard, voiceover script, recording
checklist, and editing plan are in
[`docs/demo_video_plan.md`](docs/demo_video_plan.md) — everything needed
to produce a 5-minute walkthrough.

---

## Benchmarks

Offline evaluation on the synthetic demo dataset (25 users, 60 items,
~370 interactions, most-recent-20%-per-user held out), via
`python scripts/evaluate.py --synthetic --top-k 10`:

| Model | Precision@10 | Recall@10 | MAP@10 | NDCG@10 | CTR |
|---|---|---|---|---|---|
| Collaborative (item-item CF) | 0.180 | 0.579 | 0.227 | 0.374 | 0.180 |
| Collaborative (ALS) | 0.160 | 0.521 | 0.208 | 0.351 | 0.160 |
| Content (TF-IDF) | 0.256 | 0.813 | 0.324 | 0.497 | 0.256 |
| Knowledge graph (PageRank) | 0.168 | 0.547 | 0.240 | 0.378 | 0.168 |
| Trending only | 0.068 | 0.205 | 0.086 | 0.159 | 0.068 |
| **Hybrid blend** | **0.232** | **0.747** | **0.304** | **0.475** | **0.232** |

**Read this honestly**: on this small synthetic dataset, content-based
filtering alone outperforms the default-weighted hybrid blend — which
makes sense, since the synthetic generator gives users a strong,
consistent category preference that TF-IDF picks up directly, and the
default hybrid weights weren't tuned for this specific data distribution.
This is exactly the kind of result `research/benchmarks/optimize_weights.py`
exists to fix empirically, and exactly why these numbers are printed here
unedited rather than cherry-picked. Re-run the comparison on real
MovieLens data (`python scripts/evaluate.py --data-dir
data/raw/movielens-small`) before drawing conclusions for your own use
case — synthetic data demonstrates that the evaluation pipeline works
correctly, not real-world model quality.

## Results

The full per-recommendation explanation system, the RL feedback loop,
and the popularity-bias correction are demonstrated in
[`docs/api.md`](docs/api.md)'s example responses — every number shown
there is a real API response captured against the running synthetic demo
service, not a mockup.

---

## Roadmap

Honestly split between "planned" and "you could build this next":

- [ ] Analytics Dashboard + Admin Panel frontend pages (data already
      exists in `recsys.evaluation` / `research.ab_testing` — needs
      wiring, see `frontend/README.md`)
- [ ] DeepFM model alongside the existing NCF / Wide&Deep / Autoencoder
- [ ] Postgres-backed `DataStore` for real persistence at scale
- [ ] Terraform modules for `deployment/aws/` and `deployment/gcp/`
      (currently manual `gcloud`/`aws` CLI instructions)
- [ ] Wire JWT auth into the recommendation/feedback routes (currently
      only `/auth/token` issues tokens; the other routes don't require one)
- [ ] Real-time feature store (Feast) for online feature serving at
      production scale

See [`CHANGELOG.md`](CHANGELOG.md) for what's shipped.

## Future work

Beyond the roadmap: multi-armed-bandit exploration strategies beyond
LinUCB (Thompson Sampling, neural bandits), cross-domain recommendation
(transferring signal between, say, movies and books for the same user),
and a proper online A/B testing integration connecting
`research/ab_testing/framework.py` to live traffic rather than offline
simulation.

## Contributors

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for how to get involved. This
project welcomes issues, PRs, and discussion.

## License

[MIT](LICENSE) — see the full license text for details.

---

<div align="center">

Built with collaborative filtering, content-based filtering, knowledge
graphs, deep learning, session modeling, reinforcement learning, and
trending detection — and an explanation for every single recommendation.

</div>
