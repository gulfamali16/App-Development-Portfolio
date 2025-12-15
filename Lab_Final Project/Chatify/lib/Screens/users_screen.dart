// lib/Screens/users_screen.dart (REAL-TIME VERSION)

import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _currentUserProfile;
  bool _isLoadingProfile = true;
  bool _isLoadingUsers = true;
  String _searchQuery = '';

  // Real users from database
  List<Map<String, dynamic>> _allUsers = [];

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _allUsers;
    }
    return _allUsers.where((user) {
      final name = user['display_name']?.toString().toLowerCase() ?? '';
      final about = user['about']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return name.contains(query) ||
          about.contains(query) ||
          email.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load current user profile
  Future<void> _loadUserProfile() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final profile = await _authService.getUserProfile(user.id);
        if (mounted) {
          setState(() {
            _currentUserProfile = profile;
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  // Load all users from database (excluding current user)
  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoadingUsers = true;
      });

      final users = await _chatService.getAllUsers();

      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _handleMoreOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2C2A) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.refresh, color: Color(0xFF128C7E)),
                title: const Text('Refresh Users'),
                onTap: () {
                  Navigator.pop(context);
                  _loadUsers();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Color(0xFF128C7E)),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _authService.logout();
                  if (mounted) {
                    NavigationHelper.navigateToLogin(context);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _handleProfileTap() {
    if (_currentUserProfile != null) {
      NavigationHelper.navigateToEditProfile(
        context,
        initialName: _currentUserProfile!['display_name'] ?? '',
        initialStatus: _currentUserProfile!['status'] ?? 'Available',
        initialProfileImage: _currentUserProfile!['avatar_url'] ?? '',
      );
    }
  }

  // Handle user tap - create/open chat
  Future<void> _handleUserTap(Map<String, dynamic> user) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2C2A) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // User Profile Preview
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: user['avatar_url'] != null && user['avatar_url'].isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(user['avatar_url']),
                          fit: BoxFit.cover,
                        )
                            : null,
                        color: const Color(0xFF128C7E).withOpacity(0.1),
                        border: Border.all(
                          color: const Color(0xFF128C7E),
                          width: 3,
                        ),
                      ),
                      child: user['avatar_url'] == null || user['avatar_url'].isEmpty
                          ? const Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFF128C7E),
                      )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user['display_name'] ?? 'User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111717),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['about'] ?? 'Hey there! I am using ChatiFy.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isUserOnline(user)
                            ? const Color(0xFF25D366).withOpacity(0.1)
                            : const Color(0xFF9CA3AF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user['status'] ?? 'Available',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isUserOnline(user)
                              ? const Color(0xFF25D366)
                              : const Color(0xFF9CA3AF),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.message, color: Color(0xFF128C7E)),
                title: const Text('Send Message'),
                onTap: () async {
                  Navigator.pop(context);
                  await _startChat(user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.call, color: Color(0xFF128C7E)),
                title: const Text('Voice Call'),
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon('Voice Call');
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFF128C7E)),
                title: const Text('Video Call'),
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon('Video Call');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Start chat with user
  Future<void> _startChat(Map<String, dynamic> user) async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening chat...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Create or get chat
      final chatId = await _chatService.createOrGetChat(user['id']);

      if (chatId != null && mounted) {
        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserId: user['id'],
              otherUserName: user['display_name'] ?? 'User',
              otherUserAvatar: user['avatar_url'] ?? '',
              otherUserStatus: user['status'] ?? 'Available',
            ),
          ),
        );
      } else {
        _showError('Failed to create chat');
      }
    } catch (e) {
      print('Error starting chat: $e');
      _showError('Failed to start chat');
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: const Color(0xFF128C7E),
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Check if user is online (based on last_seen)
  bool _isUserOnline(Map<String, dynamic> user) {
    final lastSeen = user['last_seen'];
    if (lastSeen == null) return false;

    try {
      final lastSeenTime = DateTime.parse(lastSeen);
      final now = DateTime.now();
      final difference = now.difference(lastSeenTime);

      // Consider online if last seen within 5 minutes
      return difference.inMinutes < 5;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF128C7E);

    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 24),
                        color: Colors.white,
                      ),
                      Text(
                        'Find Users',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _handleMoreOptions,
                            icon: const Icon(Icons.more_vert, size: 24),
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: _handleProfileTap,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                image: _currentUserProfile?['avatar_url'] != null &&
                                    _currentUserProfile!['avatar_url'].isNotEmpty
                                    ? DecorationImage(
                                  image: NetworkImage(_currentUserProfile!['avatar_url']),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: _currentUserProfile?['avatar_url'] == null ||
                                  _currentUserProfile!['avatar_url'].isEmpty
                                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _handleSearch,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 15,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withOpacity(0.7),
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _handleSearch('');
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF11211F) : Colors.white,
              child: _isLoadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                  ? _buildEmptyState(isDark)
                  : RefreshIndicator(
                onRefresh: _loadUsers,
                child: ListView.builder(
                  itemCount: _filteredUsers.length,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return _buildUserItem(user, isDark);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user, bool isDark) {
    final isOnline = _isUserOnline(user);

    return Material(
      color: isDark ? const Color(0xFF11211F) : Colors.white,
      child: InkWell(
        onTap: () => _handleUserTap(user),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: user['avatar_url'] != null && user['avatar_url'].isNotEmpty
                          ? DecorationImage(
                        image: NetworkImage(user['avatar_url']),
                        fit: BoxFit.cover,
                      )
                          : null,
                      color: const Color(0xFF128C7E).withOpacity(0.1),
                    ),
                    child: user['avatar_url'] == null || user['avatar_url'].isEmpty
                        ? const Icon(Icons.person, color: Color(0xFF128C7E))
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF25D366) : const Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF11211F) : Colors.white,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['display_name'] ?? 'User',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111717),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['about'] ?? 'Hey there! I am using ChatiFy.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['status'] ?? 'Available',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isOnline ? const Color(0xFF25D366) : const Color(0xFF9CA3AF),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),

              // Message button
              IconButton(
                onPressed: () => _startChat(user),
                icon: const Icon(Icons.message_rounded, size: 22),
                color: const Color(0xFF128C7E),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF128C7E).withOpacity(0.1),
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111717),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'No registered users yet'
                : 'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }
}