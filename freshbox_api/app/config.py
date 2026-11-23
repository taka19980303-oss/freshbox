from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Gemini API
    gemini_api_key: str = "mock_key"

    # Firebase
    firebase_project_id: str = "freshbox-dev"
    firebase_credentials_path: str = "./firebase-credentials.json"

    # App Settings
    app_env: str = "development"
    allow_origins: str = "http://localhost:3000"

    @property
    def origins_list(self) -> list[str]:
        return [o.strip() for o in self.allow_origins.split(",")]


@lru_cache
def get_settings() -> Settings:
    return Settings()
