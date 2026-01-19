/// Chat Hive Model
/// 
/// Hive-compatible data model for offline chat message storage.
/// Stores conversation history locally for offline access.
/// 
/// Features:
/// - Message history persistence
/// - Offline chat functionality
/// - Simple key-value message structure
import 'package:hive/hive.dart';
part 'chat_hive.g.dart';

/// Hive-annotated chat model for local storage
/// 
/// TypeId: 2 - Unique identifier for Hive type system
@HiveType(typeId: 2)
class ChatHive extends HiveObject {
  /// Unique chat/conversation identifier
  @HiveField(0)
  String id;
  
  /// List of messages (each message as key-value pairs)
  @HiveField(1)
  List<Map<String, String>> messages;

  ChatHive({required this.id, required this.messages});
}
