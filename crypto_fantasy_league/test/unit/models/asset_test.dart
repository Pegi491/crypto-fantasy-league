import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_fantasy_league/models/asset.dart';

void main() {
  group('Asset Model Tests', () {
    late Asset testAsset;

    setUp(() {
      testAsset = Asset(
        id: 'test-asset-id',
        name: 'Bitcoin',
        symbol: 'BTC',
        type: AssetType.token,
        address: '0x742f96c4a188346C5DB8a4dBcd6Ff9F5cfF686Bf',
        metadata: {'network': 'ethereum'},
        isActive: true,
        isPopular: false,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    test('should create Asset with all fields', () {
      expect(testAsset.id, 'test-asset-id');
      expect(testAsset.name, 'Bitcoin');
      expect(testAsset.symbol, 'BTC');
      expect(testAsset.type, AssetType.token);
      expect(testAsset.address, '0x742f96c4a188346C5DB8a4dBcd6Ff9F5cfF686Bf');
      expect(testAsset.isActive, true);
      expect(testAsset.isPopular, false);
    });

    test('should validate asset correctly', () {
      expect(testAsset.isValidAsset(), true);

      // Test invalid asset with empty name
      final invalidAsset = testAsset.copyWith(name: '');
      expect(invalidAsset.isValidAsset(), false);

      // Test invalid asset with empty symbol
      final invalidAsset2 = testAsset.copyWith(symbol: '');
      expect(invalidAsset2.isValidAsset(), false);

      // Test invalid asset with empty address
      final invalidAsset3 = testAsset.copyWith(address: '');
      expect(invalidAsset3.isValidAsset(), false);

      // Test invalid asset with invalid Ethereum address
      final invalidAsset4 = testAsset.copyWith(address: 'invalid-address');
      expect(invalidAsset4.isValidAsset(), false);
    });

    test('should create wallet asset correctly', () {
      const walletAddress = '0x742f96c4a188346C5DB8a4dBcd6Ff9F5cfF686Bf';
      final walletAsset = testAsset.copyWith(
        type: AssetType.wallet,
        address: walletAddress,
      );

      expect(walletAsset.type, AssetType.wallet);
      expect(walletAsset.address, walletAddress);
      expect(walletAsset.isValidAsset(), true);
    });

    test('should handle metadata correctly', () {
      expect(testAsset.network, 'ethereum');
      expect(testAsset.marketCap, null);
      expect(testAsset.volume24h, null);

      final updatedAsset = testAsset.updateMetadata({
        'market_cap': 1000000000.0,
        'volume_24h': 50000000.0,
      });

      expect(updatedAsset.marketCap, 1000000000.0);
      expect(updatedAsset.volume24h, 50000000.0);
      expect(updatedAsset.updatedAt.isAfter(testAsset.updatedAt), true);
    });

    test('should handle popular status', () {
      expect(testAsset.isPopular, false);

      final popularAsset = testAsset.markAsPopular();
      expect(popularAsset.isPopular, true);
      expect(popularAsset.updatedAt.isAfter(testAsset.updatedAt), true);
    });

    test('should handle deactivation', () {
      expect(testAsset.isActive, true);

      final deactivatedAsset = testAsset.deactivate();
      expect(deactivatedAsset.isActive, false);
      expect(deactivatedAsset.updatedAt.isAfter(testAsset.updatedAt), true);
    });

    test('should format short address correctly', () {
      expect(testAsset.shortAddress, '0x742f...86Bf');

      final shortAsset = testAsset.copyWith(address: '0x123');
      expect(shortAsset.shortAddress, '0x123');
    });

    test('should copy with new values', () {
      final updatedAsset = testAsset.copyWith(
        name: 'Ethereum',
        symbol: 'ETH',
        type: AssetType.wallet,
        address: '0x123456789abcdef123456789abcdef123456789a',
      );

      expect(updatedAsset.name, 'Ethereum');
      expect(updatedAsset.symbol, 'ETH');
      expect(updatedAsset.type, AssetType.wallet);
      expect(updatedAsset.address, '0x123456789abcdef123456789abcdef123456789a');
      
      // Other fields should remain unchanged
      expect(updatedAsset.id, testAsset.id);
      expect(updatedAsset.createdAt, testAsset.createdAt);
    });

    test('should serialize to and from JSON', () {
      final json = testAsset.toJson();
      final deserializedAsset = Asset.fromJson(json);

      expect(deserializedAsset.id, testAsset.id);
      expect(deserializedAsset.name, testAsset.name);
      expect(deserializedAsset.symbol, testAsset.symbol);
      expect(deserializedAsset.type, testAsset.type);
      expect(deserializedAsset.address, testAsset.address);
    });

    test('should handle Firestore conversion', () {
      final firestoreData = testAsset.toFirestore();
      
      // ID should not be included in Firestore data
      expect(firestoreData.containsKey('id'), false);
      expect(firestoreData['name'], testAsset.name);
      expect(firestoreData['symbol'], testAsset.symbol);
      expect(firestoreData['address'], testAsset.address);
    });

    test('should implement equality correctly', () {
      final sameAsset = Asset(
        id: testAsset.id,
        name: testAsset.name,
        symbol: testAsset.symbol,
        type: testAsset.type,
        address: testAsset.address,
        metadata: testAsset.metadata,
        isActive: testAsset.isActive,
        isPopular: testAsset.isPopular,
        createdAt: testAsset.createdAt,
        updatedAt: testAsset.updatedAt,
      );

      final differentAsset = testAsset.copyWith(id: 'different-id');

      expect(testAsset == sameAsset, true);
      expect(testAsset == differentAsset, false);
      expect(testAsset.hashCode == sameAsset.hashCode, true);
    });

    test('should have meaningful toString', () {
      final stringRepresentation = testAsset.toString();
      
      expect(stringRepresentation.contains('Asset{'), true);
      expect(stringRepresentation.contains('test-asset-id'), true);
      expect(stringRepresentation.contains('Bitcoin'), true);
      expect(stringRepresentation.contains('BTC'), true);
    });
  });

  group('DailyStats Tests', () {
    late DailyStats testStats;

    setUp(() {
      testStats = DailyStats(
        assetId: 'asset-123',
        date: '2024-01-01',
        timestamp: DateTime(2024, 1, 1),
        priceUsd: 50000.0,
        volumeUsd: 1000000.0,
        marketCapUsd: 900000000.0,
        socialScore: 85.5,
        changePercent24h: 5.2,
        holders: 100000,
      );
    });

    test('should create DailyStats correctly', () {
      expect(testStats.assetId, 'asset-123');
      expect(testStats.date, '2024-01-01');
      expect(testStats.priceUsd, 50000.0);
      expect(testStats.volumeUsd, 1000000.0);
      expect(testStats.marketCapUsd, 900000000.0);
      expect(testStats.socialScore, 85.5);
      expect(testStats.changePercent24h, 5.2);
      expect(testStats.holders, 100000);
    });

    test('should validate price data correctly', () {
      expect(testStats.hasValidPriceData(), true);

      final noPriceStats = DailyStats(
        assetId: testStats.assetId,
        date: testStats.date,
        timestamp: testStats.timestamp,
        priceUsd: null,
      );
      expect(noPriceStats.hasValidPriceData(), false);

      final negativePriceStats = testStats.copyWith(priceUsd: -100.0);
      expect(negativePriceStats.hasValidPriceData(), false);
    });

    test('should validate volume data correctly', () {
      expect(testStats.hasValidVolumeData(), true);

      final noVolumeStats = DailyStats(
        assetId: testStats.assetId,
        date: testStats.date,
        timestamp: testStats.timestamp,
        volumeUsd: null,
      );
      expect(noVolumeStats.hasValidVolumeData(), false);

      final negativeVolumeStats = testStats.copyWith(volumeUsd: -50.0);
      expect(negativeVolumeStats.hasValidVolumeData(), false);
    });

    test('should validate social data correctly', () {
      expect(testStats.hasValidSocialData(), true);

      final noSocialStats = DailyStats(
        assetId: testStats.assetId,
        date: testStats.date,
        timestamp: testStats.timestamp,
        socialScore: null,
      );
      expect(noSocialStats.hasValidSocialData(), false);

      final highSocialStats = testStats.copyWith(socialScore: 150.0);
      expect(highSocialStats.hasValidSocialData(), false);

      final negativeSocialStats = testStats.copyWith(socialScore: -10.0);
      expect(negativeSocialStats.hasValidSocialData(), false);
    });

    test('should check if complete correctly', () {
      expect(testStats.isComplete(), true);

      // Create new stats with null price
      final incompleteStats1 = DailyStats(
        assetId: testStats.assetId,
        date: testStats.date,
        timestamp: testStats.timestamp,
        priceUsd: null,
        volumeUsd: testStats.volumeUsd,
      );
      expect(incompleteStats1.isComplete(), false);

      // Create new stats with null volume
      final incompleteStats2 = DailyStats(
        assetId: testStats.assetId,
        date: testStats.date,
        timestamp: testStats.timestamp,
        priceUsd: testStats.priceUsd,
        volumeUsd: null,
      );
      expect(incompleteStats2.isComplete(), false);

      final incompleteStats3 = testStats.copyWith(priceUsd: -10.0);
      expect(incompleteStats3.isComplete(), false);
    });

    test('should calculate volume change percent correctly', () {
      expect(testStats.volumeChangePercent, 5.2);

      // Create stats with null change percent
      final noChangeStats = DailyStats(
        assetId: testStats.assetId,
        date: testStats.date,
        timestamp: testStats.timestamp,
        changePercent24h: null,
      );
      expect(noChangeStats.volumeChangePercent, 0.0);

      final negativeChangeStats = testStats.copyWith(changePercent24h: -3.5);
      expect(negativeChangeStats.volumeChangePercent, -3.5);
    });

    test('should calculate holder growth correctly', () {
      expect(testStats.holderGrowth, 100000.0);

      // Create stats with null holders
      final noHoldersStats = DailyStats(
        assetId: testStats.assetId,
        date: testStats.date,
        timestamp: testStats.timestamp,
        holders: null,
      );
      expect(noHoldersStats.holderGrowth, 0.0);

      final smallHoldersStats = testStats.copyWith(holders: 500);
      expect(smallHoldersStats.holderGrowth, 500.0);
    });

    test('should copy with new values', () {
      final updatedStats = testStats.copyWith(
        priceUsd: 55000.0,
        changePercent24h: -2.1,
        socialScore: 90.0,
      );

      expect(updatedStats.priceUsd, 55000.0);
      expect(updatedStats.changePercent24h, -2.1);
      expect(updatedStats.socialScore, 90.0);
      
      // Other fields should remain unchanged
      expect(updatedStats.assetId, testStats.assetId);
      expect(updatedStats.volumeUsd, testStats.volumeUsd);
    });

    test('should serialize to and from JSON', () {
      final json = testStats.toJson();
      final deserializedStats = DailyStats.fromJson(json);

      expect(deserializedStats.assetId, testStats.assetId);
      expect(deserializedStats.date, testStats.date);
      expect(deserializedStats.priceUsd, testStats.priceUsd);
      expect(deserializedStats.volumeUsd, testStats.volumeUsd);
      expect(deserializedStats.marketCapUsd, testStats.marketCapUsd);
      expect(deserializedStats.socialScore, testStats.socialScore);
      expect(deserializedStats.changePercent24h, testStats.changePercent24h);
    });

    test('should handle Firestore conversion', () {
      final firestoreData = testStats.toFirestore();
      
      expect(firestoreData['assetId'], testStats.assetId);
      expect(firestoreData['date'], testStats.date);
      expect(firestoreData['priceUsd'], testStats.priceUsd);
      expect(firestoreData['volumeUsd'], testStats.volumeUsd);
    });

    test('should implement equality correctly', () {
      final sameStats = DailyStats(
        assetId: testStats.assetId,
        date: testStats.date,
        timestamp: testStats.timestamp,
        priceUsd: testStats.priceUsd,
        volumeUsd: testStats.volumeUsd,
        marketCapUsd: testStats.marketCapUsd,
        socialScore: testStats.socialScore,
        changePercent24h: testStats.changePercent24h,
        holders: testStats.holders,
      );

      final differentStats = testStats.copyWith(date: '2024-01-02');

      expect(testStats == sameStats, true);
      expect(testStats == differentStats, false);
      expect(testStats.hashCode == sameStats.hashCode, true);
    });

    test('should have meaningful toString', () {
      final stringRepresentation = testStats.toString();
      
      expect(stringRepresentation.contains('DailyStats{'), true);
      expect(stringRepresentation.contains('asset-123'), true);
      expect(stringRepresentation.contains('2024-01-01'), true);
    });
  });
}