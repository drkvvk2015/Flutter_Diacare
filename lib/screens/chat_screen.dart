import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart' as selector;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/chat_hive.dart';
import '../utils/logger.dart';
// Removed unnecessary dart:ui import (all symbols via material.dart)

import '../widgets/glassmorphic_card.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> messages = [];
  final TextEditingController messageController = TextEditingController();
  bool showError = false;
  bool isGeneral = false; // false = patient chat, true = general chat
  String? patientId;
  String? doctorId;
  String? chatDocId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    isGeneral = args?['general'] == true;
    final user = FirebaseAuth.instance.currentUser;
    if (args?['patient'] != null) {
      patientId = args?['patient'].id as String?;
      doctorId = args?['doctorId'] as String? ?? user?.uid;
      chatDocId = 'chat_${doctorId}_$patientId';
    } else {
      doctorId = user?.uid;
      chatDocId = 'chat_general_$doctorId';
    }
    loadMessages();
  }

  Future<void> loadMessages() async {
    if (chatDocId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatDocId)
          .get();
      if (doc.exists && doc.data() != null && doc.data()!['messages'] != null) {
        if (!mounted) return;
        setState(() {
          messages.clear();
          messages.addAll(
            List<Map<String, String>>.from(doc.data()!['messages'] as List? ?? []),
          );
        });
        // Cache in Hive
        final box = Hive.box<ChatHive>('chats');
        box.put(
          chatDocId,
          ChatHive(
            id: chatDocId!,
            messages: List<Map<String, String>>.from(doc.data()!['messages'] as List? ?? []),
          ),
        );
        return;
      }
    } catch (e) {
      // Firestore failed, try Hive
      logWarn('Firestore chat error: $e');
    }
    // Load from Hive
    try {
      final box = Hive.box<ChatHive>('chats');
      final chat = box.get(chatDocId);
      if (chat != null) {
        if (!mounted) return;
        setState(() {
          messages.clear();
          messages.addAll(chat.messages);
        });
      }
    } catch (e) {
      // No messages found
    }
  }

  Future<void> sendMessage({String? filePath}) async {
    if (messageController.text.isNotEmpty || filePath != null) {
      final msg = {
        'text': messageController.text,
        'file': filePath ?? '',
        'sender': FirebaseAuth.instance.currentUser?.uid ?? 'me',
        'timestamp': DateTime.now().toIso8601String(),
      };
      if (!mounted) return; // ensure safe
      setState(() {
        messages.add(msg);
        messageController.clear();
        showError = false;
      });
      if (chatDocId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatDocId)
              .set({'messages': messages}, SetOptions(merge: true));
        } catch (e) {
          logWarn('Failed to write chat to Firestore (will rely on Hive): $e');
        }
        // Always update Hive
        try {
          final box = Hive.box<ChatHive>('chats');
          box.put(
            chatDocId,
            ChatHive(
              id: chatDocId!,
              messages: List<Map<String, String>>.from(messages),
            ),
          );
        } catch (e) {
          logError('Failed to cache chat locally: $e');
        }
      }
    } else {
      if (!mounted) return;
      setState(() => showError = true);
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => showError = false);
      });
    }
  }

  Future<void> pickFile() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        const typeGroup = selector.XTypeGroup(label: 'files');
        final file = await selector.openFile(acceptedTypeGroups: [typeGroup]);
        if (file != null) {
          await sendMessage(filePath: file.path);
        }
      } else {
        final result = await FilePicker.platform.pickFiles();
        if (result != null && result.files.single.path != null) {
          await sendMessage(filePath: result.files.single.path);
        }
      }
    } catch (e) {
      logError('File pick failed: $e');
    }
  }

  void _onChatTypeChanged(bool newIsGeneral) {
    if (newIsGeneral == isGeneral) return; // no change
    // Navigate to the correct chat flavor; mimic old Radio handlers
    final navigator = Navigator.of(context);
    if (newIsGeneral) {
      navigator.pushReplacementNamed('/chat', arguments: {'general': true});
    } else {
      if (patientId != null) {
        navigator.pushReplacementNamed(
          '/chat',
          arguments: {
            'patient': {'id': patientId},
            'doctorId': doctorId,
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        Colors.teal.shade400,
        Colors.blue.shade200,
        Colors.purple.shade200,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Hero(
          tag: 'chat-appbar',
          child: Material(
            color: Colors.transparent,
            child: Text(
              'Secure Chat',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Replaced deprecated Radio widgets with SegmentedButton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Patient'),
                  icon: Icon(Icons.person),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('General'),
                  icon: Icon(Icons.public),
                ),
              ],
              selected: {isGeneral},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                final selected = selection.first;
                _onChatTypeChanged(selected);
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Vibrant animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(gradient: gradient),
          ),
          Column(
            children: [
              if (showError)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    key: const ValueKey('error'),
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Cannot send empty message',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: ListView.builder(
                    key: ValueKey(messages.length),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['sender'] == 'me';
                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Semantics(
                          label: isMe ? 'Your message' : 'Other user message',
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: GlassmorphicCard(
                              borderRadius: 20,
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.32)
                                  : Colors.black.withValues(alpha: 0.18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (msg['file'] != null &&
                                      msg['file']!.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.attach_file,
                                          color: Colors.teal,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            msg['file']!.split('/').last,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (msg['text'] != null &&
                                      msg['text']!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 2,
                                        bottom: 2,
                                      ),
                                      child: Text(msg['text']!),
                                    ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        isMe ? 'You' : 'Other',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: GlassmorphicCard(
                  borderRadius: 32,
                  child: Row(
                    children: [
                      Semantics(
                        label: 'Attach file',
                        child: IconButton(
                          icon: const Icon(Icons.attach_file),
                          onPressed: pickFile,
                          tooltip: 'Attach file',
                        ),
                      ),
                      Expanded(
                        child: Semantics(
                          label: 'Type a message',
                          child: TextField(
                            controller: messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => sendMessage(),
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'Send message',
                        child: IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.send,
                              key: ValueKey(messageController.text.isNotEmpty),
                            ),
                          ),
                          onPressed: sendMessage,
                          tooltip: 'Send',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

