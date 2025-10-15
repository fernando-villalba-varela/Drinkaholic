import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart';
import '../models/league.dart';
import '../models/league_player_stats.dart';
import '../models/match_result.dart';
import 'league_list_viewmodel.dart';
import '../services/avatar_service.dart';

class LeagueDetailViewModel extends ChangeNotifier {
  final League league;
  final LeagueListViewModel listVM;
  final AvatarService avatarService = AvatarService();

  LeagueDetailViewModel(this.league, this.listVM);

  void addPlayer({
    required int playerId,
    required String name,
    String? avatar,
  }) {
    league.players.add(
      LeaguePlayerStats(playerId: playerId, name: name, avatarPath: avatar),
    );
    listVM.refresh();
    notifyListeners();
  }

  void recordMatch(Map<int, int> drinksMap) {
    if (drinksMap.isEmpty) return;
    final maxVal = drinksMap.values.reduce((a, b) => a > b ? a : b);
    final minVal = drinksMap.values.reduce((a, b) => a < b ? a : b);

    List<int> mvpIds = drinksMap.entries
        .where((e) => e.value == maxVal)
        .map((e) => e.key)
        .toList();
    List<int> ratitaIds = drinksMap.entries
        .where((e) => e.value == minVal)
        .map((e) => e.key)
        .toList();

    if (mvpIds.length > 1) mvpIds = [_tieBreaker(mvpIds)];
    if (ratitaIds.length > 1) ratitaIds = [_tieBreaker(ratitaIds)];

    final mvpId = mvpIds.first;
    final ratitaId = ratitaIds.first;

    for (final p in league.players) {
      final drinks = drinksMap[p.playerId] ?? 0;
      final isMvp = p.playerId == mvpId;
      final isRatita = p.playerId == ratitaId;
      int bonus = 0;

      if (isMvp && p.lastWasRatita) {
        for (final other in league.players.where(
          (x) => x.playerId != p.playerId,
        )) {
          other.totalDrinks += 10;
        }
      }
      if (isRatita && p.lastWasRatita) {
        bonus += 10;
      }

      p.applyGame(
        drinks: drinks,
        isMvp: isMvp,
        isRatita: isRatita,
        bonusDrinks: bonus,
      );

      if (isMvp) {
        p.points += 3;
      } else if (isRatita) {
        p.points -= 3;
      } else {
        p.points += 1;
      }
    }

    league.matches.add(
      MatchResult(
        id: const Uuid().v4(),
        leagueId: league.id,
        date: DateTime.now(),
        perPlayerDrinks: Map<int, int>.from(drinksMap),
        mvpPlayerIds: mvpIds,
        ratitaPlayerIds: ratitaIds,
      ),
    );
    listVM.refresh();
    notifyListeners();
  }

  int _tieBreaker(List<int> ids) {
    ids.shuffle();
    return ids.first;
  }

  // === AVATAR / FOTO ===
  Future<void> showAvatarOptions(BuildContext context, int playerId) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF00C9FF).withOpacity(.95),
        title: Text(
          'Avatar / Foto',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.collections, color: Colors.white),
              title: const Text(
                'Elegir avatar',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _chooseAvatar(context, playerId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                'Tomar foto',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _takePhoto(context, playerId);
              },
            ),
            if (league.players
                    .firstWhere((p) => p.playerId == playerId)
                    .avatarPath !=
                null)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.white),
                title: const Text(
                  'Quitar avatar/foto',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  final p = league.players.firstWhere(
                    (e) => e.playerId == playerId,
                  );
                  p.avatarPath = null;
                  listVM.refresh();
                  notifyListeners();
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseAvatar(BuildContext context, int playerId) async {
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> map = jsonDecode(manifest);
      final assets = map.keys
          .where(
            (k) =>
                k.startsWith('assets/avatars/') &&
                (k.endsWith('.png') ||
                    k.endsWith('.jpg') ||
                    k.endsWith('.jpeg') ||
                    k.endsWith('.gif') ||
                    k.endsWith('.webp')),
          )
          .toList();
      if (assets.isEmpty) return;
      final used = league.players
          .where((p) => p.avatarPath != null && p.playerId != playerId)
          .map((p) => p.avatarPath!)
          .toSet();
      final selected = await showDialog<String>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF00C9FF).withOpacity(.95),
          title: const Text(
            'Elegir avatar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: assets.length,
              itemBuilder: (_, i) {
                final path = assets[i];
                final isUsed = used.contains(path);
                final current =
                    league.players
                        .firstWhere((p) => p.playerId == playerId)
                        .avatarPath ==
                    path;
                return GestureDetector(
                  onTap: isUsed && !current
                      ? null
                      : () => Navigator.pop(context, path),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: current
                            ? Colors.white
                            : isUsed
                            ? Colors.redAccent
                            : Colors.white30,
                        width: current || isUsed ? 3 : 1,
                      ),
                    ),
                    child: ClipOval(
                      child: ColorFiltered(
                        colorFilter: isUsed && !current
                            ? ColorFilter.mode(
                                Colors.black.withOpacity(.65),
                                BlendMode.darken,
                              )
                            : const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.multiply,
                              ),
                        child: Image.asset(path, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
      if (selected != null) {
        final p = league.players.firstWhere((e) => e.playerId == playerId);
        p.avatarPath = selected;
        listVM.refresh();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _takePhoto(BuildContext context, int playerId) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
    );
    if (photo == null) return;
    final p = league.players.firstWhere((e) => e.playerId == playerId);
    p.avatarPath = photo.path;
    listVM.refresh();
    notifyListeners();
  }
  // === FIN AVATAR / FOTO ===

  Future<void> changeAvatar({
    required BuildContext context,
    required int playerId,
  }) async {
    final player = league.players.firstWhere((p) => p.playerId == playerId);
    final used = league.players
        .where((p) => p.avatarPath != null && p.playerId != playerId)
        .map((p) => p.avatarPath!)
        .toSet();
    final selected = await avatarService.pickAvatarFromAssets(
      context: context,
      used: used,
      current: player.avatarPath,
    );
    if (selected != null) {
      player.avatarPath = selected;
      listVM.refresh();
      notifyListeners();
    }
  }

  Future<void> takePhotoAvatar({
    required BuildContext context,
    required int playerId,
  }) async {
    final file = await avatarService.takePhoto(context);
    if (file != null) {
      final p = league.players.firstWhere((e) => e.playerId == playerId);
      p.avatarPath = file.path;
      listVM.refresh();
      notifyListeners();
    }
  }

  Future<void> deleteAvatar({
    required BuildContext context,
    required int playerId,
  }) async {
    final p = league.players.firstWhere((e) => e.playerId == playerId);
    final ok = await avatarService.confirmDelete(
      context: context,
      title: 'Eliminar avatar de ${p.name}?',
    );
    if (ok) {
      p.avatarPath = null;
      listVM.refresh();
      notifyListeners();
    }
  }
}

final ImagePicker _picker = ImagePicker();
