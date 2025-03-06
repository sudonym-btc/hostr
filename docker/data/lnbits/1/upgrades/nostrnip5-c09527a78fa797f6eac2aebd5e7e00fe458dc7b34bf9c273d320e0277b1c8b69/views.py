from http import HTTPStatus
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import HTMLResponse
from lnbits.core.models import User
from lnbits.decorators import check_user_exists
from lnbits.helpers import template_renderer

from .crud import (
    get_address,
    get_domain_by_id,
    get_domain_public_data,
)
from .helpers import normalize_identifier
from .models import AddressStatus
from .services import get_identifier_status

nostrnip5_generic_router: APIRouter = APIRouter()


def nostrnip5_renderer():
    return template_renderer(["nostrnip5/templates"])


@nostrnip5_generic_router.get("/", response_class=HTMLResponse)
async def index(request: Request, user: User = Depends(check_user_exists)):
    return nostrnip5_renderer().TemplateResponse(
        "nostrnip5/index.html", {"request": request, "user": user.json()}
    )


@nostrnip5_generic_router.get("/domain/{domain_id}", response_class=HTMLResponse)
async def domain_details(
    request: Request, domain_id: str, user: User = Depends(check_user_exists)
):
    domain = await get_domain_by_id(domain_id)
    if not domain:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Domain does not exist.")
    return nostrnip5_renderer().TemplateResponse(
        "nostrnip5/domain.html",
        {"request": request, "domain": domain.json(), "user": user.json()},
    )


@nostrnip5_generic_router.get("/signup/{domain_id}", response_class=HTMLResponse)
async def signup(
    request: Request,
    domain_id: str,
    identifier: Optional[str] = None,
    years: Optional[int] = None,
):
    domain = await get_domain_by_id(domain_id)

    if not domain:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Domain does not exist.")

    status = (
        await get_identifier_status(domain, identifier, years or 1)
        if identifier
        else AddressStatus(identifier="", available=True)
    )

    return nostrnip5_renderer().TemplateResponse(
        "nostrnip5/signup.html",
        {
            "request": request,
            "domain_id": domain_id,
            "domain": domain.public_data(),
            "identifier": (normalize_identifier(identifier) if identifier else ""),
            "identifier_cost": status.price_formatted,
            "identifier_available": status.available,
        },
    )


@nostrnip5_generic_router.get(
    "/rotate/{domain_id}/{address_id}", response_class=HTMLResponse
)
async def rotate(
    request: Request, domain_id: str, address_id: str, secret: Optional[str] = None
):
    domain = await get_domain_public_data(domain_id)
    address = await get_address(domain_id, address_id)

    if not domain:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND, detail="Domain does not exist."
        )

    if not address:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND, detail="Address does not exist."
        )

    return nostrnip5_renderer().TemplateResponse(
        "nostrnip5/rotate.html",
        {
            "request": request,
            "domain_id": domain_id,
            "domain": domain,
            "address_id": address_id,
            "address": address,
            "secret": secret,
        },
    )
