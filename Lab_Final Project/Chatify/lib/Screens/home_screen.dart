import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatiFy - Home',
      theme: ThemeData(
        fontFamily: 'Plus Jakarta Sans',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8F8),
      ),
      darkTheme: ThemeData(
        fontFamily: 'Plus Jakarta Sans',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF11211F),
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0; // 0: Chats, 1: Users, 2: Calls
  final List<Chat> _chats = [
    Chat(
      name: 'Jane Doe',
      lastMessage: 'Hey, are we still on for lunch?',
      time: '10:30 AM',
      unreadCount: 2,
      isOnline: true,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBCnRb2Mq5BI-x21XrehQHNqLBzJwdwCYtyy7kJy5BkfYFDa1EW43PklT_OJK7HM0Gruv575uvfn-1IG0oAvkcdVSPbDt6rzNNsU8GABjgzSAeBo-BOCjJ3EI3WgAbDWeUbhfIMc_1U8KyR568FKtPFJlF68UgCFfsCs0rx6utPJZiuliZ7QkHXQ2sesamk3ocREcr5bV6mMtLoYMzYf0ZOdXsCQhC1XV0_xW_5HF28e9960pgugEn-VHugF4PwkwhpiPvERDo46pE',
    ),
    Chat(
      name: 'Team Alpha',
      lastMessage: 'Mark: Please review the design docs.',
      time: '09:15 AM',
      unreadCount: 0,
      isOnline: false,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA3oM34VYJpn5gqUnZIcaZ71zM9WNXKzXYjPOm7urYC636UE6o6pH5jAzDQ17xgvQnk3VgrsJI8wrtAkfDcFUWzK_tM5CZ-QZ5JYCADiWTxSQ7ao4HeDyZqRHEuJJaM-fQN5hLpc5FnBeIc3YWY7DKv2Rz_YHrdE069NoVND4kFQlMqXOrfwCq9iUw-86XMXU3xLyxDySmxx0sCviAFr2CwXET8mJK788w2-_u_KfitWQPQl7fHy9fhevEoVd4U0qWwBKMZ6K39d4U',
    ),
    Chat(
      name: 'Mom',
      lastMessage: 'Sent a photo',
      time: 'Yesterday',
      unreadCount: 0,
      isOnline: false,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3gsq_YZcE76khx9qF8zkD1yUzkzbW9K_KTQ5mSxIiVcGBTHPezBJ9ppl65PPk9-8bKx5ZoIJD5qWDHalWDr0Klrb33pfyGycygxGJp4e6Zxjj4bYS-lrRSVD2RmdOoDH5_CNpPXCTIiaAwFGp7sU7Y5bb7W0p4OLPIx3mVAogkxORdQPPssXgyu5szxdbRWu0Hxl2UvECN9pQUoVkjHUn8sL5eIekXd-0lcCc1-UwgFGyj7fxWkcos9kzdqb0d0yqoaD-wx2_eVs',
      hasMedia: true,
    ),
    Chat(
      name: 'John Smith',
      lastMessage: 'Can we reschedule the meeting?',
      time: 'Tuesday',
      unreadCount: 0,
      isOnline: false,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCWWGWzmwrnr0votvth7E8VpaN_dVKGJcxOtoOG0X_Y-FxmKRCeAPp5cbqrWDgV6a-CYsP6fCN_HKwmOmeItPI667XUjz5fEkCDrFdVTtYqL9wnvTJyHzeYjx1O-rofzXkAYwHoytVX9C1Pe30t2O7a_07G5eEnlwNbhR3R3Ckz7xyEKmS-bkLYKc0DlP028ji50jaf-FiUbyeKbUyQcXVkwNqJJ-SEAbBk-OtIRXdT2z7MhoMM6EJ7ZsnrNwNpJ0RCyz3jAGSLJTU',
    ),
    Chat(
      name: 'Design Team',
      lastMessage: 'Alice: The new mockups are ready.',
      time: 'Monday',
      unreadCount: 0,
      isOnline: false,
      isGroup: true,
      initials: 'DT',
    ),
    Chat(
      name: 'David Brown',
      lastMessage: 'Sounds good!',
      time: '12/10/2023',
      unreadCount: 0,
      isOnline: false,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDnmTJAWmhFXUQdTjoqhXqp5iynF9OnLjujocW6gxp12AZwbYBFGvnifA9kS5pQ-TtcjSsVhXgoMQhlsuZCKhuyQqGSf4IKSqvwEmPwLSoPkDs5ffFWj1LYyE-HWG7Qpasyz1KfveJ2fcaKW_nmranY1yPBzfDlWGkyugHG4Su0-YSNrJaGjGlevulRAkG26syTn7VZ0iUhOXO0atlLMPo6Fnvj5eZ_Kv0cYw6cJjke4OyMP6nnmxXng8e_EGRybmdeirO30xtRUck',
    ),
  ];

  final List<User> _users = [
    User(
      name: 'Alex Johnson',
      status: 'Available',
      isOnline: true,
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    ),
    User(
      name: 'Sarah Miller',
      status: 'At work',
      isOnline: true,
      imageUrl: 'https://images.unsplash.com/photo-1494790108755-2616b786d4d2?w=200',
    ),
    User(
      name: 'Michael Chen',
      status: 'Online',
      isOnline: true,
      imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
    ),
    User(
      name: 'Emma Wilson',
      status: 'Last seen 2h ago',
      isOnline: false,
      imageUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
    ),
    User(
      name: 'Robert Garcia',
      status: 'Available',
      isOnline: true,
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
    ),
    User(
      name: 'Lisa Taylor',
      status: 'Away',
      isOnline: false,
      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
    ),
    User(
      name: 'David Kim',
      status: 'Busy',
      isOnline: true,
      imageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200',
    ),
    User(
      name: 'Sophia Lee',
      status: 'Online',
      isOnline: true,
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    ),
  ];

  void _handleTabChange(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  void _handleSearch() {
    // Implement search functionality
  }

  void _handleMoreOptions() {
    // Show more options menu
  }

  void _handleNewChat() {
    // Create new chat
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
                // App Bar
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // App Title
                      Text(
                        'ChatiFy',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Plus Jakarta Sans',
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
                        ],
                      ),
                    ],
                  ),
                ),

                // Tabs
                Row(
                  children: [
                    // Chats Tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _handleTabChange(0),
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'CHATS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w500,
                                color: _selectedTab == 0 ? Colors.white : Colors.white.withOpacity(0.7),
                                fontFamily: 'Plus Jakarta Sans',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Users Tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _handleTabChange(1),
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'USERS', // Changed from "STATUS"
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w500,
                                color: _selectedTab == 1 ? Colors.white : Colors.white.withOpacity(0.7),
                                fontFamily: 'Plus Jakarta Sans',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Calls Tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _handleTabChange(2),
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTab == 2 ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'CALLS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedTab == 2 ? FontWeight.w700 : FontWeight.w500,
                                color: _selectedTab == 2 ? Colors.white : Colors.white.withOpacity(0.7),
                                fontFamily: 'Plus Jakarta Sans',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0: // Chats
        return _buildChatsList();
      case 1: // Users
        return _buildUsersList();
      case 2: // Calls
        return _buildCallsList();
      default:
        return _buildChatsList();
    }
  }

  Widget _buildChatsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      itemCount: _chats.length,
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemBuilder: (context, index) {
        final chat = _chats[index];
        return GestureDetector(
          onTap: () => _handleChatTap(chat),
          child: Container(
            color: isDark ? const Color(0xFF11211F) : Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          // Avatar Container
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: chat.imageUrl != null
                                  ? Colors.transparent
                                  : chat.isGroup ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
                              image: chat.imageUrl != null
                                  ? DecorationImage(
                                image: NetworkImage(chat.imageUrl!),
                                fit: BoxFit.cover,
                              )
                                  : null,
                            ),
                            child: chat.imageUrl == null && chat.initials != null
                                ? Center(
                              child: Text(
                                chat.initials!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                                : null,
                          ),

                          // Online Indicator
                          if (chat.isOnline && !chat.isGroup)
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

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
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
                                Text(
                                  chat.time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: chat.unreadCount > 0
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
                                  child: Row(
                                    children: [
                                      if (chat.hasMedia)
                                        const Icon(
                                          Icons.photo_camera,
                                          size: 16,
                                          color: Color(0xFF6B7280),
                                        ),
                                      if (chat.hasMedia) const SizedBox(width: 4),
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
                                    ],
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

                // Divider
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 1,
                  color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsersList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF1A2C2A) : const Color(0xFFF8FAFC),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2D3748) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Icons.search,
                        size: 20,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search users...',
                            hintStyle: TextStyle(
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                              fontSize: 14,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF111717),
                            fontSize: 14,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Users List
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final user = _users[index];
              return GestureDetector(
                onTap: () => _handleUserTap(user),
                child: Container(
                  color: isDark ? const Color(0xFF11211F) : Colors.white,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Avatar
                            Stack(
                              children: [
                                // Avatar Container
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

                                // Online Indicator
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: user.isOnline ? const Color(0xFF25D366) : const Color(0xFF9CA3AF),
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

                            // User Info
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

                            // Action Button
                            IconButton(
                              onPressed: () => _handleUserTap(user),
                              icon: const Icon(Icons.message, size: 20),
                              color: const Color(0xFF128C7E),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF128C7E).withOpacity(0.1),
                                shape: const CircleBorder(),
                                minimumSize: const Size(36, 36),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        height: 1,
                        color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
  final bool isGroup;
  final String? imageUrl;
  final String? initials;
  final bool hasMedia;

  Chat({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
    this.isGroup = false,
    this.imageUrl,
    this.initials,
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