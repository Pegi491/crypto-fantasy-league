# Crypto Fantasy League - Cloud Functions

This directory contains Firebase Cloud Functions for the Crypto Fantasy League market data pipeline.

## Overview

The market data pipeline consists of several components:

### Data Ingestion Functions
- **pullEtherscanData**: Fetches wallet balances and transaction data from Etherscan API
- **pullCoinGeckoData**: Fetches token prices and market data from CoinGecko API  
- **pullSocialData**: Fetches social sentiment scores and metrics

### Data Processing Functions
- **validateAssetData**: Validates and sanitizes incoming market data
- **calculateDailyStats**: Processes raw data into structured daily statistics
- **updateAssetMetadata**: Updates asset metadata, popularity rankings, and data freshness

### Scheduled Functions
- **pullMarketDataScheduled**: Runs every 5 minutes to fetch market data
- **calculateDailyStatsScheduled**: Runs daily at 00:05 UTC to calculate daily statistics
- **pullSocialDataScheduled**: Runs hourly to fetch social sentiment data
- **updateAssetMetadataScheduled**: Runs weekly to update asset metadata

## Setup

1. Install dependencies:
```bash
npm install
```

2. Set up environment secrets in Firebase:
```bash
firebase functions:secrets:set ETHERSCAN_API_KEY
firebase functions:secrets:set COINGECKO_API_KEY
firebase functions:secrets:set SOCIAL_API_KEY
```

3. Build the functions:
```bash
npm run build
```

4. Deploy to Firebase:
```bash
npm run deploy
```

## Development

### Local Development
```bash
# Start the Firebase emulator
npm run serve

# Run tests
npm test

# Lint code
npm run lint
```

### Testing
The functions include comprehensive unit tests for data validation and processing logic.

Run tests with:
```bash
npm test
```

## API Rate Limits

- **Etherscan**: 5 requests per second (free tier)
- **CoinGecko**: 10-50 requests per minute (depends on tier)
- **Social APIs**: Varies by provider

## Error Handling

All functions include comprehensive error handling with:
- Retry logic for transient failures
- Rate limiting with exponential backoff
- Detailed logging for debugging
- Graceful degradation when APIs are unavailable

## Data Validation

All incoming data is validated and sanitized to ensure:
- Data type correctness
- Range validation for numeric values
- Address format validation for Ethereum addresses
- Data freshness checks

## Monitoring

Functions automatically log key metrics:
- Processing counts
- Error rates
- API response times
- Data validation results

Monitor function health in the Firebase Console under Functions.