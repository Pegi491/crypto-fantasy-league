"use strict";
// ABOUTME: CoinGecko API integration for token prices and market data
// ABOUTME: Handles rate limiting, error handling, and comprehensive market metrics
Object.defineProperty(exports, "__esModule", { value: true });
exports.pullCoinGeckoData = pullCoinGeckoData;
const admin = require("firebase-admin");
const firebase_functions_1 = require("firebase-functions");
const axios_1 = require("axios");
const firestore = admin.firestore();
class CoinGeckoAPI {
    constructor(config) {
        this.lastRequestTime = 0;
        this.config = Object.assign({ baseUrl: "https://api.coingecko.com/api/v3", rateLimit: 10 }, config);
    }
    async rateLimitDelay() {
        const minInterval = 60000 / (this.config.rateLimit || 10); // Convert to milliseconds
        const timeSinceLastRequest = Date.now() - this.lastRequestTime;
        if (timeSinceLastRequest < minInterval) {
            const delay = minInterval - timeSinceLastRequest;
            firebase_functions_1.logger.debug(`Rate limiting: waiting ${delay}ms`);
            await new Promise(resolve => setTimeout(resolve, delay));
        }
        this.lastRequestTime = Date.now();
    }
    async makeRequest(endpoint, params) {
        var _a, _b;
        await this.rateLimitDelay();
        const url = `${this.config.baseUrl}${endpoint}`;
        const headers = {
            "User-Agent": "crypto-fantasy-league/1.0",
        };
        // Add API key if provided (for pro tier)
        if (this.config.apiKey) {
            headers["x-cg-pro-api-key"] = this.config.apiKey;
        }
        try {
            firebase_functions_1.logger.debug("Making CoinGecko API request", {
                endpoint,
                params,
            });
            const response = await axios_1.default.get(url, {
                params,
                headers,
                timeout: 15000,
            });
            return response.data;
        }
        catch (error) {
            if (error instanceof axios_1.AxiosError) {
                firebase_functions_1.logger.error("CoinGecko API request failed", {
                    status: (_a = error.response) === null || _a === void 0 ? void 0 : _a.status,
                    message: error.message,
                    endpoint,
                    params,
                });
                if (((_b = error.response) === null || _b === void 0 ? void 0 : _b.status) === 429) {
                    // Rate limit hit, wait longer
                    await new Promise(resolve => setTimeout(resolve, 5000));
                    throw new Error("Rate limit exceeded");
                }
            }
            throw error;
        }
    }
    async getMarketData(coinIds) {
        if (coinIds.length === 0) {
            return [];
        }
        // CoinGecko allows up to 250 coins per request
        const chunks = [];
        for (let i = 0; i < coinIds.length; i += 250) {
            chunks.push(coinIds.slice(i, i + 250));
        }
        const allMarketData = [];
        for (const chunk of chunks) {
            try {
                const data = await this.makeRequest("/coins/markets", {
                    ids: chunk.join(","),
                    vs_currency: "usd",
                    order: "market_cap_desc",
                    per_page: "250",
                    page: "1",
                    sparkline: "false",
                    price_change_percentage: "24h",
                    locale: "en",
                });
                const marketData = data.map((coin) => ({
                    id: coin.id,
                    symbol: coin.symbol,
                    name: coin.name,
                    currentPrice: coin.current_price || 0,
                    marketCap: coin.market_cap || 0,
                    marketCapRank: coin.market_cap_rank || 0,
                    fullyDilutedValuation: coin.fully_diluted_valuation,
                    totalVolume: coin.total_volume || 0,
                    high24h: coin.high_24h || 0,
                    low24h: coin.low_24h || 0,
                    priceChange24h: coin.price_change_24h || 0,
                    priceChangePercentage24h: coin.price_change_percentage_24h || 0,
                    marketCapChange24h: coin.market_cap_change_24h || 0,
                    marketCapChangePercentage24h: coin.market_cap_change_percentage_24h || 0,
                    circulatingSupply: coin.circulating_supply || 0,
                    totalSupply: coin.total_supply,
                    maxSupply: coin.max_supply,
                    ath: coin.ath || 0,
                    athChangePercentage: coin.ath_change_percentage || 0,
                    athDate: coin.ath_date || "",
                    atl: coin.atl || 0,
                    atlChangePercentage: coin.atl_change_percentage || 0,
                    atlDate: coin.atl_date || "",
                    lastUpdated: coin.last_updated || "",
                    timestamp: Date.now(),
                }));
                allMarketData.push(...marketData);
            }
            catch (error) {
                firebase_functions_1.logger.error("Failed to get market data chunk", {
                    chunk,
                    error: error instanceof Error ? error.message : "Unknown error",
                });
            }
        }
        return allMarketData;
    }
    async getTokenInfo(contractAddress, platform = "ethereum") {
        try {
            const data = await this.makeRequest(`/coins/${platform}/contract/${contractAddress}`);
            return {
                id: data.id,
                symbol: data.symbol,
                name: data.name,
                contractAddress: data.contract_address,
                marketData: data.market_data,
            };
        }
        catch (error) {
            firebase_functions_1.logger.warn("Failed to get token info", {
                contractAddress,
                platform,
                error: error instanceof Error ? error.message : "Unknown error",
            });
            return null;
        }
    }
    async searchCoins(query) {
        try {
            const data = await this.makeRequest("/search", { q: query });
            return data.coins || [];
        }
        catch (error) {
            firebase_functions_1.logger.warn("Failed to search coins", {
                query,
                error: error instanceof Error ? error.message : "Unknown error",
            });
            return [];
        }
    }
    async getTrendingCoins() {
        try {
            const data = await this.makeRequest("/search/trending");
            return data.coins || [];
        }
        catch (error) {
            firebase_functions_1.logger.warn("Failed to get trending coins", {
                error: error instanceof Error ? error.message : "Unknown error",
            });
            return [];
        }
    }
}
async function pullCoinGeckoData(config) {
    var _a, _b, _c;
    firebase_functions_1.logger.info("Starting CoinGecko data pull");
    const api = new CoinGeckoAPI(config);
    const errors = [];
    let assetsUpdated = 0;
    const marketData = [];
    try {
        // Get all token assets from Firestore
        const assetsSnapshot = await firestore
            .collection("assets")
            .where("type", "==", "token")
            .where("isActive", "==", true)
            .get();
        if (assetsSnapshot.empty) {
            firebase_functions_1.logger.info("No active token assets found");
            return { assetsUpdated: 0, marketData: [], errors: [] };
        }
        // Extract CoinGecko IDs from asset metadata
        const coinIds = [];
        const assetsByCoinId = {};
        for (const doc of assetsSnapshot.docs) {
            const asset = doc.data();
            const coinGeckoId = (_a = asset.metadata) === null || _a === void 0 ? void 0 : _a.coinGeckoId;
            if (coinGeckoId) {
                coinIds.push(coinGeckoId);
                assetsByCoinId[coinGeckoId] = Object.assign({ id: doc.id }, asset);
            }
            else {
                // Try to find CoinGecko ID by contract address
                try {
                    const tokenInfo = await api.getTokenInfo(asset.address);
                    if (tokenInfo && tokenInfo.id) {
                        coinIds.push(tokenInfo.id);
                        assetsByCoinId[tokenInfo.id] = Object.assign({ id: doc.id }, asset);
                        // Update asset with CoinGecko ID
                        await doc.ref.update({
                            "metadata.coinGeckoId": tokenInfo.id,
                            updatedAt: admin.firestore.Timestamp.now(),
                        });
                    }
                }
                catch (error) {
                    const errorMessage = `Failed to find CoinGecko ID for asset ${asset.symbol}: ${error instanceof Error ? error.message : "Unknown error"}`;
                    errors.push(errorMessage);
                    firebase_functions_1.logger.warn(errorMessage);
                }
            }
        }
        if (coinIds.length === 0) {
            firebase_functions_1.logger.info("No assets with CoinGecko IDs found");
            return { assetsUpdated: 0, marketData: [], errors };
        }
        firebase_functions_1.logger.info(`Fetching market data for ${coinIds.length} coins`);
        // Get market data for all coins
        const coins = await api.getMarketData(coinIds);
        marketData.push(...coins);
        // Store market data in Firestore
        const batch = firestore.batch();
        const timestamp = admin.firestore.Timestamp.now();
        for (const coin of coins) {
            // Store daily stats
            const statsDocRef = firestore
                .collection("daily_stats")
                .doc(`${coin.id}_${new Date().toISOString().split("T")[0]}`);
            batch.set(statsDocRef, {
                assetId: ((_b = assetsByCoinId[coin.id]) === null || _b === void 0 ? void 0 : _b.id) || coin.id,
                date: new Date().toISOString().split("T")[0],
                priceUsd: coin.currentPrice,
                volumeUsd: coin.totalVolume,
                marketCapUsd: coin.marketCap,
                changePercent24h: coin.priceChangePercentage24h,
                high24h: coin.high24h,
                low24h: coin.low24h,
                rank: coin.marketCapRank,
                timestamp: timestamp,
            }, { merge: true });
            // Update asset metadata
            const assetId = (_c = assetsByCoinId[coin.id]) === null || _c === void 0 ? void 0 : _c.id;
            if (assetId) {
                const assetRef = firestore.collection("assets").doc(assetId);
                batch.update(assetRef, {
                    "metadata.market_cap": coin.marketCap,
                    "metadata.volume_24h": coin.totalVolume,
                    "metadata.price_usd": coin.currentPrice,
                    "metadata.rank": coin.marketCapRank,
                    lastCoinGeckoFetch: timestamp,
                    updatedAt: timestamp,
                });
                assetsUpdated++;
            }
        }
        await batch.commit();
        firebase_functions_1.logger.info("CoinGecko data pull completed successfully", {
            assetsUpdated,
            coinsProcessed: coins.length,
            errors: errors.length,
        });
        return {
            assetsUpdated,
            marketData,
            errors,
        };
    }
    catch (error) {
        firebase_functions_1.logger.error("CoinGecko data pull failed", error);
        throw error;
    }
}
//# sourceMappingURL=coingecko.js.map