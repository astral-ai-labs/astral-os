---
description: Python Rules for working with Python Codebases
globs: "*.py"
alwaysApply: false
---

**What's in here:** Complete Python coding guidelines including style conventions, file structure patterns, error handling, class design, testing patterns, and development tooling with uv and ruff.

# Python Coding Guidelines

In here

**Write Python code with absolute clarity as the top priority.** Keep it Simple, Stupid (KISS) - choose the most straightforward solution that any developer can understand at first glance. Readability isn't optional, it's everything. Code should tell a story that flows naturally from top to bottom.

These guidelines ensure our Python codebases are maintainable, approachable, and immediately understandable:

## Python Style Conventions

Our Python code follows **PEP8** with these specific formatting choices:

- **Line length: 100 characters** - Enforced by ruff configuration
- **Double quotes for strings** - Consistent string quoting style
- **Trailing commas in multi-line structures** - Better diffs and easier editing
- **Type hints everywhere** - Function signatures, class attributes, and variable annotations
- **ruff for formatting** - Faster alternative to Black with same results
- **Pydantic v2 for data validation** - Modern data validation and settings management

### Code Formatting Examples

```python
# ✅ Good - Double quotes, trailing commas, type hints
def create_user_profile(
    user_data: UserCreateRequest,
    settings: Optional[UserSettings] = None,
    notify_admin: bool = True,
) -> UserProfile:
    """Create user profile with validation and notifications."""
    # Implementation here
    pass

# ✅ Good - Multi-line collections with trailing commas
ALLOWED_EXTENSIONS = {
    ".jpg",
    ".png",
    ".gif",
    ".pdf",
}

# ✅ Good - Pydantic v2 for data validation
from pydantic import BaseModel, Field, ConfigDict

class UserSettings(BaseModel):
    """User preference settings."""
    model_config = ConfigDict(frozen=True)

    theme: str = Field(default="light", pattern="^(light|dark)$")
    notifications_enabled: bool = True
    max_file_size_mb: int = Field(default=10, ge=1, le=100)
```

## Python Style guides

### 1. File Structure & Header

**Every Python file must start with a clear header:**

```python
# ==============================================================================
# user_service.py — User management and authentication
# ==============================================================================
# Purpose: Handle user CRUD operations and session management
# Sections: Imports, Models, Validators, Public API
# ==============================================================================
```

### 2. Import Organization

**Three distinct groups, separated by blank lines:**

```python
# ==============================================================================
# Imports
# ==============================================================================

# Standard Library --------------------------------------------------------------
import os
import sys
from datetime import datetime
from typing import Optional, List, Dict

# Third-Party -------------------------------------------------------------------
import requests
import pydantic
from sqlalchemy import Column, String

# Internal ----------------------------------------------------------------------
from ._base import BaseResource, NOT_GIVEN
from .models import User, UserProfile
from astral_ai.core.exceptions import ValidationError
```

### 3. Public API Declaration

**Use `__all__` to explicitly define the public interface:**

```python
# ==============================================================================
# Public API
# ==============================================================================
__all__ = [
    "UserService",
    "create_user",
    "validate_email",
    "UserNotFoundError",
]
```

### 4. Section Markers

**Use consistent section headers throughout the file:**

```python
# ==============================================================================
# Models & Types
# ==============================================================================

# ==============================================================================
# Helper Functions
# ==============================================================================

# ==============================================================================
# Main Implementation
# ==============================================================================
```

### 5. Type Hints & Documentation

**Always use type hints and appropriate docstrings:**

```python
def fetch_user_profile(user_id: str, include_settings: bool = False) -> Optional[UserProfile]:
    """Retrieve user profile data with optional settings."""
    # 1️⃣ Validate input -----------------
    if not user_id or not user_id.strip():
        raise ValueError("User ID cannot be empty")

    # 2️⃣ Query database -----------------
    profile = db.query(UserProfile).filter_by(user_id=user_id).first()

    # 3️⃣ Include settings if requested -----------------
    if include_settings and profile:
        profile.settings = fetch_user_settings(user_id)

    return profile

def log_event(event: str) -> None:
    """Log application event to monitoring system."""
    logger.info(f"Event: {event}")

class UserValidator:
    """Validates user input data and business rules."""

    def validate_email(self, email: str) -> bool:
        """Check if email format is valid."""
        return "@" in email and "." in email.split("@")[1]
```

