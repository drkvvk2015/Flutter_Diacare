import 'package:hive_flutter/hive_flutter.dart';
import '../models/patient_hive.dart';
import '../models/appointment_hive.dart';
import '../models/chat_hive.dart';

Future<void> initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(PatientHiveAdapter());
  Hive.registerAdapter(AppointmentHiveAdapter());
  Hive.registerAdapter(ChatHiveAdapter());
  await Hive.openBox<PatientHive>('patients');
  await Hive.openBox<AppointmentHive>('appointments');
  await Hive.openBox<ChatHive>('chats');
}
