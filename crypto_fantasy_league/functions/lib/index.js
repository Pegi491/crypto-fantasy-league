"use strict";
// ABOUTME: Main entry point for Firebase Cloud Functions
// ABOUTME: Exports all market data pipeline functions and schedulers
Object.defineProperty(exports, "__esModule", { value: true });
exports.calculateDailyStatsManual = exports.validateAssetDataManual = exports.pullCoinGeckoDataManual = exports.pullEtherscanDataManual = exports.updateAssetMetadataScheduled = exports.pullSocialDataScheduled = exports.calculateDailyStatsScheduled = exports.pullMarketDataScheduled = void 0;
const admin = require("firebase-admin");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const firebase_functions_1 = require("firebase-functions");
// Import market data functions
const etherscan_1 = require("./market-data/etherscan");
const coingecko_1 = require("./market-data/coingecko");
const social_1 = require("./market-data/social");
const validator_1 = require("./data-processing/validator");
const calculator_1 = require("./data-processing/calculator");
const updater_1 = require("./data-processing/updater");
// Initialize Firebase Admin
admin.initializeApp();
// Environment configuration
const region = (0, params_1.defineString)("REGION", { default: "us-central1" });
// API Key secrets
const etherscanApiKey = (0, params_1.defineSecret)("ETHERSCAN_API_KEY");
const coinGeckoApiKey = (0, params_1.defineSecret)("COINGECKO_API_KEY");
const socialApiKey = (0, params_1.defineSecret)("SOCIAL_API_KEY");
// Scheduled function: Pull market data every 5 minutes
exports.pullMarketDataScheduled = (0, scheduler_1.onSchedule)({
    schedule: "*/5 * * * *", // Every 5 minutes
    timeZone: "UTC",
    region: region.value(),
    secrets: [etherscanApiKey, coinGeckoApiKey],
    memory: "256MiB",
    timeoutSeconds: 120,
}, async (event) => {
    firebase_functions_1.logger.info("Starting scheduled market data pull", {
        timestamp: event.scheduleTime,
    });
    try {
        // Run data pulls in parallel for efficiency
        const [etherscanResult, coinGeckoResult] = await Promise.allSettled([
            (0, etherscan_1.pullEtherscanData)({
                apiKey: etherscanApiKey.value(),
            }),
            (0, coingecko_1.pullCoinGeckoData)({
                apiKey: coinGeckoApiKey.value(),
            }),
        ]);
        // Log results
        if (etherscanResult.status === "fulfilled") {
            firebase_functions_1.logger.info("Etherscan data pull completed", {
                assetsUpdated: etherscanResult.value.assetsUpdated,
            });
        }
        else {
            firebase_functions_1.logger.error("Etherscan data pull failed", {
                error: etherscanResult.reason,
            });
        }
        if (coinGeckoResult.status === "fulfilled") {
            firebase_functions_1.logger.info("CoinGecko data pull completed", {
                assetsUpdated: coinGeckoResult.value.assetsUpdated,
            });
        }
        else {
            firebase_functions_1.logger.error("CoinGecko data pull failed", {
                error: coinGeckoResult.reason,
            });
        }
        firebase_functions_1.logger.info("Scheduled market data pull completed");
    }
    catch (error) {
        firebase_functions_1.logger.error("Market data pull failed", error);
        throw error;
    }
});
// Scheduled function: Calculate daily statistics at 00:05 UTC
exports.calculateDailyStatsScheduled = (0, scheduler_1.onSchedule)({
    schedule: "5 0 * * *", // Daily at 00:05 UTC
    timeZone: "UTC",
    region: region.value(),
    memory: "512MiB",
    timeoutSeconds: 300,
}, async (event) => {
    firebase_functions_1.logger.info("Starting daily stats calculation", {
        timestamp: event.scheduleTime,
    });
    try {
        const result = await (0, calculator_1.calculateDailyStats)();
        firebase_functions_1.logger.info("Daily stats calculation completed", {
            assetsProcessed: result.assetsProcessed,
            statsCreated: result.statsCreated,
        });
    }
    catch (error) {
        firebase_functions_1.logger.error("Daily stats calculation failed", error);
        throw error;
    }
});
// Scheduled function: Pull social data every hour
exports.pullSocialDataScheduled = (0, scheduler_1.onSchedule)({
    schedule: "0 * * * *", // Every hour
    timeZone: "UTC",
    region: region.value(),
    secrets: [socialApiKey],
    memory: "256MiB",
    timeoutSeconds: 180,
}, async (event) => {
    firebase_functions_1.logger.info("Starting social data pull", {
        timestamp: event.scheduleTime,
    });
    try {
        const result = await (0, social_1.pullSocialData)({
            apiKey: socialApiKey.value(),
        });
        firebase_functions_1.logger.info("Social data pull completed", {
            assetsUpdated: result.assetsUpdated,
        });
    }
    catch (error) {
        firebase_functions_1.logger.error("Social data pull failed", error);
        throw error;
    }
});
// Scheduled function: Update asset metadata weekly
exports.updateAssetMetadataScheduled = (0, scheduler_1.onSchedule)({
    schedule: "0 1 * * 0", // Weekly on Sunday at 01:00 UTC
    timeZone: "UTC",
    region: region.value(),
    memory: "512MiB",
    timeoutSeconds: 600,
}, async (event) => {
    firebase_functions_1.logger.info("Starting asset metadata update", {
        timestamp: event.scheduleTime,
    });
    try {
        const result = await (0, updater_1.updateAssetMetadata)();
        firebase_functions_1.logger.info("Asset metadata update completed", {
            assetsUpdated: result.assetsUpdated,
        });
    }
    catch (error) {
        firebase_functions_1.logger.error("Asset metadata update failed", error);
        throw error;
    }
});
// Manual trigger functions for testing and admin use
exports.pullEtherscanDataManual = (0, https_1.onCall)({
    region: region.value(),
    secrets: [etherscanApiKey],
    memory: "256MiB",
}, async (request) => {
    var _a;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new Error("Authentication required");
    }
    firebase_functions_1.logger.info("Manual Etherscan data pull triggered", {
        userId: request.auth.uid,
    });
    return await (0, etherscan_1.pullEtherscanData)({
        apiKey: etherscanApiKey.value(),
    });
});
exports.pullCoinGeckoDataManual = (0, https_1.onCall)({
    region: region.value(),
    secrets: [coinGeckoApiKey],
    memory: "256MiB",
}, async (request) => {
    var _a;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new Error("Authentication required");
    }
    firebase_functions_1.logger.info("Manual CoinGecko data pull triggered", {
        userId: request.auth.uid,
    });
    return await (0, coingecko_1.pullCoinGeckoData)({
        apiKey: coinGeckoApiKey.value(),
    });
});
exports.validateAssetDataManual = (0, https_1.onCall)({
    region: region.value(),
    memory: "256MiB",
}, async (request) => {
    var _a;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new Error("Authentication required");
    }
    firebase_functions_1.logger.info("Manual asset data validation triggered", {
        userId: request.auth.uid,
    });
    return await (0, validator_1.validateAssetData)(request.data);
});
exports.calculateDailyStatsManual = (0, https_1.onCall)({
    region: region.value(),
    memory: "512MiB",
}, async (request) => {
    var _a;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new Error("Authentication required");
    }
    firebase_functions_1.logger.info("Manual daily stats calculation triggered", {
        userId: request.auth.uid,
    });
    return await (0, calculator_1.calculateDailyStats)();
});
//# sourceMappingURL=index.js.map