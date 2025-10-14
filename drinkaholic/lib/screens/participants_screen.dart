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
  State<_ParticipantsScreenBody> createState() => _ParticipantsScreenBodyState();
}
class _ParticipantsScreenBodyState extends State<_ParticipantsScreenBody> {
  
  List<Player> get _players => Provider.of<ParticipantsViewmodel>(context).players;
  TextEditingController get _controller => Provider.of<ParticipantsViewmodel>(context).controller;
 
  


  @override
  Widget build(BuildContext context) {
     final viewModel = Provider.of<ParticipantsViewmodel>(context, listen: false);
    viewModel.context = context;
    
    return Scaffold(
      backgroundColor: const Color(0xFF23606E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Drinkaholic',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 36,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _players.length + 1,
                itemBuilder: (context, index) {
                  if (index < _players.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Provider.of<ParticipantsViewmodel>(context, listen: false).onAvatarTap(index),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white,
                              backgroundImage: _players[index].imagen != null
                                  ? FileImage(_players[index].imagen!)
                                  : _players[index].avatar != null
                                      ? AssetImage(_players[index].avatar!) as ImageProvider
                                      : null,
                              child: (_players[index].imagen == null && _players[index].avatar == null)
                                  ? Icon(
                                      Icons.camera_alt,
                                      color: Colors.teal[700],
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Provider.of<ParticipantsViewmodel>(context, listen: false).confirmDelete(index),
                              child: Text(
                                _players[index].nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // en este padding va el TextField para añadir jugadores
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Icon(
                              Icons.person_add,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Añadir participante',
                                hintStyle: TextStyle(color: Colors.white54),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white38),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              onSubmitted: (_) => Provider.of<ParticipantsViewmodel>(context, listen: false).addPlayer(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: Provider.of<ParticipantsViewmodel>(context, listen: false).addPlayer,
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.teal[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              onPressed: () {
                // Acción al presionar el botón de la guerraaa
              },
              child: const Text(
                'Vamos a la guerra',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}


