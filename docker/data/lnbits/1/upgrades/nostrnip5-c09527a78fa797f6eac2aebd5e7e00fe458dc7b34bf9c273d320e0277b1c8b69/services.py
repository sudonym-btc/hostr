from datetime import datetime, timedelta, timezone
from typing import Optional

import httpx
from lnbits.core.crud import get_standalone_payment, get_user
from lnbits.core.models import Payment
from lnbits.core.services import create_invoice, pay_invoice
from lnbits.db import Filters, Page
from loguru import logger

from .crud import (
    create_address_internal,
    create_identifier_ranking,
    delete_inferior_ranking,
    get_active_address_by_local_part,
    get_address,
    get_address_for_owner,
    get_addresses_for_owner,
    get_all_addresses,
    get_all_addresses_paginated,
    get_domain_by_id,
    get_domains,
    get_identifier_ranking,
    get_settings,
    update_address,
)
from .helpers import (
    normalize_identifier,
    owner_id_from_user_id,
    validate_pub_key,
)
from .models import (
    Address,
    AddressExtra,
    AddressFilters,
    AddressStatus,
    CreateAddressData,
    Domain,
    PriceData,
)


async def get_user_domains(
    user_id: str, wallet_id: str, all_wallets: Optional[bool] = False
) -> list[Domain]:
    wallet_ids = [wallet_id]
    if all_wallets:
        user = await get_user(user_id)  # type: ignore
        if not user:
            return []
        wallet_ids = user.wallet_ids

    return await get_domains(wallet_ids)


async def get_user_addresses(
    user_id: str, wallet_id: str, all_wallets: Optional[bool] = False
) -> list[Address]:
    wallet_ids = [wallet_id]
    if all_wallets:
        user = await get_user(user_id)  # type: ignore
        if not user:
            return []
        wallet_ids = user.wallet_ids

    return await get_all_addresses(wallet_ids)


async def get_user_addresses_paginated(
    user_id: str,
    wallet_id: str,
    all_wallets: Optional[bool] = False,
    filters: Optional[Filters[AddressFilters]] = None,
) -> Page[Address]:
    wallet_ids = [wallet_id]
    if all_wallets:
        user = await get_user(user_id)  # type: ignore
        if not user:
            return Page(data=[], total=0)
        wallet_ids = user.wallet_ids

    return await get_all_addresses_paginated(wallet_ids, filters)


async def get_identifier_status(
    domain: Domain, identifier: str, years: int, promo_code: Optional[str] = None
) -> AddressStatus:
    identifier = normalize_identifier(identifier)
    address = await get_active_address_by_local_part(domain.id, identifier)
    if address:
        return AddressStatus(identifier=identifier, available=False)

    price_data = await get_identifier_price_data(domain, identifier, years, promo_code)

    if not price_data:
        return AddressStatus(identifier=identifier, available=False)

    return AddressStatus(
        identifier=identifier,
        available=True,
        price=price_data.price,
        price_in_sats=await price_data.price_sats(),
        price_reason=price_data.reason,
        currency=domain.currency,
    )


async def get_identifier_price_data(
    domain: Domain, identifier: str, years: int, promo_code: Optional[str] = None
) -> Optional[PriceData]:
    identifier_ranking = await get_identifier_ranking(identifier)
    rank = identifier_ranking.rank if identifier_ranking else None

    if rank == 0:
        return None

    return await domain.price_for_identifier(identifier, years, rank, promo_code)


async def request_user_address(
    domain: Domain,
    address_data: CreateAddressData,
    wallet_id: str,
    user_id: str,
):
    address = await create_address(
        domain, address_data, wallet_id, user_id, address_data.promo_code
    )
    assert (
        address.extra.price_in_sats
    ), f"Cannot compute price for '{address_data.local_part}'."

    address.promo_code_status = domain.cost_extra.promo_code_status(
        address_data.promo_code
    )

    resp = {
        **dict(address),
        "payment_hash": None,
        "payment_request": None,
    }

    if address_data.create_invoice:
        payment = await create_invoice_for_identifier(domain, address, wallet_id)
        resp["payment_hash"] = payment.payment_hash
        resp["payment_request"] = payment.bolt11

    return resp


