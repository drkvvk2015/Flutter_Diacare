import 'package:hive/hive.dart';
part 'chat_hive.g.dart';

@HiveType(typeId: 2)
class ChatHive extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  List<Map<String, String>> messages;

  ChatHive({required this.id, required this.messages});
}
