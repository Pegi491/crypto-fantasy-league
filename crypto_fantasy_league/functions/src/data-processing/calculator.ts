// ABOUTME: Daily statistics calculation for crypto assets and wallets
// ABOUTME: Processes raw market data into structured daily statistics

import * as admin from "firebase-admin";
import {logger} from "firebase-functions";

const firestore = admin.firestore();

export interface DailyStatsResult {
  assetsProcessed: number;
  statsCreated: number;
  errors: string[];
}

export interface AssetDailyStats {
  assetId: string;
  date: string;
  priceUsd?: number;
  volumeUsd?: number;
  marketCapUsd?: number;
  changePercent24h?: number;
  high24h?: number;
  low24h?: number;
  holders?: number;
  socialScore?: number;
  timestamp: admin.firestore.Timestamp;
}

export class DailyStatsCalculator {
  private static formatDate(date: Date): string {
    return date.toISOString().split("T")[0];
  }

  private static async getLatestMarketData(assetId: string): Promise<any> {
    try {
      // Get the most recent market data for this asset
      const marketDataSnapshot = await firestore
        .collection("market_data")
        .where("assetId", "==", assetId)
        .orderBy("timestamp", "desc")
        .limit(1)
        .get();

      if (marketDataSnapshot.empty) {
        return null;
      }

      return marketDataSnapshot.docs[0].data();
    } catch (error) {
      logger.warn("Failed to get market data", {assetId, error});
      return null;
    }
  }

  private static async getLatestSocialData(symbol: string): Promise<any> {
    try {
      const today = this.formatDate(new Date());
      const socialDocRef = firestore
        .collection("social_metrics")
        .doc(`${symbol}_${today}`);

      const socialDoc = await socialDocRef.get();
      return socialDoc.exists ? socialDoc.data() : null;
    } catch (error) {
      logger.warn("Failed to get social data", {symbol, error});
      return null;
    }
  }

  private static async getWalletHolders(contractAddress: string): Promise<number> {
    try {
      // This would typically require a service like Etherscan or Moralis
      // For now, return a placeholder or estimated value
      const holdersSnapshot = await firestore
        .collection("wallet_balances")
        .where("contractAddress", "==", contractAddress)
        .where("balanceFormatted", ">", 0)
        .get();

      return holdersSnapshot.size;
    } catch (error) {
      logger.warn("Failed to get holder count", {contractAddress, error});
      return 0;
    }
  }

  static async calculateAssetDailyStats(asset: any, date: string): Promise<AssetDailyStats | null> {
    try {
      const assetId = asset.id;
      const symbol = asset.symbol;

      // Get latest market data
      const marketData = await this.getLatestMarketData(assetId);
      
      // Get social data
      const socialData = await this.getLatestSocialData(symbol);

      // Get holder count for tokens
      let holders: number | undefined;
      if (asset.type === "token" && asset.address) {
        holders = await this.getWalletHolders(asset.address);
      }

      // Create daily stats object
      const dailyStats: AssetDailyStats = {
        assetId,
        date,
        timestamp: admin.firestore.Timestamp.now(),
      };

      // Add market data if available
      if (marketData) {
        dailyStats.priceUsd = marketData.currentPrice || marketData.priceUsd;
        dailyStats.volumeUsd = marketData.totalVolume || marketData.volumeUsd;
        dailyStats.marketCapUsd = marketData.marketCap || marketData.marketCapUsd;
        dailyStats.changePercent24h = marketData.priceChangePercentage24h || marketData.changePercent24h;
        dailyStats.high24h = marketData.high24h;
        dailyStats.low24h = marketData.low24h;
      }

      // Add social data if available
      if (socialData) {
        dailyStats.socialScore = socialData.socialScore;
      }

      // Add holder data if available
      if (holders !== undefined) {
        dailyStats.holders = holders;
      }

      // Only return stats if we have at least some meaningful data
      if (dailyStats.priceUsd || dailyStats.volumeUsd || dailyStats.socialScore) {
        return dailyStats;
      }

      return null;
    } catch (error) {
      logger.error("Failed to calculate daily stats for asset", {
        assetId: asset.id,
        error: error instanceof Error ? error.message : "Unknown error",
      });
      return null;
    }
  }

