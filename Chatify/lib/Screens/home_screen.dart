// lib/Screens/home_screen_UPDATED.dart

import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  int _selectedTab = 0;
  Map<String, dynamic>? _currentUserProfile;
  bool _isLoadingProfile = true;
  List<Map<String, dynamic>> _chats = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingChats = true;
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadChats();
    _loadUsers();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final profile = await _authService.getUserProfile(user.id);
        setState(() {
          _currentUserProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _chatService.getUserChats();
      setState(() {
        _chats = chats;
        _isLoadingChats = false;
      });
    } catch (e) {
      print('Error loading chats: $e');
      setState(() {
        _isLoadingChats = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _chatService.getAllUsers();
      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  void _handleTabChange(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  void _handleSearch() {
    showSearch(
      context: context,
      delegate: ChatSearchDelegate(),
    );
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
                title: const Text('Refresh'),
                onTap: () {
                  Navigator.pop(context);
                  _loadChats();
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
                  NavigationHelper.navigateToLogin(context);
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

  void _handleChatTap(Map<String, dynamic> chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chat['chat_id'],
          otherUserId: chat['other_user_id'],
          otherUserName: chat['other_user_name'],
          otherUserAvatar: chat['other_user_avatar'] ?? '',
          otherUserStatus: chat['other_user_status'] ?? 'Offline',
        ),
      ),
    ).then((_) {
      // Refresh chats when coming back
      _loadChats();
    });
  }

  Future<void> _handleUserTap(Map<String, dynamic> user) async {
    // Create or get chat with this user
    final chatId = await _chatService.createOrGetChat(user['id']);

    if (chatId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserId: user['id'],
            otherUserName: user['display_name'] ?? 'User',
            otherUserAvatar: user['avatar_url'] ?? '',
            otherUserStatus: user['status'] ?? 'Offline',
          ),
        ),
      ).then((_) {
        _loadChats();
      });
    }
  }

  void _handleNewChat() {
    // Show users list to start new chat
    setState(() {
      _selectedTab = 1; // Switch to USERS tab
    });
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
                      Text(
                        'ChatiFy',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Plus Jakarta Sans',
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _handleSearch,
                            icon: const Icon(Icons.search, size: 24),
                            color: Colors.white,
                          ),
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

                // Tabs
                Row(
                  children: [
                    _buildTab(0, 'CHATS'),
                    _buildTab(1, 'USERS'),
                    _buildTab(2, 'CALLS'),
                  ],
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF11211F) : Colors.white,
              child: _buildContent(),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _handleNewChat,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 8,
        child: const Icon(Icons.chat_bubble, size: 26),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTabChange(index),
        child: Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                fontFamily: 'Plus Jakarta Sans',
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildChatsList();
      case 1:
        return _buildUsersList();
      case 2:
        return _buildCallsList();
      default:
        return _buildChatsList();
    }
  }

  Widget _buildChatsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingChats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111717),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to start a new chat',
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

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.builder(
        itemCount: _chats.length,
        padding: const EdgeInsets.only(bottom: 80),
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return _buildChatItem(chat, isDark);
        },
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat, bool isDark) {
    final unreadCount = chat['unread_count'] ?? 0;
    final lastMessage = chat['last_message'] ?? '';

    return Material(
      color: isDark ? const Color(0xFF11211F) : Colors.white,
      child: InkWell(
        onTap: () => _handleChatTap(chat),
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
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: chat['other_user_avatar'] != null &&
                          chat['other_user_avatar'].isNotEmpty
                          ? DecorationImage(
                        image: NetworkImage(chat['other_user_avatar']),
                        fit: BoxFit.cover,
                      )
                          : null,
                      color: const Color(0xFF128C7E).withOpacity(0.1),
                    ),
                    child: chat['other_user_avatar'] == null ||
                        chat['other_user_avatar'].isEmpty
                        ? const Icon(Icons.person, color: Color(0xFF128C7E))
                        : null,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            chat['other_user_name'] ?? 'User',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF111717),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat['last_message_time'] != null)
                          Text(
                            _formatTime(chat['last_message_time']),
                            style: TextStyle(
                              fontSize: 12,
                              color: unreadCount > 0
                                  ? const Color(0xFF128C7E)
                                  : isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage.isEmpty ? 'Start chatting' : lastMessage,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                              color: isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF128C7E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        itemCount: _users.length,
        padding: const EdgeInsets.only(bottom: 80),
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserItem(user, isDark);
        },
      ),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user, bool isDark) {
    final isOnline = user['status'] != 'Offline';

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
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
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
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF25D366) : const Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF11211F) : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
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
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['status'] ?? 'Offline',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _handleUserTap(user),
                icon: const Icon(Icons.message, size: 20),
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

  Widget _buildCallsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call,
            size: 64,
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 16),
          Text(
            'Calls feature coming soon',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } catch (e) {
      return '';
    }
  }
}

class ChatSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = '',
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return const Center(child: Text('Search results'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('Search for chats'));
  }
}