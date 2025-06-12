"use strict";
// ABOUTME: Asset metadata updater for maintaining asset information
// ABOUTME: Updates asset metadata, popularity rankings, and data freshness
Object.defineProperty(exports, "__esModule", { value: true });
exports.AssetMetadataUpdater = void 0;
exports.updateAssetMetadata = updateAssetMetadata;
const admin = require("firebase-admin");
const firebase_functions_1 = require("firebase-functions");
const firestore = admin.firestore();
class AssetMetadataUpdater {
    static async updateAssetPopularity(asset) {
        try {
            const metadata = asset.metadata || {};
            const volume24h = metadata.volume_24h || 0;
            const marketCap = metadata.market_cap || 0;
            const socialScore = metadata.social_score || 0;
            // Determine if asset should be marked as popular
            const isPopular = volume24h >= this.POPULAR_THRESHOLD_VOLUME ||
                marketCap >= this.POPULAR_THRESHOLD_MARKET_CAP ||
                socialScore >= 70; // High social score
            // Update if popularity status has changed
            if (asset.isPopular !== isPopular) {
                await firestore.collection("assets").doc(asset.id).update({
                    isPopular,
                    updatedAt: admin.firestore.Timestamp.now(),
                });
                firebase_functions_1.logger.info("Updated asset popularity", {
                    assetId: asset.id,
                    symbol: asset.symbol,
                    isPopular,
                    volume24h,
                    marketCap,
                    socialScore,
                });
                return true;
            }
            return false;
        }
        catch (error) {
            firebase_functions_1.logger.error("Failed to update asset popularity", {
                assetId: asset.id,
                error: error instanceof Error ? error.message : "Unknown error",
            });
            throw error;
        }
    }
    static async updateAssetRanking(asset) {
        try {
            const metadata = asset.metadata || {};
            const currentRank = metadata.rank || 0;
            const marketCap = metadata.market_cap || 0;
            // Only update ranking for tokens with market cap data
            if (asset.type === "token" && marketCap > 0) {
                // Get count of assets with higher market cap
                const higherRankCount = await firestore
                    .collection("assets")
                    .where("type", "==", "token")
                    .where("metadata.market_cap", ">", marketCap)
                    .get();
                const newRank = higherRankCount.size + 1;
                if (newRank !== currentRank) {
                    await firestore.collection("assets").doc(asset.id).update({
                        "metadata.rank": newRank,
                        updatedAt: admin.firestore.Timestamp.now(),
                    });
                    firebase_functions_1.logger.debug("Updated asset ranking", {
                        assetId: asset.id,
                        symbol: asset.symbol,
                        oldRank: currentRank,
                        newRank,
                        marketCap,
                    });
                    return true;
                }
            }
            return false;
        }
        catch (error) {
            firebase_functions_1.logger.error("Failed to update asset ranking", {
                assetId: asset.id,
                error: error instanceof Error ? error.message : "Unknown error",
            });
            throw error;
        }
    }
    static async updateDataFreshness(asset) {
        try {
            const now = admin.firestore.Timestamp.now();
            const staleThreshold = admin.firestore.Timestamp.fromMillis(now.toMillis() - this.STALE_DATA_HOURS * 60 * 60 * 1000);
            const updates = {};
            let hasUpdates = false;
            // Check various data sources for freshness
            const lastEtherscanFetch = asset.lastEtherscanFetch;
            const lastCoinGeckoFetch = asset.lastCoinGeckoFetch;
            const lastSocialFetch = asset.lastSocialFetch;
            // Mark data as stale if it's old
            if (asset.type === "wallet" && lastEtherscanFetch && lastEtherscanFetch < staleThreshold) {
                updates["metadata.etherscanDataStale"] = true;
                hasUpdates = true;
            }
            if (asset.type === "token" && lastCoinGeckoFetch && lastCoinGeckoFetch < staleThreshold) {
                updates["metadata.coinGeckoDataStale"] = true;
                hasUpdates = true;
            }
            if (lastSocialFetch && lastSocialFetch < staleThreshold) {
                updates["metadata.socialDataStale"] = true;
                hasUpdates = true;
            }
            // Calculate data completeness score
            let completenessScore = 0;
            const metadata = asset.metadata || {};
            if (metadata.price_usd)
                completenessScore += 25;
            if (metadata.volume_24h)
                completenessScore += 25;
            if (metadata.market_cap)
                completenessScore += 25;
            if (metadata.social_score)
                completenessScore += 25;
            updates["metadata.dataCompleteness"] = completenessScore;
            hasUpdates = true;
            if (hasUpdates) {
                updates.updatedAt = now;
                await firestore.collection("assets").doc(asset.id).update(updates);
                firebase_functions_1.logger.debug("Updated data freshness", {
                    assetId: asset.id,
                    symbol: asset.symbol,
                    completenessScore,
                    staleData: Object.keys(updates).filter(k => k.includes("Stale")),
                });
                return true;
            }
            return false;
        }
        catch (error) {
            firebase_functions_1.logger.error("Failed to update data freshness", {
                assetId: asset.id,
                error: error instanceof Error ? error.message : "Unknown error",
            });
            throw error;
        }
    }
    static async enrichAssetMetadata(asset) {
        try {
            const metadata = asset.metadata || {};
            const updates = {};
            let hasUpdates = false;
            // Add computed fields
            if (metadata.price_usd && metadata.volume_24h) {
                const volumeToPrice = metadata.volume_24h / metadata.price_usd;
                if (metadata.volumeToPriceRatio !== volumeToPrice) {
                    updates["metadata.volumeToPriceRatio"] = Math.round(volumeToPrice);
                    hasUpdates = true;
                }
            }
            // Calculate price volatility from recent daily stats
            if (asset.type === "token") {
                const recentStatsSnapshot = await firestore
                    .collection("daily_stats")
                    .where("assetId", "==", asset.id)
                    .orderBy("timestamp", "desc")
                    .limit(7)
                    .get();
                if (recentStatsSnapshot.size >= 3) {
                    const prices = recentStatsSnapshot.docs
                        .map(doc => doc.data().priceUsd)
                        .filter(price => price && price > 0);
                    if (prices.length >= 3) {
                        const volatility = this.calculateVolatility(prices);
                        if (metadata.volatility7d !== volatility) {
                            updates["metadata.volatility7d"] = volatility;
                            hasUpdates = true;
                        }
                    }
                }
            }
            // Add asset category based on market cap
            if (metadata.market_cap) {
                let category = "unknown";
                if (metadata.market_cap > 10000000000) { // $10B+
                    category = "large-cap";
                }
                else if (metadata.market_cap > 2000000000) { // $2B+
                    category = "mid-cap";
                }
                else if (metadata.market_cap > 300000000) { // $300M+
                    category = "small-cap";
                }
                else {
                    category = "micro-cap";
                }
                if (metadata.category !== category) {
                    updates["metadata.category"] = category;
                    hasUpdates = true;
                }
            }
            // Add risk score based on various factors
            const riskScore = this.calculateRiskScore(metadata);
            if (metadata.riskScore !== riskScore) {
                updates["metadata.riskScore"] = riskScore;
                hasUpdates = true;
            }
            if (hasUpdates) {
                updates.updatedAt = admin.firestore.Timestamp.now();
                await firestore.collection("assets").doc(asset.id).update(updates);
                firebase_functions_1.logger.debug("Enriched asset metadata", {
                    assetId: asset.id,
                    symbol: asset.symbol,
                    updatedFields: Object.keys(updates),
                });
                return true;
            }
            return false;
        }
        catch (error) {
            firebase_functions_1.logger.error("Failed to enrich asset metadata", {
                assetId: asset.id,
                error: error instanceof Error ? error.message : "Unknown error",
            });
            throw error;
        }
    }
    static calculateVolatility(prices) {
        if (prices.length < 2)
            return 0;
        // Calculate daily returns
        const returns = [];
        for (let i = 1; i < prices.length; i++) {
            returns.push((prices[i] - prices[i - 1]) / prices[i - 1]);
        }
        // Calculate standard deviation
        const mean = returns.reduce((sum, r) => sum + r, 0) / returns.length;
        const variance = returns.reduce((sum, r) => sum + Math.pow(r - mean, 2), 0) / returns.length;
        const volatility = Math.sqrt(variance) * 100; // Convert to percentage
        return Math.round(volatility * 100) / 100; // Round to 2 decimal places
    }
    static calculateRiskScore(metadata) {
        let riskScore = 50; // Start with neutral risk
        // Market cap factor (lower market cap = higher risk)
        if (metadata.market_cap) {
            if (metadata.market_cap < 100000000)
                riskScore += 20; // <$100M
            else if (metadata.market_cap < 1000000000)
                riskScore += 10; // <$1B
            else if (metadata.market_cap > 10000000000)
                riskScore -= 10; // >$10B
        }
        // Volatility factor
        if (metadata.volatility7d) {
            if (metadata.volatility7d > 50)
                riskScore += 15; // High volatility
            else if (metadata.volatility7d < 10)
                riskScore -= 10; // Low volatility
        }
        // Volume factor (very low volume = higher risk)
        if (metadata.volume_24h && metadata.market_cap) {
            const volumeRatio = metadata.volume_24h / metadata.market_cap;
            if (volumeRatio < 0.01)
                riskScore += 15; // Very low liquidity
            else if (volumeRatio > 0.5)
                riskScore += 10; // Suspiciously high volume
        }
        // Social sentiment factor
        if (metadata.social_score) {
            if (metadata.social_score < 30)
                riskScore += 10; // Poor sentiment
            else if (metadata.social_score > 80)
                riskScore -= 5; // Good sentiment
        }
        // Clamp between 0 and 100
        return Math.max(0, Math.min(100, Math.round(riskScore)));
    }
}
exports.AssetMetadataUpdater = AssetMetadataUpdater;
AssetMetadataUpdater.POPULAR_THRESHOLD_VOLUME = 1000000; // $1M daily volume
AssetMetadataUpdater.POPULAR_THRESHOLD_MARKET_CAP = 10000000; // $10M market cap
AssetMetadataUpdater.STALE_DATA_HOURS = 24; // Data older than 24 hours is stale
async function updateAssetMetadata() {
    firebase_functions_1.logger.info("Starting asset metadata update");
    const errors = [];
    let assetsUpdated = 0;
    try {
        // Get all assets
        const assetsSnapshot = await firestore
            .collection("assets")
            .get();
        firebase_functions_1.logger.info(`Processing ${assetsSnapshot.size} assets for metadata update`);
        // Process assets in batches to avoid overwhelming Firestore
        const batchSize = 50;
        const assetDocs = assetsSnapshot.docs;
        for (let i = 0; i < assetDocs.length; i += batchSize) {
            const batch = assetDocs.slice(i, i + batchSize);
            await Promise.all(batch.map(async (assetDoc) => {
                const asset = Object.assign({ id: assetDoc.id }, assetDoc.data());
                try {
                    let updated = false;
                    // Update popularity
                    const popularityUpdated = await AssetMetadataUpdater.updateAssetPopularity(asset);
                    if (popularityUpdated)
                        updated = true;
                    // Update ranking
                    const rankingUpdated = await AssetMetadataUpdater.updateAssetRanking(asset);
                    if (rankingUpdated)
                        updated = true;
                    // Update data freshness
                    const freshnessUpdated = await AssetMetadataUpdater.updateDataFreshness(asset);
                    if (freshnessUpdated)
                        updated = true;
                    // Enrich metadata
                    const enrichmentUpdated = await AssetMetadataUpdater.enrichAssetMetadata(asset);
                    if (enrichmentUpdated)
                        updated = true;
                    if (updated) {
                        assetsUpdated++;
                    }
                }
                catch (error) {
                    const errorMessage = `Failed to update metadata for asset ${asset.symbol || asset.id}: ${error instanceof Error ? error.message : "Unknown error"}`;
                    errors.push(errorMessage);
                    firebase_functions_1.logger.warn(errorMessage);
                }
            }));
            // Small delay between batches
            if (i + batchSize < assetDocs.length) {
                await new Promise(resolve => setTimeout(resolve, 100));
            }
        }
        firebase_functions_1.logger.info("Asset metadata update completed successfully", {
            assetsUpdated,
            errors: errors.length,
        });
        return {
            assetsUpdated,
            errors,
        };
    }
    catch (error) {
        firebase_functions_1.logger.error("Asset metadata update failed", error);
        throw error;
    }
}
//# sourceMappingURL=updater.js.map