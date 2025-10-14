import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class Player {
  String name;
  File? avatar;
  Player(this.name, {this.avatar});
}

class HomeScreen extends StatefulWidget {
  final String title;
  const HomeScreen({super.key, required this.title});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Player> _players = [
    Player('James'),
    Player('Laura'),
    Player('Karl'),
    Player('Helen'),
  ];
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  void _addPlayer() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _players.add(Player(name));
        _controller.clear();
      });
    }
  }

  void _removePlayer(int index) {
    final avatar = _players[index].avatar;
    if (avatar != null && avatar.existsSync()) {
      avatar.deleteSync();
    }
    setState(() {
      _players.removeAt(index);
    });
  }

  void _onAvatarTap(int index) {
    print('Avatar tap en $index');
    if (_players[index].avatar == null) {
      _pickImage(index);
    } else {
      _confirmDeletePhoto(index);
    }
  }

  Future<void> _pickImage(int index) async {
    print('Intentando pedir permiso de cámara');
    final status = await Permission.camera.request();
    print('Permiso de cámara: $status');
    if (status.isGranted) {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
      );
      print('Foto tomada: ${photo?.path}');
      if (photo != null && mounted) {
        setState(() {
          _players[index].avatar = File(photo.path);
        });
      }
    } else if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes dar permiso de cámara para tomar una foto.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF23606E),
        title: Text(
          '¿Quieres eliminar a ${_players[index].name}?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _removePlayer(index);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeletePhoto(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF23606E),
        title: Text(
          '¿Quieres eliminar la foto de ${_players[index].name}?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
            onPressed: () {
              setState(() {
                _players[index].avatar = null;
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                            onTap: () => _onAvatarTap(index),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white,
                              backgroundImage: _players[index].avatar != null
                                  ? FileImage(_players[index].avatar!)
                                  : null,
                              child: _players[index].avatar == null
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
                              onTap: () => _confirmDelete(index),
                              child: Text(
                                _players[index].name,
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
                              onSubmitted: (_) => _addPlayer(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: _addPlayer,
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
