import asyncio

from lnbits.core.models import Payment
from lnbits.tasks import register_invoice_listener
from loguru import logger

from .crud import get_address, update_address
from .models import Address
from .services import activate_address, pay_referer_for_promo_code, update_ln_address


async def wait_for_paid_invoices():
    invoice_queue = asyncio.Queue()
    register_invoice_listener(invoice_queue, "ext_nostrnip5")

    while True:
        payment = await invoice_queue.get()
        await on_invoice_paid(payment)


async def on_invoice_paid(payment: Payment) -> None:
    if not payment.extra or payment.extra.get("tag") != "nostrnip5":
        return

    domain_id = payment.extra.get("domain_id")
    address_id = payment.extra.get("address_id")
    action = payment.extra.get("action")

    if not domain_id or not address_id or not action:
        logger.info(
            f"Cannot {action} for payment '{payment.payment_hash}'."
            f"Missing domain ID ({domain_id}) or address ID ({address_id})."
        )
        return

    try:
        address = await get_address(domain_id, address_id)
        if not address:
            logger.info(
                f"Cannot find address for payment '{payment.payment_hash}'."
                f"Missing domain ID ({domain_id}) or address ID ({address_id})."
            )
            return

        await _handle_action(action, payment, address)
    except Exception as exc:
        logger.warning(exc)
        logger.info(f"Issues on {action} address `{domain_id}/{address_id}`")


async def _handle_action(action: str, payment: Payment, address: Address):
    if action == "activate":
        await _activate_address(payment, address)
    if action == "reimburse":
        address.reimburse_amount = 0
        await update_address(address)


async def _activate_address(payment: Payment, address: Address):
    activated_address = await activate_address(
        address.domain_id, address.id, payment.payment_hash
    )
    if activated_address:
        await _create_ln_address(payment, activated_address)
        await _pay_promo_code(payment, activated_address)
    else:
        address.extra.reimburse_payment_hash = payment.payment_hash
        address.reimburse_amount = payment.amount
        await update_address(address)


async def _create_ln_address(payment: Payment, address: Address):
    assert payment.extra, "No extra data on payment."
    wallet = payment.extra.get("reimburse_wallet_id")
    if not wallet:
        logger.warning(
            "No wallet found for Lightning Address"
            f" '{address.local_part} ({address.id}')."
        )
        return
    address.extra.ln_address.wallet = wallet
    await update_ln_address(address)


async def _pay_promo_code(payment: Payment, address: Address):
    assert payment.extra, "No extra data on payment."
    referer = payment.extra.get("referer")
    if not referer:
        return
    referer_bonus_sats = payment.extra.get("referer_bonus_sats")
    if not referer_bonus_sats or not isinstance(referer_bonus_sats, int):
        logger.warning(
            f"Found referer but no bonus specified for '{address.local_part}'."
        )
        return

    await pay_referer_for_promo_code(address, referer, int(referer_bonus_sats))
