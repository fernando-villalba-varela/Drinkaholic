import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/league_detail_viewmodel.dart';
import '../widgets/league/league_app_bar_button.dart';
import '../widgets/common/animated_background.dart';
import '../widgets/league/detail/leaderboard_tab.dart';
import '../widgets/league/detail/participants_tab.dart';
import '../widgets/league/detail/play_tab.dart';

class LeagueDetailScreen extends StatefulWidget {
  const LeagueDetailScreen({super.key});

  @override
  State<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen>
    with TickerProviderStateMixin {
  Widget _buildAnimatedBackground() {
    return const AnimatedBackground();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LeagueDetailViewModel>();
    final league = vm.league;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 80,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              LeagueAppBarButton(
                onTap: () => Navigator.of(context).pop(),
                icon: Icons.arrow_back,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  league.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                      Shadow(
                        color: Colors.purple,
                        offset: Offset(-1, -1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // FUTURA IMPLEMENTACION: Exportar liga a JSON
              // LeagueAppBarButton(
              //   onTap: () => vm.showExportDialog(context),
              //   icon: Icons.upload_file,
              // ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0x4DFFFFFF), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicator: BoxDecoration(),
                  dividerColor: Colors.transparent,
                  dividerHeight: 0,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: 'Scoreboard'),
                    Tab(text: 'Jugadores'),
                    Tab(text: 'Jugar'),
                  ],
                ),
              ),
            ),
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
            const SafeArea(
              child: TabBarView(
                children: [LeaderboardTab(), ParticipantsTab(), PlayTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
