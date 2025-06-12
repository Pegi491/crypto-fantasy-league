// ABOUTME: Data validation and sanitization for market data pipeline
// ABOUTME: Ensures data quality and consistency before storage

import {logger} from "firebase-functions";

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
  sanitizedData?: any;
}

export interface AssetDataValidation {
  symbol: string;
  price?: number;
  volume?: number;
  marketCap?: number;
  change24h?: number;
  timestamp?: number;
}

export class DataValidator {
  private static readonly MIN_PRICE = 0.000001; // Minimum valid price (1 millionth)
  private static readonly MAX_PRICE = 10000000; // Maximum valid price (10M)
  private static readonly MIN_VOLUME = 0;
  private static readonly MAX_VOLUME = 1000000000000; // 1T
  private static readonly MIN_MARKET_CAP = 0;
  private static readonly MAX_MARKET_CAP = 10000000000000; // 10T
  private static readonly MAX_CHANGE_PERCENT = 10000; // 10000% (for extreme meme coins)
  private static readonly MAX_AGE_MINUTES = 30; // Data must be less than 30 minutes old

  static validateAssetData(data: AssetDataValidation): ValidationResult {
    const errors: string[] = [];
    const warnings: string[] = [];
    const sanitizedData: any = {...data};

    // Validate symbol
    if (!data.symbol || typeof data.symbol !== "string") {
      errors.push("Symbol is required and must be a string");
    } else {
      sanitizedData.symbol = data.symbol.trim().toUpperCase();
      if (sanitizedData.symbol.length < 1 || sanitizedData.symbol.length > 10) {
        errors.push("Symbol must be between 1 and 10 characters");
      }
    }

    // Validate price
    if (data.price !== undefined) {
      if (typeof data.price !== "number" || isNaN(data.price)) {
        errors.push("Price must be a valid number");
      } else if (data.price < 0) {
        errors.push("Price cannot be negative");
      } else if (data.price < this.MIN_PRICE) {
        warnings.push(`Price ${data.price} is extremely low`);
      } else if (data.price > this.MAX_PRICE) {
        warnings.push(`Price ${data.price} is extremely high`);
      }
      
      // Round to 8 decimal places
      sanitizedData.price = Math.round(data.price * 100000000) / 100000000;
    }

    // Validate volume
    if (data.volume !== undefined) {
      if (typeof data.volume !== "number" || isNaN(data.volume)) {
        errors.push("Volume must be a valid number");
      } else if (data.volume < this.MIN_VOLUME) {
        errors.push("Volume cannot be negative");
      } else if (data.volume > this.MAX_VOLUME) {
        warnings.push(`Volume ${data.volume} is extremely high`);
      }
      
      sanitizedData.volume = Math.round(data.volume);
    }

    // Validate market cap
    if (data.marketCap !== undefined) {
      if (typeof data.marketCap !== "number" || isNaN(data.marketCap)) {
        errors.push("Market cap must be a valid number");
      } else if (data.marketCap < this.MIN_MARKET_CAP) {
        errors.push("Market cap cannot be negative");
      } else if (data.marketCap > this.MAX_MARKET_CAP) {
        warnings.push(`Market cap ${data.marketCap} is extremely high`);
      }
      
      sanitizedData.marketCap = Math.round(data.marketCap);
    }

    // Validate price change
    if (data.change24h !== undefined) {
      if (typeof data.change24h !== "number" || isNaN(data.change24h)) {
        errors.push("24h change must be a valid number");
      } else if (Math.abs(data.change24h) > this.MAX_CHANGE_PERCENT) {
        warnings.push(`24h change ${data.change24h}% is extreme`);
      }
      
      // Round to 4 decimal places
      sanitizedData.change24h = Math.round(data.change24h * 10000) / 10000;
    }

    // Validate timestamp
    if (data.timestamp !== undefined) {
      if (typeof data.timestamp !== "number" || isNaN(data.timestamp)) {
        errors.push("Timestamp must be a valid number");
      } else {
        const now = Date.now();
        const ageMinutes = (now - data.timestamp) / (1000 * 60);
        
        if (data.timestamp > now) {
          errors.push("Timestamp cannot be in the future");
        } else if (ageMinutes > this.MAX_AGE_MINUTES) {
          warnings.push(`Data is ${Math.round(ageMinutes)} minutes old`);
        }
      }
    } else {
      // Add current timestamp if not provided
      sanitizedData.timestamp = Date.now();
    }

    // Cross-validation checks
    if (data.price && data.volume && data.marketCap) {
      // Basic sanity check: if volume is very high but market cap is very low, something's wrong
      const volumeToMarketCapRatio = data.volume / data.marketCap;
      if (volumeToMarketCapRatio > 10) {
        warnings.push("Volume to market cap ratio is unusually high");
      }
    }

    return {
      isValid: errors.length === 0,
      errors,
      warnings,
      sanitizedData: errors.length === 0 ? sanitizedData : undefined,
    };
  }

