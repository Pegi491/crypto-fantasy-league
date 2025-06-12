// ABOUTME: Etherscan API integration for wallet balance and transaction data
// ABOUTME: Handles rate limiting, error handling, and data transformation

import * as admin from "firebase-admin";
import {logger} from "firebase-functions";
import axios, {AxiosError} from "axios";

const firestore = admin.firestore();

export interface EtherscanConfig {
  apiKey: string;
  baseUrl?: string;
  rateLimit?: number; // requests per second
}

export interface WalletBalance {
  address: string;
  balance: string; // Wei amount as string
  balanceEth: number; // ETH amount as number
  timestamp: number;
}

export interface TokenBalance {
  address: string;
  contractAddress: string;
  symbol: string;
  decimals: number;
  balance: string;
  balanceFormatted: number;
  timestamp: number;
}

export interface EtherscanResult {
  assetsUpdated: number;
  walletBalances: WalletBalance[];
  tokenBalances: TokenBalance[];
  errors: string[];
}

class EtherscanAPI {
  private config: EtherscanConfig;
  private lastRequestTime: number = 0;

  constructor(config: EtherscanConfig) {
    this.config = {
      baseUrl: "https://api.etherscan.io/api",
      rateLimit: 5, // 5 requests per second default
      ...config,
    };
  }

  private async rateLimitDelay(): Promise<void> {
    const minInterval = 1000 / (this.config.rateLimit || 5);
    const timeSinceLastRequest = Date.now() - this.lastRequestTime;
    
    if (timeSinceLastRequest < minInterval) {
      const delay = minInterval - timeSinceLastRequest;
      await new Promise(resolve => setTimeout(resolve, delay));
    }
    
    this.lastRequestTime = Date.now();
  }

  private async makeRequest(params: Record<string, string>): Promise<any> {
    await this.rateLimitDelay();

    const url = this.config.baseUrl;
    const requestParams = {
      ...params,
      apikey: this.config.apiKey,
    };

    try {
      logger.debug("Making Etherscan API request", {
        module: params.module,
        action: params.action,
        address: params.address?.substring(0, 10) + "...",
      });

      const response = await axios.get(url!, {
        params: requestParams,
        timeout: 10000,
      });

      if (response.data.status !== "1") {
        throw new Error(`Etherscan API error: ${response.data.message}`);
      }

      return response.data.result;
    } catch (error) {
      if (error instanceof AxiosError) {
        logger.error("Etherscan API request failed", {
          status: error.response?.status,
          message: error.message,
          params: requestParams,
        });
        
        if (error.response?.status === 429) {
          // Rate limit hit, wait longer
          await new Promise(resolve => setTimeout(resolve, 2000));
          throw new Error("Rate limit exceeded");
        }
      }
      throw error;
    }
  }

  async getEthBalance(address: string): Promise<WalletBalance> {
    const result = await this.makeRequest({
      module: "account",
      action: "balance",
      address: address,
      tag: "latest",
    });

    const balanceWei = result;
    const balanceEth = parseFloat(balanceWei) / Math.pow(10, 18);

    return {
      address,
      balance: balanceWei,
      balanceEth,
      timestamp: Date.now(),
    };
  }

  async getTokenBalances(address: string, contractAddresses: string[]): Promise<TokenBalance[]> {
    const balances: TokenBalance[] = [];

    for (const contractAddress of contractAddresses) {
      try {
        // Get token balance
        const balanceResult = await this.makeRequest({
          module: "account",
          action: "tokenbalance",
          contractaddress: contractAddress,
          address: address,
          tag: "latest",
        });

        // Get token info (symbol and decimals)
        const [symbolResult, decimalsResult] = await Promise.all([
          this.makeRequest({
            module: "proxy",
            action: "eth_call",
            to: contractAddress,
            data: "0x95d89b41", // symbol() function selector
            tag: "latest",
          }).catch(() => "UNKNOWN"),
          this.makeRequest({
            module: "proxy",
            action: "eth_call",
            to: contractAddress,
            data: "0x313ce567", // decimals() function selector
            tag: "latest",
          }).catch(() => "18"),
        ]);

        // Parse results
        const decimals = parseInt(decimalsResult, 16) || 18;
        const balance = balanceResult;
        const balanceFormatted = parseFloat(balance) / Math.pow(10, decimals);

        // Decode symbol from hex
        let symbol = "UNKNOWN";
        if (typeof symbolResult === "string" && symbolResult.startsWith("0x")) {
          try {
            const decoded = Buffer.from(symbolResult.slice(2), "hex").toString("utf8");
            symbol = decoded.replace(/\0/g, "").trim() || "UNKNOWN";
          } catch {
            logger.warn("Failed to decode token symbol", {contractAddress});
          }
        }

        balances.push({
          address,
          contractAddress,
          symbol,
          decimals,
          balance,
          balanceFormatted,
          timestamp: Date.now(),
        });
      } catch (error) {
        logger.warn("Failed to get token balance", {
          address,
          contractAddress,
          error: error instanceof Error ? error.message : "Unknown error",
        });
      }
    }

    return balances;
  }

