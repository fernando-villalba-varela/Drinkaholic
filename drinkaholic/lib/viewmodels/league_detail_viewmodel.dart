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
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class LeagueDetailViewModel extends ChangeNotifier {
  final League league;
  final LeagueListViewModel listVM;
  final AvatarService avatarService = AvatarService();

  LeagueDetailViewModel(this.league, this.listVM);

  void addPlayer({required int playerId, required String name, String? avatar}) {
    league.players.add(LeaguePlayerStats(playerId: playerId, name: name, avatarPath: avatar));
    listVM.refresh();
    notifyListeners();
  }

  Map<int, String> recordMatch(Map<int, int> drinksMap, LanguageService languageService) {
    final Map<int, String> streakMessages = {};

    if (drinksMap.isEmpty) return streakMessages;

    final maxVal = drinksMap.values.reduce((a, b) => a > b ? a : b);
    final minVal = drinksMap.values.reduce((a, b) => a < b ? a : b);

    List<int> mvpIds = drinksMap.entries.where((e) => e.value == maxVal).map((e) => e.key).toList();
    List<int> ratitaIds = drinksMap.entries.where((e) => e.value == minVal).map((e) => e.key).toList();

    if (mvpIds.length > 1) mvpIds = [_tieBreaker(mvpIds)];
    if (ratitaIds.length > 1) ratitaIds = [_tieBreaker(ratitaIds)];

    final mvpId = mvpIds.first;
    final ratitaId = ratitaIds.first;

    // Detectar rachas de MVP consecutivos
    if (league.currentMvpStreak == mvpId) {
      league.mvpStreakCount++;
    } else {
      league.currentMvpStreak = mvpId;
      league.mvpStreakCount = 1;
    }

    // Detectar rachas de Ratita consecutivas
    if (league.currentRatitaStreak == ratitaId) {
      league.ratitaStreakCount++;
    } else {
      league.currentRatitaStreak = ratitaId;
      league.ratitaStreakCount = 1;
    }

    // Generar mensajes para rachas de MVP (2 o más victorias consecutivas)
    if (league.mvpStreakCount >= 2) {
      final mvpPlayer = league.players.firstWhere((p) => p.playerId == mvpId);
      streakMessages[mvpId] = languageService.translate('mvp_streak_message')
          .replaceAll('{name}', mvpPlayer.name)
          .replaceAll('{count}', league.mvpStreakCount.toString());
    }

    // Generar mensajes para rachas de Ratita (2 o más derrotas consecutivas)
    if (league.ratitaStreakCount >= 2) {
      final ratitaPlayer = league.players.firstWhere((p) => p.playerId == ratitaId);
      streakMessages[ratitaId] = languageService.translate('ratita_streak_message')
          .replaceAll('{name}', ratitaPlayer.name)
          .replaceAll('{count}', league.ratitaStreakCount.toString());
    }

    for (final p in league.players) {
      final drinks = drinksMap[p.playerId];

      // Solo procesar jugadores que participaron en la partida
      if (drinks == null) continue;

      final isMvp = p.playerId == mvpId;
      final isRatita = p.playerId == ratitaId;

      // Solo aplicar los tragos base del juego, sin bonificaciones que afecten el scoreboard
      p.applyGame(
        drinks: drinks,
        isMvp: isMvp,
        isRatita: isRatita,
        bonusDrinks: 0, // No agregar bonificaciones al scoreboard
      );

      // Sistema de puntos simple y claro
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

    return streakMessages;
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
        backgroundColor: const Color(0xF200C9FF), // 00C9FF with 95% opacity
          title: Text(
            Provider.of<LanguageService>(context, listen: false).translate('avatar_photo_title'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.collections, color: Colors.white),
              title: Text(Provider.of<LanguageService>(context, listen: false).translate('choose_avatar_option'), style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _chooseAvatar(context, playerId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: Text(Provider.of<LanguageService>(context, listen: false).translate('take_photo_option'), style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _takePhoto(context, playerId);
              },
            ),
            if (league.players.firstWhere((p) => p.playerId == playerId).avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.white),
                title: Text(Provider.of<LanguageService>(context, listen: false).translate('remove_avatar_option'), style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  final p = league.players.firstWhere((e) => e.playerId == playerId);
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
            child: Text(Provider.of<LanguageService>(context, listen: false).translate('cancel'), style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseAvatar(BuildContext context, int playerId) async {
    try {
      final manifestContent = await rootBundle.loadString('assets/avatar_manifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final List<String> assets = [];
      if (manifestMap.containsKey('avatars')) {
        assets.addAll(List<String>.from(manifestMap['avatars']));
      }
      if (assets.isEmpty) return;
      assets.sort();
      final used = league.players
          .where((p) => p.avatarPath != null && p.playerId != playerId)
          .map((p) => p.avatarPath!)
          .toSet();
      final selected = await showDialog<String>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xF200C9FF), // 00C9FF with 95% opacity
          title: Text(
            Provider.of<LanguageService>(context, listen: false).translate('choose_avatar_dialog_title'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                final current = league.players.firstWhere((p) => p.playerId == playerId).avatarPath == path;
                return GestureDetector(
                  onTap: isUsed && !current ? null : () => Navigator.pop(context, path),
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
                            ? const ColorFilter.mode(
                                Color(0xA6000000), // black with 65% opacity
                                BlendMode.darken,
                              )
                            : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
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
              child: Text(Provider.of<LanguageService>(context, listen: false).translate('cancel'), style: const TextStyle(color: Colors.white70)),
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
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 60);
    if (photo == null) return;
    final p = league.players.firstWhere((e) => e.playerId == playerId);
    p.avatarPath = photo.path;
    listVM.refresh();
    notifyListeners();
  }
  // === FIN AVATAR / FOTO ===

  Future<void> changeAvatar({required BuildContext context, required int playerId}) async {
    final player = league.players.firstWhere((p) => p.playerId == playerId);
    final used = league.players
        .where((p) => p.avatarPath != null && p.playerId != playerId)
        .map((p) => p.avatarPath!)
        .toSet();
    final selected = await avatarService.pickAvatarFromAssets(context: context, used: used, current: player.avatarPath);
    if (selected != null) {
      player.avatarPath = selected;
      listVM.refresh();
      notifyListeners();
    }
  }

  Future<void> takePhotoAvatar({required BuildContext context, required int playerId}) async {
    final file = await avatarService.takePhoto(context);
    if (file != null) {
      final p = league.players.firstWhere((e) => e.playerId == playerId);
      p.avatarPath = file.path;
      listVM.refresh();
      notifyListeners();
    }
  }

  Future<void> deleteAvatar({required BuildContext context, required int playerId}) async {
    final p = league.players.firstWhere((e) => e.playerId == playerId);
    final ok = await avatarService.confirmDelete(context: context, title: 'Eliminar avatar de ${p.name}?');
    if (ok) {
      p.avatarPath = null;
      listVM.refresh();
      notifyListeners();
    }
  }

  // === DELETE PLAYER ===
  void showDeletePlayerDialog(BuildContext context, int playerId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(Provider.of<LanguageService>(context, listen: false).translate('delete_player_title')),
        content: Text(Provider.of<LanguageService>(context, listen: false).translate('confirm_delete_player_dialog_content')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(Provider.of<LanguageService>(context, listen: false).translate('cancel'))),
          TextButton(
            onPressed: () {
              league.players.removeWhere((p) => p.playerId == playerId);
              listVM.refresh();
              notifyListeners();
              Navigator.pop(context);
            },
            child: Text(Provider.of<LanguageService>(context, listen: false).translate('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // === EXPORT LEAGUE ===
  void showExportDialog(BuildContext context) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(league.toJson());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(Provider.of<LanguageService>(context, listen: false).translate('export_league_title')),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: SelectableText(jsonString)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Navigator.pop(context);
            },
            child: Text(Provider.of<LanguageService>(context, listen: false).translate('copy_button')),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(Provider.of<LanguageService>(context, listen: false).translate('close_button'))),
        ],
      ),
    );
  }

  /// Guarda los cambios de la liga y notifica a los observadores
  void saveLeague() {
    listVM.refresh(); // Actualiza la lista de ligas
    notifyListeners(); // Notifica los cambios locales
  }
}

final ImagePicker _picker = ImagePicker();
