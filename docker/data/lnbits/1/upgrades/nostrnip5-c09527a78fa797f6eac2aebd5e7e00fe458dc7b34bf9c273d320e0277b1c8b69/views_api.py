from http import HTTPStatus
from typing import Optional
from uuid import uuid4

import httpx
from fastapi import APIRouter, Depends, Query, Request, Response
from fastapi.exceptions import HTTPException
from lnbits.core.crud import get_wallets
from lnbits.core.models import SimpleStatus, User, WalletTypeInfo
from lnbits.core.services import create_invoice
from lnbits.db import Filters, Page
from lnbits.decorators import (
    check_admin,
    check_user_exists,
    optional_user_id,
    parse_filters,
    require_admin_key,
    require_invoice_key,
)
from lnbits.helpers import generate_filter_params_openapi
from lnbits.utils.cache import cache
from loguru import logger

from .crud import (
    create_domain_internal,
    create_settings,
    delete_address,
    delete_address_by_id,
    delete_domain,
    get_active_address_by_local_part,
    get_address,
    get_domain,
    get_domain_by_id,
    get_identifier_ranking,
    get_settings,
    update_address,
    update_domain,
    update_identifier_ranking,
)
from .helpers import (
    owner_id_from_user_id,
    validate_pub_key,
)
from .models import (
    Address,
    AddressFilters,
    AddressStatus,
    CreateAddressData,
    CreateDomainData,
    Domain,
    EditDomainData,
    IdentifierRanking,
    LnAddressConfig,
    Nip5Settings,
    RotateAddressData,
    UpdateAddressData,
    UserSetting,
)
from .services import (
    activate_address,
    check_address_payment,
    create_address,
    get_identifier_status,
    get_reimburse_wallet_id,
    get_user_addresses,
    get_user_addresses_paginated,
    get_user_domains,
    get_valid_addresses_for_owner,
    refresh_buckets,
    request_user_address,
    update_identifiers,
    update_ln_address,
)

nostrnip5_api_router: APIRouter = APIRouter()
address_filters = parse_filters(AddressFilters)
rotation_secret_prefix = "nostr_nip_5_rotation_secret_"


@nostrnip5_api_router.get("/api/v1/domains")
async def api_domains(
    all_wallets: bool = Query(None),
    key_info: WalletTypeInfo = Depends(require_invoice_key),
) -> list[Domain]:
    wallet = key_info.wallet
    domains = await get_user_domains(wallet.user, wallet.id, all_wallets)
    return domains


@nostrnip5_api_router.get("/api/v1/domain/{domain_id}")
async def api_get_domain(
    domain_id: str, key_info: WalletTypeInfo = Depends(require_invoice_key)
):
    domain = await get_domain(domain_id, key_info.wallet.id)
    if not domain:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Domain not found.")
    return domain


@nostrnip5_api_router.post("/api/v1/domain", status_code=HTTPStatus.CREATED)
async def api_create_domain(
    data: CreateDomainData, key_info: WalletTypeInfo = Depends(require_admin_key)
):
    data.validate_data()
    return await create_domain_internal(wallet_id=key_info.wallet.id, data=data)


@nostrnip5_api_router.put("/api/v1/domain")
async def api_update_domain(
    data: EditDomainData, wallet: WalletTypeInfo = Depends(require_admin_key)
):
    data.validate_data()
    return await update_domain(wallet_id=wallet.wallet.id, data=data)


@nostrnip5_api_router.delete(
    "/api/v1/domain/{domain_id}", status_code=HTTPStatus.CREATED
)
async def api_domain_delete(
    domain_id: str,
    key_info: WalletTypeInfo = Depends(require_admin_key),
):
    # make sure the address belongs to the user
    deleted = await delete_domain(domain_id, key_info.wallet.id)
    return SimpleStatus(success=deleted, message="Deleted")