  async getMultipleEthBalances(addresses: string[]): Promise<WalletBalance[]> {
    // Etherscan supports up to 20 addresses in a single call
    const chunks = [];
    for (let i = 0; i < addresses.length; i += 20) {
      chunks.push(addresses.slice(i, i + 20));
    }

    const allBalances: WalletBalance[] = [];

    for (const chunk of chunks) {
      try {
        const result = await this.makeRequest({
          module: "account",
          action: "balancemulti",
          address: chunk.join(","),
          tag: "latest",
        });

        const balances = result.map((item: any) => ({
          address: item.account,
          balance: item.balance,
          balanceEth: parseFloat(item.balance) / Math.pow(10, 18),
          timestamp: Date.now(),
        }));

        allBalances.push(...balances);
      } catch (error) {
        logger.error("Failed to get multiple ETH balances", {
          addresses: chunk,
          error: error instanceof Error ? error.message : "Unknown error",
        });
      }
    }

    return allBalances;
  }
}

export async function pullEtherscanData(config: EtherscanConfig): Promise<EtherscanResult> {
  logger.info("Starting Etherscan data pull");

  const api = new EtherscanAPI(config);
  const errors: string[] = [];
  let assetsUpdated = 0;
  const walletBalances: WalletBalance[] = [];
  const tokenBalances: TokenBalance[] = [];

  try {
    // Get all wallet assets from Firestore
    const assetsSnapshot = await firestore
      .collection("assets")
      .where("type", "==", "wallet")
      .where("isActive", "==", true)
      .get();

    const walletAddresses = assetsSnapshot.docs.map(doc => doc.data().address);

    if (walletAddresses.length === 0) {
      logger.info("No active wallet assets found");
      return {assetsUpdated: 0, walletBalances: [], tokenBalances: [], errors: []};
    }

    logger.info(`Fetching balances for ${walletAddresses.length} wallet addresses`);

    // Get ETH balances for all wallets
    const ethBalances = await api.getMultipleEthBalances(walletAddresses);
    walletBalances.push(...ethBalances);

    // Get token contracts to check
    const tokenAssetsSnapshot = await firestore
      .collection("assets")
      .where("type", "==", "token")
      .where("isActive", "==", true)
      .get();

    const tokenContracts = tokenAssetsSnapshot.docs.map(doc => doc.data().address);

    // Get token balances for each wallet
    for (const walletAddress of walletAddresses) {
      try {
        const tokens = await api.getTokenBalances(walletAddress, tokenContracts);
        tokenBalances.push(...tokens);
      } catch (error) {
        const errorMessage = `Failed to get token balances for ${walletAddress}: ${
          error instanceof Error ? error.message : "Unknown error"
        }`;
        errors.push(errorMessage);
        logger.warn(errorMessage);
      }
    }

    // Store balance data in Firestore
    const batch = firestore.batch();
    const timestamp = admin.firestore.Timestamp.now();

    // Store ETH balances
    for (const balance of ethBalances) {
      const docRef = firestore
        .collection("wallet_balances")
        .doc(`${balance.address}_ETH_${Date.now()}`);
      
      batch.set(docRef, {
        ...balance,
        symbol: "ETH",
        updatedAt: timestamp,
      });
    }

    // Store token balances
    for (const balance of tokenBalances) {
      if (balance.balanceFormatted > 0) { // Only store non-zero balances
        const docRef = firestore
          .collection("wallet_balances")
          .doc(`${balance.address}_${balance.contractAddress}_${Date.now()}`);
        
        batch.set(docRef, {
          ...balance,
          updatedAt: timestamp,
        });
      }
    }

    // Update asset metadata with last fetch time
    for (const doc of assetsSnapshot.docs) {
      batch.update(doc.ref, {
        lastEtherscanFetch: timestamp,
        updatedAt: timestamp,
      });
      assetsUpdated++;
    }

    await batch.commit();

    logger.info("Etherscan data pull completed successfully", {
      assetsUpdated,
      ethBalances: ethBalances.length,
      tokenBalances: tokenBalances.filter(t => t.balanceFormatted > 0).length,
      errors: errors.length,
    });

    return {
      assetsUpdated,
      walletBalances,
      tokenBalances,
      errors,
    };
  } catch (error) {
    logger.error("Etherscan data pull failed", error);
    throw error;
  }
}