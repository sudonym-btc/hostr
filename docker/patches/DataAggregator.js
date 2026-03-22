"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const Utils_1 = require("../../Utils");
const EvmNetworks_1 = require("../../wallet/ethereum/EvmNetworks");
const Binance_1 = __importDefault(require("./exchanges/Binance"));
const Bitfinex_1 = __importDefault(require("./exchanges/Bitfinex"));
const CoinbasePro_1 = __importDefault(require("./exchanges/CoinbasePro"));
const Kraken_1 = __importDefault(require("./exchanges/Kraken"));
class DataAggregator {
    constructor() {
        this.exchanges = [
            new Kraken_1.default(),
            new Binance_1.default(),
            new Bitfinex_1.default(),
            new CoinbasePro_1.default(),
        ];
        this.pairs = new Set();
        this.latestRates = new Map();
        // Pairs that need to be fetched inverted (base/quote swapped)
        this.invertedPairs = new Set();
        this.registerPair = (baseAsset, quoteAsset) => {
            this.pairs.add([baseAsset, quoteAsset]);
        };
        this.fetchPairs = async () => {
            const rateMap = new Map();
            const queryPromises = [];
            const queryRate = async (base, quote) => {
                const pairId = (0, Utils_1.getPairId)({ base, quote });
                const inversePairId = (0, Utils_1.getPairId)({ base: quote, quote: base });
                const rate = await this.getRateWithInverse(base, quote);
                if (rate !== undefined) {
                    rateMap.set(pairId, rate);
                    rateMap.set(inversePairId, 1 / rate);
                }
                else {
                    // If the rate couldn't be fetched, the latest one should be used
                    rateMap.set(pairId, this.latestRates.get(pairId) || NaN);
                    rateMap.set(inversePairId, this.latestRates.get(inversePairId) || NaN);
                }
            };
            this.pairs.forEach(([baseAsset, quoteAsset]) => {
                queryPromises.push(queryRate(baseAsset, quoteAsset));
            });
            await Promise.all(queryPromises);
            this.latestRates = rateMap;
            return rateMap;
        };
        this.getRateWithInverse = async (baseAsset, quoteAsset) => {
            const pairId = (0, Utils_1.getPairId)({ base: baseAsset, quote: quoteAsset });
            const shouldInvert = this.invertedPairs.has(pairId);
            const [first, second] = shouldInvert
                ? [quoteAsset, baseAsset]
                : [baseAsset, quoteAsset];
            // Try the preferred order first
            const rate = await this.getRate(first, second);
            if (rate !== undefined) {
                return shouldInvert ? 1 / rate : rate;
            }
            // Try the other order
            const inverseRate = await this.getRate(second, first);
            if (inverseRate !== undefined) {
                // Remember to use inverted order for subsequent fetches
                if (!shouldInvert) {
                    this.invertedPairs.add(pairId);
                }
                return shouldInvert ? inverseRate : 1 / inverseRate;
            }
            return undefined;
        };
        this.getRate = async (baseAsset, quoteAsset) => {
            const promises = [];
            this.exchanges.forEach((exchange) => promises.push(exchange.getPrice(this.assetMapper(baseAsset), this.assetMapper(quoteAsset))));
            const results = await Promise.all(promises.map((promise) => promise.catch((error) => error)));
            // Filter all results that are not numeric (failed requests)
            const validResults = results.filter((result) => !isNaN(Number(result)));
            if (validResults.length === 0) {
                return undefined;
            }
            validResults.sort((a, b) => a - b);
            const middle = (validResults.length - 1) / 2;
            if (validResults.length % 2 === 0) {
                return ((validResults[Math.ceil(middle)] + validResults[Math.floor(middle)]) / 2);
            }
            else {
                return validResults[middle];
            }
        };
        this.assetMapper = (asset) => {
            switch (asset) {
                case EvmNetworks_1.networks.Arbitrum.symbol:
                    return 'ETH';
                case 'TBTC':
                case 'tBTC':
                    return 'BTC';
                default:
                    return asset;
            }
        };
    }
}
exports.default = DataAggregator;
//# sourceMappingURL=DataAggregator.js.map