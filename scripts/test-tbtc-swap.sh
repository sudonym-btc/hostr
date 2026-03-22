#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# test-tbtc-swap.sh
#
# End-to-end test: Lightning BTC → tBTC reverse swap via Boltz on Arbitrum.
#
# Flow:
#   1. Generate a random preimage + hash
#   2. Create a reverse swap (BTC → tBTC) via Boltz API
#   3. Pay the Lightning hold invoice via LND-1
#   4. Wait for Boltz to lock tBTC in the ERC20Swap contract
#   5. Claim the tBTC using an Anvil account
#   6. Log the tBTC balance difference
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

BOLTZ_API="https://boltz.hostr.development"
ARBITRUM_RPC="http://localhost:8546"

# Anvil Account #0 — the claimer (has ETH for gas + tBTC from init)
CLAIM_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
CLAIM_PK="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# Contract addresses
ERC20_SWAP="0x71C95911E9a5D330f4D621842EC243EE1343292e"
TBTC_TOKEN="0x948B3c65b89DF0B4894ABE91E6D02FE579834F8F"

# LND credentials for paying invoice (boltz lnd-1 has channels)
LND_EXEC="docker exec boltz-lnd-1 lncli --network=regtest --rpcserver=localhost:10009 --tlscertpath=/app/lnd/tls.cert --macaroonpath=/app/lnd/data/chain/bitcoin/regtest/admin.macaroon"

SWAP_AMOUNT=100000  # 100k sats

echo "═══════════════════════════════════════════════════════════════"
echo " Lightning → tBTC Reverse Swap Test"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ── 1. Generate preimage & hash ──────────────────────────────────────────
echo "Step 1: Generating preimage..."
PREIMAGE=$(openssl rand -hex 32)
PREIMAGE_HASH=$(echo -n "$PREIMAGE" | xxd -r -p | openssl dgst -sha256 -binary | xxd -p -c 64)
echo "  Preimage:      $PREIMAGE"
echo "  Preimage Hash: $PREIMAGE_HASH"
echo ""

# ── 2. Check tBTC balance BEFORE ─────────────────────────────────────────
echo "Step 2: Checking tBTC balance before swap..."
BALANCE_BEFORE_RAW=$(cast call --rpc-url "$ARBITRUM_RPC" \
  "$TBTC_TOKEN" "balanceOf(address)" "$CLAIM_ADDRESS" 2>&1)
BALANCE_BEFORE=$(python3 -c "print(int('$BALANCE_BEFORE_RAW', 16))")
echo "  tBTC balance before: $BALANCE_BEFORE wei ($(python3 -c "print(f'{$BALANCE_BEFORE/10**18:.6f}')") tBTC)"
echo ""

# ── 3. Create reverse swap ───────────────────────────────────────────────
echo "Step 3: Creating reverse swap (BTC → tBTC, ${SWAP_AMOUNT} sats)..."
SWAP_RESPONSE=$(curl -sk -X POST "$BOLTZ_API/v2/swap/reverse" \
  -H "Content-Type: application/json" \
  -d "{
    \"from\": \"BTC\",
    \"to\": \"tBTC\",
    \"invoiceAmount\": $SWAP_AMOUNT,
    \"preimageHash\": \"$PREIMAGE_HASH\",
    \"claimAddress\": \"$CLAIM_ADDRESS\"
  }")

echo "  Swap response:"
echo "$SWAP_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$SWAP_RESPONSE"
echo ""

