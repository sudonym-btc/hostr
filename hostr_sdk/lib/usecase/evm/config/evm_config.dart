import 'dart:convert';

/// Top-level EVM config for the deployment.
///
/// Parsed from the `EVM_CONFIG` env variable (JSON string).
class EvmConfig {
  final BoltzConfig? boltz;
  final List<EvmChainConfig> chains;

  const EvmConfig({this.boltz, this.chains = const []});

  factory EvmConfig.fromJson(Map<String, dynamic> json) {
    return EvmConfig(
      boltz: json['boltz'] != null
          ? BoltzConfig.fromJson(json['boltz'] as Map<String, dynamic>)
          : null,
      chains:
          (json['chains'] as List<dynamic>?)
              ?.map((c) => EvmChainConfig.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory EvmConfig.fromJsonString(String jsonString) =>
      EvmConfig.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
    if (boltz != null) 'boltz': boltz!.toJson(),
    'chains': chains.map((c) => c.toJson()).toList(),
  };
}

/// Per-chain config. Deliberately minimal — no swap or escrow fields.
class EvmChainConfig {
  final String id;
  final int chainId;
  final String rpcUrl;
  final AAConfig? accountAbstraction;

  /// The Boltz currency string for this chain's native asset (e.g. `RBTC`).
  /// Used by [BoltzSwapProvider] to resolve swap pairs when no ERC-20 token
  /// address is specified. Set to `null` on chains that only support ERC-20
  /// token swaps (no native asset pair).
  final String? boltzCurrency;

  /// The deployed escrow contract address for this chain (optional).
  ///
  /// When set, [EscrowMethods.ensureEscrowMethod] will fetch the runtime
  /// bytecode and include its SHA-256 hash as a `"c"` tag in the user's
  /// escrow-method Nostr event.
  final String? escrowContractAddress;

  /// Well-known ERC-20 tokens on this chain (symbol → config).
  ///
  /// These are tokens the app needs to know about operationally — e.g. for
  /// escrow funding, token approvals, and resolving decimals from on-chain
  /// trade data. Boltz-discovered tokens are separate (dynamic, swap-only).
  final Map<String, TokenConfig> tokens;

  const EvmChainConfig({
    required this.id,
    required this.chainId,
    required this.rpcUrl,
    this.boltzCurrency,
    this.accountAbstraction,
    this.escrowContractAddress,
    this.tokens = const {},
  });

  /// Look up a [TokenConfig] by its contract address (case-insensitive).
  TokenConfig? tokenByAddress(String address) {
    final normalized = address.toLowerCase();
    for (final entry in tokens.values) {
      if (entry.address.toLowerCase() == normalized) return entry;
    }
    return null;
  }

  factory EvmChainConfig.fromJson(Map<String, dynamic> json) {
    return EvmChainConfig(
      id: json['id'] as String,
      chainId: json['chainId'] as int,
      rpcUrl: json['rpcUrl'] as String,
      boltzCurrency: json['boltzCurrency'] as String?,
      accountAbstraction: json['accountAbstraction'] != null
          ? AAConfig.fromJson(
              json['accountAbstraction'] as Map<String, dynamic>,
            )
          : null,
      escrowContractAddress: json['escrowContractAddress'] as String?,
      tokens:
          (json['tokens'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              TokenConfig.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chainId': chainId,
    'rpcUrl': rpcUrl,
    if (boltzCurrency != null) 'boltzCurrency': boltzCurrency,
    if (accountAbstraction != null)
      'accountAbstraction': accountAbstraction!.toJson(),
    if (escrowContractAddress != null)
      'escrowContractAddress': escrowContractAddress,
    if (tokens.isNotEmpty)
      'tokens': tokens.map((k, v) => MapEntry(k, v.toJson())),
  };
}

/// Config for a well-known ERC-20 token on a specific chain.
class TokenConfig {
  /// Checksummed EIP-55 contract address.
  final String address;

  /// Number of decimal places (e.g. 6 for USDT, 18 for tBTC).
  final int decimals;

  /// Solidity storage slot index for the `balanceOf` mapping.
  ///
  /// Used by [EscrowFundOperation] to build `eth_estimateUserOperationGas`
  /// state overrides that simulate having a token balance before the swap
  /// delivers it.
  ///
  /// Defaults to `0` (OpenZeppelin ERC-20).  Common alternatives:
  ///   - `2` — USDT / DAI
  ///   - `9` — USDC
  ///
  /// For custom contracts, inspect the storage layout (e.g. `forge inspect
  /// MyToken storage-layout`).
  final int balanceStorageSlot;

  /// Solidity storage slot index for the `allowance` mapping.
  ///
  /// Defaults to `1` (OpenZeppelin ERC-20).  Common alternatives:
  ///   - `4` — USDT
  ///   - `10` — USDC
  final int allowanceStorageSlot;

  const TokenConfig({
    required this.address,
    required this.decimals,
    this.balanceStorageSlot = 0,
    this.allowanceStorageSlot = 1,
  });

  factory TokenConfig.fromJson(Map<String, dynamic> json) {
    return TokenConfig(
      address: json['address'] as String,
      decimals: json['decimals'] as int,
      balanceStorageSlot: json['balanceStorageSlot'] as int? ?? 0,
      allowanceStorageSlot: json['allowanceStorageSlot'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'address': address,
    'decimals': decimals,
    if (balanceStorageSlot != 0) 'balanceStorageSlot': balanceStorageSlot,
    if (allowanceStorageSlot != 1) 'allowanceStorageSlot': allowanceStorageSlot,
  };
}

/// Boltz API config — one per deployment.
class BoltzConfig {
  final String apiUrl;

  const BoltzConfig({required this.apiUrl});

  String get wsUrl => '${apiUrl.replaceFirst('http', 'ws')}/ws';

  factory BoltzConfig.fromJson(Map<String, dynamic> json) {
    return BoltzConfig(apiUrl: json['apiUrl'] as String);
  }

  Map<String, dynamic> toJson() => {'apiUrl': apiUrl};
}

/// ERC-4337 Account Abstraction config — per chain.
class AAConfig {
  final String bundlerUrl;
  final String entryPointAddress;
  final String accountFactoryAddress;
  final String paymasterAddress;

  const AAConfig({
    required this.bundlerUrl,
    required this.entryPointAddress,
    required this.accountFactoryAddress,
    required this.paymasterAddress,
  });

  factory AAConfig.fromJson(Map<String, dynamic> json) {
    return AAConfig(
      bundlerUrl: json['bundlerUrl'] as String,
      entryPointAddress: json['entryPointAddress'] as String,
      accountFactoryAddress: json['accountFactoryAddress'] as String,
      paymasterAddress: json['paymasterAddress'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'bundlerUrl': bundlerUrl,
    'entryPointAddress': entryPointAddress,
    'accountFactoryAddress': accountFactoryAddress,
    'paymasterAddress': paymasterAddress,
  };
}