async def create_invoice_for_identifier(
    domain: Domain,
    address: Address,
    reimburse_wallet_id: str,
) -> Payment:
    price_data = await get_identifier_price_data(
        domain, address.local_part, address.extra.years, address.extra.promo_code
    )
    assert price_data, f"Cannot compute price for '{address.local_part}'."
    price_in_sats = await price_data.price_sats()
    discount_sats = await price_data.discount_sats()
    referer_bonus_sats = await price_data.referer_bonus_sats()

    payment = await create_invoice(
        wallet_id=domain.wallet,
        amount=int(price_in_sats),
        memo=f"Payment of {address.extra.price} {address.extra.currency} "
        f"for NIP-05 {address.local_part}@{domain.domain}",
        extra={
            "tag": "nostrnip5",
            "domain_id": domain.id,
            "address_id": address.id,
            "action": "activate",
            "reimburse_wallet_id": reimburse_wallet_id,
            "discount_sats": int(discount_sats),
            "referer": address.extra.referer,
            "referer_bonus_sats": int(referer_bonus_sats),
        },
    )
    return payment


async def create_address(
    domain: Domain,
    data: CreateAddressData,
    wallet_id: Optional[str] = None,
    user_id: Optional[str] = None,
    promo_code: Optional[str] = None,
) -> Address:

    identifier = normalize_identifier(data.local_part)
    data.local_part = identifier
    if data.pubkey != "":
        data.pubkey = validate_pub_key(data.pubkey)

    owner_id = owner_id_from_user_id(user_id)
    address = await get_address_for_owner(owner_id, domain.id, identifier)

    promo_code = promo_code or (address.extra.promo_code if address else None)
    identifier_status = await get_identifier_status(
        domain, identifier, data.years, promo_code
    )

    assert identifier_status.available, f"Identifier '{identifier}' not available."
    assert identifier_status.price, f"Cannot compute price for '{identifier}'."

    extra = address.extra if address else AddressExtra()
    extra.price = identifier_status.price
    extra.price_in_sats = identifier_status.price_in_sats
    extra.currency = domain.currency
    extra.years = data.years
    extra.promo_code = data.promo_code
    extra.referer = domain.cost_extra.promo_code_referer(promo_code, data.referer)
    extra.max_years = domain.cost_extra.max_years
    extra.ln_address.wallet = wallet_id or ""

    if address:
        assert not address.active, f"Identifier '{data.local_part}' already activated."
        address.extra = extra
        address.pubkey = data.pubkey
        address = await update_address(address)
    else:
        address = await create_address_internal(data, owner_id, extra=extra)

    return address


async def activate_address(
    domain_id: str, address_id: str, payment_hash: Optional[str] = None
) -> Address:
    logger.info(f"Activating NIP-05 '{address_id}' for {domain_id}")

    address = await get_address(domain_id, address_id)
    assert address, f"Cannot find address '{address_id}' for {domain_id}."
    active_address = await get_active_address_by_local_part(
        domain_id, address.local_part
    )
    assert not active_address, f"Address '{address.local_part}' already active."

    address.extra.activated_by_owner = payment_hash is None
    address.extra.payment_hash = payment_hash
    address.active = True
    address.expires_at = datetime.now(timezone.utc) + timedelta(
        days=365 * address.extra.years
    )
    await update_address(address)
    logger.info(f"Activated NIP-05 '{address.local_part}' ({address_id}).")

    return address


async def get_valid_addresses_for_owner(
    owner_id: str, local_part: Optional[str] = None, active: Optional[bool] = None
) -> list[Address]:

    valid_addresses = []
    addresses = await get_addresses_for_owner(owner_id)
    for address in addresses:
        if active is not None and active != address.active:
            continue
        if local_part and address.local_part != local_part:
            continue
        domain = await get_domain_by_id(address.domain_id)
        if not domain:
            continue
        status = await get_identifier_status(
            domain, address.local_part, address.extra.years, address.extra.promo_code
        )

        if status.available:
            # update to latest price
            address.extra.price_in_sats = status.price_in_sats
            address.extra.price = status.price
        elif not address.active:
            # do not return addresses which cannot be sold
            continue

        address.extra.currency = domain.currency
        address.promo_code_status = domain.cost_extra.promo_code_status(
            address.extra.promo_code
        )
        valid_addresses.append(address)

    return valid_addresses


async def pay_referer_for_promo_code(address: Address, referer: str, bonus_sats: int):
    try:
        assert bonus_sats > 0, f"Bonus amount negative: '{bonus_sats}'."

        domain = await get_domain_by_id(address.domain_id)
        assert domain, f"Missing domain for '{address.local_part}'."

        referer_address = await get_active_address_by_local_part(
            address.domain_id, referer
        )
        assert referer_address, f"Missing address for referer '{referer}'."
        referer_wallet = referer_address.extra.ln_address.wallet
        assert referer_wallet, f"Missing wallet for referer '{referer}'."

        payment = await create_invoice(
            wallet_id=referer_wallet,
            amount=bonus_sats,
            memo=f"Referer bonus of {bonus_sats} sats to '{referer}' "
            f"from NIP-05 {address.local_part}@{domain.domain}",
            extra={
                "tag": "nostrnip5",
                "domain_id": domain.id,
                "address_id": address.id,
                "action": "referer_bonus",
            },
        )

        await pay_invoice(wallet_id=domain.wallet, payment_request=payment.bolt11)

    except Exception as exc:
        logger.warning(f"Failed to pay referer for '{referer}'.")
        logger.warning(exc)


