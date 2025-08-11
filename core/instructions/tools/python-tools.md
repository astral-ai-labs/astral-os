# Python Development Tools

**Fast, reliable Python tooling** - uv for package management and ruff for linting/formatting.

## Installation

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install ruff
uv tool install ruff
```

---

## Project Initialization

```bash
# Create a new Python project
uv init

# Create a new Python application (with scripts)
uv init --app

# Initialize in existing directory
uv init .
```

---

## Basic Commands

### `uv run`
Run a command or script
```bash
uv run python script.py
uv run pytest
uv run ruff check .
```

### `uv init`
Create a new project
```bash
uv init my-project
uv init --app my-app
```

### `uv add`
Add dependencies to the project
```bash
uv add requests
uv add --dev pytest ruff mypy
uv add fastapi --extra standard
```

### `uv remove`
Remove dependencies from the project
```bash
uv remove requests
uv remove --dev pytest
```

### `uv version`
Read or update the project's version
```bash
uv version
uv version 1.2.3
```

### `uv sync`
Update the project's environment
```bash
uv sync
uv sync --dev
```

### `uv lock`
Update the project's lockfile
```bash
uv lock
uv lock --upgrade
```

### `uv export`
Export the project's lockfile to an alternate format
```bash
uv export --format requirements-txt > requirements.txt
```

### `uv tree`
Display the project's dependency tree
```bash
uv tree
uv tree --depth 2
```

### `uv tool`
Run and install commands provided by Python packages
```bash
uv tool install ruff
uv tool list
uv tool run black .
```

### `uv python`
Manage Python versions and installations
```bash
uv python install 3.12
uv python pin 3.12
uv python list
```

### `uv pip`
Manage Python packages with a pip-compatible interface
```bash
uv pip install requests
uv pip list
uv pip freeze
```

### `uv venv`
Create a virtual environment
```bash
uv venv
uv venv .venv
```

### `uv build`
Build Python packages into source distributions and wheels
```bash
uv build
```

### `uv publish`
Upload distributions to an index
```bash
uv publish
```

### `uv cache`
Manage uv's cache
```bash
uv cache clean
uv cache dir
```

### `uv self`
Manage the uv executable
```bash
uv self update
```

### `uv help`
Display documentation for a command
```bash
uv help
uv help add
```

---

## Ruff Configuration

### Basic Usage
```bash
# Check code
uv run ruff check .

# Fix issues
uv run ruff check . --fix

# Format code
uv run ruff format .
```

### Configuration (.ruff.toml)
```toml
line-length = 88
target-version = "py312"

[lint]
select = ["E", "W", "F", "I", "N", "UP", "B", "SIM"]
ignore = ["E501"]

[lint.isort]
known-first-party = ["src"]
```

---

## Python Style Guide

- **Follow PEP8** with these specific choices:
  - Line length: 100 characters (set by Ruff in pyproject.toml)
  - Use double quotes for strings
  - Use trailing commas in multi-line structures
- **Always use type hints** for function signatures and class attributes
- **Format with `ruff format`** (faster alternative to Black)
- **Use `pydantic` v2** for data validation and settings management

---

## FastAPI Installation

```bash
# Install FastAPI with standard extras (includes uvicorn and other essentials)
uv add fastapi --extra standard
```