@nostrnip5_api_router.get("/api/v1/domain/{domain_id}/nostr.json")
async def api_get_nostr_json(
    response: Response, domain_id: str, name: str = Query(None)
):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET,OPTIONS"

    if not name:
        return {"names": {}, "relays": {}}

    cached_nip5 = cache.get(f"{domain_id}/{name}")
    if cached_nip5:
        return cached_nip5

    address = await get_active_address_by_local_part(domain_id, name)

    if not address:
        return {"names": {}, "relays": {}}

    nip5 = {
        "names": {address.local_part: address.pubkey},
        "relays": {address.pubkey: address.extra.relays},
    }

    cache.set(f"{domain_id}/{name}", nip5, 600)

    return nip5


@nostrnip5_api_router.get("/api/v1/domain/{domain_id}/search")
async def api_search_identifier(
    domain_id: str, q: Optional[str] = None, years: Optional[int] = None
) -> AddressStatus:

    if not q:
        return AddressStatus(identifier="")

    domain = await get_domain_by_id(domain_id)
    if not domain:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Domain not found.")

    return await get_identifier_status(domain, q, years or 1)


@nostrnip5_api_router.get("/api/v1/domain/{domain_id}/payments/{payment_hash}")
async def api_check_address_payment(domain_id: str, payment_hash: str):
    # todo: can it be replaced with websocket?
    paid = await check_address_payment(domain_id, payment_hash)
    return {"paid": paid}


@nostrnip5_api_router.get("/api/v1/addresses")
async def api_get_addresses(
    all_wallets: bool = Query(None),
    key_info: WalletTypeInfo = Depends(require_invoice_key),
) -> list[Address]:
    return await get_user_addresses(
        key_info.wallet.user, key_info.wallet.id, all_wallets
    )


@nostrnip5_api_router.get(
    "/api/v1/addresses/paginated",
    name="Addresses List",
    summary="get paginated list of addresses",
    response_description="list of addresses",
    openapi_extra=generate_filter_params_openapi(AddressFilters),
    response_model=Page[Address],
)
async def api_get_addresses_paginated(
    all_wallets: bool = Query(None),
    filters: Filters = Depends(address_filters),
    key_info: WalletTypeInfo = Depends(require_invoice_key),
) -> Page[Address]:
    page = await get_user_addresses_paginated(
        key_info.wallet.user, key_info.wallet.id, all_wallets, filters
    )
    return page


@nostrnip5_api_router.delete("/api/v1/domain/{domain_id}/address/{address_id}")
async def api_delete_address(
    domain_id: str,
    address_id: str,
    key_info: WalletTypeInfo = Depends(require_invoice_key),
):

    # make sure the address belongs to the user
    domain = await get_domain(domain_id, key_info.wallet.id)
    if not domain:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Domain not found.")
    address = await get_address(domain_id, address_id)
    if not address:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Address not found.")
    if address.domain_id != domain_id:
        raise HTTPException(HTTPStatus.BAD_REQUEST, "Domain ID missmatch.")
    await delete_address_by_id(domain_id, address_id)
    cache.pop(f"{domain_id}/{address.local_part}")


@nostrnip5_api_router.put("/api/v1/domain/{domain_id}/address/{address_id}/activate")
async def api_activate_address(
    domain_id: str,
    address_id: str,
    key_info: WalletTypeInfo = Depends(require_admin_key),
) -> Address:
    # make sure the address belongs to the user
    domain = await get_domain(domain_id, key_info.wallet.id)
    if not domain:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Domain not found.")
    active_address = await activate_address(domain_id, address_id)
    cache.pop(f"{domain_id}/{active_address.local_part}")
    return await update_ln_address(active_address)