async def check_address_payment(domain_id: str, payment_hash: str) -> bool:
    payment = await get_standalone_payment(payment_hash, incoming=True)
    if not payment:
        logger.debug(f"No payment found for hash {payment_hash}")
        return False

    assert payment.extra, "No extra data on payment."
    payment_address_id = payment.extra.get("address_id")
    assert payment_address_id, "Payment does not exist for this address."

    payment_domain_id = payment.extra.get("domain_id")
    assert payment_domain_id == domain_id, "Payment does not exist for this domain."

    if payment.pending is False:
        return True

    status = await payment.check_status()
    return status.success


async def get_reimburse_wallet_id(address: Address) -> str:
    payment_hash = address.extra.reimburse_payment_hash
    assert payment_hash, f"No payment hash found to reimburse '{address.id}'."

    payment = await get_standalone_payment(
        checking_id_or_hash=payment_hash, incoming=True
    )
    assert payment, f"No payment found to reimburse '{payment_hash}'."
    assert payment.extra, "No extra data on payment."
    wallet_id = payment.extra.get("reimburse_wallet_id")
    assert wallet_id, f"No wallet found to reimburse payment {payment_hash}."
    return wallet_id


async def update_identifiers(identifiers: list[str], bucket: int):
    for identifier in identifiers:
        try:
            await update_identifier(identifier, bucket)
        except Exception as exc:
            logger.warning(exc)


async def update_identifier(identifier, bucket):
    await delete_inferior_ranking(identifier, bucket)
    await create_identifier_ranking(identifier, bucket)


async def update_ln_address(address: Address) -> Address:
    nip5_settings = await get_settings(owner_id_from_user_id("admin"))
    assert nip5_settings, "No NIP-05 settings found."
    assert nip5_settings.lnaddress_api_endpoint, "No endpoint found for LN Address."
    assert nip5_settings.lnaddress_api_admin_key, "No api key found for LN Address."

    ln_address = address.extra.ln_address

    async with httpx.AsyncClient(verify=False) as client:
        method = "PUT" if ln_address.pay_link_id else "POST"
        url = f"{nip5_settings.lnaddress_api_endpoint}/lnurlp/api/v1/links"
        url = f"{url}/{ln_address.pay_link_id}" if ln_address.pay_link_id else url
        headers = {
            "Content-Type": "application/json; charset=utf-8",
            "X-API-KEY": nip5_settings.lnaddress_api_admin_key,
        }
        payload = {
            "description": f"Lightning Address for NIP05 {address.local_part}",
            "wallet": ln_address.wallet,
            "min": ln_address.min,
            "max": ln_address.max,
            "comment_chars": "255",
            "username": address.local_part,
            "zaps": True,
        }

        resp = await client.request(
            method,
            url,
            headers=headers,
            json=payload,
        )

        resp.raise_for_status()

        pay_link_data = resp.json()
        ln_address.pay_link_id = pay_link_data["id"]

        logger.success(
            f"Updated Lightning Address for '{address.local_part}' ({address.id})."
        )

        address = await update_address(address)
        logger.info(f"Updated address for '{address.local_part}' ({address.id}).")
        return address


async def refresh_buckets(
    client: httpx.AsyncClient, ranking_url: str, dataset_url: str, bucket: int
):
    logger.info(f"Refresh requested for top {bucket} identifiers.")

    resp = await client.get(url=ranking_url)
    resp.raise_for_status()
    data = resp.json()

    datasets = data["result"]["datasets"]
    datasets.sort(key=lambda b: b["meta"]["top"])

    logger.info("Bucket info received.")

    for dataset in datasets:
        top = dataset["meta"]["top"]
        if top > bucket:
            continue
        logger.info(f"Refreshing bucket {top}.")
        url = f"""{dataset_url}/{dataset["alias"]}"""
        await refresh_bucket(client, url, top)
        logger.info(f"Refreshed bucket {top}.")

    logger.info(f"Top {bucket} identifiers ranking refreshed.")


async def refresh_bucket(
    client: httpx.AsyncClient,
    url: str,
    bucket: int,
):
    resp = await client.get(url)
    resp.raise_for_status()

    for identifier in resp.text.split("\n"):
        try:
            identifier_name = identifier.split(".")[0]
            await update_identifier(identifier_name, bucket)
            await update_identifier(identifier, bucket)
        except Exception as exc:
            logger.warning(exc)
