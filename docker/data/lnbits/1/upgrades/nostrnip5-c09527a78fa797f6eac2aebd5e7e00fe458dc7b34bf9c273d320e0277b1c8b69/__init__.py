import asyncio

from fastapi import APIRouter
from loguru import logger

from .crud import db
from .tasks import wait_for_paid_invoices
from .views import nostrnip5_generic_router
from .views_api import nostrnip5_api_router

nostrnip5_static_files = [
    {
        "path": "/nostrnip5/static",
        "name": "nostrnip5_static",
    }
]

nostrnip5_ext: APIRouter = APIRouter(prefix="/nostrnip5", tags=["nostrnip5"])
nostrnip5_ext.include_router(nostrnip5_generic_router)
nostrnip5_ext.include_router(nostrnip5_api_router)

scheduled_tasks: list[asyncio.Task] = []


def nostrnip5_stop():
    for task in scheduled_tasks:
        try:
            task.cancel()
        except Exception as ex:
            logger.warning(ex)


def nostrnip5_start():
    from lnbits.tasks import create_permanent_unique_task

    task = create_permanent_unique_task("ext_nostrnip5", wait_for_paid_invoices)
    scheduled_tasks.append(task)


__all__ = [
    "nostrnip5_ext",
    "nostrnip5_static_files",
    "nostrnip5_start",
    "nostrnip5_stop",
    "db",
]
