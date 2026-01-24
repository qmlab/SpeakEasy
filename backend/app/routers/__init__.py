from app.routers.players import router as players_router
from app.routers.objects import router as objects_router
from app.routers.game import router as game_router
from app.routers.progress import router as progress_router
from app.routers.auth import router as auth_router

__all__ = ["players_router", "objects_router", "game_router", "progress_router", "auth_router"]
