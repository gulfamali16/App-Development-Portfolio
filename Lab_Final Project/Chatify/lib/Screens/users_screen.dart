import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0; // 0: Chats, 1: Users, 2: Calls

  // Dummy chat data
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
  ];

  // Dummy users data
  final List<User> _users = [
    User(
      name: 'Alex Johnson',
      status: 'Software Developer',
      isOnline: true,
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      hasRequested: false,
    ),
    User(
      name: 'Sarah Miller',
      status: 'Product Designer',
      isOnline: true,
      imageUrl: 'https://images.unsplash.com/photo-1494790108755-2616b786d4d2?w=200',
      hasRequested: true,
    ),
    User(
      name: 'Michael Chen',
      status: 'Project Manager',
      isOnline: true,
      imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
      hasRequested: false,
    ),
    User(
      name: 'Emma Wilson',
      status: 'Marketing Specialist',
      isOnline: false,
      imageUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
      hasRequested: false,
    ),
    User(
      name: 'Robert Garcia',
      status: 'UX Researcher',
      isOnline: true,
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
      hasRequested: false,
    ),
    User(
      name: 'Lisa Taylor',
      status: 'Frontend Developer',
      isOnline: false,
      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
      hasRequested: true,
    ),
  ];

  void _handleTabChange(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  void _handleSearch() {
    // Implement search
  }

  void _handleMoreOptions() {
    // Show more options
  }

  void _handleNewChat() {
    // Create new chat
  }

  void _handleSendRequest(int userIndex) {
    setState(() {
      _users[userIndex].hasRequested = true;
    });
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message request sent to ${_users[userIndex].name}'),
        backgroundColor: const Color(0xFF128C7E),
      ),
    );
  }

  void _handleCancelRequest(int userIndex) {
    setState(() {
      _users[userIndex].hasRequested = false;
    });
    // Show cancellation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request cancelled for ${_users[userIndex].name}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF128C7E);

    return Scaffold(
      body: Column(
        children: [
          // Header with exact same design
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              border: isDark
                  ? const Border(bottom: BorderSide(color: Color(0xFF374151), width: 1))
                  : null,
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
                // App Bar - exact same design
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
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
                              padding: EdgeInsets.zero,
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
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tabs - exact same design
                Row(
                  children: [
                    // Chats Tab
                    _buildTab(
                      index: 0,
                      label: 'CHATS',
                      isDark: isDark,
                      isActive: _selectedTab == 0,
                    ),

                    // Users Tab (replaced Status)
                    _buildTab(
                      index: 1,
                      label: 'USERS',
                      isDark: isDark,
                      isActive: _selectedTab == 1,
                    ),

                    // Calls Tab
                    _buildTab(
                      index: 2,
                      label: 'CALLS',
                      isDark: isDark,
                      isActive: _selectedTab == 2,
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
              child: _selectedTab == 0
                  ? _buildChatsList(isDark)
                  : _selectedTab == 1
                  ? _buildUsersList(isDark)
                  : _buildCallsList(isDark),
            ),
          ),
        ],
      ),

      // Floating Action Button - exact same design
      floatingActionButton: FloatingActionButton(
        onPressed: _handleNewChat,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 8,
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.chat_bubble, size: 26),
            Positioned(
              top: 12,
              right: 12,
              child: Icon(Icons.add, size: 14, color: Colors.white),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
    required bool isDark,
    required bool isActive,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTabChange(index),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
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
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                    fontFamily: 'Plus Jakarta Sans',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatsList(bool isDark) {
    return ListView.builder(
      itemCount: _chats.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        final chat = _chats[index];
        return Material(
          color: isDark ? const Color(0xFF11211F) : Colors.white,
          child: InkWell(
            onTap: () {
              // Navigate to chat
            },
            splashColor: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF3F4F6),
            highlightColor: isDark
                ? Colors.white.withOpacity(0.02)
                : const Color(0xFFF9FAFB),
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
                      // Avatar
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

                      // Online indicator
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

                  // Chat info
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
                              child: Row(
                                children: [
                                  if (chat.hasMedia)
                                    const Icon(
                                      Icons.photo_camera,
                                      size: 16,
                                      color: Color(0xFF6B7280),
                                    ),
                                  if (chat.hasMedia) const SizedBox(width: 6),
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
          ),
        );
      },
    );
  }

  Widget _buildUsersList(bool isDark) {
    return ListView.builder(
      itemCount: _users.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        final user = _users[index];
        return Material(
          color: isDark ? const Color(0xFF11211F) : Colors.white,
          child: InkWell(
            onTap: () {
              // View user profile
            },
            splashColor: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF3F4F6),
            highlightColor: isDark
                ? Colors.white.withOpacity(0.02)
                : const Color(0xFFF9FAFB),
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
                      // Avatar
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

                      // Online indicator
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

                  // User info
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Request button
                  if (!user.hasRequested)
                    ElevatedButton(
                      onPressed: () => _handleSendRequest(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF128C7E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Request',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => _handleCancelRequest(index),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF128C7E)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Requested',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF128C7E),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCallsList(bool isDark) {
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
  bool hasRequested;

  User({
    required this.name,
    required this.status,
    required this.isOnline,
    required this.imageUrl,
    this.hasRequested = false,
  });
}