# Any args passed to the make script, use with $(call args, default_value)
args = `arg="$(filter-out $@,$(MAKECMDGOALS))" && echo $${arg:-${1}}`
SHELL := /bin/bash

########################################################################################################################
# Quality checks
########################################################################################################################

test:
	PYTHONPATH=. poetry run pytest tests

test-coverage:
	PYTHONPATH=. poetry run pytest tests --cov private_gpt --cov-report term --cov-report=html --cov-report xml --junit-xml=tests-results.xml

black:
	poetry run black . --check

ruff:
	poetry run ruff check private_gpt tests

format:
	poetry run black .
	poetry run ruff check private_gpt tests --fix

mypy:
	poetry run mypy private_gpt

check:
	make format
	make mypy

########################################################################################################################
# Run
########################################################################################################################

run:
	PGPT_PROFILES=local poetry run python -m private_gpt

dev-windows:
	(set PGPT_PROFILES=local & poetry run python -m uvicorn private_gpt.main:app --reload --port 8001)

dev:
	PYTHONUNBUFFERED=1 PGPT_PROFILES=local poetry run python -m uvicorn private_gpt.main:app --reload --port 8001

########################################################################################################################
# Misc
########################################################################################################################

api-docs:
	PGPT_PROFILES=mock poetry run python scripts/extract_openapi.py private_gpt.main:app --out fern/openapi/openapi.json

ingest:
	@poetry run python scripts/ingest_folder.py --ignore=.git documents/

stats:
	poetry run python scripts/utils.py stats

wipe:
	poetry run python scripts/utils.py wipe

setup:
	poetry run python scripts/setup

clean:
	rm -rf local_data/* models/*

gpu-drivers:
	echo "Installing nvidia drivers"
	wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/sbsa/cuda-ubuntu2204.pin
	sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
	wget https://developer.download.nvidia.com/compute/cuda/12.4.1/local_installers/cuda-repo-ubuntu2204-12-4-local_12.4.1-550.54.15-1_arm64.deb
	sudo dpkg -i cuda-repo-ubuntu2204-12-4-local_12.4.1-550.54.15-1_arm64.deb
	sudo cp /var/cuda-repo-ubuntu2204-12-4-local/cuda-*-keyring.gpg /usr/share/keyrings/
	sudo apt-get update
	sudo apt-get -y install cuda-toolkit-12-4
	sudo nvcc --version
	sudo nvidia-smi

system-configure: gpu-drivers
	echo "Installing private-gpt dependencies"
	sudo add-apt-repository --yes ppa:deadsnakes/ppa
	sudo apt update && sudo apt install -y python3.11
	sudo apt install -y build-essential manpages-dev software-properties-common
	sudo add-apt-repository --yes ppa:ubuntu-toolchain-r/test
	sudo apt update && sudo apt install gcc-11 g++-11 tmux
	curl -sSL https://install.python-poetry.org | python3 -
	echo 'export PATH="/home/ubuntu/.local/bin:$$PATH"' >> ~/.bashrc
	source ~/.bashrc && poetry env use 3.11
	source ~/.bashrc && CMAKE_ARGS='-DLLAMA_CUBLAS=on' poetry install --extras "ui llms-llama-cpp embeddings-huggingface vector-stores-qdrant"

list:
	@echo "Available commands:"
	@echo "  test            : Run tests using pytest"
	@echo "  test-coverage   : Run tests with coverage report"
	@echo "  black           : Check code format with black"
	@echo "  ruff            : Check code with ruff"
	@echo "  format          : Format code with black and ruff"
	@echo "  mypy            : Run mypy for type checking"
	@echo "  check           : Run format and mypy commands"
	@echo "  run             : Run the application"
	@echo "  dev-windows     : Run the application in development mode on Windows"
	@echo "  dev             : Run the application in development mode"
	@echo "  api-docs        : Generate API documentation"
	@echo "  ingest          : Ingest data using specified script"
	@echo "  wipe            : Wipe data using specified script"
	@echo "  setup           : Setup the application"
