// lib/services/chat_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class ChatService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // GET ALL USERS (excluding current user)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      final response = await _supabase
          .from('users')
          .select()
          .neq('id', currentUserId ?? '')
          .order('display_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  // CREATE OR GET CHAT between two users
  Future<String?> createOrGetChat(String otherUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return null;

      // Check if chat already exists
      final existingChat = await _supabase
          .from('chats')
          .select('id')
          .or('and(user1_id.eq.$currentUserId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$currentUserId)')
          .maybeSingle();

      if (existingChat != null) {
        return existingChat['id'] as String;
      }

      // Create new chat
      final newChat = await _supabase
          .from('chats')
          .insert({
        'user1_id': currentUserId,
        'user2_id': otherUserId,
        'created_at': DateTime.now().toIso8601String(),
      })
          .select('id')
          .single();

      return newChat['id'] as String;
    } catch (e) {
      print('Error creating/getting chat: $e');
      return null;
    }
  }

  // GET ALL CHATS for current user
  Future<List<Map<String, dynamic>>> getUserChats() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      // Get all chats where user is participant
      final chats = await _supabase
          .from('chats')
          .select('''
            id,
            user1_id,
            user2_id,
            last_message,
            last_message_time,
            created_at
          ''')
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
          .order('last_message_time', ascending: false);

      // Get other user details for each chat
      List<Map<String, dynamic>> enrichedChats = [];

      for (var chat in chats) {
        final otherUserId = chat['user1_id'] == currentUserId
            ? chat['user2_id']
            : chat['user1_id'];

        // Get other user's profile
        final userProfile = await _supabase
            .from('users')
            .select('id, display_name, avatar_url, status, last_seen')
            .eq('id', otherUserId)
            .maybeSingle();

        if (userProfile != null) {
          // Get unread message count
          final unreadCount = await _getUnreadCount(chat['id'], currentUserId);

          enrichedChats.add({
            'chat_id': chat['id'],
            'other_user_id': otherUserId,
            'other_user_name': userProfile['display_name'],
            'other_user_avatar': userProfile['avatar_url'],
            'other_user_status': userProfile['status'],
            'last_seen': userProfile['last_seen'],
            'last_message': chat['last_message'],
            'last_message_time': chat['last_message_time'],
            'unread_count': unreadCount,
          });
        }
      }

      return enrichedChats;
    } catch (e) {
      print('Error getting user chats: $e');
      return [];
    }
  }

  // GET UNREAD MESSAGE COUNT
  Future<int> _getUnreadCount(String chatId, String userId) async {
    try {
      final count = await _supabase
          .from('messages')
          .select('id')
          .eq('chat_id', chatId)
          .neq('sender_id', userId)
          .eq('is_read', false)
          .count();

      return count.count;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // SEND MESSAGE
  Future<bool> sendMessage({
    required String chatId,
    required String content,
    String messageType = 'text',
    String? mediaUrl,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      // Insert message
      await _supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': currentUserId,
        'content': content,
        'message_type': messageType,
        'media_url': mediaUrl,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update chat's last message
      await _supabase.from('chats').update({
        'last_message': content,
        'last_message_time': DateTime.now().toIso8601String(),
      }).eq('id', chatId);

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // LISTEN TO MESSAGES (Real-time)
  Stream<List<Map<String, dynamic>>> listenToMessages(String chatId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map((data) {
      return List<Map<String, dynamic>>.from(data);
    });
  }

  // MARK MESSAGES AS READ
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // DELETE MESSAGE
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_deleted': true})
          .eq('id', messageId);
      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  // UPDATE TYPING STATUS
  Future<void> updateTypingStatus(String chatId, bool isTyping) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Upsert typing status
      await _supabase.from('typing_status').upsert({
        'chat_id': chatId,
        'user_id': currentUserId,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  // LISTEN TO TYPING STATUS
// LISTEN TO TYPING STATUS
  Stream<bool> listenToTypingStatus(String chatId, String otherUserId) {
    return _supabase
        .from('typing_status')
        .stream(primaryKey: ['chat_id', 'user_id'])
        .map((data) {
      // Filter the data for the specific chat and user
      final filtered = data.where((item) =>
      item['chat_id'] == chatId &&
          item['user_id'] == otherUserId
      ).toList();

      if (filtered.isEmpty) return false;
      return filtered.first['is_typing'] as bool? ?? false;
    });
  }

  // SEARCH MESSAGES in a chat
  Future<List<Map<String, dynamic>>> searchMessages(String chatId, String query) async {
    try {
      final messages = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .ilike('content', '%$query%')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(messages);
    } catch (e) {
      print('Error searching messages: $e');
      return [];
    }
  }

  // GET CHAT DETAILS
  Future<Map<String, dynamic>?> getChatDetails(String chatId) async {
    try {
      final chat = await _supabase
          .from('chats')
          .select()
          .eq('id', chatId)
          .single();

      return chat;
    } catch (e) {
      print('Error getting chat details: $e');
      return null;
    }
  }
}