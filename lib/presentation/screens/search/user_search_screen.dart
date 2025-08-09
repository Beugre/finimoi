import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/user_search_service.dart';
import '../../../domain/entities/user_model.dart';
import '../../../data/providers/auth_provider.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  final Function(UserModel user) onUserSelected;
  final String title;
  final String searchHint;

  const UserSearchScreen({
    super.key,
    required this.onUserSelected,
    this.title = 'Rechercher un contact',
    this.searchHint = 'Tapez un FinIMoiTag, email ou téléphone',
  });

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<UserModel> _searchResults = [];
  List<UserModel> _recentContacts = [];
  bool _isSearching = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecentContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadRecentContacts() async {
    final userId = ref.read(currentUserProvider)?.uid;
    if (userId == null) return;

    final userSearchService = ref.read(userSearchServiceProvider);
    try {
      final contacts = await userSearchService.getRecentContacts(userId);
      setState(() {
        _recentContacts = contacts;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _currentQuery = '';
      });
      return;
    }

    if (query == _currentQuery) return;

    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });

    _performSearch(query);
  }

  void _performSearch(String query) async {
    final userSearchService = ref.read(userSearchServiceProvider);

    try {
      List<UserModel> results = [];

      // Recherche par FinIMoiTag
      if (query.startsWith('@')) {
        final tag = query.substring(1);
        results = await userSearchService.searchUsersByTag(tag);
      }
      // Recherche par email
      else if (query.contains('@')) {
        final user = await userSearchService.searchUserByEmail(query);
        if (user != null) results = [user];
      }
      // Recherche par téléphone
      else if (RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(query)) {
        final user = await userSearchService.searchUserByPhone(query);
        if (user != null) results = [user];
      }
      // Recherche par tag sans @
      else {
        results = await userSearchService.searchUsersByTag(query);
      }

      if (mounted && query == _currentQuery) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted && query == _currentQuery) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de recherche: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primaryViolet,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryViolet,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              autofocus: true,
            ),
          ),

          // Results
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentQuery.isNotEmpty) {
      if (_searchResults.isEmpty) {
        return _buildEmptyResults();
      }
      return _buildUsersList(_searchResults, 'Résultats de recherche');
    }

    // Show recent contacts when not searching
    if (_recentContacts.isEmpty) {
      return _buildEmptyState();
    }
    return _buildUsersList(_recentContacts, 'Contacts récents');
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec un autre FinIMoiTag, email ou téléphone',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Recherchez vos contacts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tapez un FinIMoiTag (@pseudo), email ou numéro de téléphone pour trouver vos contacts',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: AppColors.primaryViolet.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryViolet.withAlpha(50)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryViolet,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  'Exemples de recherche:',
                  style: TextStyle(
                    color: AppColors.primaryViolet,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• @johndoe\n• jean.dupont@email.com\n• +225 XX XX XX XX XX',
                  style: TextStyle(
                    color: AppColors.primaryViolet,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<UserModel> users, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserTile(user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserTile(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryViolet,
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : null,
          child: user.profileImageUrl == null
              ? Text(
                  _getInitials(user.firstName, user.lastName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          '${user.firstName} ${user.lastName}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '@${user.finimoiTag ?? 'pas_de_tag'}',
              style: TextStyle(
                color: AppColors.primaryViolet,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (user.phoneNumber != null) ...[
              const SizedBox(height: 2),
              Text(
                user.phoneNumber!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryViolet.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Sélectionner',
            style: TextStyle(
              color: AppColors.primaryViolet,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () => widget.onUserSelected(user),
      ),
    );
  }

  String _getInitials(String firstName, String lastName) {
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();
  }
}