# Parse response
SWAP_ID=$(echo "$SWAP_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
INVOICE=$(echo "$SWAP_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['invoice'])" 2>/dev/null)
REFUND_ADDRESS=$(echo "$SWAP_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('refundAddress',''))" 2>/dev/null)
TIMEOUT=$(echo "$SWAP_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('timeoutBlockHeight',''))" 2>/dev/null)
ONCHAIN_AMOUNT=$(echo "$SWAP_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('onchainAmount',''))" 2>/dev/null)

if [ -z "$SWAP_ID" ] || [ -z "$INVOICE" ]; then
  echo "ERROR: Failed to create swap. Response: $SWAP_RESPONSE"
  exit 1
fi

echo "  Swap ID:          $SWAP_ID"
echo "  Invoice:          ${INVOICE:0:40}..."
echo "  Refund Address:   $REFUND_ADDRESS"
echo "  Timeout Height:   $TIMEOUT"
echo "  Onchain Amount:   $ONCHAIN_AMOUNT sats"
echo ""

# ── 4. Pay the Lightning invoice ─────────────────────────────────────────
echo "Step 4: Paying Lightning invoice via LND-1..."
# Pay in background since it's a hold invoice — it won't resolve until we claim
$LND_EXEC payinvoice --force "$INVOICE" &
PAY_PID=$!
echo "  Payment initiated (PID: $PAY_PID)"
echo ""

# ── 5. Wait for Boltz to lock tBTC on-chain ──────────────────────────────
echo "Step 5: Waiting for Boltz to lock tBTC in ERC20Swap..."

# Poll the swap status
for i in $(seq 1 60); do
  STATUS_RESPONSE=$(curl -sk "$BOLTZ_API/v2/swap/$SWAP_ID" 2>&1)
  STATUS=$(echo "$STATUS_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null || echo "")

  if [ "$STATUS" = "transaction.mempool" ] || [ "$STATUS" = "transaction.confirmed" ]; then
    echo "  ✓ Lockup detected! Status: $STATUS (attempt $i)"
    # Get the lockup transaction details
    LOCKUP_TX=$(echo "$STATUS_RESPONSE" | python3 -c "
import sys,json
d = json.load(sys.stdin)
tx = d.get('transaction', {})
print(f\"  Transaction ID: {tx.get('id', 'N/A')}\")
print(f\"  Hex: {tx.get('hex', 'N/A')[:80]}...\") if tx.get('hex') else None
" 2>/dev/null || echo "")
    echo "$LOCKUP_TX"
    break
  fi

  if echo "$STATUS" | grep -qi "error\|failed\|expired"; then
    echo "  ✗ Swap failed! Status: $STATUS"
    echo "  Full response: $STATUS_RESPONSE"
    kill $PAY_PID 2>/dev/null || true
    exit 1
  fi

  echo "  Waiting... status=$STATUS (attempt $i/60)"
  sleep 2
done

if [ "$STATUS" != "transaction.mempool" ] && [ "$STATUS" != "transaction.confirmed" ]; then
  echo "  ✗ Timeout waiting for lockup transaction"
  kill $PAY_PID 2>/dev/null || true
  exit 1
fi
echo ""

# Give Anvil a moment to process the block
sleep 2

# ── 6. Verify the lockup in the ERC20Swap contract ──────────────────────
echo "Step 6: Verifying lockup in ERC20Swap contract..."

# Compute the swap hash to check if it's registered
# hashValues(preimageHash, amount, tokenAddress, claimAddress, refundAddress, timelock)
ONCHAIN_WEI=$(python3 -c "print($ONCHAIN_AMOUNT * 10**10)")
echo "  Onchain amount in wei: $ONCHAIN_WEI"

SWAP_HASH=$(cast call --rpc-url "$ARBITRUM_RPC" \
  "$ERC20_SWAP" \
  "hashValues(bytes32,uint256,address,address,address,uint256)(bytes32)" \
  "0x$PREIMAGE_HASH" \
  "$ONCHAIN_WEI" \
  "$TBTC_TOKEN" \
  "$CLAIM_ADDRESS" \
  "$REFUND_ADDRESS" \
  "$TIMEOUT" 2>&1)
echo "  Swap hash: $SWAP_HASH"

SWAP_EXISTS=$(cast call --rpc-url "$ARBITRUM_RPC" \
  "$ERC20_SWAP" \
  "swaps(bytes32)(bool)" \
  "$SWAP_HASH" 2>&1)
echo "  Swap registered: $SWAP_EXISTS"

if echo "$SWAP_EXISTS" | grep -qi "false"; then
  echo "  ✗ Swap not found in contract! Trying to debug..."
  echo "  Checking recent Lockup events..."
  cast logs --rpc-url "$ARBITRUM_RPC" \
    --address "$ERC20_SWAP" \
    --from-block 1 \
    "Lockup(bytes32,uint256,address,address,address,uint256)" 2>&1 | head -30
  echo ""
  echo "  Note: Amount conversion might be wrong. Boltz may use raw satoshi values."
  # Try with raw sats
  SWAP_HASH_SATS=$(cast call --rpc-url "$ARBITRUM_RPC" \
    "$ERC20_SWAP" \
    "hashValues(bytes32,uint256,address,address,address,uint256)(bytes32)" \
    "0x$PREIMAGE_HASH" \
    "$ONCHAIN_AMOUNT" \
    "$TBTC_TOKEN" \
    "$CLAIM_ADDRESS" \
    "$REFUND_ADDRESS" \
    "$TIMEOUT" 2>&1)
  SWAP_EXISTS_SATS=$(cast call --rpc-url "$ARBITRUM_RPC" \
    "$ERC20_SWAP" \
    "swaps(bytes32)(bool)" \
    "$SWAP_HASH_SATS" 2>&1)
  echo "  With raw sats — hash: $SWAP_HASH_SATS, exists: $SWAP_EXISTS_SATS"
fi
echo ""

# ── 7. Claim the tBTC ────────────────────────────────────────────────────
echo "Step 7: Claiming tBTC from ERC20Swap..."

# claim(bytes32 preimage, uint256 amount, address tokenAddress, address refundAddress, uint256 timelock)
# msg.sender must be claimAddress
CLAIM_TX=$(cast send --rpc-url "$ARBITRUM_RPC" \
  --private-key "$CLAIM_PK" \
  "$ERC20_SWAP" \
  "claim(bytes32,uint256,address,address,uint256)" \
  "0x$PREIMAGE" \
  "$ONCHAIN_WEI" \
  "$TBTC_TOKEN" \
  "$REFUND_ADDRESS" \
  "$TIMEOUT" 2>&1)

CLAIM_STATUS=$(echo "$CLAIM_TX" | grep -i "status" | head -1)
CLAIM_TX_HASH=$(echo "$CLAIM_TX" | grep -i "transactionHash" | awk '{print $NF}')

if echo "$CLAIM_STATUS" | grep -q "1"; then
  echo "  ✓ Claim transaction successful!"
else
  echo "  ✗ Claim might have failed. Trying with raw sats amount..."
  CLAIM_TX=$(cast send --rpc-url "$ARBITRUM_RPC" \
    --private-key "$CLAIM_PK" \
    "$ERC20_SWAP" \
    "claim(bytes32,uint256,address,address,uint256)" \
    "0x$PREIMAGE" \
    "$ONCHAIN_AMOUNT" \
    "$TBTC_TOKEN" \
    "$REFUND_ADDRESS" \
    "$TIMEOUT" 2>&1)
  CLAIM_STATUS=$(echo "$CLAIM_TX" | grep -i "status" | head -1)
fi
echo "  Claim TX hash: $CLAIM_TX_HASH"
echo "  $CLAIM_STATUS"
echo ""

# Wait for payment to settle
sleep 3
kill $PAY_PID 2>/dev/null || true
wait $PAY_PID 2>/dev/null || true

# ── 8. Check tBTC balance AFTER ──────────────────────────────────────────
echo "Step 8: Checking tBTC balance after swap..."
BALANCE_AFTER_RAW=$(cast call --rpc-url "$ARBITRUM_RPC" \
  "$TBTC_TOKEN" "balanceOf(address)" "$CLAIM_ADDRESS" 2>&1)
BALANCE_AFTER=$(python3 -c "print(int('$BALANCE_AFTER_RAW', 16))")

BALANCE_AFTER_TBTC=$(python3 -c "print(f'{$BALANCE_AFTER/10**18:.6f}')")
echo "  tBTC balance after:  $BALANCE_AFTER wei ($BALANCE_AFTER_TBTC tBTC)"
echo ""

# ── 9. Calculate and display the difference ──────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
echo " RESULTS"
echo "═══════════════════════════════════════════════════════════════"

python3 << PYEOF
before = $BALANCE_BEFORE
after = $BALANCE_AFTER
diff = after - before
diff_tbtc = diff / 10**18
onchain_sats = $ONCHAIN_AMOUNT
expected_wei = onchain_sats * 10**10

print(f'  Balance before:  {before} wei ({before/10**18:.6f} tBTC)')
print(f'  Balance after:   {after} wei ({after/10**18:.6f} tBTC)')
print(f'  Difference:      +{diff} wei (+{diff_tbtc:.10f} tBTC)')
print(f'  Expected:        +{expected_wei} wei (+{onchain_sats} sats = {expected_wei/10**18:.10f} tBTC)')
print(f'  Match:           {"YES ✅" if diff == expected_wei else "NO (diff=" + str(diff - expected_wei) + ")"}')
print()
if diff > 0:
    print(f'  ✅ SWAP SUCCESSFUL — received +{diff_tbtc:.10f} tBTC ({diff // 10**10} sats equiv)')
else:
    print(f'  ❌ SWAP FAILED — no tBTC received')
PYEOF
echo ""
echo "  Swap ID:      $SWAP_ID"
echo "  Claim TX:     $CLAIM_TX_HASH"

# Final swap status
FINAL_STATUS=$(curl -sk "$BOLTZ_API/v2/swap/$SWAP_ID" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))" 2>/dev/null)
echo "  Final status: $FINAL_STATUS"
echo "═══════════════════════════════════════════════════════════════"
