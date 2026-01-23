import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/appointment_hive.dart';
import '../models/chat_hive.dart';
import '../models/patient_hive.dart';

/// Initialize Hive for local caching
/// Works on all platforms including web
Future<void> initHive() async {
  try {
    await Hive.initFlutter();
    
    // Register adapters only once
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PatientHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppointmentHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ChatHiveAdapter());
    }
    
    // Open boxes
    await Hive.openBox<PatientHive>('patients');
    await Hive.openBox<AppointmentHive>('appointments');
    await Hive.openBox<ChatHive>('chats');
    await Hive.openBox<dynamic>('app_settings');
    
    debugPrint('[Hive] Initialized successfully');
  } catch (e) {
    debugPrint('[Hive] Initialization error: $e');
    // Continue app execution even if Hive fails
  }
}
