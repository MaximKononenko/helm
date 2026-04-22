"""
{{OB_PROJECT_NAME}} - API Routes

Define all API endpoints here.
"""

from fastapi import APIRouter

router = APIRouter(prefix="/api/v1", tags=["API"])


@router.get("/")
async def root():
    """
    Root endpoint.
    
    Returns:
        dict: Welcome message.
    """
    return {
        "message": "Welcome to {{OB_PROJECT_NAME}}",
        "docs": "/docs",
    }


@router.get("/info")
async def info():
    """
    Service information endpoint.
    
    Returns:
        dict: Service metadata.
    """
    return {
        "service": "{{OB_PROJECT_NAME}}",
        "owner": "{{OWNER}}",
        "python_version": "{{PYTHON_VERSION}}",
    }


# Add your custom routes below
# Example:
# @router.get("/items/{item_id}")
# async def get_item(item_id: int):
#     return {"item_id": item_id}
