// ABOUTME: CoinGecko API integration for token prices and market data
// ABOUTME: Handles rate limiting, error handling, and comprehensive market metrics

import * as admin from "firebase-admin";
import {logger} from "firebase-functions";
import axios, {AxiosError} from "axios";

const firestore = admin.firestore();

export interface CoinGeckoConfig {
  apiKey?: string;
  baseUrl?: string;
  rateLimit?: number; // requests per minute for free tier
}

export interface MarketData {
  id: string;
  symbol: string;
  name: string;
  contractAddress?: string;
  currentPrice: number;
  marketCap: number;
  marketCapRank: number;
  fullyDilutedValuation?: number;
  totalVolume: number;
  high24h: number;
  low24h: number;
  priceChange24h: number;
  priceChangePercentage24h: number;
  marketCapChange24h: number;
  marketCapChangePercentage24h: number;
  circulatingSupply: number;
  totalSupply?: number;
  maxSupply?: number;
  ath: number;
  athChangePercentage: number;
  athDate: string;
  atl: number;
  atlChangePercentage: number;
  atlDate: string;
  lastUpdated: string;
  timestamp: number;
}

export interface CoinGeckoResult {
  assetsUpdated: number;
  marketData: MarketData[];
  errors: string[];
}

class CoinGeckoAPI {
  private config: CoinGeckoConfig;
  private lastRequestTime: number = 0;

  constructor(config: CoinGeckoConfig) {
    this.config = {
      baseUrl: "https://api.coingecko.com/api/v3",
      rateLimit: 10, // 10 requests per minute for free tier
      ...config,
    };
  }

