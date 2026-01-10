import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/language_service.dart';
import '../../../viewmodels/league_detail_viewmodel.dart';

class ParticipantsTab extends StatefulWidget {
  const ParticipantsTab({super.key});

  @override
  State<ParticipantsTab> createState() => _ParticipantsTabState();
}

class _ParticipantsTabState extends State<ParticipantsTab> {
  final TextEditingController _addCtrl = TextEditingController();

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LeagueDetailViewModel>();
    final players = vm.league.players;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: players.length + 1,
      itemBuilder: (_, i) {
        if (i < players.length) {
          final p = players[i];
          return PlayerCard(
            name: p.name,
            avatarPath: p.avatarPath,
            onAvatarTap: () => vm.showAvatarOptions(context, p.playerId),
            onTap: () => vm.showDeletePlayerDialog(context, p.playerId),
          );
        } else {
          return AddPlayerCard(
            controller: _addCtrl,
            onAdd: () {
              final name = _addCtrl.text.trim();
              if (name.isEmpty) return;
              vm.addPlayer(playerId: DateTime.now().microsecondsSinceEpoch, name: name);
              _addCtrl.clear();
            },
          );
        }
      },
    );
  }
}

class PlayerCard extends StatelessWidget {
  final String name;
  final String? avatarPath;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;

  const PlayerCard({
    super.key,
    required this.name,
    required this.avatarPath,
    required this.onTap,
    required this.onAvatarTap,
  });

  ImageProvider? _avatarImage() {
    if (avatarPath == null) return null;
    if (avatarPath!.startsWith('assets/')) return AssetImage(avatarPath!);
    final f = File(avatarPath!);
    if (f.existsSync()) return FileImage(f);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final img = _avatarImage();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x2EFFFFFF), // white with 18% opacity
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x59FFFFFF)), // white with 35% opacity
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onAvatarTap,
              child: CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0x40FFFFFF), // white with 25% opacity
                backgroundImage: img,
                child: img == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(1, 1))],
                ),
              ),
            ),
            Icon(
              Icons.touch_app,
              color: const Color(0xB3FFFFFF), // white with 70% opacity
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class AddPlayerCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const AddPlayerCard({super.key, required this.controller, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x59FFFFFF)), // white with 35% opacity
        color: const Color(0x1FFFFFFF), // white with 12% opacity
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0x40FFFFFF), // white with 25% opacity
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: Provider.of<LanguageService>(context).translate('add_player_dots_hint'),
                hintStyle: const TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => onAdd(),
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
