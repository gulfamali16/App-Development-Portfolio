// lib/Screens/home_screen.dart
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int _selectedTab = 0;
  Map<String, dynamic>? _currentUserProfile;
  bool _isLoadingProfile = true;

  final List<Chat> _chats = [
    Chat(
      name: 'Jane Doe',
      lastMessage: 'Hey, are we still on for lunch?',
      time: '10:30 AM',
      unreadCount: 2,
      isOnline: true,
      imageUrl: 'https://i.pravatar.cc/150?img=1',
    ),
    Chat(
      name: 'Team Alpha',
      lastMessage: 'Mark: Please review the design docs.',
      time: '09:15 AM',
      unreadCount: 0,
      isOnline: false,
      imageUrl: 'https://i.pravatar.cc/150?img=5',
    ),
    Chat(
      name: 'Mom',
      lastMessage: 'Sent a photo',
      time: 'Yesterday',
      unreadCount: 0,
      isOnline: false,
      imageUrl: 'https://i.pravatar.cc/150?img=20',
      hasMedia: true,
    ),
    Chat(
      name: 'John Smith',
      lastMessage: 'Can we reschedule the meeting?',
      time: 'Tuesday',
      unreadCount: 0,
      isOnline: false,
      imageUrl: 'https://i.pravatar.cc/150?img=12',
    ),
  ];

  final List<User> _users = [
    User(
      name: 'Alex Johnson',
      status: 'Available',
      isOnline: true,
      imageUrl: 'https://i.pravatar.cc/150?img=33',
    ),
    User(
      name: 'Sarah Miller',
      status: 'At work',
      isOnline: true,
      imageUrl: 'https://i.pravatar.cc/150?img=44',
    ),
    User(
      name: 'Michael Chen',
      status: 'Busy',
      isOnline: true,
      imageUrl: 'https://i.pravatar.cc/150?img=13',
    ),
    User(
      name: 'Emma Wilson',
      status: 'Last seen 2h ago',
      isOnline: false,
      imageUrl: 'https://i.pravatar.cc/150?img=47',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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
                leading: const Icon(Icons.group_add, color: Color(0xFF128C7E)),
                title: const Text('New Group'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle new group
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Color(0xFF128C7E)),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle settings
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

  void _handleNewChat() {
    // Navigate to create new chat
  }

  void _handleChatTap(Chat chat) {
    // Navigate to chat screen
  }

  void _handleUserTap(User user) {
    // Start chat with user
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
                // App Bar with Profile Icon
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // App Title
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

                      // Action Buttons
                      Row(
                        children: [
                          // Search Button
                          IconButton(
                            onPressed: _handleSearch,
                            icon: const Icon(Icons.search, size: 24),
                            color: Colors.white,
                            style: IconButton.styleFrom(
                              shape: const CircleBorder(),
                              minimumSize: const Size(40, 40),
                            ),
                          ),

                          // More Options Button
                          IconButton(
                            onPressed: _handleMoreOptions,
                            icon: const Icon(Icons.more_vert, size: 24),
                            color: Colors.white,
                            style: IconButton.styleFrom(
                              shape: const CircleBorder(),
                              minimumSize: const Size(40, 40),
                            ),
                          ),

                          const SizedBox(width: 4),

                          // Profile Icon
                          GestureDetector(
                            onTap: _handleProfileTap,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
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
                                  ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              )
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

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: _handleNewChat,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 8,
        child: const Icon(Icons.chat_bubble, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

    return ListView.builder(
      itemCount: _chats.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        final chat = _chats[index];
        return _buildChatItem(chat, isDark);
      },
    );
  }

  Widget _buildChatItem(Chat chat, bool isDark) {
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
                      image: DecorationImage(
                        image: NetworkImage(chat.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (chat.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            chat.name,
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
                        Text(
                          chat.time,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: chat.unreadCount > 0
                                ? const Color(0xFF128C7E)
                                : isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
                            chat.lastMessage,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF128C7E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              chat.unreadCount.toString(),
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

    return ListView.builder(
      itemCount: _users.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        final user = _users[index];
        return _buildUserItem(user, isDark);
      },
    );
  }

  Widget _buildUserItem(User user, bool isDark) {
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
                      image: DecorationImage(
                        image: NetworkImage(user.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: user.isOnline
                            ? const Color(0xFF25D366)
                            : const Color(0xFF9CA3AF),
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
                      user.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111717),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
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
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }
}

class Chat {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final String imageUrl;
  final bool hasMedia;

  Chat({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
    required this.imageUrl,
    this.hasMedia = false,
  });
}

class User {
  final String name;
  final String status;
  final bool isOnline;
  final String imageUrl;

  User({
    required this.name,
    required this.status,
    required this.isOnline,
    required this.imageUrl,
  });
}

class ChatSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
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