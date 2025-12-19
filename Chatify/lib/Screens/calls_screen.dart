// lib/Screens/calls_screen.dart
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  final AuthService _authService = AuthService();
  int _selectedCallType = 0; // 0: All Calls, 1: Missed Calls
  Map<String, dynamic>? _currentUserProfile;
  bool _isLoadingProfile = true;

  final List<Call> _allCalls = [];
  final List<Call> _missedCalls = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadCalls();
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

  void _loadCalls() {
    // Sample call data
    _allCalls.addAll([
      Call(
        name: 'Jane Doe',
        time: '10:30 AM',
        date: 'Today',
        isMissed: false,
        isOutgoing: true,
        callType: CallType.voice,
        duration: '5:32',
        imageUrl: 'https://i.pravatar.cc/150?img=1',
      ),
      Call(
        name: 'Mom',
        time: 'Yesterday, 9:15 PM',
        date: 'Yesterday',
        isMissed: true,
        isOutgoing: false,
        callType: CallType.video,
        duration: 'Missed',
        imageUrl: 'https://i.pravatar.cc/150?img=20',
      ),
      Call(
        name: 'John Smith',
        time: 'Dec 12, 2:45 PM',
        date: 'Dec 12',
        isMissed: false,
        isOutgoing: true,
        callType: CallType.voice,
        duration: '12:45',
        imageUrl: 'https://i.pravatar.cc/150?img=12',
      ),
      Call(
        name: 'Team Alpha',
        time: 'Dec 11, 11:20 AM',
        date: 'Dec 11',
        isMissed: false,
        isOutgoing: false,
        callType: CallType.group,
        duration: '23:18',
        isGroup: true,
        initials: 'TA',
      ),
      Call(
        name: 'David Brown',
        time: 'Dec 10, 4:30 PM',
        date: 'Dec 10',
        isMissed: true,
        isOutgoing: false,
        callType: CallType.voice,
        duration: 'Missed',
        imageUrl: 'https://i.pravatar.cc/150?img=15',
      ),
      Call(
        name: 'Alex Johnson',
        time: 'Dec 9, 3:15 PM',
        date: 'Dec 9',
        isMissed: false,
        isOutgoing: true,
        callType: CallType.video,
        duration: '7:22',
        imageUrl: 'https://i.pravatar.cc/150?img=33',
      ),
      Call(
        name: 'Sarah Miller',
        time: 'Dec 8, 10:45 AM',
        date: 'Dec 8',
        isMissed: true,
        isOutgoing: false,
        callType: CallType.voice,
        duration: 'Missed',
        imageUrl: 'https://i.pravatar.cc/150?img=44',
      ),
      Call(
        name: 'Michael Chen',
        time: 'Dec 7, 5:20 PM',
        date: 'Dec 7',
        isMissed: false,
        isOutgoing: true,
        callType: CallType.video,
        duration: '15:30',
        imageUrl: 'https://i.pravatar.cc/150?img=13',
      ),
    ]);

    // Filter missed calls
    _missedCalls.addAll(_allCalls.where((call) => call.isMissed));
  }

  void _handleCallBack(Call call) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${call.name}...'),
        backgroundColor: const Color(0xFF128C7E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleDeleteCall(int index, bool isMissedSection) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Call'),
          content: const Text('Are you sure you want to delete this call record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  if (isMissedSection) {
                    _missedCalls.removeAt(index);
                  } else {
                    _allCalls.removeAt(index);
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Call deleted'),
                    backgroundColor: Color(0xFF128C7E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleClearAllMissedCalls() {
    if (_missedCalls.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Missed Calls'),
          content: const Text('Are you sure you want to clear all missed calls?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _allCalls.removeWhere((call) => call.isMissed);
                  _missedCalls.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All missed calls cleared'),
                    backgroundColor: Color(0xFF128C7E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
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
              if (_selectedCallType == 1 && _missedCalls.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_sweep, color: Colors.red),
                  title: const Text('Clear All Missed Calls', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _handleClearAllMissedCalls();
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

  Widget _buildCallTypeIcon(CallType type, bool isOutgoing) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case CallType.voice:
        return Icon(
          isOutgoing ? Icons.call_made : Icons.call_received,
          size: 16,
          color: isOutgoing
              ? const Color(0xFF128C7E)
              : isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        );
      case CallType.video:
        return Icon(
          Icons.videocam,
          size: 16,
          color: isOutgoing
              ? const Color(0xFF128C7E)
              : isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        );
      case CallType.group:
        return Icon(
          Icons.group,
          size: 16,
          color: isOutgoing
              ? const Color(0xFF128C7E)
              : isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        );
    }
  }

  Widget _buildCallDuration(Call call) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (call.isMissed) {
      return const Text(
        'Missed',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.red,
          fontFamily: 'Plus Jakarta Sans',
        ),
      );
    }

    return Row(
      children: [
        _buildCallTypeIcon(call.callType, call.isOutgoing),
        const SizedBox(width: 4),
        Text(
          call.duration,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: call.isOutgoing
                ? const Color(0xFF128C7E)
                : isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF128C7E);
    final currentCalls = _selectedCallType == 0 ? _allCalls : _missedCalls;

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
                      // Back Button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 24),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          shape: const CircleBorder(),
                          minimumSize: const Size(40, 40),
                        ),
                      ),

                      // Title
                      Text(
                        'Calls',
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

                // Segmented Control
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        // All Calls Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCallType = 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _selectedCallType == 0
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Center(
                                child: Text(
                                  'All Calls',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedCallType == 0
                                        ? primaryColor
                                        : Colors.white,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Missed Calls Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCallType = 1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _selectedCallType == 1
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Text(
                                      'Missed',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedCallType == 1
                                            ? primaryColor
                                            : Colors.white,
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                  ),
                                  if (_missedCalls.isNotEmpty && _selectedCallType != 1)
                                    Positioned(
                                      top: 10,
                                      right: 20,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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

          // Calls List
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF11211F) : Colors.white,
              child: currentCalls.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                itemCount: currentCalls.length,
                padding: const EdgeInsets.only(bottom: 80),
                itemBuilder: (context, index) {
                  final call = currentCalls[index];
                  return _buildCallItem(call, index, _selectedCallType == 1, isDark);
                },
              ),
            ),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement new call functionality
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 8,
        child: const Icon(Icons.add_call, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCallItem(Call call, int index, bool isMissedSection, bool isDark) {
    return Material(
      color: isDark ? const Color(0xFF11211F) : Colors.white,
      child: InkWell(
        onTap: () => _handleCallBack(call),
        onLongPress: () => _handleDeleteCall(index, isMissedSection),
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
              // Call Type Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: call.isMissed
                      ? Colors.red.withOpacity(0.1)
                      : (call.isOutgoing
                      ? const Color(0xFF128C7E).withOpacity(0.1)
                      : isDark
                      ? const Color(0xFF2D3748)
                      : const Color(0xFFF3F4F6)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  call.callType == CallType.video ? Icons.videocam : Icons.call,
                  size: 22,
                  color: call.isMissed
                      ? Colors.red
                      : (call.isOutgoing
                      ? const Color(0xFF128C7E)
                      : isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                ),
              ),

              const SizedBox(width: 16),

              // Call Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            call.name,
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
                          call.time,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCallDuration(call),
                        if (call.isGroup)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF128C7E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Group',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF128C7E),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Call Back Button (for missed calls)
              if (call.isMissed)
                IconButton(
                  onPressed: () => _handleCallBack(call),
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF128C7E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call,
                      size: 18,
                      color: Colors.white,
                    ),
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
            _selectedCallType == 0 ? Icons.call : Icons.call_missed,
            size: 80,
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedCallType == 0 ? 'No calls yet' : 'No missed calls',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111717),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCallType == 0
                ? 'Your call history will appear here'
                : 'All clear! No missed calls',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }
}

enum CallType {
  voice,
  video,
  group,
}

class Call {
  final String name;
  final String time;
  final String date;
  final bool isMissed;
  final bool isOutgoing;
  final CallType callType;
  final String duration;
  final String? imageUrl;
  final bool isGroup;
  final String? initials;

  Call({
    required this.name,
    required this.time,
    required this.date,
    required this.isMissed,
    required this.isOutgoing,
    required this.callType,
    required this.duration,
    this.imageUrl,
    this.isGroup = false,
    this.initials,
  });
}