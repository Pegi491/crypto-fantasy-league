// ABOUTME: Unit tests for data validation functions
// ABOUTME: Tests various data validation scenarios and edge cases

import {DataValidator} from "../data-processing/validator";

describe("DataValidator", () => {
  describe("validateAssetData", () => {
    test("should validate correct asset data", () => {
      const validData = {
        symbol: "BTC",
        price: 50000.50,
        volume: 1000000,
        marketCap: 900000000,
        change24h: 5.25,
        timestamp: Date.now(),
      };

      const result = DataValidator.validateAssetData(validData);

      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
      expect(result.sanitizedData).toBeDefined();
      expect(result.sanitizedData?.symbol).toBe("BTC");
      expect(result.sanitizedData?.price).toBe(50000.5);
    });

    test("should reject invalid symbol", () => {
      const invalidData = {
        symbol: "",
        price: 50000,
      };

      const result = DataValidator.validateAssetData(invalidData);

      expect(result.isValid).toBe(false);
      expect(result.errors).toContain("Symbol is required and must be a string");
    });

    test("should reject negative price", () => {
      const invalidData = {
        symbol: "BTC",
        price: -100,
      };

      const result = DataValidator.validateAssetData(invalidData);

      expect(result.isValid).toBe(false);
      expect(result.errors).toContain("Price cannot be negative");
    });

    test("should warn about extreme values", () => {
      const extremeData = {
        symbol: "MEME",
        price: 0.0000001,
        volume: 500000000000,
        change24h: 1000,
      };

      const result = DataValidator.validateAssetData(extremeData);

      expect(result.isValid).toBe(true);
      expect(result.warnings.length).toBeGreaterThan(0);
    });

    test("should sanitize and round values", () => {
      const messyData = {
        symbol: "  eth  ",
        price: 3000.123456789,
        volume: 1000000.789,
        change24h: 5.123456,
      };

      const result = DataValidator.validateAssetData(messyData);

      expect(result.isValid).toBe(true);
      expect(result.sanitizedData?.symbol).toBe("ETH");
      expect(result.sanitizedData?.price).toBe(3000.12345679); // 8 decimal places
      expect(result.sanitizedData?.volume).toBe(1000001); // Rounded
      expect(result.sanitizedData?.change24h).toBe(5.1235); // 4 decimal places
    });

    test("should add timestamp if missing", () => {
      const dataWithoutTimestamp = {
        symbol: "BTC",
        price: 50000,
      };

      const result = DataValidator.validateAssetData(dataWithoutTimestamp);

      expect(result.isValid).toBe(true);
      expect(result.sanitizedData?.timestamp).toBeDefined();
      expect(typeof result.sanitizedData?.timestamp).toBe("number");
    });
  });

  describe("validateWalletBalance", () => {
    test("should validate correct wallet balance", () => {
      const validBalance = {
        address: "0x742f96c4a188346C5DB8a4dBcd6Ff9F5cfF686Bf",
        balance: "1000000000000000000",
        contractAddress: "0xA0b86a33E6441e2e59Ade7Dc0a6c12e4Ad80E02e",
      };

      const result = DataValidator.validateWalletBalance(validBalance);

      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
      expect(result.sanitizedData?.address).toBe("0x742f96c4a188346c5db8a4dbcd6ff9f5cff686bf");
    });

    test("should reject invalid Ethereum address", () => {
      const invalidBalance = {
        address: "invalid-address",
        balance: "1000",
      };

      const result = DataValidator.validateWalletBalance(invalidBalance);

      expect(result.isValid).toBe(false);
      expect(result.errors).toContain("Invalid Ethereum address format");
    });

    test("should reject negative balance", () => {
      const invalidBalance = {
        address: "0x742f96c4a188346C5DB8a4dBcd6Ff9F5cfF686Bf",
        balance: "-1000",
      };

      const result = DataValidator.validateWalletBalance(invalidBalance);

      expect(result.isValid).toBe(false);
      expect(result.errors).toContain("Balance must be a valid non-negative number");
    });

    test("should handle numeric balance", () => {
      const numericBalance = {
        address: "0x742f96c4a188346C5DB8a4dBcd6Ff9F5cfF686Bf",
        balance: 1000,
      };

      const result = DataValidator.validateWalletBalance(numericBalance);

      expect(result.isValid).toBe(true);
      expect(result.sanitizedData?.balance).toBe("1000");
    });
  });

  describe("validateSocialMetrics", () => {
    test("should validate correct social metrics", () => {
      const validMetrics = {
        symbol: "BTC",
        socialScore: 85,
        sentimentScore: 0.75,
        mentions24h: 1500,
      };

      const result = DataValidator.validateSocialMetrics(validMetrics);

      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
      expect(result.sanitizedData?.symbol).toBe("BTC");
      expect(result.sanitizedData?.socialScore).toBe(85);
    });

    test("should reject invalid social score range", () => {
      const invalidMetrics = {
        symbol: "BTC",
        socialScore: 150,
      };

      const result = DataValidator.validateSocialMetrics(invalidMetrics);

      expect(result.isValid).toBe(false);
      expect(result.errors).toContain("Social score must be between 0 and 100");
    });

    test("should reject invalid sentiment score range", () => {
      const invalidMetrics = {
        symbol: "BTC",
        sentimentScore: 2.5,
      };

      const result = DataValidator.validateSocialMetrics(invalidMetrics);

      expect(result.isValid).toBe(false);
      expect(result.errors).toContain("Sentiment score must be between -1 and 1");
    });

    test("should round values appropriately", () => {
      const messyMetrics = {
        symbol: "  btc  ",
        socialScore: 85.7,
        sentimentScore: 0.12345,
        mentions24h: 1500.9,
      };

      const result = DataValidator.validateSocialMetrics(messyMetrics);

      expect(result.isValid).toBe(true);
      expect(result.sanitizedData?.symbol).toBe("BTC");
      expect(result.sanitizedData?.socialScore).toBe(86); // Rounded
      expect(result.sanitizedData?.sentimentScore).toBe(0.123); // 3 decimal places
      expect(result.sanitizedData?.mentions24h).toBe(1501); // Rounded
    });
  });
});