#!/usr/bin/env node
/** Reject application payment implementations and reverse NMDK dependencies. */
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs'
import { dirname, extname, isAbsolute, join, relative, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

export function checkPaymentBoundary(root = resolve(dirname(fileURLToPath(import.meta.url)), '..')) {
  const errors = []
  const display = path => relative(root, path)
  const paymentPackages = ['marketplace_evm', 'marketplace_models']

  function files(path) {
    if (!existsSync(path)) return []
    if (statSync(path).isFile()) return [path]
    return readdirSync(path, { withFileTypes: true }).flatMap(entry =>
      entry.isSymbolicLink() ? [] : files(join(path, entry.name)),
    )
  }

  function withoutComments(source) {
    return source.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '')
  }

  function constructsSwapState(source) {
    const states = /\bSwap(?:In|Out)(?:Initialised|RequestCreated|PaymentProgress|AwaitingOnChain|InvoicePaid|LockupTxInMempool|Funded|Claimed|ClaimTxInMempool|Completed|Failed|PaymentDispatching|ClaimRelaying|ExternalInvoiceRequired|InvoiceCreated|WaitingForTimelock|Refunding|Refunded|Locking)\s*\(/g
    for (const match of source.matchAll(states)) {
      if (/\bcase\s*$/.test(source.slice(0, match.index))) continue
      let depth = 1
      let end = match.index + match[0].length
      while (depth && end < source.length) {
        if (source[end] === '(') depth++
        if (source[end] === ')') depth--
        end++
      }
      // Object patterns in switch expressions inspect state; they do not create it.
      if (/^\s*(?:=>|when\b)/.test(source.slice(end))) continue
      return true
    }
    return false
  }

  const removedPaths = [
    'models',
    'hostr_sdk/lib/usecase/evm',
    'hostr_sdk/lib/usecase/escrow',
    'hostr_sdk/lib/usecase/trade_account_allocator/trade_account_allocator.dart',
    'hostr_sdk/lib/datasources/boltz',
    'hostr_sdk/lib/datasources/contracts/boltz',
    'hostr_sdk/lib/datasources/contracts/escrow',
    'hostr_sdk/lib/datasources/swagger/boltz.json',
    ...['bloc_x', 'custom_logger', 'evm_signature', 'stream_status', 'telemetry', 'token_amount_ext', 'trace_context']
      .map(name => `hostr_sdk/lib/util/${name}.dart`),
  ]
  for (const path of removedPaths) {
    const absolutePath = join(root, path)
    if (existsSync(absolutePath) && (!statSync(absolutePath).isDirectory() || files(absolutePath).length)) {
      errors.push(`${path} is a removed compatibility path; use the canonical NMDK package directly`)
    }
  }
  for (const path of files(join(root, 'hostr_sdk/lib/datasources/swagger_generated'))) {
    if (/\/boltz[^/]*\.dart$/.test(path)) {
      errors.push(`${display(path)} duplicates NMDK generated bindings`)
    }
  }

  function isRemovedPath(path) {
    const localPath = relative(root, path)
    return removedPaths.some(removed => localPath === removed || localPath.startsWith(`${removed}/`)) ||
      /^hostr_sdk\/lib\/datasources\/swagger_generated\/boltz[^/]*\.dart$/.test(localPath)
  }

  for (const packageName of ['app', 'hostr_sdk', 'hostr_cli', 'escrow']) {
    const buildConfig = join(root, packageName, 'build.yaml')
    if (existsSync(buildConfig) && /\bweb3dart_builders\s*:/.test(readFileSync(buildConfig, 'utf8').replace(/^\s*#.*$/gm, ''))) {
      errors.push(`${display(buildConfig)} registers an application ABI builder; generate bindings only in NMDK`)
    }
    const manifest = join(root, packageName, 'pubspec.yaml')
    if (existsSync(manifest) && /^\s+models:\s*$/m.test(readFileSync(manifest, 'utf8'))) {
      errors.push(`${display(manifest)} depends on removed models; use marketplace_models directly`)
    }
    for (const directory of ['lib', 'bin', 'test']) {
      for (const path of files(join(root, packageName, directory)).filter(path => extname(path) === '.dart')) {
        const source = withoutComments(readFileSync(path, 'utf8'))
        for (const [, uri] of source.matchAll(/\b(?:import|export)\s+['"]([^'"]+)['"]/g)) {
          const destination = uri.startsWith('package:hostr_sdk/')
            ? join(root, 'hostr_sdk/lib', uri.slice('package:hostr_sdk/'.length))
            : !uri.includes(':') ? resolve(dirname(path), uri) : null
          if (uri.startsWith('package:models/') || destination && isRemovedPath(destination)) {
            errors.push(`${display(path)} imports removed compatibility path ${uri}; import NMDK directly`)
          }
        }
      }
    }
  }

  for (const packageName of paymentPackages) {
    const packageRoot = join(root, 'dependencies/nmdk/packages', packageName)
    const manifest = join(packageRoot, 'pubspec.yaml')
    if (!existsSync(manifest)) {
      errors.push(`${display(manifest)} is missing`)
      continue
    }
    const yaml = readFileSync(manifest, 'utf8')
    if (/^\s+(?:hostr|hostr_sdk|hostr_cli|models):\s*$/m.test(yaml)) {
      errors.push(`${display(manifest)} depends on a Hostr package`)
    }
    for (const path of files(join(packageRoot, 'lib')).filter(path => extname(path) === '.dart')) {
      const source = withoutComments(readFileSync(path, 'utf8'))
      const directives = [...source.matchAll(/\b(?:import|export|part)\s+([^;]+);/g)]
      const uris = directives.flatMap(([, directive]) =>
        [...directive.matchAll(/['"]([^'"]+)['"]/g)].map(([, uri]) => uri),
      )
      for (const uri of uris) {
        if (/^package:(?:hostr|hostr_sdk|hostr_cli|models)\//.test(uri)) {
          errors.push(`${display(path)} imports Hostr through ${uri}`)
        }
        if (!uri.includes(':')) {
          const destination = resolve(dirname(path), uri)
          const withinPackage = relative(packageRoot, destination)
          if (withinPackage.startsWith('..') || isAbsolute(withinPackage)) {
            errors.push(`${display(path)} escapes its package through ${uri}`)
          } else if (!existsSync(destination)) {
            errors.push(`${display(path)} references missing ${uri}`)
          }
        }
      }
    }
  }

  for (const directory of ['app/lib', 'hostr_sdk/lib', 'hostr_cli/lib']) {
    for (const path of files(join(root, directory)).filter(path => extname(path) === '.dart')) {
      const source = withoutComments(readFileSync(path, 'utf8'))
      if (/\bContractAbi\.fromJson\s*\(|\bContractFunction\s*\(|\.encodeCall\s*\(/.test(source)) {
        errors.push(`${display(path)} encodes EVM contracts in the application`)
      }
      if (/\b(?:EscrowEip712Signer|BoltzCallBuilder|BoltzClaimSigner|MultiEscrow|ERC20Swap|EtherSwap)\s*\(/.test(source) ||
          /\.(?:signClaim|signRelease|signArbitrate|signWithdraw|decodeResults)\s*\(/.test(source)) {
        errors.push(`${display(path)} assembles or decodes payment protocol details; use a driver operation`)
      }
      if (/\b(?:TypedMessage|EIP712Domain|MessageTypeProperty|hashTypedData|signTypedData)\s*\(/.test(source)) {
        errors.push(`${display(path)} implements EIP-712 signing outside NMDK`)
      }
      if (/\.(?:swapReversePost|swapSubmarinePost|swapSubmarineIdRefundGet|swapSubmarineIdPreimageGet)\s*\(/.test(source)) {
        errors.push(`${display(path)} calls the Boltz wire protocol outside NMDK`)
      }
      if (/\boperationStateStore\s*\.\s*(?:write|delete)\s*\(\s*['"]swap_(?:in|out)['"]/.test(source)) {
        errors.push(`${display(path)} mutates a driver-owned swap journal; use a driver operation`)
      }
      if (constructsSwapState(source)) {
        errors.push(`${display(path)} constructs a swap transition; let the driver advance its state`)
      }
    }
  }

  for (const path of files(join(root, 'escrow/contracts/contracts'))) {
    if (extname(path) === '.sol') {
      errors.push(`${display(path)} duplicates contract source; deploy the canonical NMDK artifact`)
    }
  }

  // Path dependencies must be present before pub get in fresh containers.
  for (const dockerfile of ['app/Dockerfile.web', 'escrow/Dockerfile', 'ai/mcp-server/Dockerfile']) {
    const path = join(root, dockerfile)
    if (!existsSync(path)) continue
    const source = readFileSync(path, 'utf8').replace(/^\s*#.*$/gm, '')
    if (/^COPY\s+models(?:\/|\s)/m.test(source)) {
      errors.push(`${dockerfile} copies the removed models package`)
    }
    const pubGet = source.search(/^RUN\s+(?:dart|flutter)\s+pub\s+get\b/m)
    const beforePubGet = pubGet < 0 ? source : source.slice(0, pubGet)
    for (const packageName of paymentPackages) {
      const packagePath = `dependencies/nmdk/packages/${packageName}`
      const copy = new RegExp(`^COPY\\s+${packagePath}/?\\s+/workspace/${packagePath}/?\\s*$`, 'm')
      if (!copy.test(beforePubGet)) {
        errors.push(`${dockerfile} must copy ${packagePath} into /workspace before pub get`)
      }
    }
    if (dockerfile === 'ai/mcp-server/Dockerfile' &&
        !/^COPY\s+--from=daemon-build\s+\/workspace\/dependencies\/nmdk\/packages\/marketplace_models\/native\/?\s+\/opt\/hostr-daemon\/native\/?\s*$/m.test(source)) {
      errors.push(`${dockerfile} must copy native assets from canonical marketplace_models`)
    }
  }

  const localCompose = join(root, 'compose.local.yaml')
  if (existsSync(localCompose)) {
    const source = readFileSync(localCompose, 'utf8')
    if (/\.\/models(?:\/|:)/.test(source)) errors.push('compose.local.yaml mounts the removed models package')
    const escrow = source.match(/^  escrow:\s*\n([\s\S]*?)(?=^  [\w-]+:|$(?![\s\S]))/m)?.[1] ?? ''
    for (const packageName of paymentPackages) {
      const packagePath = `dependencies/nmdk/packages/${packageName}/lib`
      if (!escrow.includes(`- ./${packagePath}:/workspace/${packagePath}`)) {
        errors.push(`compose.local.yaml escrow must mount ${packagePath} for driver development`)
      }
    }
  }

  return { errors }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const { errors } = checkPaymentBoundary()
  if (errors.length) {
    console.error(`Payment boundary failed:\n${errors.map(error => `- ${error}`).join('\n')}`)
    process.exitCode = 1
  } else {
    console.log('Payment boundary passed (direct NMDK imports, no compatibility layers or reverse Hostr dependency).')
  }
}
