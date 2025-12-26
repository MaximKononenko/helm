"""
{{PROJECT_NAME}} - Application Configuration

Configuration management using Pydantic Settings.
Environment variables take precedence over defaults.
"""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """
    Application settings.
    
    All settings can be overridden via environment variables.
    """
    
    # Project Information
    PROJECT_NAME: str = "{{PROJECT_NAME}}"
    PROJECT_DESCRIPTION: str = "{{DESCRIPTION}}"
    VERSION: str = "1.0.0"
    
    # API Configuration
    API_PREFIX: str = "/api/v1"
    DEBUG: bool = False
    
    # Server Configuration
    HOST: str = "0.0.0.0"
    PORT: int = {{PORT}}
    
    # CORS Configuration
    ALLOWED_ORIGINS: list[str] = ["*"]
    
    # Logging Configuration
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"
    
    class Config:
        """Pydantic configuration."""
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


# Global settings instance
settings = Settings()
