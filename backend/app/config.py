from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "FinCopilot API"
    API_V1_STR: str = "/api/v1"

    # SQLite for local dev — swap to postgresql+asyncpg for production
    DATABASE_URL: str = "sqlite+aiosqlite:///./fincopilot.db"

    REDIS_URL: str = "redis://localhost:6379/0"
    QDRANT_URL: str = "http://localhost:6333"

    # JWT
    SECRET_KEY: str = "super-secret-change-me-in-production"
    ACCESS_TOKEN_EXPIRE_DAYS: int = 7

    # File uploads
    UPLOAD_DIR: str = "./uploads"

    # AI Keys
    GEMINI_API_KEY: str | None = None

    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )


settings = Settings()