@nostrnip5_api_router.get(
    "/api/v1/domain/{domain_id}/address/{address_id}/reimburse",
    dependencies=[Depends(require_admin_key)],
    status_code=HTTPStatus.CREATED,
)
async def api_address_reimburse(
    domain_id: str,
    address_id: str,
):

    # make sure the address belongs to the user
    domain = await get_domain_by_id(domain_id)
    if not domain:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Domain not found.")

    address = await get_address(domain.id, address_id)
    if not address:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Address not found.")
    if address.domain_id != domain_id:
        raise HTTPException(HTTPStatus.BAD_REQUEST, "Domain ID missmatch.")

    wallet_id = await get_reimburse_wallet_id(address)

    payment_hash, payment_request = await create_invoice(
        wallet_id=wallet_id,
        amount=address.reimburse_amount,
        memo=f"Reimbursement for NIP-05 for {address.local_part}@{domain.domain}",
        extra={
            "tag": "nostrnip5",
            "domain_id": domain_id,
            "address_id": address.id,
            "local_part": address.local_part,
            "action": "reimburse",
        },
    )

    return {
        "payment_hash": payment_hash,
        "payment_request": payment_request,
        "address_id": address.id,
    }


@nostrnip5_api_router.put("/api/v1/domain/{domain_id}/address/{address_id}")
async def api_update_address(
    domain_id: str,
    address_id: str,
    data: UpdateAddressData,
    w: WalletTypeInfo = Depends(require_admin_key),
) -> Address:

    data.validate_relays_urls()

    # make sure the domain belongs to the user
    domain = await get_domain(domain_id, w.wallet.id)
    if not domain:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Domain not found.")

    address = await get_address(domain_id, address_id)
    if not address:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Address not found.")
    if address.domain_id != domain_id:
        raise HTTPException(HTTPStatus.BAD_REQUEST, "Domain ID missmatch")

    _pubkey = data.pubkey or address.pubkey
    if not _pubkey:
        raise HTTPException(HTTPStatus.BAD_REQUEST, "Pubkey is required.")

    pubkey = validate_pub_key(_pubkey)
    address.pubkey = pubkey

    if data.relays:
        address.extra.relays = data.relays

    await update_address(address)
    cache.pop(f"{domain_id}/{address.local_part}")
    return address


@nostrnip5_api_router.post(
    "/api/v1/domain/{domain_id}/address", status_code=HTTPStatus.CREATED
)
async def api_request_address(
    address_data: CreateAddressData,
    domain_id: str,
    key_info: WalletTypeInfo = Depends(require_admin_key),
):
    address_data.normalize()

    # make sure the domain belongs to the user
    domain = await get_domain(domain_id, key_info.wallet.id)
    if not domain:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Domain not found.")

    if address_data.domain_id != domain_id:
        raise HTTPException(HTTPStatus.BAD_REQUEST, "Domain ID missmatch")

    address = await create_address(
        domain, address_data, key_info.wallet.id, key_info.wallet.user
    )
    if not address.extra.price_in_sats:
        raise HTTPException(
            HTTPStatus.BAD_REQUEST,
            f"Cannot compute price. for {address_data.local_part}",
        )
    return {
        "payment_hash": None,
        "payment_request": None,
        **address.dict(),
    }


@nostrnip5_api_router.get("/api/v1/user/addresses")
async def api_get_user_addresses(
    user_id: Optional[str] = Depends(optional_user_id),
    local_part: Optional[str] = None,
    active: Optional[bool] = None,
):
    if not user_id:
        raise HTTPException(HTTPStatus.UNAUTHORIZED)

    owner_id = owner_id_from_user_id(user_id)
    if not owner_id:
        raise HTTPException(HTTPStatus.UNAUTHORIZED)
    return await get_valid_addresses_for_owner(owner_id, local_part, active)


@nostrnip5_api_router.delete("/api/v1/user/domain/{domain_id}/address/{address_id}")
async def api_delete_user_address(
    domain_id: str,
    address_id: str,
    user_id: Optional[str] = Depends(optional_user_id),
):

    if not user_id:
        raise HTTPException(HTTPStatus.UNAUTHORIZED)

    owner_id = owner_id_from_user_id(user_id)  # todo: allow for admins
    return await delete_address(domain_id, address_id, owner_id)


