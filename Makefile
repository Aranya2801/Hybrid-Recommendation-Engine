.PHONY: help install install-minimal test test-core test-backend lint format \
        train evaluate download-data run run-frontend docker-up docker-down clean

help:
	@echo "Hybrid Recommendation Engine — common commands"
	@echo ""
	@echo "  make install          Install full dependencies (incl. PyTorch)"
	@echo "  make install-minimal  Install without PyTorch (classic recommenders only)"
	@echo "  make test             Run the full test suite"
	@echo "  make test-core        Run only recsys/ unit tests"
	@echo "  make test-backend     Run only backend API integration tests"
	@echo "  make lint             Run ruff check + format check"
	@echo "  make format           Auto-fix formatting with ruff"
	@echo "  make download-data    Download MovieLens (small)"
	@echo "  make train            Fit all models on synthetic data, log to MLflow"
	@echo "  make evaluate         Print the model comparison table"
	@echo "  make run              Run the FastAPI backend locally (uvicorn --reload)"
	@echo "  make run-frontend     Run the Next.js frontend locally"
	@echo "  make docker-up        docker compose up (backend, frontend, redis, prometheus, grafana, mlflow)"
	@echo "  make docker-down      docker compose down"
	@echo "  make clean            Remove caches, pyc files, build artifacts"

install:
	pip install -r requirements.txt

install-minimal:
	pip install -r requirements-minimal.txt

test:
	pytest tests/ backend/tests/ -v

test-core:
	pytest tests/ -v

test-backend:
	pytest backend/tests/ -v

lint:
	ruff check .
	ruff format --check .

format:
	ruff check --fix .
	ruff format .

download-data:
	python scripts/download_movielens.py --size small

train:
	python scripts/train.py --synthetic

evaluate:
	python scripts/evaluate.py --synthetic

run:
	uvicorn backend.app.main:app --reload --port 8000

run-frontend:
	cd frontend && npm run dev

docker-up:
	docker compose up --build

docker-down:
	docker compose down

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	rm -rf models_store/*.pkl mlruns
