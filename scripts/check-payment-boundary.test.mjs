import assert from 'node:assert/strict'
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import test from 'node:test'
import { checkPaymentBoundary } from './check-payment-boundary.mjs'

function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'hostr-payment-boundary-'))
  t.after(() => rmSync(root, { recursive: true, force: true }))
  const put = (path, source) => {
    const destination = join(root, path)
    mkdirSync(dirname(destination), { recursive: true })
    writeFileSync(destination, source)
  }
  for (const name of ['marketplace_evm', 'marketplace_models']) {
    put(`dependencies/nmdk/packages/${name}/pubspec.yaml`, `name: ${name}\n`)
  }
  return { put, check: () => checkPaymentBoundary(root).errors }
}

test('accepts direct canonical imports and package-local implementations', t => {
  const { put, check } = fixture(t)
  put('hostr_sdk/lib/hostr.dart', "import 'package:marketplace_evm/marketplace_evm.dart';\n")
  put('app/lib/main.dart', "import 'package:marketplace_models/main.dart';\n")
  put('dependencies/nmdk/packages/marketplace_evm/lib/marketplace_evm.dart', 'class Evm {}\n')
  assert.deepEqual(check(), [])
})

test('rejects ABI builder registration even when disabled', t => {
  const { put, check } = fixture(t)
  put('hostr_sdk/build.yaml', 'targets:\n  $default:\n    builders:\n      web3dart_builders:\n        enabled: false\n')
  assert.ok(check().some(error => error.includes('registers an application ABI builder')))
})

test('rejects CLI swap transitions and writes while allowing status reads', t => {
  const { put, check } = fixture(t)
  const path = 'hostr_cli/lib/daemon.dart'
  put(path, "final state = SwapInAwaitingOnChain(data);\nawait hostr.operationStateStore.write('swap_in', id, state.toJson());")
  assert.ok(check().some(error => error.includes('constructs a swap transition')))
  assert.ok(check().some(error => error.includes('mutates a driver-owned swap journal')))
  put(path, "final state = await hostr.operationStateStore.read('swap_in', id);\nif (state is SwapInAwaitingOnChain) return state.toJson();\nswitch(state) { case SwapInCompleted(): break; }\nreturn switch(state) { SwapInPaymentProgress(paymentState: PayExternalRequired()) => true, _ => false }; ")
  assert.deepEqual(check(), [])
})

test('rejects mechanism implementations and regeneration inputs in Hostr', t => {
  const { put, check } = fixture(t)
  put('hostr_sdk/lib/usecase/evm/evm.dart', 'class Evm {}\n')
  put('hostr_sdk/lib/datasources/contracts/boltz/EtherSwap.abi.json', '{}')
  put('escrow/contracts/contracts/MultiEscrow.sol', 'contract MultiEscrow {}')
  assert.ok(check().some(error => error.includes('hostr_sdk/lib/usecase/evm is a removed')))
  assert.ok(check().some(error => error.includes('hostr_sdk/lib/datasources/contracts/boltz is a removed')))
  assert.ok(check().some(error => error.includes('duplicates contract source')))
})

test('rejects reverse application dependencies in manifests and Dart imports', t => {
  const { put, check } = fixture(t)
  put('dependencies/nmdk/packages/marketplace_evm/pubspec.yaml', 'name: marketplace_evm\ndependencies:\n  hostr_sdk:\n    path: ../../../../../hostr_sdk\n')
  put('dependencies/nmdk/packages/marketplace_evm/lib/bad.dart', "import 'package:hostr_sdk/hostr_sdk.dart';\n")
  assert.ok(check().some(error => error.includes('depends on a Hostr package')))
  assert.ok(check().some(error => error.includes('imports Hostr')))
})

test('checks conditional platform imports, including missing native files', t => {
  const { put, check } = fixture(t)
  put('dependencies/nmdk/packages/marketplace_evm/lib/client.dart', "import 'stub.dart' if (dart.library.io) 'native.dart';\n")
  put('dependencies/nmdk/packages/marketplace_evm/lib/stub.dart', '')
  assert.ok(check().some(error => error.includes('missing native.dart')))
  put('dependencies/nmdk/packages/marketplace_evm/lib/native.dart', '')
  assert.deepEqual(check(), [])
})

test('rejects compatibility exports even when they only forward canonical types', t => {
  const { put, check } = fixture(t)
  put('hostr_sdk/lib/usecase/evm/main.dart', "export 'package:marketplace_evm/marketplace_evm.dart';\n")
  put('models/lib/main.dart', "export 'package:marketplace_models/main.dart';\n")
  assert.equal(check().filter(error => error.includes('removed compatibility path;')).length, 2)
})

test('rejects old package imports, relative wrappers, and model dependencies', t => {
  const { put, check } = fixture(t)
  put('app/lib/main.dart', "import 'package:models/main.dart';\n")
  put('hostr_sdk/lib/hostr.dart', "import 'usecase/evm/evm.dart';\n")
  put('hostr_cli/bin/main.dart', "import 'package:hostr_sdk/usecase/escrow/main.dart';\n")
  put('app/pubspec.yaml', 'dependencies:\n  models:\n    path: ../models\n')
  assert.equal(check().filter(error => error.includes('imports removed compatibility path')).length, 3)
  assert.ok(check().some(error => error.includes('depends on removed models')))
})

