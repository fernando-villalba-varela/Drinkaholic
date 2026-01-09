import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/league_list_viewmodel.dart';
import '../widgets/league/league_app_bar_button.dart';
import '../widgets/common/animated_background.dart';
import '../widgets/league/league_card.dart';
import '../widgets/league/league_empty_state.dart';
import '../widgets/league/fab_new_league.dart';

class LeagueListScreen extends StatefulWidget {
  const LeagueListScreen({super.key});

  @override
  State<LeagueListScreen> createState() => _LeagueListScreenState();
}

class _LeagueListScreenState extends State<LeagueListScreen> with TickerProviderStateMixin {
  Widget _buildAnimatedBackground() {
    return const AnimatedBackground();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
    );
    return Consumer<LeagueListViewModel>(
      builder: (_, vm, _) => Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 80,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              LeagueAppBarButton(onTap: () => Navigator.of(context).pop(), icon: Icons.arrow_back),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'LIGAS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 4),
                      Shadow(color: Colors.purple, offset: Offset(-1, -1), blurRadius: 2),
                    ],
                  ),
                ),
              ),
              // FUTURA IMPLEMENTACION: Importar liga desde JSON
              // LeagueAppBarButton(
              //   onTap: () => vm.showImportLeagueDialog(context),
              //   icon: Icons.download,
              // ),
            ],
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFC466B), Color(0xFF3F5EFB)],
                ),
              ),
            ),
            _buildAnimatedBackground(),
            SafeArea(
              child: vm.leagues.isEmpty
                  ? const LeagueEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
                      itemCount: vm.leagues.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (_, i) => LeagueCard(league: vm.leagues[i]),
                    ),
            ),
          ],
        ),
        floatingActionButton: FabNewLeague(onPressed: () => _showCreateLeagueDialog(context)),
      ),
    );
  }

  void _showCreateLeagueDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16363F),
        title: const Text('Crear nueva liga', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.tealAccent,
          decoration: const InputDecoration(
            labelText: 'Nombre de la liga',
            labelStyle: TextStyle(color: Colors.tealAccent),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.tealAccent)),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitCreateLeague(context, nameCtrl),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade700),
            onPressed: () => _submitCreateLeague(context, nameCtrl),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _submitCreateLeague(BuildContext context, TextEditingController c) {
    final name = c.text.trim();
    if (name.isNotEmpty) {
      context.read<LeagueListViewModel>().createLeague(name);
    }
    Navigator.pop(context);
  }
}
