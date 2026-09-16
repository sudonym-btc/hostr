# Escrow

Hostr uses NMDK's escrow drivers for reservation settlement. NMDK owns on-chain funding, payment-proof verification, swap recovery, and settlement; Hostr connects these mechanisms to its booking flow and MCP tools.

Escrow operations flow through the Dart daemon and MCP action catalog used by agents and Hostr automation.

## Structure

```bash
escrow
├── contracts          # Deployment tooling for the canonical NMDK contract
├── lib                # Escrow daemon/runtime code
└── bin                # Escrow helper entry points

hostr_cli
├── bin/hostr_daemon.dart
└── lib/src/actions    # MCP action catalog, including escrow tools

ai/mcp-server
└── src/generated      # Generated MCP tool definitions
```

- [Arbitration services specification](../specifications/arbitration.md)
- [Orders and settlement specification](../specifications/orders.md)
- [Payment driver architecture](../infrastructure/payment-drivers.md)
- Action catalog: [hostr_cli/lib/src/actions/hostr_actions.dart](../source/hostr_cli/lib/src/actions/hostr_actions.dart)
- Generated MCP tools: [ai/mcp-server/src/generated/hostr-actions.ts](../source/ai/mcp-server/src/generated/hostr-actions.ts)
- MCP runtime overview: [../ai/README.md](../ai/README.md)

## User-Facing Escrow Flow

Normal booking/payment flows should not call escrow settlement tools directly.

| MCP tool | Purpose |
| -------- | ------- |
| `hostr_escrow_methods` | Shows mutually compatible escrow services and payment forms for a buyer/seller pair. |
| `hostr_reservations_bookAndPay` | Primary instant-book flow. Creates the private offer, prepares escrow funding, and returns payment details when needed. |
| `hostr_swaps_watch` | Observes the swap/payment/proof/reservation state after payment starts. |
| `hostr_swaps_recoverAll` | Explicit recovery path for stuck persisted swap operations, previewed before execution. |

The booking flow swaps Lightning payment into smart-contract escrow where needed, then publishes the reservation proof through the daemon-side payment proof orchestration.

## Escrow-Operator MCP Tools

Escrow operators use role-gated MCP tools. These are visible only when the authenticated Hostr pubkey is configured as an escrow service.

| MCP tool | Purpose |
| -------- | ------- |
| `hostr_escrow_service_list` | List public escrow service events for the authenticated escrow pubkey. |
| `hostr_escrow_service_get` | Inspect one escrow service event. |
| `hostr_escrow_service_update` / `hostr_escrow_service_edit` | Preview and publish service settings such as fee percent, maximum duration, and token fee hints. |
| `hostr_escrow_service_delete` | Preview and publish deletion of a public escrow service event. |
| `hostr_escrow_trades_list` | List on-chain trades assigned to the authenticated escrow pubkey. |
| `hostr_escrow_trades_view` | Inspect on-chain state, event history, participants, amounts, and reservation context for a trade. |
| `hostr_escrow_trades_audit` | Run a structured reservation/transition audit before deciding whether arbitration is needed. |
| `hostr_escrow_trades_arbitrate` | Preview and execute settlement splits after explicit approval. |

Write tools default to preview/dry-run behavior and should only be executed live after the user approves the returned preview.

## Settlement Model

Escrow service events advertise the escrow operator, deployed contract address, runtime bytecode hash, supported chain, fee policy, and token fee hints. User escrow-method events declare trusted escrow pubkeys, accepted bytecode hashes, and accepted payment forms.

On-chain trades move through funded, released, arbitrated, or claimed states. Settlement uses a pull-payment balance mapping instead of direct transfers, and arbitration chooses a split between buyer and seller while crediting the escrow fee to the arbiter.

See the arbitration and order specifications for the event and settlement details.
