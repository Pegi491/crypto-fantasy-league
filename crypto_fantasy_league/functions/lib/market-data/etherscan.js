"use strict";
// ABOUTME: Etherscan API integration for wallet balance and transaction data
// ABOUTME: Handles rate limiting, error handling, and data transformation
Object.defineProperty(exports, "__esModule", { value: true });
exports.pullEtherscanData = pullEtherscanData;
const admin = require("firebase-admin");
const firebase_functions_1 = require("firebase-functions");
const axios_1 = require("axios");
const firestore = admin.firestore();
class EtherscanAPI {
    constructor(config) {
        this.lastRequestTime = 0;
        this.config = Object.assign({ baseUrl: "https://api.etherscan.io/api", rateLimit: 5 }, config);
    }
    async rateLimitDelay() {
        const minInterval = 1000 / (this.config.rateLimit || 5);
        const timeSinceLastRequest = Date.now() - this.lastRequestTime;
        if (timeSinceLastRequest < minInterval) {
            const delay = minInterval - timeSinceLastRequest;
            await new Promise(resolve => setTimeout(resolve, delay));
        }
        this.lastRequestTime = Date.now();
    }
    async makeRequest(params) {
        var _a, _b, _c;
        await this.rateLimitDelay();
        const url = this.config.baseUrl;
        const requestParams = Object.assign(Object.assign({}, params), { apikey: this.config.apiKey });
        try {
            firebase_functions_1.logger.debug("Making Etherscan API request", {
                module: params.module,
                action: params.action,
                address: ((_a = params.address) === null || _a === void 0 ? void 0 : _a.substring(0, 10)) + "...",
            });
            const response = await axios_1.default.get(url, {
                params: requestParams,
                timeout: 10000,
            });
            if (response.data.status !== "1") {
                throw new Error(`Etherscan API error: ${response.data.message}`);
            }
            return response.data.result;
        }
        catch (error) {
            if (error instanceof axios_1.AxiosError) {
                firebase_functions_1.logger.error("Etherscan API request failed", {
                    status: (_b = error.response) === null || _b === void 0 ? void 0 : _b.status,
                    message: error.message,
                    params: requestParams,
                });
                if (((_c = error.response) === null || _c === void 0 ? void 0 : _c.status) === 429) {
                    // Rate limit hit, wait longer
                    await new Promise(resolve => setTimeout(resolve, 2000));
                    throw new Error("Rate limit exceeded");
                }
            }
            throw error;
        }
    }
    async getEthBalance(address) {
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
    async getTokenBalances(address, contractAddresses) {
        const balances = [];
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
                    }
                    catch (_a) {
                        firebase_functions_1.logger.warn("Failed to decode token symbol", { contractAddress });
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
            }
            catch (error) {
                firebase_functions_1.logger.warn("Failed to get token balance", {
                    address,
                    contractAddress,
                    error: error instanceof Error ? error.message : "Unknown error",
                });
            }
        }
        return balances;
    }
    async getMultipleEthBalances(addresses) {
        // Etherscan supports up to 20 addresses in a single call
        const chunks = [];
        for (let i = 0; i < addresses.length; i += 20) {
            chunks.push(addresses.slice(i, i + 20));
        }
        const allBalances = [];
        for (const chunk of chunks) {
            try {
                const result = await this.makeRequest({
                    module: "account",
                    action: "balancemulti",
                    address: chunk.join(","),
                    tag: "latest",
                });
                const balances = result.map((item) => ({
                    address: item.account,
                    balance: item.balance,
                    balanceEth: parseFloat(item.balance) / Math.pow(10, 18),
                    timestamp: Date.now(),
                }));
                allBalances.push(...balances);
            }
            catch (error) {
                firebase_functions_1.logger.error("Failed to get multiple ETH balances", {
                    addresses: chunk,
                    error: error instanceof Error ? error.message : "Unknown error",
                });
            }
        }
        return allBalances;
    }
}
async function pullEtherscanData(config) {
    firebase_functions_1.logger.info("Starting Etherscan data pull");
    const api = new EtherscanAPI(config);
    const errors = [];
    let assetsUpdated = 0;
    const walletBalances = [];
    const tokenBalances = [];
    try {
        // Get all wallet assets from Firestore
        const assetsSnapshot = await firestore
            .collection("assets")
            .where("type", "==", "wallet")
            .where("isActive", "==", true)
            .get();
        const walletAddresses = assetsSnapshot.docs.map(doc => doc.data().address);
        if (walletAddresses.length === 0) {
            firebase_functions_1.logger.info("No active wallet assets found");
            return { assetsUpdated: 0, walletBalances: [], tokenBalances: [], errors: [] };
        }
        firebase_functions_1.logger.info(`Fetching balances for ${walletAddresses.length} wallet addresses`);
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
            }
            catch (error) {
                const errorMessage = `Failed to get token balances for ${walletAddress}: ${error instanceof Error ? error.message : "Unknown error"}`;
                errors.push(errorMessage);
                firebase_functions_1.logger.warn(errorMessage);
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
            batch.set(docRef, Object.assign(Object.assign({}, balance), { symbol: "ETH", updatedAt: timestamp }));
        }
        // Store token balances
        for (const balance of tokenBalances) {
            if (balance.balanceFormatted > 0) { // Only store non-zero balances
                const docRef = firestore
                    .collection("wallet_balances")
                    .doc(`${balance.address}_${balance.contractAddress}_${Date.now()}`);
                batch.set(docRef, Object.assign(Object.assign({}, balance), { updatedAt: timestamp }));
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
        firebase_functions_1.logger.info("Etherscan data pull completed successfully", {
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
    }
    catch (error) {
        firebase_functions_1.logger.error("Etherscan data pull failed", error);
        throw error;
    }
}
//# sourceMappingURL=etherscan.js.map