  private async rateLimitDelay(): Promise<void> {
    const minInterval = 60000 / (this.config.rateLimit || 10); // Convert to milliseconds
    const timeSinceLastRequest = Date.now() - this.lastRequestTime;
    
    if (timeSinceLastRequest < minInterval) {
      const delay = minInterval - timeSinceLastRequest;
      logger.debug(`Rate limiting: waiting ${delay}ms`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
    
    this.lastRequestTime = Date.now();
  }

  private async makeRequest(endpoint: string, params?: Record<string, string>): Promise<any> {
    await this.rateLimitDelay();

    const url = `${this.config.baseUrl}${endpoint}`;
    const headers: Record<string, string> = {
      "User-Agent": "crypto-fantasy-league/1.0",
    };

    // Add API key if provided (for pro tier)
    if (this.config.apiKey) {
      headers["x-cg-pro-api-key"] = this.config.apiKey;
    }

    try {
      logger.debug("Making CoinGecko API request", {
        endpoint,
        params,
      });

      const response = await axios.get(url, {
        params,
        headers,
        timeout: 15000,
      });

      return response.data;
    } catch (error) {
      if (error instanceof AxiosError) {
        logger.error("CoinGecko API request failed", {
          status: error.response?.status,
          message: error.message,
          endpoint,
          params,
        });
        
        if (error.response?.status === 429) {
          // Rate limit hit, wait longer
          await new Promise(resolve => setTimeout(resolve, 5000));
          throw new Error("Rate limit exceeded");
        }
      }
      throw error;
    }
  }

  async getMarketData(coinIds: string[]): Promise<MarketData[]> {
    if (coinIds.length === 0) {
      return [];
    }

    // CoinGecko allows up to 250 coins per request
    const chunks = [];
    for (let i = 0; i < coinIds.length; i += 250) {
      chunks.push(coinIds.slice(i, i + 250));
    }

    const allMarketData: MarketData[] = [];

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

        const marketData = data.map((coin: any) => ({
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
      } catch (error) {
        logger.error("Failed to get market data chunk", {
          chunk,
          error: error instanceof Error ? error.message : "Unknown error",
        });
      }
    }

    return allMarketData;
  }

  async getTokenInfo(contractAddress: string, platform: string = "ethereum"): Promise<any> {
    try {
      const data = await this.makeRequest(`/coins/${platform}/contract/${contractAddress}`);
      return {
        id: data.id,
        symbol: data.symbol,
        name: data.name,
        contractAddress: data.contract_address,
        marketData: data.market_data,
      };
    } catch (error) {
      logger.warn("Failed to get token info", {
        contractAddress,
        platform,
        error: error instanceof Error ? error.message : "Unknown error",
      });
      return null;
    }
  }

  async searchCoins(query: string): Promise<any[]> {
    try {
      const data = await this.makeRequest("/search", {q: query});
      return data.coins || [];
    } catch (error) {
      logger.warn("Failed to search coins", {
        query,
        error: error instanceof Error ? error.message : "Unknown error",
      });
      return [];
    }
  }

  async getTrendingCoins(): Promise<any[]> {
    try {
      const data = await this.makeRequest("/search/trending");
      return data.coins || [];
    } catch (error) {
      logger.warn("Failed to get trending coins", {
        error: error instanceof Error ? error.message : "Unknown error",
      });
      return [];
    }
  }
}

export async function pullCoinGeckoData(config: CoinGeckoConfig): Promise<CoinGeckoResult> {
  logger.info("Starting CoinGecko data pull");

  const api = new CoinGeckoAPI(config);
  const errors: string[] = [];
  let assetsUpdated = 0;
  const marketData: MarketData[] = [];

  try {
    // Get all token assets from Firestore
    const assetsSnapshot = await firestore
      .collection("assets")
      .where("type", "==", "token")
      .where("isActive", "==", true)
      .get();

    if (assetsSnapshot.empty) {
      logger.info("No active token assets found");
      return {assetsUpdated: 0, marketData: [], errors: []};
    }

    // Extract CoinGecko IDs from asset metadata
    const coinIds: string[] = [];
    const assetsByCoinId: Record<string, any> = {};

    for (const doc of assetsSnapshot.docs) {
      const asset = doc.data();
      const coinGeckoId = asset.metadata?.coinGeckoId;
      
      if (coinGeckoId) {
        coinIds.push(coinGeckoId);
        assetsByCoinId[coinGeckoId] = {id: doc.id, ...asset};
      } else {
        // Try to find CoinGecko ID by contract address
        try {
          const tokenInfo = await api.getTokenInfo(asset.address);
          if (tokenInfo && tokenInfo.id) {
            coinIds.push(tokenInfo.id);
            assetsByCoinId[tokenInfo.id] = {id: doc.id, ...asset};
            
            // Update asset with CoinGecko ID
            await doc.ref.update({
              "metadata.coinGeckoId": tokenInfo.id,
              updatedAt: admin.firestore.Timestamp.now(),
            });
          }
        } catch (error) {
          const errorMessage = `Failed to find CoinGecko ID for asset ${asset.symbol}: ${
            error instanceof Error ? error.message : "Unknown error"
          }`;
          errors.push(errorMessage);
          logger.warn(errorMessage);
        }
      }
    }

    if (coinIds.length === 0) {
      logger.info("No assets with CoinGecko IDs found");
      return {assetsUpdated: 0, marketData: [], errors};
    }

    logger.info(`Fetching market data for ${coinIds.length} coins`);

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
        assetId: assetsByCoinId[coin.id]?.id || coin.id,
        date: new Date().toISOString().split("T")[0],
        priceUsd: coin.currentPrice,
        volumeUsd: coin.totalVolume,
        marketCapUsd: coin.marketCap,
        changePercent24h: coin.priceChangePercentage24h,
        high24h: coin.high24h,
        low24h: coin.low24h,
        rank: coin.marketCapRank,
        timestamp: timestamp,
      }, {merge: true});

      // Update asset metadata
      const assetId = assetsByCoinId[coin.id]?.id;
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

    logger.info("CoinGecko data pull completed successfully", {
      assetsUpdated,
      coinsProcessed: coins.length,
      errors: errors.length,
    });

    return {
      assetsUpdated,
      marketData,
      errors,
    };
  } catch (error) {
    logger.error("CoinGecko data pull failed", error);
    throw error;
  }
}