test('checks imports emitted by root and package Dart generators', t => {
  const { put, check } = fixture(t)
  for (const path of ['scripts/generate-env.dart', 'hostr_sdk/tool/generate-env.dart']) {
    put(path, `buffer.writeln("import 'package:hostr_sdk/usecase/evm/config/evm_config.dart';");`)
    assert.ok(check().some(error => error.includes(path) && error.includes('imports removed compatibility path')))
    put(path, `buffer.writeln("import 'package:marketplace_evm/usecase/evm/config/evm_config.dart';");`)
  }
  assert.deepEqual(check(), [])
})

test('rejects package-relative imports that escape the driver', t => {
  const { put, check } = fixture(t)
  put('dependencies/nmdk/packages/marketplace_evm/lib/bad.dart', "import '../../../../../../hostr_sdk/lib/hostr.dart';\n")
  assert.ok(check().some(error => error.includes('escapes its package')))
})

test('rejects payment mechanism code hidden in UI and unrelated SDK folders', t => {
  const { put, check } = fixture(t)
  const cases = [
    ['app/lib/screens/withdraw.dart', 'final data = function.encodeCall([signature]);', 'encodes EVM'],
    ['app/lib/screens/payment.dart', 'final signer = EscrowEip712Signer();', 'protocol details'],
    ['hostr_sdk/lib/seed/sink.dart', 'final event = abi.decodeResults(topics, data);', 'protocol details'],
    ['hostr_sdk/lib/helpers/escrow.dart', 'final data = eip712.TypedMessage(types: types);', 'EIP-712'],
    ['app/lib/helpers/refund.dart', 'client.swapSubmarineIdRefundGet(id: id);', 'Boltz wire protocol'],
  ]
  for (const [path, source, message] of cases) {
    put(path, source)
    assert.ok(check().some(error => error.includes(path) && error.includes(message)), path)
  }
})

test('allows payment presentation and driver delegation without protocol details', t => {
  const { put, check } = fixture(t)
  put('app/lib/screens/payment.dart', `
    // Previously used ContractAbi.fromJson and signer.signClaim().
    final params = item.swapOutParams();
    final operation = chain.swapOut(params);
    final status = operation.state.data?.lastBoltzStatus;
  `)
  put('hostr_sdk/lib/seed/sink.dart', 'await driver.arbitrate(tradeId: id, paymentForward: 0.7, bondForward: 0);')
  assert.deepEqual(check(), [])
})

const packageCopies = ['marketplace_models', 'marketplace_evm'].map(name =>
  `COPY dependencies/nmdk/packages/${name} /workspace/dependencies/nmdk/packages/${name}`,
).join('\n')

test('requires canonical path packages before container dependency resolution', t => {
  const { put, check } = fixture(t)
  for (const dockerfile of ['app/Dockerfile.web', 'escrow/Dockerfile']) {
    put(dockerfile, `FROM scratch\nRUN dart pub get\n${packageCopies}\n`)
    assert.equal(check().filter(error => error.startsWith(dockerfile)).length, 2)
    put(dockerfile, `FROM scratch\n${packageCopies}\nRUN dart pub get\n`)
  }
  assert.deepEqual(check(), [])
})

test('requires MCP native assets from the canonical package', t => {
  const { put, check } = fixture(t)
  const source = `${packageCopies}\nRUN dart pub get\n`
  put('ai/mcp-server/Dockerfile', `${source}COPY --from=daemon-build /workspace/models/native /opt/hostr-daemon/native\n`)
  assert.ok(check().some(error => error.includes('native assets from canonical')))
  put('ai/mcp-server/Dockerfile', `${source}COPY --from=daemon-build /workspace/dependencies/nmdk/packages/marketplace_models/native /opt/hostr-daemon/native\n`)
  assert.deepEqual(check(), [])
})

test('requires canonical library mounts on the local escrow service', t => {
  const { put, check } = fixture(t)
  const volumes = ['marketplace_models', 'marketplace_evm'].map(name =>
    `      - ./dependencies/nmdk/packages/${name}/lib:/workspace/dependencies/nmdk/packages/${name}/lib`,
  ).join('\n')
  put('compose.local.yaml', `services:\n  escrow:\n    volumes: []\n  unrelated:\n    volumes:\n${volumes}\n`)
  assert.equal(check().filter(error => error.includes('escrow must mount')).length, 2)
  put('compose.local.yaml', `services:\n  escrow:\n    volumes:\n${volumes}\n  unrelated:\n    image: scratch\n`)
  assert.deepEqual(check(), [])
})

test('rejects packaging the removed model facade', t => {
  const { put, check } = fixture(t)
  put('app/Dockerfile.web', `COPY models /workspace/models\n${packageCopies}\nRUN flutter pub get\n`)
  assert.ok(check().some(error => error.includes('copies the removed models')))
})
