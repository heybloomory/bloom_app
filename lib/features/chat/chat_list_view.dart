import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_thread_screen.dart';

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text(
        'Please login to use chat.',
        style: TextStyle(color: Colors.white70),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: user.uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();

    return Column(
  children: [
    // 🔹 Header with New Chat button
    Row(
      children: [
        const Expanded(
          child: Text(
            'Chats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            _openNewChat(context);
          },
        ),
      ],
    ),
    const SizedBox(height: 10),

    // 🔹 Chat list
    Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Text(
              'Chat error: ${snap.error}',
              style: const TextStyle(color: Colors.white70),
            );
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Text(
              'No chats yet.\nCreate a DM or Group.',
              style: TextStyle(color: Colors.white70),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final type = data['type'] ?? 'dm';
              final title = type == 'group'
                  ? (data['title'] ?? 'Group')
                  : 'Direct Message';

              return ListTile(
                title: Text(title, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  data['lastMessageText'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => ChatThreadScreen(
                        conversationId: d.id,
                        title: title,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    ),
  ],
);

  }
}


void _openNewChat(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _NewChatSheet(),
  );
}


class _NewChatSheet extends StatelessWidget {
  const _NewChatSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text('New Direct Message',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _createDM(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.group, color: Colors.white),
            title: const Text('New Group',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _createGroup(context);
            },
          ),
        ],
      ),
    );
  }
}

Future<void> _createDM(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final otherUserId = 'PASTE_OTHER_USER_UID_HERE'; // TEMP

  final ids = [user.uid, otherUserId]..sort();
  final convoId = 'dm_${ids[0]}_${ids[1]}';

  final ref =
      FirebaseFirestore.instance.collection('conversations').doc(convoId);

  final snap = await ref.get();
  if (!snap.exists) {
    await ref.set({
      'type': 'dm',
      'participants': ids,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageText': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }
}

Future<void> _createGroup(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final ref = FirebaseFirestore.instance.collection('conversations').doc();

  await ref.set({
    'type': 'group',
    'title': 'New Group',
    'participants': [user.uid], // add more later
    'createdAt': FieldValue.serverTimestamp(),
    'lastMessageText': '',
    'lastMessageAt': FieldValue.serverTimestamp(),
  });
}
