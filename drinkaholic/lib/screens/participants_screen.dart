import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // <-- Añade esta línea
import '../viewmodels/participants_viewmodel.dart'; // <-- Añade esta línea
import '../models/player.dart';

class ParticipantsScreen extends StatelessWidget {
  final String title;
  const ParticipantsScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParticipantsViewmodel(),
      child: const _ParticipantsScreenBody(),
    );
  }
}

class _ParticipantsScreenBody extends StatefulWidget {
  const _ParticipantsScreenBody({Key? key}) : super(key: key);

  @override
  State<_ParticipantsScreenBody> createState() =>
      _ParticipantsScreenBodyState();
}

class _ParticipantsScreenBodyState extends State<_ParticipantsScreenBody> {
  List<Player> get _players =>
      Provider.of<ParticipantsViewmodel>(context).players;
  TextEditingController get _controller =>
      Provider.of<ParticipantsViewmodel>(context).controller;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ParticipantsViewmodel>(
      context,
      listen: false,
    );
    viewModel.context = context;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00C9FF), // Cyan (matching Quick Game button)
              Color(0xFF92FE9D), // Green (matching Quick Game button)
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom header with back button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    // Modern back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Title with modern styling
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Colors.white,
                          Color(0xFFE0F7FA),
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'JUGADORES',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 44), // Balance space for back button
                  ],
                ),
              ),
              // Players list with modern cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    itemCount: _players.length + 1,
                    itemBuilder: (context, index) {
                      if (index < _players.length) {
                        return _buildPlayerCard(index);
                      } else {
                        return _buildAddPlayerCard();
                      }
                    },
                  ),
                ),
              ),
              // Modern start game button
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () {
                    // Start game action
                  },
                  child: Container(
                    width: double.infinity,
                    height: 65,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(32),
                        onTap: () {
                          // Start game action
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sports_esports,
                                color: Color(0xFF00C9FF),
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                '¡EMPEZAR A JUGAR!',
                                style: TextStyle(
                                  color: Color(0xFF00C9FF),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(int index) {
    final viewModel = Provider.of<ParticipantsViewmodel>(context, listen: false);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with modern styling
            GestureDetector(
              onTap: () => viewModel.onAvatarTap(index),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: (_players[index].imagen != null || _players[index].avatar != null)
                    ? ClipOval(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: _players[index].imagen != null
                              ? Image.file(
                                  _players[index].imagen!,
                                  fit: BoxFit.cover,
                                  width: 56,
                                  height: 56,
                                )
                              : Image.asset(
                                  _players[index].avatar!,
                                  fit: BoxFit.cover,
                                  width: 56,
                                  height: 56,
                                ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Player name
            Expanded(
              child: GestureDetector(
                onTap: () => viewModel.confirmDelete(index),
                child: Text(
                  _players[index].nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Delete indicator
            Icon(
              Icons.touch_app,
              color: Colors.white.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPlayerCard() {
    final viewModel = Provider.of<ParticipantsViewmodel>(context, listen: false);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            // Add icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person_add,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Text field
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Añadir jugador...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: (_) => viewModel.addPlayer(),
              ),
            ),
            // Add button
            GestureDetector(
              onTap: viewModel.addPlayer,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