@nostrnip5_api_router.put("/api/v1/domain/{domain_id}/address/{address_id}/rotate")
async def api_rotate_user_address(
    domain_id: str,
    address_id: str,
    data: RotateAddressData,
):
    pubkey = validate_pub_key(data.pubkey)
    if not data.secret.startswith(rotation_secret_prefix):
        raise HTTPException(
            HTTPStatus.BAD_REQUEST,
            f"Rotation secret must start with '{rotation_secret_prefix}'",
        )

    # make sure the domain belongs to the user
    domain = await get_domain_by_id(domain_id)
    if not domain:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Domain not found.")
    address = await get_address(domain_id, address_id)
    if not address:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Address not found.")
    if address.domain_id != domain_id:
        raise HTTPException(HTTPStatus.BAD_REQUEST, "Domain ID missmatch")
    owner_id = owner_id_from_user_id(data.secret)
    if address.owner_id != owner_id:
        raise HTTPException(HTTPStatus.UNAUTHORIZED, "Address secret is incorrect.")

    address.pubkey = pubkey
    await update_address(address)
    cache.pop(f"{domain_id}/{address.local_part}")
    return True


@nostrnip5_api_router.put("/api/v1/user/domain/{domain_id}/address/{address_id}")
async def api_update_user_address(
    domain_id: str,
    address_id: str,
    data: UpdateAddressData,
    user_id: Optional[str] = Depends(optional_user_id),
) -> Address:

    if not user_id:
        raise HTTPException(HTTPStatus.UNAUTHORIZED)

    data.validate_data()

    address = await get_address(domain_id, address_id)
    if not address:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Address not found.")
    if address.domain_id != domain_id:
        raise HTTPException(HTTPStatus.BAD_REQUEST, "Domain ID missmatch")

    owner_id = owner_id_from_user_id(user_id)
    if address.owner_id != owner_id:
        raise HTTPException(
            HTTPStatus.UNAUTHORIZED, "Address does not belong to this user."
        )

    if data.relays:
        address.extra.relays = data.relays

    for k, v in data.dict().items():
        setattr(address, k, v)

    await update_address(address)
    cache.pop(f"{domain_id}/{address.local_part}")

    return address


@nostrnip5_api_router.post(
    "/api/v1/user/domain/{domain_id}/address", status_code=HTTPStatus.CREATED
)
async def api_request_user_address(
    address_data: CreateAddressData,
    domain_id: str,
    user_id: Optional[str] = Depends(optional_user_id),
):

    if not user_id:
        raise HTTPException(HTTPStatus.UNAUTHORIZED)

    address_data.normalize()

    # make sure the address belongs to the user
    domain = await get_domain_by_id(address_data.domain_id)
    assert domain, "Domain does not exist."

    assert address_data.domain_id == domain_id, "Domain ID missmatch"

    wallet_id = (await get_wallets(user_id))[0].id

    return await request_user_address(domain, address_data, wallet_id, user_id)


@nostrnip5_api_router.post(
    "/api/v1/public/domain/{domain_id}/address", status_code=HTTPStatus.CREATED
)
async def api_request_public_user_address(
    address_data: CreateAddressData,
    domain_id: str,
    user_id: Optional[str] = Depends(optional_user_id),
):

    address_data.normalize()
    # make sure the address belongs to the user
    domain = await get_domain_by_id(address_data.domain_id)
    if not domain:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Domain not found.")
    if address_data.domain_id != domain_id:
        raise HTTPException(HTTPStatus.BAD_REQUEST, "Domain ID missmatch")

    wallet_id = (await get_wallets(user_id))[0].id if user_id else None
    # used when the user is not authenticated
    temp_user_id = rotation_secret_prefix + uuid4().hex

    resp = await request_user_address(
        domain, address_data, wallet_id or "", user_id or temp_user_id
    )
    if not user_id:
        resp["rotation_secret"] = temp_user_id

    return resp


