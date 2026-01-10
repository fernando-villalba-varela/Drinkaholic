import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  Locale _currentLocale = const Locale('es');
  
  Locale get currentLocale => _currentLocale;
  bool get isSpanish => _currentLocale.languageCode == 'es';

  static const String _storageKey = 'selected_language';

  // Singleton pattern (optional, but using Provider so mostly for static access necessity if any)
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString(_storageKey);
    if (langCode != null) {
      _currentLocale = Locale(langCode);
      notifyListeners();
    }
  }

  Future<void> toggleLanguage() async {
    if (_currentLocale.languageCode == 'es') {
      _currentLocale = const Locale('en');
    } else {
      _currentLocale = const Locale('es');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _currentLocale.languageCode);
    
    notifyListeners();
  }

  // Simple key-value map for UI strings that are not in the JSONs
  String translate(String key) {
    Map<String, Map<String, String>> _localizedValues = {
      'play_quick': {
        'es': 'JUGAR',
        'en': 'PLAY',
      },
      'play_league': {
        'es': 'MODO LIGA',
        'en': 'LEAGUE MODE',
      },
      'settings': {
        'es': 'Configuración',
        'en': 'Settings',
      },
      'players': {
        'es': 'Jugadores',
        'en': 'Players',
      },
      'active_challenges_title': {
        'es': 'Retos y Eventos Activos',
        'en': 'Active Challenges & Events',
      },
       'empty_active_challenges': {
        'es': 'No hay retos constantes activos',
        'en': 'No active constant challenges',
      },
      'empty_active_events': {
        'es': 'No hay eventos globales activos',
        'en': 'No active global events',
      },
      'endless_mode': {
        'es': 'Modo Endless',
        'en': 'Endless Mode',
      },
      'constant_challenges_title': {
        'es': '📋 Retos Constantes',
        'en': '📋 Constant Challenges',
      },
       'global_events_title': {
        'es': '🌐 Eventos Globales',
        'en': '🌐 Global Events',
      },
      'round': {
        'es': 'RONDA',
        'en': 'ROUND',
      },
       'tap_screen': {
        'es': 'TOCA LA PANTALLA',
        'en': 'TAP THE SCREEN',
      },
       'menu_reload_elixirs': {
        'es': 'Recarga tus elixires',
        'en': 'Replenish your elixirs',
      },
      'round_100_title': {
        'es': '¡Ronda 100 Completada!',
        'en': 'Round 100 Completed!',
      },
      'round_100_content': {
        'es': 'Habéis sobrevivido a la previa, ¿Queréis continuar en el MODO ENDLESS?\n\nLa dificultad aumentará cada 25 rondas (+1 trago permanente).',
        'en': 'You survived the pre-game, do you want to continue in ENDLESS MODE?\n\nDifficulty will increase every 25 rounds (+1 permanent drink).',
      },
      'end_here': {
        'es': 'Terminar aquí',
        'en': 'End here',
      },
      'continue': {
        'es': '¡Continuar!',
        'en': 'Continue!',
      },
      'drinks_per_endless': {
        'es': 'tragos en todas las cartas',
        'en': 'drinks on all cards',
      },
      'endless_modifier': {
        'es': '(+{extra} tragos por endless)',
        'en': '(+{extra} drinks for endless)',
      },
      'level': {
        'es': 'Nivel',
        'en': 'Level',
      },
      'players_title': {
        'es': 'JUGADORES',
        'en': 'PLAYERS',
      },
      'add_player_hint': {
        'es': 'Añadir jugador...',
        'en': 'Add player...',
      },
      'start_playing_button': {
        'es': '¡EMPEZAR A JUGAR!',
        'en': 'START PLAYING!',
      },
      'leagues_title': {
        'es': 'LIGAS',
        'en': 'LEAGUES',
      },
      'create_new_league_title': {
        'es': 'Crear nueva liga',
        'en': 'Create new league',
      },
      'league_name_label': {
        'es': 'Nombre de la liga',
        'en': 'League name',
      },
      'cancel': {
        'es': 'Cancelar',
        'en': 'Cancel',
      },
      'accept': {
        'es': 'Aceptar',
        'en': 'Accept',
      },
      // League Details
      'scoreboard_tab': {'es': 'Scoreboard', 'en': 'Scoreboard'},
      'players_tab': {'es': 'Jugadores', 'en': 'Players'},
      'play_tab': {'es': 'Jugar', 'en': 'Play'},
      
      // League Game
      'exit_game_title': {'es': '¿Salir del juego?', 'en': 'Exit game?'},
      'exit_game_confirmation': {'es': '¿Estás seguro de que quieres salir? Se perderá el progreso del juego.', 'en': 'Are you sure you want to exit? Game progress will be lost.'},
      'exit': {'es': 'Salir', 'en': 'Exit'},
      'round_label': {'es': 'RONDA', 'en': 'ROUND'},
      
      // Game Results
      'game_over_title': {'es': '¡Juego Terminado!', 'en': 'Game Over!'},
      'rounds_completed_text': {'es': 'Se han completado', 'en': 'Completed'}, // handled with interpolation
      'rounds': {'es': 'rondas', 'en': 'rounds'},
      'mvp_title': {'es': '🏆 MVDP', 'en': '🏆 MVDP'},
      'rat_title': {'es': '🐭 Ratita', 'en': '🐭 Rat/Loser'},
      'drinks_count_suffix': {'es': 'tragos', 'en': 'drinks'},
      'game_statistics_title': {'es': 'Estadísticas del Juego', 'en': 'Game Statistics'},
      'save_and_return_button': {'es': 'Guardar y Volver', 'en': 'Save and Return'},
      'breaking_news_intro': {'es': ' -> El duende con un litte boy en la mano anuncia lo siguiente:', 'en': ' -> The goblin holding a little boy announces:'},
      
      // Tiebreaker
      'tiebreaker_question_title': {'es': '⚖️ El duende va a hablar', 'en': '⚖️ The Goblin Speaks'},
      'tiebreaker_mvp_title': {'es': 'Desempate MVDP', 'en': 'MVDP Tiebreaker'},
      'tiebreaker_ratita_title': {'es': 'Desempate Ratita', 'en': 'Rat Tiebreaker'},
      'tiebreaker_question_subtitle': {'es': 'Hay empate en quien cumple la condición\n¡El duende te ayudará a elegir!', 'en': 'There is a tie!\nThe goblin will help you choose!'},
      'tiebreaker_mvp_subtitle_1': {'es': 'Hay varios jugones empatados con', 'en': 'Several players tied with'},
      'tiebreaker_mvp_subtitle_2': {'es': 'tragos\n (Solo puede haber un', 'en': 'drinks\n (There can be only one'},
      'mvp_highlight': {'es': 'puto amo', 'en': 'GOAT'},
      'tiebreaker_ratita_subtitle_1': {'es': 'Manda huevos que hayais bebido', 'en': 'Unbelievable you drank'},
      'tiebreaker_ratita_subtitle_2': {'es': 'tragos\n (', 'en': 'drinks\n ('},
      'ratita_highlight': {'es': 'sois escoria', 'en': 'you are scum'},
      'spin_hint': {'es': 'Solo el Little Boy sabe tu destino...', 'en': 'Only the Little Boy knows your fate...'},
      'spinning_text': {'es': '¡Girando...!', 'en': 'Spinning...!'},
      'elf_chooses': {'es': '🧙 El duende elige a... 🧙', 'en': '🧙 The goblin chooses... 🧙'},
      'mvp_winner_msg': {'es': '¡Se te ha caido esto! -> 👑', 'en': 'You dropped this! -> 👑'},
      'ratita_winner_msg': {'es': '¡Ratitaa🐭🐭 (JAJA)!', 'en': 'Rattt! 🐭🐭 (HAHA)!'},
      'question_tiebreaker_result_1': {'es': 'El duende sabe que', 'en': 'The goblin knows that'},
      'question_tiebreaker_result_2': {'es': '... ¡Así que bebete los', 'en': '... So drink the'},
      'confirm': {'es': 'Confirmar', 'en': 'Confirm'},
      'confirm_result': {'es': 'Confirmar Resultado', 'en': 'Confirm Result'},
      
      // Avatar Selection
      'select_avatar_title': {'es': 'Seleccionar avatar para', 'en': 'Select avatar for'},
      'avatar_photo_title': {'es': 'Avatar / Foto', 'en': 'Avatar / Photo'},
      'choose_avatar_option': {'es': 'Elegir avatar creado', 'en': 'Choose created avatar'},
      'take_photo_option': {'es': 'Tomar foto', 'en': 'Take photo'},
      'remove_avatar_option': {'es': 'Quitar avatar/foto', 'en': 'Remove avatar/photo'},
      'choose_avatar_dialog_title': {'es': 'Elegir avatar', 'en': 'Choose avatar'},
      'no_avatars_found': {'es': 'No se encontraron avatars. Verifica la carpeta assets/avatars/', 'en': 'No avatars found. Check assets/avatars/ folder'},
      
      // League Empty State
      'empty_league_title': {'es': 'Aún no eres un borracho', 'en': 'You are not a drunkard yet'},
      'empty_league_subtitle': {'es': 'Pulsa "Nueva liga" para emborracharte de gloria o importa una liga de tu amigo.', 'en': 'Press "New League" to get drunk on glory or import a friend\'s league.'},
      'new_league_button': {'es': 'Nueva liga', 'en': 'New League'},
      'camera_permission_denied': {'es': 'Debes dar permiso de cámara para tomar una foto.', 'en': 'You must grant camera permission to take a photo.'},
      'select_avatar_grid_title': {'es': 'Elegir avatar para', 'en': 'Choose avatar for'},
      'delete_photo_title': {'es': 'Eliminar foto', 'en': 'Delete photo'},
      'delete_photo_content': {'es': '¿Quieres eliminar la foto de este jugador?', 'en': 'Do you want to delete this player\'s photo?'},
      'delete': {'es': 'Eliminar', 'en': 'Delete'},
      'confirm_delete_photo_content': {'es': '¿Quieres eliminar la foto de', 'en': 'Do you want to delete the photo of'},
      'confirm_delete_player_content': {'es': '¿Quieres eliminar a', 'en': 'Do you want to delete'},
      'no_players_title': {'es': 'No hay jugadores', 'en': 'No players'},
      'add_players_hint': {'es': 'Agrega jugadores desde la pestaña "Jugadores"', 'en': 'Add players from the "Players" tab'},
      'add_player_dots_hint': {'es': 'Añadir jugador...', 'en': 'Add player...'},
      'you_have_selected': {'es': 'Habéis señalado a', 'en': 'You have selected'},
      'who_meets_condition': {'es': '¿Quiénes cumplen la condición?', 'en': 'Who meets the condition?'},
      'select_players_button': {'es': 'Selecciona jugadores', 'en': 'Select players'},
      'confirm_selection': {'es': 'Confirmar', 'en': 'Confirm'},
      'god_bless_you': {'es': '¡Que dios os bendiga!', 'en': 'God bless you!'},
      'need_at_least_2': {'es': 'Necesitas al menos 2 jugadores', 'en': 'Need at least 2 players'},
      'select_at_least_2': {'es': 'Selecciona al menos 2 jugadores', 'en': 'Select at least 2 players'},
      'participants_count': {'es': 'participantes', 'en': 'participants'},
      'edit_players_title': {'es': 'Editar jugadores', 'en': 'Edit players'},
      'export_league_title': {'es': 'Exportar liga', 'en': 'Export League'},
      'copy_button': {'es': 'Copiar', 'en': 'Copy'},
      'close_button': {'es': 'Cerrar', 'en': 'Close'},
      'delete_player_title': {'es': 'Eliminar jugador', 'en': 'Delete player'},
      'confirm_delete_player_dialog_content': {'es': '¿Seguro que quieres eliminarlo?', 'en': 'Are you sure you want to delete them?'},
      'mvp_streak_message': {'es': '{name} ha ganado {count} veces seguidas! El duende te da 10 tragos a repartir mientras se rie y bebe.', 'en': '{name} has won {count} times in a row! The goblin gives you 10 drinks to distribute while laughing.'},
      'ratita_streak_message': {'es': '{name} ha perdido {count} veces seguidas. El duende se mea en tu boca y bebes 10 tragos.', 'en': '{name} has lost {count} times in a row. The goblin pees in your mouth and you drink 10 sips.'},
      'for_player': {'es': 'Para: {name}', 'en': 'For: {name}'},
      'rename_player_title': {'es': 'Renombrar jugador', 'en': 'Rename player'},
      'name_hint': {'es': 'Nombre', 'en': 'Name'},
      'save_button': {'es': 'Guardar', 'en': 'Save'},
      'done_button': {'es': 'Listo', 'en': 'Done'},
    };

    if (_localizedValues.containsKey(key)) {
      return _localizedValues[key]?[_currentLocale.languageCode] ?? key;
    }
    return key;
  }
}
