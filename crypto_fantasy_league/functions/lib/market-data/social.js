"use strict";
// ABOUTME: Social sentiment data integration for crypto assets
// ABOUTME: Aggregates social metrics from multiple sources with rate limiting
Object.defineProperty(exports, "__esModule", { value: true });
exports.pullSocialData = pullSocialData;
const admin = require("firebase-admin");
const firebase_functions_1 = require("firebase-functions");
const axios_1 = require("axios");
const firestore = admin.firestore();
class SocialDataAPI {
    constructor(config) {
        this.lastRequestTime = 0;
        this.config = Object.assign({ baseUrl: "https://api.lunarcrush.com/v2", rateLimit: 100 }, config);
    }
    async rateLimitDelay() {
        const minInterval = 36000 / (this.config.rateLimit || 100); // Convert to milliseconds
        const timeSinceLastRequest = Date.now() - this.lastRequestTime;
        if (timeSinceLastRequest < minInterval) {
            const delay = minInterval - timeSinceLastRequest;
            await new Promise(resolve => setTimeout(resolve, delay));
        }
        this.lastRequestTime = Date.now();
    }
    async makeRequest(endpoint, params) {
        var _a, _b;
        await this.rateLimitDelay();
        const url = `${this.config.baseUrl}${endpoint}`;
        const requestParams = Object.assign(Object.assign({}, params), { key: this.config.apiKey });
        try {
            firebase_functions_1.logger.debug("Making Social API request", {
                endpoint,
                params: Object.keys(params || {}),
            });
            const response = await axios_1.default.get(url, {
                params: requestParams,
                timeout: 15000,
            });
            return response.data;
        }
        catch (error) {
            if (error instanceof axios_1.AxiosError) {
                firebase_functions_1.logger.error("Social API request failed", {
                    status: (_a = error.response) === null || _a === void 0 ? void 0 : _a.status,
                    message: error.message,
                    endpoint,
                });
                if (((_b = error.response) === null || _b === void 0 ? void 0 : _b.status) === 429) {
                    await new Promise(resolve => setTimeout(resolve, 5000));
                    throw new Error("Rate limit exceeded");
                }
            }
            throw error;
        }
    }
    async getAssetSocialMetrics(symbol) {
        try {
            // Get basic social metrics
            const data = await this.makeRequest("/assets", {
                symbol: symbol.toUpperCase(),
                data_points: "1",
                interval: "1d",
            });
            if (!data.data || data.data.length === 0) {
                return null;
            }
            const asset = data.data[0];
            return {
                assetId: asset.id || symbol,
                symbol: symbol.toUpperCase(),
                socialScore: Math.round(asset.galaxy_score || 0),
                mentions24h: asset.social_volume_24h || 0,
                sentiment: this.classifySentiment(asset.sentiment || 0),
                sentimentScore: asset.sentiment || 0,
                twitterFollowers: asset.twitter_followers,
                twitterMentions: asset.tweets_24h,
                redditSubscribers: asset.reddit_subscribers,
                redditPosts: asset.reddit_posts_24h,
                githubStars: asset.github_stars,
                githubCommits: asset.github_commits_24h,
                timestamp: Date.now(),
            };
        }
        catch (error) {
            firebase_functions_1.logger.warn("Failed to get social metrics", {
                symbol,
                error: error instanceof Error ? error.message : "Unknown error",
            });
            return null;
        }
    }
    classifySentiment(score) {
        if (score > 0.1)
            return "positive";
        if (score < -0.1)
            return "negative";
        return "neutral";
    }
    async getTrendingAssets(limit = 10) {
        try {
            const data = await this.makeRequest("/assets", {
                sort: "galaxy_score",
                limit: limit.toString(),
                page: "1",
            });
            return data.data || [];
        }
        catch (error) {
            firebase_functions_1.logger.warn("Failed to get trending assets", {
                error: error instanceof Error ? error.message : "Unknown error",
            });
            return [];
        }
    }
}
// Fallback social data generator for testing
class MockSocialDataAPI {
    async getAssetSocialMetrics(symbol) {
        // Generate mock social data for testing
        const baseScore = Math.random() * 100;
        const sentimentScore = (Math.random() - 0.5) * 2; // -1 to 1
        return {
            assetId: `mock_${symbol}`,
            symbol: symbol.toUpperCase(),
            socialScore: Math.round(baseScore),
            mentions24h: Math.round(Math.random() * 1000),
            sentiment: this.classifySentiment(sentimentScore),
            sentimentScore,
            twitterFollowers: Math.round(Math.random() * 100000),
            twitterMentions: Math.round(Math.random() * 500),
            redditSubscribers: Math.round(Math.random() * 50000),
            redditPosts: Math.round(Math.random() * 100),
            githubStars: Math.round(Math.random() * 5000),
            githubCommits: Math.round(Math.random() * 50),
            timestamp: Date.now(),
        };
    }
    classifySentiment(score) {
        if (score > 0.1)
            return "positive";
        if (score < -0.1)
            return "negative";
        return "neutral";
    }
    async getTrendingAssets() {
        return [];
    }
}
async function pullSocialData(config) {
    firebase_functions_1.logger.info("Starting social data pull");
    // Use mock API if no real API key provided
    const api = config.apiKey === "test" || !config.apiKey ?
        new MockSocialDataAPI() :
        new SocialDataAPI(config);
    const errors = [];
    let assetsUpdated = 0;
    const socialMetrics = [];
    try {
        // Get all active assets from Firestore
        const assetsSnapshot = await firestore
            .collection("assets")
            .where("isActive", "==", true)
            .where("isPopular", "==", true) // Only pull social data for popular assets
            .get();
        if (assetsSnapshot.empty) {
            firebase_functions_1.logger.info("No popular assets found for social data");
            return { assetsUpdated: 0, socialMetrics: [], errors: [] };
        }
        firebase_functions_1.logger.info(`Fetching social data for ${assetsSnapshot.size} assets`);
        // Process each asset
        for (const doc of assetsSnapshot.docs) {
            const asset = doc.data();
            try {
                const metrics = await api.getAssetSocialMetrics(asset.symbol);
                if (metrics) {
                    socialMetrics.push(metrics);
                    // Store social metrics in Firestore
                    const socialDocRef = firestore
                        .collection("social_metrics")
                        .doc(`${asset.symbol}_${new Date().toISOString().split("T")[0]}`);
                    await socialDocRef.set(Object.assign(Object.assign({}, metrics), { updatedAt: admin.firestore.Timestamp.now() }), { merge: true });
                    // Update asset metadata
                    await doc.ref.update({
                        "metadata.social_score": metrics.socialScore,
                        "metadata.sentiment": metrics.sentiment,
                        "metadata.mentions_24h": metrics.mentions24h,
                        lastSocialFetch: admin.firestore.Timestamp.now(),
                        updatedAt: admin.firestore.Timestamp.now(),
                    });
                    assetsUpdated++;
                }
            }
            catch (error) {
                const errorMessage = `Failed to get social data for ${asset.symbol}: ${error instanceof Error ? error.message : "Unknown error"}`;
                errors.push(errorMessage);
                firebase_functions_1.logger.warn(errorMessage);
            }
        }
        firebase_functions_1.logger.info("Social data pull completed successfully", {
            assetsUpdated,
            metricsCollected: socialMetrics.length,
            errors: errors.length,
        });
        return {
            assetsUpdated,
            socialMetrics,
            errors,
        };
    }
    catch (error) {
        firebase_functions_1.logger.error("Social data pull failed", error);
        throw error;
    }
}
//# sourceMappingURL=social.js.map