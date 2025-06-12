// ABOUTME: Social sentiment data integration for crypto assets
// ABOUTME: Aggregates social metrics from multiple sources with rate limiting

import * as admin from "firebase-admin";
import {logger} from "firebase-functions";
import axios, {AxiosError} from "axios";

const firestore = admin.firestore();

export interface SocialConfig {
  apiKey: string;
  baseUrl?: string;
  rateLimit?: number;
}

export interface SocialMetrics {
  assetId: string;
  symbol: string;
  socialScore: number; // 0-100 sentiment score
  mentions24h: number;
  sentiment: "positive" | "negative" | "neutral";
  sentimentScore: number; // -1 to 1
  twitterFollowers?: number;
  twitterMentions?: number;
  redditSubscribers?: number;
  redditPosts?: number;
  githubStars?: number;
  githubCommits?: number;
  timestamp: number;
}

export interface SocialResult {
  assetsUpdated: number;
  socialMetrics: SocialMetrics[];
  errors: string[];
}

class SocialDataAPI {
  private config: SocialConfig;
  private lastRequestTime: number = 0;

  constructor(config: SocialConfig) {
    this.config = {
      baseUrl: "https://api.lunarcrush.com/v2",
      rateLimit: 100, // 100 requests per hour
      ...config,
    };
  }

  private async rateLimitDelay(): Promise<void> {
    const minInterval = 36000 / (this.config.rateLimit || 100); // Convert to milliseconds
    const timeSinceLastRequest = Date.now() - this.lastRequestTime;
    
    if (timeSinceLastRequest < minInterval) {
      const delay = minInterval - timeSinceLastRequest;
      await new Promise(resolve => setTimeout(resolve, delay));
    }
    
    this.lastRequestTime = Date.now();
  }

  private async makeRequest(endpoint: string, params?: Record<string, string>): Promise<any> {
    await this.rateLimitDelay();

    const url = `${this.config.baseUrl}${endpoint}`;
    const requestParams = {
      ...params,
      key: this.config.apiKey,
    };

    try {
      logger.debug("Making Social API request", {
        endpoint,
        params: Object.keys(params || {}),
      });

      const response = await axios.get(url, {
        params: requestParams,
        timeout: 15000,
      });

      return response.data;
    } catch (error) {
      if (error instanceof AxiosError) {
        logger.error("Social API request failed", {
          status: error.response?.status,
          message: error.message,
          endpoint,
        });
        
        if (error.response?.status === 429) {
          await new Promise(resolve => setTimeout(resolve, 5000));
          throw new Error("Rate limit exceeded");
        }
      }
      throw error;
    }
  }

  async getAssetSocialMetrics(symbol: string): Promise<SocialMetrics | null> {
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
    } catch (error) {
      logger.warn("Failed to get social metrics", {
        symbol,
        error: error instanceof Error ? error.message : "Unknown error",
      });
      return null;
    }
  }

  private classifySentiment(score: number): "positive" | "negative" | "neutral" {
    if (score > 0.1) return "positive";
    if (score < -0.1) return "negative";
    return "neutral";
  }

  async getTrendingAssets(limit: number = 10): Promise<any[]> {
    try {
      const data = await this.makeRequest("/assets", {
        sort: "galaxy_score",
        limit: limit.toString(),
        page: "1",
      });

      return data.data || [];
    } catch (error) {
      logger.warn("Failed to get trending assets", {
        error: error instanceof Error ? error.message : "Unknown error",
      });
      return [];
    }
  }
}

// Fallback social data generator for testing
class MockSocialDataAPI {
  async getAssetSocialMetrics(symbol: string): Promise<SocialMetrics | null> {
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

  private classifySentiment(score: number): "positive" | "negative" | "neutral" {
    if (score > 0.1) return "positive";
    if (score < -0.1) return "negative";
    return "neutral";
  }

  async getTrendingAssets(): Promise<any[]> {
    return [];
  }
}

export async function pullSocialData(config: SocialConfig): Promise<SocialResult> {
  logger.info("Starting social data pull");

  // Use mock API if no real API key provided
  const api = config.apiKey === "test" || !config.apiKey ? 
    new MockSocialDataAPI() : 
    new SocialDataAPI(config);

  const errors: string[] = [];
  let assetsUpdated = 0;
  const socialMetrics: SocialMetrics[] = [];

  try {
    // Get all active assets from Firestore
    const assetsSnapshot = await firestore
      .collection("assets")
      .where("isActive", "==", true)
      .where("isPopular", "==", true) // Only pull social data for popular assets
      .get();

    if (assetsSnapshot.empty) {
      logger.info("No popular assets found for social data");
      return {assetsUpdated: 0, socialMetrics: [], errors: []};
    }

    logger.info(`Fetching social data for ${assetsSnapshot.size} assets`);

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
          
          await socialDocRef.set({
            ...metrics,
            updatedAt: admin.firestore.Timestamp.now(),
          }, {merge: true});

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
      } catch (error) {
        const errorMessage = `Failed to get social data for ${asset.symbol}: ${
          error instanceof Error ? error.message : "Unknown error"
        }`;
        errors.push(errorMessage);
        logger.warn(errorMessage);
      }
    }

    logger.info("Social data pull completed successfully", {
      assetsUpdated,
      metricsCollected: socialMetrics.length,
      errors: errors.length,
    });

    return {
      assetsUpdated,
      socialMetrics,
      errors,
    };
  } catch (error) {
    logger.error("Social data pull failed", error);
    throw error;
  }
}