### 6. Error Handling Patterns

**FAIL FAST - Check for errors immediately and raise exceptions at the first sign of trouble. Never let invalid data propagate through your system:**

```python
def process_payment(amount: float, user_id: str) -> PaymentResult:
    """Process user payment - fail immediately on any invalid input."""
    # FAIL FAST: Validate all inputs immediately
    if amount <= 0:
        raise ValueError(f"Payment amount must be positive, got: {amount}")

    if not user_id or not user_id.strip():
        raise ValueError("User ID cannot be empty")

    if amount > 10000:  # Business rule
        raise ValueError(f"Payment amount exceeds limit: {amount}")

    try:
        # 1️⃣ Validate user exists - FAIL FAST -----------------
        user = get_user(user_id)
        if not user:
            raise UserNotFoundError(f"User {user_id} not found")

        if not user.is_active:
            raise UserInactiveError(f"User {user_id} is not active")

        # 2️⃣ Check payment method - FAIL FAST -----------------
        if not user.payment_method:
            raise PaymentMethodMissingError(f"User {user_id} has no payment method")

        # 3️⃣ Process payment -----------------
        result = payment_gateway.charge(amount, user.payment_method)

        # 4️⃣ Update records -----------------
        update_user_balance(user_id, -amount)

        return PaymentResult(success=True, transaction_id=result.id)

    except PaymentGatewayError as e:
        logger.error(f"Payment failed for user {user_id}: {e}")
        raise PaymentProcessingError(f"Payment processing failed: {e}")

def create_user_account(email: str, name: str, age: int) -> User:
    """Create user account with immediate validation."""
    # FAIL FAST: Check all requirements upfront
    if not email:
        raise ValueError("Email is required")

    if "@" not in email:
        raise ValueError(f"Invalid email format: {email}")

    if not name or len(name.strip()) < 2:
        raise ValueError("Name must be at least 2 characters")

    if age < 13:
        raise ValueError(f"User must be at least 13 years old, got: {age}")

    if user_exists(email):
        raise UserAlreadyExistsError(f"User with email {email} already exists")

    # Only proceed if ALL validations pass
    return User(email=email.lower().strip(), name=name.strip(), age=age)

def validate_file_upload(file_data: bytes, filename: str) -> None:
    """Validate file upload - fail immediately on any issue."""
    # FAIL FAST: Multiple early checks
    if not file_data:
        raise ValueError("File data cannot be empty")

    if len(file_data) > MAX_FILE_SIZE:
        raise FileTooLargeError(f"File size {len(file_data)} exceeds limit {MAX_FILE_SIZE}")

    if not filename:
        raise ValueError("Filename is required")

    file_ext = filename.lower().split('.')[-1]
    if file_ext not in ALLOWED_EXTENSIONS:
        raise InvalidFileTypeError(f"File type .{file_ext} not allowed")

    # Additional checks for specific file types
    if file_ext in ['jpg', 'png']:
        if not is_valid_image(file_data):
            raise CorruptedFileError("Image file appears to be corrupted")
```

### 7. Class Design & Structure

**Keep classes focused and well-organized:**

```python
class DatabaseConnection:
    """Singleton database connection manager."""

    _instance: Optional['DatabaseConnection'] = None

    def __new__(cls) -> 'DatabaseConnection':
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self) -> None:
        if not hasattr(self, '_initialized'):
            self._connection = self._create_connection()
            self._initialized = True

    def execute_query(self, sql: str, params: Dict = None) -> List[Dict]:
        """Execute SQL query with optional parameters."""
        # Implementation here
        pass

class UserService:
    """Main service for user operations."""

    def __init__(self, db: DatabaseConnection):
        self.db = db
        self._cache: Dict[str, User] = {}

    def create_user(self, user_data: CreateUserRequest) -> User:
        """Create new user account."""
        # 1️⃣ Validate input -----------------
        self._validate_user_data(user_data)

        # 2️⃣ Check for duplicates -----------------
        if self._user_exists(user_data.email):
            raise UserAlreadyExistsError(f"User with email {user_data.email} already exists")

        # 3️⃣ Create user record -----------------
        user = User(
            email=user_data.email,
            name=user_data.name,
            created_at=datetime.now()
        )

        # 4️⃣ Save to database -----------------
        self.db.save(user)

        return user
```

### 8. Configuration & Constants

