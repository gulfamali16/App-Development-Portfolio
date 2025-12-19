import 'package:flutter/material.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  int _selectedCallType = 0; // 0: All Calls, 1: Missed Calls
  final List<Call> _allCalls = [];
  final List<Call> _missedCalls = [];

  @override
  void initState() {
    super.initState();
    _loadCalls();
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
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBCnRb2Mq5BI-x21XrehQHNqLBzJwdwCYtyy7kJy5BkfYFDa1EW43PklT_OJK7HM0Gruv575uvfn-1IG0oAvkcdVSPbDt6rzNNsU8GABjgzSAeBo-BOCjJ3EI3WgAbDWeUbhfIMc_1U8KyR568FKtPFJlF68UgCFfsCs0rx6utPJZiuliZ7QkHXQ2sesamk3ocREcr5bV6mMtLoYMzYf0ZOdXsCQhC1XV0_xW_5HF28e9960pgugEn-VHugF4PwkwhpiPvERDo46pE',
      ),
      Call(
        name: 'Mom',
        time: 'Yesterday, 9:15 PM',
        date: 'Yesterday',
        isMissed: true,
        isOutgoing: false,
        callType: CallType.video,
        duration: 'Missed',
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3gsq_YZcE76khx9qF8zkD1yUzkzbW9K_KTQ5mSxIiVcGBTHPezBJ9ppl65PPk9-8bKx5ZoIJD5qWDHalWDr0Klrb33pfyGycygxGJp4e6Zxjj4bYS-lrRSVD2RmdOoDH5_CNpPXCTIiaAwFGp7sU7Y5bb7W0p4OLPIx3mVAogkxORdQPPssXgyu5szxdbRWu0Hxl2UvECN9pQUoVkjHUn8sL5eIekXd-0lcCc1-UwgFGyj7fxWkcos9kzdqb0d0yqoaD-wx2_eVs',
      ),
      Call(
        name: 'John Smith',
        time: 'Dec 12, 2:45 PM',
        date: 'Dec 12',
        isMissed: false,
        isOutgoing: true,
        callType: CallType.voice,
        duration: '12:45',
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCWWGWzmwrnr0votvth7E8VpaN_dVKGJcxOtoOG0X_Y-FxmKRCeAPp5cbqrWDgV6a-CYsP6fCN_HKwmOmeItPI667XUjz5fEkCDrFdVTtYqL9wnvTJyHzeYjx1O-rofzXkAYwHoytVX9C1Pe30t2O7a_07G5eEnlwNbhR3R3Ckz7xyEKmS-bkLYKc0DlP028ji50jaf-FiUbyeKbUyQcXVkwNqJJ-SEAbBk-OtIRXdT2z7MhoMM6EJ7ZsnrNwNpJ0RCyz3jAGSLJTU',
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
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDnmTJAWmhFXUQdTjoqhXqp5iynF9OnLjujocW6gxp12AZwbYBFGvnifA9kS5pQ-TtcjSsVhXgoMQhlsuZCKhuyQqGSf4IKSqvwEmPwLSoPkDs5ffFWj1LYyE-HWG7Qpasyz1KfveJ2fcaKW_nmranY1yPBzfDlWGkyugHG4Su0-YSNrJaGjGlevulRAkG26syTn7VZ0iUhOXO0atlLMPo6Fnvj5eZ_Kv0cYw6cJjke4OyMP6nnmxXng8e_EGRybmdeirO30xtRUck',
      ),
      Call(
        name: 'Alex Johnson',
        time: 'Dec 9, 3:15 PM',
        date: 'Dec 9',
        isMissed: false,
        isOutgoing: true,
        callType: CallType.video,
        duration: '7:22',
        imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      ),
      Call(
        name: 'Sarah Miller',
        time: 'Dec 8, 10:45 AM',
        date: 'Dec 8',
        isMissed: true,
        isOutgoing: false,
        callType: CallType.voice,
        duration: 'Missed',
        imageUrl: 'https://images.unsplash.com/photo-1494790108755-2616b786d4d2?w=200',
      ),
      Call(
        name: 'Michael Chen',
        time: 'Dec 7, 5:20 PM',
        date: 'Dec 7',
        isMissed: false,
        isOutgoing: true,
        callType: CallType.video,
        duration: '15:30',
        imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
      ),
    ]);

    // Filter missed calls
    _missedCalls.addAll(_allCalls.where((call) => call.isMissed));
  }

  void _handleCallBack(Call call) {
    // Implement call back functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${call.name}...'),
        backgroundColor: const Color(0xFF128C7E),
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
      return Text(
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
          // Header with Tabs
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF11211F) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                
                // Segmented Control
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2C2A) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
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
                                    ? primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'All Calls',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedCallType == 0
                                        ? Colors.white
                                        : isDark ? Colors.white : const Color(0xFF374151),
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
                                    ? primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
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
                                            ? Colors.white
                                            : isDark ? Colors.white : const Color(0xFF374151),
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                  ),
                                  if (_missedCalls.isNotEmpty && _selectedCallType != 1)
                                    Positioned(
                                      top: 8,
                                      right: 16,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
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
                
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Calls List
          Expanded(
            child: currentCalls.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    itemCount: currentCalls.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      final call = currentCalls[index];
                      return _buildCallItem(call, index, _selectedCallType == 1);
                    },
                  ),
          ),
        ],
      ),
      
      // Floating Action Button for New Call
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

  Widget _buildCallItem(Call call, int index, bool isMissedSection) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: isDark ? const Color(0xFF11211F) : Colors.white,
      child: InkWell(
        onTap: () => _handleCallBack(call),
        onLongPress: () => _handleDeleteCall(index, isMissedSection),
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
              // Call Type Icon
              Container(
                width: 40,
                height: 40,
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
                  size: 20,
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
                            child: Text(
                              'Group',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF128C7E),
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
                    decoration: BoxDecoration(
                      color: const Color(0xFF128C7E),
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
            _selectedCallType == 0 
                ? 'No calls yet' 
                : 'No missed calls',
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
          if (_selectedCallType == 1 && _allCalls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton(
                onPressed: _handleClearAllMissedCalls,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF128C7E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Clear All Missed Calls'),
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