@nostrnip5_api_router.post(
    "/api/v1/user/domain/{domain_id}/address/{address_id}/lnaddress"
)
@nostrnip5_api_router.put(
    "/api/v1/user/domain/{domain_id}/address/{address_id}/lnaddress"
)
async def api_lnurl_create_or_update(
    domain_id: str,
    address_id: str,
    data: LnAddressConfig,
    user_id: Optional[str] = Depends(optional_user_id),
):
    if not user_id:
        raise HTTPException(HTTPStatus.UNAUTHORIZED)

    # make sure the address belongs to the user
    domain = await get_domain_by_id(domain_id)
    if not domain:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Domain not found.")

    address = await get_address(domain.id, address_id)
    if not address:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Address not found.")
    if address.domain_id != domain_id:
        raise HTTPException(HTTPStatus.BAD_REQUEST, "Domain ID missmatch")
    if not address.active:
        raise HTTPException(HTTPStatus.BAD_REQUEST, "Address not active.")
    owner_id = owner_id_from_user_id(user_id)
    if address.owner_id != owner_id:
        raise HTTPException(
            HTTPStatus.UNAUTHORIZED, "Address does not belong to this user."
        )

    data.pay_link_id = address.extra.ln_address.pay_link_id
    address.extra.ln_address = data
    await update_ln_address(address)

    return SimpleStatus(
        success=True,
        message=f"Lightning address '{address.local_part}@{domain.domain}' updated.",
    )


@nostrnip5_api_router.put(
    "/api/v1/domain/ranking/{bucket}",
)
async def api_refresh_identifier_ranking(
    bucket: int,
    user: User = Depends(check_admin),
):
    owner_id = owner_id_from_user_id("admin" if user.admin else user.id)
    nip5_settings = await get_settings(owner_id)
    if not nip5_settings:
        raise HTTPException(HTTPStatus.NOT_FOUND, "Settings for user not found.")

    headers = {"Authorization": f"Bearer {nip5_settings.cloudflare_access_token}"}
    ranking_url = "https://api.cloudflare.com/client/v4/radar/datasets?limit=12&datasetType=RANKING_BUCKET"
    dataset_url = "https://api.cloudflare.com/client/v4/radar/datasets"

    async with httpx.AsyncClient(headers=headers) as client:
        await refresh_buckets(client, ranking_url, dataset_url, bucket)


@nostrnip5_api_router.patch(
    "/api/v1/domain/ranking/{bucket}",
    dependencies=[Depends(check_admin)],
)
async def api_add_identifier_ranking(bucket: int, request: Request):
    identifiers = (await request.body()).decode("utf-8").splitlines()
    logger.info(f"Updating {len(identifiers)} rankings.")
    await update_identifiers(identifiers, bucket)
    logger.info(f"Updated {len(identifiers)} rankings.")
    return {"count": len(identifiers)}


@nostrnip5_api_router.get(
    "/api/v1/ranking/search",
    dependencies=[Depends(check_admin)],
)
async def api_domain_search_address(
    q: Optional[str] = None,
) -> Optional[IdentifierRanking]:
    if not q:
        return None
    return await get_identifier_ranking(q)


@nostrnip5_api_router.put(
    "/api/v1/ranking",
    dependencies=[Depends(check_admin)],
)
async def api_domain_update_ranking(
    identifier_ranking: IdentifierRanking,
) -> Optional[IdentifierRanking]:
    return await update_identifier_ranking(
        identifier_ranking.name, identifier_ranking.rank
    )


@nostrnip5_api_router.post("/api/v1/settings")
@nostrnip5_api_router.put("/api/v1/settings")
async def api_settings_create_or_update(
    settings: Nip5Settings,
    user: User = Depends(check_user_exists),
):
    owner_id = owner_id_from_user_id("admin" if user.admin else user.id)
    user_settings = UserSetting(owner_id=owner_id, settings=settings)
    await create_settings(user_settings)


@nostrnip5_api_router.get("/api/v1/settings")
async def api_get_settings(
    user: User = Depends(check_user_exists),
) -> Nip5Settings:
    owner_id = owner_id_from_user_id("admin" if user.admin else user.id)
    nip5_settings = await get_settings(owner_id)

    return nip5_settings or Nip5Settings()
