// ABOUTME: Main entry point for Firebase Cloud Functions
// ABOUTME: Exports all market data pipeline functions and schedulers

import * as admin from "firebase-admin";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onCall} from "firebase-functions/v2/https";
import {defineString, defineSecret} from "firebase-functions/params";
import {logger} from "firebase-functions";

// Import market data functions
import {pullEtherscanData} from "./market-data/etherscan";
import {pullCoinGeckoData} from "./market-data/coingecko";
import {pullSocialData} from "./market-data/social";
import {validateAssetData} from "./data-processing/validator";
import {calculateDailyStats} from "./data-processing/calculator";
import {updateAssetMetadata} from "./data-processing/updater";

// Initialize Firebase Admin
admin.initializeApp();

// Environment configuration
const region = defineString("REGION", {default: "us-central1"});

// API Key secrets
const etherscanApiKey = defineSecret("ETHERSCAN_API_KEY");
const coinGeckoApiKey = defineSecret("COINGECKO_API_KEY");
const socialApiKey = defineSecret("SOCIAL_API_KEY");

// Scheduled function: Pull market data every 5 minutes
export const pullMarketDataScheduled = onSchedule({
  schedule: "*/5 * * * *", // Every 5 minutes
  timeZone: "UTC",
  region: region.value(),
  secrets: [etherscanApiKey, coinGeckoApiKey],
  memory: "256MiB",
  timeoutSeconds: 120,
}, async (event) => {
  logger.info("Starting scheduled market data pull", {
    timestamp: event.scheduleTime,
  });

  try {
    // Run data pulls in parallel for efficiency
    const [etherscanResult, coinGeckoResult] = await Promise.allSettled([
      pullEtherscanData({
        apiKey: etherscanApiKey.value(),
      }),
      pullCoinGeckoData({
        apiKey: coinGeckoApiKey.value(),
      }),
    ]);

    // Log results
    if (etherscanResult.status === "fulfilled") {
      logger.info("Etherscan data pull completed", {
        assetsUpdated: etherscanResult.value.assetsUpdated,
      });
    } else {
      logger.error("Etherscan data pull failed", {
        error: etherscanResult.reason,
      });
    }

    if (coinGeckoResult.status === "fulfilled") {
      logger.info("CoinGecko data pull completed", {
        assetsUpdated: coinGeckoResult.value.assetsUpdated,
      });
    } else {
      logger.error("CoinGecko data pull failed", {
        error: coinGeckoResult.reason,
      });
    }

    logger.info("Scheduled market data pull completed");
  } catch (error) {
    logger.error("Market data pull failed", error);
    throw error;
  }
});

// Scheduled function: Calculate daily statistics at 00:05 UTC
export const calculateDailyStatsScheduled = onSchedule({
  schedule: "5 0 * * *", // Daily at 00:05 UTC
  timeZone: "UTC",
  region: region.value(),
  memory: "512MiB",
  timeoutSeconds: 300,
}, async (event) => {
  logger.info("Starting daily stats calculation", {
    timestamp: event.scheduleTime,
  });

  try {
    const result = await calculateDailyStats();
    
    logger.info("Daily stats calculation completed", {
      assetsProcessed: result.assetsProcessed,
      statsCreated: result.statsCreated,
    });
  } catch (error) {
    logger.error("Daily stats calculation failed", error);
    throw error;
  }
});

// Scheduled function: Pull social data every hour
export const pullSocialDataScheduled = onSchedule({
  schedule: "0 * * * *", // Every hour
  timeZone: "UTC",
  region: region.value(),
  secrets: [socialApiKey],
  memory: "256MiB",
  timeoutSeconds: 180,
}, async (event) => {
  logger.info("Starting social data pull", {
    timestamp: event.scheduleTime,
  });

  try {
    const result = await pullSocialData({
      apiKey: socialApiKey.value(),
    });
    
    logger.info("Social data pull completed", {
      assetsUpdated: result.assetsUpdated,
    });
  } catch (error) {
    logger.error("Social data pull failed", error);
    throw error;
  }
});

// Scheduled function: Update asset metadata weekly
export const updateAssetMetadataScheduled = onSchedule({
  schedule: "0 1 * * 0", // Weekly on Sunday at 01:00 UTC
  timeZone: "UTC",
  region: region.value(),
  memory: "512MiB",
  timeoutSeconds: 600,
}, async (event) => {
  logger.info("Starting asset metadata update", {
    timestamp: event.scheduleTime,
  });

  try {
    const result = await updateAssetMetadata();
    
    logger.info("Asset metadata update completed", {
      assetsUpdated: result.assetsUpdated,
    });
  } catch (error) {
    logger.error("Asset metadata update failed", error);
    throw error;
  }
});

// Manual trigger functions for testing and admin use
export const pullEtherscanDataManual = onCall({
  region: region.value(),
  secrets: [etherscanApiKey],
  memory: "256MiB",
}, async (request) => {
  if (!request.auth?.uid) {
    throw new Error("Authentication required");
  }

  logger.info("Manual Etherscan data pull triggered", {
    userId: request.auth.uid,
  });

  return await pullEtherscanData({
    apiKey: etherscanApiKey.value(),
  });
});

export const pullCoinGeckoDataManual = onCall({
  region: region.value(),
  secrets: [coinGeckoApiKey],
  memory: "256MiB",
}, async (request) => {
  if (!request.auth?.uid) {
    throw new Error("Authentication required");
  }

  logger.info("Manual CoinGecko data pull triggered", {
    userId: request.auth.uid,
  });

  return await pullCoinGeckoData({
    apiKey: coinGeckoApiKey.value(),
  });
});

export const validateAssetDataManual = onCall({
  region: region.value(),
  memory: "256MiB",
}, async (request) => {
  if (!request.auth?.uid) {
    throw new Error("Authentication required");
  }

  logger.info("Manual asset data validation triggered", {
    userId: request.auth.uid,
  });

  return await validateAssetData(request.data);
});

export const calculateDailyStatsManual = onCall({
  region: region.value(),
  memory: "512MiB",
}, async (request) => {
  if (!request.auth?.uid) {
    throw new Error("Authentication required");
  }

  logger.info("Manual daily stats calculation triggered", {
    userId: request.auth.uid,
  });

  return await calculateDailyStats();
});