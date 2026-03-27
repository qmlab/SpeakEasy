from app.routers.players import router as players_router
from app.routers.objects import router as objects_router
from app.routers.game import router as game_router
from app.routers.progress import router as progress_router
from app.routers.auth import router as auth_router
from app.routers.adaptive import router as adaptive_router
from app.routers.dashboard import router as dashboard_router
from app.routers.tasks import router as tasks_router
from app.routers.ai import router as ai_router

__all__ = [
    "players_router",
    "objects_router",
    "game_router",
    "progress_router",
    "auth_router",
    "adaptive_router",
    "dashboard_router",
    "tasks_router",
    "ai_router",
]