  static async calculateWalletDailyStats(walletAddress: string, date: string): Promise<any> {
    try {
      // Get all recent balances for this wallet
      const balancesSnapshot = await firestore
        .collection("wallet_balances")
        .where("address", "==", walletAddress)
        .where("timestamp", ">=", admin.firestore.Timestamp.fromMillis(Date.now() - 24 * 60 * 60 * 1000))
        .get();

      if (balancesSnapshot.empty) {
        return null;
      }

      const balances = balancesSnapshot.docs.map(doc => doc.data());
      
      // Calculate total portfolio value in USD
      let totalValueUsd = 0;
      const assetBreakdown: any[] = [];

      for (const balance of balances) {
        if (balance.symbol === "ETH") {
          // ETH balance - need to get ETH price
          const ethPrice = await this.getAssetPrice("ethereum");
          const valueUsd = balance.balanceEth * (ethPrice || 0);
          totalValueUsd += valueUsd;
          
          assetBreakdown.push({
            symbol: "ETH",
            balance: balance.balanceEth,
            priceUsd: ethPrice,
            valueUsd,
          });
        } else if (balance.balanceFormatted > 0) {
          // Token balance
          const tokenPrice = await this.getTokenPrice(balance.contractAddress);
          const valueUsd = balance.balanceFormatted * (tokenPrice || 0);
          totalValueUsd += valueUsd;

          assetBreakdown.push({
            symbol: balance.symbol,
            balance: balance.balanceFormatted,
            priceUsd: tokenPrice,
            valueUsd,
          });
        }
      }

      return {
        walletAddress,
        date,
        totalValueUsd,
        assetCount: assetBreakdown.length,
        assetBreakdown,
        timestamp: admin.firestore.Timestamp.now(),
      };
    } catch (error) {
      logger.error("Failed to calculate wallet daily stats", {
        walletAddress,
        error: error instanceof Error ? error.message : "Unknown error",
      });
      return null;
    }
  }

  private static async getAssetPrice(coinGeckoId: string): Promise<number | null> {
    try {
      const assetSnapshot = await firestore
        .collection("assets")
        .where("metadata.coinGeckoId", "==", coinGeckoId)
        .limit(1)
        .get();

      if (assetSnapshot.empty) {
        return null;
      }

      const asset = assetSnapshot.docs[0].data();
      return asset.metadata?.price_usd || null;
    } catch {
      return null;
    }
  }

  private static async getTokenPrice(contractAddress: string): Promise<number | null> {
    try {
      const assetSnapshot = await firestore
        .collection("assets")
        .where("address", "==", contractAddress)
        .limit(1)
        .get();

      if (assetSnapshot.empty) {
        return null;
      }

      const asset = assetSnapshot.docs[0].data();
      return asset.metadata?.price_usd || null;
    } catch {
      return null;
    }
  }
}

export async function calculateDailyStats(): Promise<DailyStatsResult> {
  logger.info("Starting daily stats calculation");

  const errors: string[] = [];
  let assetsProcessed = 0;
  let statsCreated = 0;

  try {
    const today = DailyStatsCalculator["formatDate"](new Date());
    
    // Get all active assets
    const assetsSnapshot = await firestore
      .collection("assets")
      .where("isActive", "==", true)
      .get();

    logger.info(`Processing ${assetsSnapshot.size} active assets`);

    const batch = firestore.batch();
    
    // Process each asset
    for (const assetDoc of assetsSnapshot.docs) {
      const asset = {id: assetDoc.id, ...assetDoc.data()};
      
      try {
        const dailyStats = await DailyStatsCalculator.calculateAssetDailyStats(asset, today);
        
        if (dailyStats) {
          const statsDocRef = firestore
            .collection("daily_stats")
            .doc(`${asset.id}_${today}`);
          
          batch.set(statsDocRef, dailyStats, {merge: true});
          statsCreated++;
        }
        
        assetsProcessed++;
      } catch (error) {
        const errorMessage = `Failed to process asset ${(asset as any).symbol || asset.id}: ${
          error instanceof Error ? error.message : "Unknown error"
        }`;
        errors.push(errorMessage);
        logger.warn(errorMessage);
      }
    }

    // Process wallet assets separately
    const walletAssetsSnapshot = await firestore
      .collection("assets")
      .where("type", "==", "wallet")
      .where("isActive", "==", true)
      .get();

    for (const walletDoc of walletAssetsSnapshot.docs) {
      const wallet = walletDoc.data();
      
      try {
        const walletStats = await DailyStatsCalculator.calculateWalletDailyStats(
          wallet.address, 
          today
        );
        
        if (walletStats) {
          const statsDocRef = firestore
            .collection("wallet_daily_stats")
            .doc(`${wallet.address}_${today}`);
          
          batch.set(statsDocRef, walletStats, {merge: true});
          statsCreated++;
        }
      } catch (error) {
        const errorMessage = `Failed to process wallet ${wallet.address}: ${
          error instanceof Error ? error.message : "Unknown error"
        }`;
        errors.push(errorMessage);
        logger.warn(errorMessage);
      }
    }

    // Commit all changes
    await batch.commit();

    logger.info("Daily stats calculation completed successfully", {
      assetsProcessed,
      statsCreated,
      errors: errors.length,
    });

    return {
      assetsProcessed,
      statsCreated,
      errors,
    };
  } catch (error) {
    logger.error("Daily stats calculation failed", error);
    throw error;
  }
}