  static validateWalletBalance(data: any): ValidationResult {
    const errors: string[] = [];
    const warnings: string[] = [];
    const sanitizedData: any = {...data};

    // Validate address
    if (!data.address || typeof data.address !== "string") {
      errors.push("Address is required and must be a string");
    } else {
      sanitizedData.address = data.address.trim().toLowerCase();
      
      // Basic Ethereum address validation
      if (!sanitizedData.address.match(/^0x[a-f0-9]{40}$/)) {
        errors.push("Invalid Ethereum address format");
      }
    }

    // Validate balance
    if (data.balance !== undefined) {
      if (typeof data.balance !== "string" && typeof data.balance !== "number") {
        errors.push("Balance must be a string or number");
      } else {
        const balanceNum = typeof data.balance === "string" ? 
          parseFloat(data.balance) : data.balance;
        
        if (isNaN(balanceNum) || balanceNum < 0) {
          errors.push("Balance must be a valid non-negative number");
        }
        
        sanitizedData.balance = data.balance.toString();
      }
    }

    // Validate contract address for tokens
    if (data.contractAddress) {
      if (typeof data.contractAddress !== "string") {
        errors.push("Contract address must be a string");
      } else {
        sanitizedData.contractAddress = data.contractAddress.trim().toLowerCase();
        
        if (!sanitizedData.contractAddress.match(/^0x[a-f0-9]{40}$/)) {
          errors.push("Invalid contract address format");
        }
      }
    }

    return {
      isValid: errors.length === 0,
      errors,
      warnings,
      sanitizedData: errors.length === 0 ? sanitizedData : undefined,
    };
  }

  static validateSocialMetrics(data: any): ValidationResult {
    const errors: string[] = [];
    const warnings: string[] = [];
    const sanitizedData: any = {...data};

    // Validate symbol
    if (!data.symbol || typeof data.symbol !== "string") {
      errors.push("Symbol is required and must be a string");
    } else {
      sanitizedData.symbol = data.symbol.trim().toUpperCase();
    }

    // Validate social score (0-100)
    if (data.socialScore !== undefined) {
      if (typeof data.socialScore !== "number" || isNaN(data.socialScore)) {
        errors.push("Social score must be a valid number");
      } else if (data.socialScore < 0 || data.socialScore > 100) {
        errors.push("Social score must be between 0 and 100");
      }
      
      sanitizedData.socialScore = Math.round(data.socialScore);
    }

    // Validate sentiment score (-1 to 1)
    if (data.sentimentScore !== undefined) {
      if (typeof data.sentimentScore !== "number" || isNaN(data.sentimentScore)) {
        errors.push("Sentiment score must be a valid number");
      } else if (data.sentimentScore < -1 || data.sentimentScore > 1) {
        errors.push("Sentiment score must be between -1 and 1");
      }
      
      sanitizedData.sentimentScore = Math.round(data.sentimentScore * 1000) / 1000;
    }

    // Validate mentions
    if (data.mentions24h !== undefined) {
      if (typeof data.mentions24h !== "number" || isNaN(data.mentions24h)) {
        errors.push("Mentions count must be a valid number");
      } else if (data.mentions24h < 0) {
        errors.push("Mentions count cannot be negative");
      }
      
      sanitizedData.mentions24h = Math.round(data.mentions24h);
    }

    return {
      isValid: errors.length === 0,
      errors,
      warnings,
      sanitizedData: errors.length === 0 ? sanitizedData : undefined,
    };
  }
}

export async function validateAssetData(data: any): Promise<ValidationResult> {
  logger.info("Validating asset data", {
    dataType: typeof data,
    hasSymbol: !!data?.symbol,
  });

  try {
    let result: ValidationResult;

    // Determine data type and validate accordingly
    if (data.address && (data.balance !== undefined)) {
      // Wallet balance data
      result = DataValidator.validateWalletBalance(data);
    } else if (data.socialScore !== undefined || data.sentimentScore !== undefined) {
      // Social metrics data
      result = DataValidator.validateSocialMetrics(data);
    } else {
      // Market data
      result = DataValidator.validateAssetData(data);
    }

    logger.info("Data validation completed", {
      isValid: result.isValid,
      errorCount: result.errors.length,
      warningCount: result.warnings.length,
    });

    return result;
  } catch (error) {
    logger.error("Data validation failed", error);
    return {
      isValid: false,
      errors: [`Validation error: ${error instanceof Error ? error.message : "Unknown error"}`],
      warnings: [],
    };
  }
}