**Group constants and configuration at the top:**

```python
# ==============================================================================
# Configuration & Constants
# ==============================================================================

# API Settings
DEFAULT_TIMEOUT = 30
MAX_RETRY_ATTEMPTS = 3
API_BASE_URL = "https://api.example.com"

# Validation Rules
MIN_PASSWORD_LENGTH = 8
MAX_USERNAME_LENGTH = 50
ALLOWED_FILE_TYPES = {".jpg", ".png", ".pdf"}

# Database Settings
CONNECTION_POOL_SIZE = 10
QUERY_TIMEOUT = 60
```

### 9. Context Managers & Resource Management

**Use context managers for resource cleanup:**

```python
from contextlib import contextmanager
from typing import Generator

@contextmanager
def database_transaction() -> Generator[DatabaseConnection, None, None]:
    """Provide database connection with automatic transaction handling."""
    conn = get_db_connection()
    trans = conn.begin()
    try:
        yield conn
        trans.commit()
    except Exception:
        trans.rollback()
        raise
    finally:
        conn.close()

# Usage
def transfer_funds(from_user: str, to_user: str, amount: float) -> None:
    """Transfer funds between users with transaction safety."""
    with database_transaction() as db:
        # 1️⃣ Validate users -----------------
        sender = db.get_user(from_user)
        receiver = db.get_user(to_user)

        # 2️⃣ Check balance -----------------
        if sender.balance < amount:
            raise InsufficientFundsError("Not enough balance")

        # 3️⃣ Execute transfer -----------------
        sender.balance -= amount
        receiver.balance += amount

        # 4️⃣ Save changes -----------------
        db.save(sender)
        db.save(receiver)
```

### 10. Testing Patterns

**Write clear, focused test functions:**

```python
# ==============================================================================
# Test Utilities
# ==============================================================================

def test_create_user_success():
    """Test successful user creation with valid data."""
    # Arrange
    user_data = CreateUserRequest(
        email="test@example.com",
        name="Test User"
    )

    # Act
    user = user_service.create_user(user_data)

    # Assert
    assert user.email == "test@example.com"
    assert user.name == "Test User"
    assert user.created_at is not None

def test_create_user_duplicate_email():
    """Test user creation fails with duplicate email."""
    # Arrange
    existing_email = "existing@example.com"
    create_test_user(email=existing_email)

    user_data = CreateUserRequest(email=existing_email, name="New User")

    # Act & Assert
    with pytest.raises(UserAlreadyExistsError):
        user_service.create_user(user_data)
```

### 11. Performance Patterns

**Use efficient Python patterns:**

```python
# List comprehensions for filtering/mapping
active_users = [user for user in users if user.is_active]
user_names = [user.name for user in users]

# Generator expressions for large datasets
user_emails = (user.email for user in users if user.verified)

# Efficient string operations
error_messages = []
if not user.email:
    error_messages.append("Email is required")
if not user.name:
    error_messages.append("Name is required")

if error_messages:
    raise ValidationError("; ".join(error_messages))

# Use dataclasses for simple data containers
from dataclasses import dataclass

@dataclass
class UserSummary:
    """Summary of user account information."""
    user_id: str
    name: str
    email: str
    last_login: Optional[datetime] = None
```

### 12. Async Patterns

**For async code, follow consistent patterns:**

```python
import asyncio
from typing import AsyncGenerator

async def fetch_user_data(user_ids: List[str]) -> List[User]:
    """Fetch multiple users concurrently."""
    # 1️⃣ Create tasks -----------------
    tasks = [fetch_single_user(user_id) for user_id in user_ids]

    # 2️⃣ Execute concurrently -----------------
    results = await asyncio.gather(*tasks, return_exceptions=True)

    # 3️⃣ Filter successful results -----------------
    users = []
    for result in results:
        if isinstance(result, User):
            users.append(result)
        else:
            logger.warning(f"Failed to fetch user: {result}")

    return users

async def process_user_stream() -> AsyncGenerator[ProcessedUser, None]:
    """Process users from stream with backpressure handling."""
    async for user_batch in get_user_stream(batch_size=100):
        for user in user_batch:
            try:
                processed = await process_user(user)
                yield processed
            except Exception as e:
                logger.error(f"Failed to process user {user.id}: {e}")
```

---

**Remember**: Always prioritize readability, consistency, and maintainability in your Python code.

---

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
