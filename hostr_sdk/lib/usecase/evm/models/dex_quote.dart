/// A single DEX quote returned by the Boltz Quote API.
///
/// Mirrors the web app's `DexQuote` type exactly:
/// `{ amountIn: bigint, amountOut: bigint, data: unknown }`.
///
/// [data] is opaque — it comes from `/v2/quote/{chain}/in` or `/out`
/// and is passed verbatim to `/v2/quote/{chain}/encode` at execution time.
/// The SDK never inspects its contents.
class DexQuote {
  /// Raw amount fed into the DEX (smallest unit, e.g. wei).
  final BigInt amountIn;

  /// Raw amount received from the DEX (smallest unit, e.g. wei).
  final BigInt amountOut;

  /// Opaque quote payload from Boltz Quote API — passed to `/encode`.
  final Object data;

  const DexQuote({
    required this.amountIn,
    required this.amountOut,
    required this.data,
  });

  @override
  String toString() => 'DexQuote(in=$amountIn, out=$amountOut)';
}
