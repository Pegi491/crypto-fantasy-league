// ABOUTME: Leagues screen for browsing, joining, and managing fantasy leagues
// ABOUTME: Displays user's leagues and provides options to discover new leagues

import 'package:flutter/material.dart';
import '../../utils/logger.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leagues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              AppLogger.info('Create league button pressed');
              _showCreateLeagueDialog();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Leagues'),
            Tab(text: 'Discover'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyLeagues(),
          _buildDiscoverLeagues(),
        ],
      ),
    );
  }

  Widget _buildMyLeagues() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No leagues joined yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join your first league to start competing with friends and traders worldwide',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _tabController.animateTo(1);
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Discover Leagues'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverLeagues() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildFilterChips(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildLeaguesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Search leagues...',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) {
        AppLogger.debug('League search: $value');
        // TODO: Implement search functionality
      },
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Public'),
            selected: true,
            onSelected: (selected) {
              AppLogger.debug('Public filter: $selected');
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Wallet League'),
            selected: false,
            onSelected: (selected) {
              AppLogger.debug('Wallet League filter: $selected');
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Meme Coin'),
            selected: false,
            onSelected: (selected) {
              AppLogger.debug('Meme Coin filter: $selected');
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Beginner'),
            selected: false,
            onSelected: (selected) {
              AppLogger.debug('Beginner filter: $selected');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaguesList() {
    // Sample data for demonstration
    final sampleLeagues = [
      {
        'name': 'Crypto Newbie League',
        'description': 'Perfect for beginners learning the ropes',
        'members': 8,
        'maxMembers': 12,
        'type': 'Wallet League',
        'isPublic': true,
      },
      {
        'name': 'Meme Masters',
        'description': 'Trade the hottest meme coins',
        'members': 15,
        'maxMembers': 20,
        'type': 'Meme Coin',
        'isPublic': true,
      },
      {
        'name': 'Whale Watchers',
        'description': 'Follow the biggest wallets in DeFi',
        'members': 6,
        'maxMembers': 10,
        'type': 'Wallet League',
        'isPublic': true,
      },
    ];

    return ListView.builder(
      itemCount: sampleLeagues.length,
      itemBuilder: (context, index) {
        final league = sampleLeagues[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              league['name'] as String,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(league['description'] as String),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        league['type'] as String,
                        style: const TextStyle(fontSize: 12),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.people,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${league['members']}/${league['maxMembers']}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                AppLogger.info('Join league: ${league['name']}');
                _showJoinLeagueDialog(league['name'] as String);
              },
              child: const Text('Join'),
            ),
          ),
        );
      },
    );
  }

  void _showCreateLeagueDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create League'),
        content: const Text(
          'League creation will be available in a future update. Stay tuned!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showJoinLeagueDialog(String leagueName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join $leagueName'),
        content: const Text(
          'League joining functionality will be available in a future update. Stay tuned!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}