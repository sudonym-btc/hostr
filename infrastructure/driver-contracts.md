# Shared driver contracts

The TypeScript and Dart EVM drivers share their external wire contracts through
existing generators. Runtime orchestration remains native to each language.

| Source of truth | TypeScript consumer | Dart consumer |
| --- | --- | --- |
| `dependencies/marketplace-evm-contracts/contracts/MultiEscrow.sol` | Compiled ABI, generated EIP-712 domain, ordered fields, factor scale and error signatures | Same ABI and generated signing constants |
| `dependencies/marketplace-evm-ts/schemas/boltz.openapi.json` | `openapi-typescript` types used by `openapi-fetch` | `swagger_dart_code_generator` models used by Chopper |
| Locked `boltz-core` Solidity artifacts | Generated ERC20Swap ABI overloads used by the swap call builder | ERC20Swap, EtherSwap and TestERC20 bindings |
| Locked OpenZeppelin artifacts | Standard ERC-20 protocol | IERC20 and IERC20Metadata bindings |
| `dependencies/marketplace-driver-interface-ts/schemas/amount.schema.json` | Generated amount type and parser, consumed by both driver and Nostr event amounts | Generated amount fields/parser/serializer, inherited by `DenominatedAmount`; integer parser also used by `TokenAmount` |

The pinned Boltz document is the release-tagged API 3.13.0 `swagger-spec.json`.
It includes one documented schema correction: the EVM submarine response's optional `claimAddress`,
which that backend returns but its published schema omits. Both drivers now
receive that field through their generated models. Do not fetch a running
backend implicitly during generation; review and replace the pinned document
when intentionally upgrading the backend.

## Regenerate

After installing npm and Dart dependencies:

```sh
# Recompile only when the Solidity source changes.
npm --workspace @sudonym-btc/marketplace-evm-contracts run build:artifacts

# Refresh TS bindings, stage the same inputs for Dart, and run Dart generators.
npm run generate:drivers

# Read-only checks of generated TS outputs and Dart generator inputs.
npm run check:drivers
```

The Dart copies of OpenAPI and ABI inputs are generated staging files; edit the
canonical source above. Only the six contract bindings actually used by the
driver or its integration tests are generated. The signing generator reads the
EIP-712 constructor and type-hash declarations directly from Solidity and fails
if their syntax changes beyond what it supports.

## Validate

```sh
npm run test:evm
npm run test:driver-contracts
npm run test:dart
```

`test/fixtures/driver-wire.json` contains the same Boltz bodies, contract calldata,
and deterministic EIP-712 signatures for both test suites. The vectors include
amounts and withdrawal nonces above JavaScript's safe integer range. Tests
exercise the real TypeScript REST client, escrow/swap call builders and signing
types, and the real Dart generated models, bindings and escrow signer. The source
checks also compare every Dart binding's embedded ABI with its canonical artifact
to detect stale generation independently of fixture coverage.

Bytecode identity uses the same canonical lowercase, `0x`-prefixed SHA-256 hash
in both drivers. Deployment verification requires that exact representation.

Both runtimes serialize amounts as canonical integer-unit strings, with explicit
denomination and decimal precision and optional logical currency. Decimal strings
remain a display/input format through `fromDecimal` and `toDecimalString`; JSON
does not infer units from numeric types. Negative integer values support native
arithmetic. Payments separately apply their required nonnegative bounds.
`test/fixtures/amount-wire.json` exercises identical valid and rejected JSON in
both languages, including values above JavaScript's safe integer range.

Asset identity and marketplace proof envelopes still describe different product
layers: the Dart token model is an EVM chain/address pair, while the generic TS
driver asset includes payment method and policy routing; Dart event proofs also
do not yet implement the TS public/sealed payment-term tree. These should migrate
as a complete marketplace protocol rather than introducing unconsumed DTOs.

## Compiler tooling

All first-party TypeScript packages build with TypeScript 7.0.2. Documentation
and lint tooling share an isolated workspace using TypeScript 6.0.3, the newest
compiler API supported by TypeDoc 0.28.20 and typescript-eslint 8.70.0. The
OpenAPI generator is separately locked to TypeScript 5.9.3 because the latest
openapi-typescript 7.13.0 requires TypeScript 5.x. These development tools do not
enter the published drivers. Run generation and documentation from the aggregate
workspace, which installs all three compiler APIs without overriding peer ranges.
The aggregate's default TypeScript dependency is also 6.0.3 so transitive API
tools such as `ts-api-utils` cannot be hoisted onto the native compiler, which
does not export the JavaScript AST API. Package-local build compilers remain 7.0.2.

`permissionless` 0.4.1 still declares the optional `ox` 0.11.x peer; the EVM
workspace supplies 0.11.3 for development. Driver source does not import it and
published consumers install successfully without that development dependency.
Solc 0.8.37 pins `tmp` 0.2.6; the aggregate selects its patched 0.2.7 release.
All other direct npm dependencies were updated to their latest stable release.

EVM stack deployment mounts `MARKETPLACE_EVM_CONTRACTS_DIR` read-only. Aggregate
wrappers discover the one canonical contract package; standalone stack users
provide its path explicitly. There are no nested escrow source/artifact copies.
