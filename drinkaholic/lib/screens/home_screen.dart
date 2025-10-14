import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/player.dart';
import 'dart:io';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  final String title;
  const HomeScreen({super.key, required this.title});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Player> _players = [
    Player(id: 1, nombre: 'James'),
    Player(id: 2, nombre: 'Laura'),
    Player(id: 3, nombre: 'Karl'),
    Player(id: 4, nombre: 'Helen'),
  ];
  int _nextPlayerId = 5;
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  void _addPlayer() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _players.add(Player(id: _nextPlayerId++, nombre: name));
        _controller.clear();
      });
    }
  }

  void _removePlayer(int index) {
    final imagen = _players[index].imagen;
    if (imagen != null && imagen.existsSync()) {
      imagen.deleteSync();
    }
    setState(() {
      _players.removeAt(index);
    });
  }

  void _onAvatarTap(int index) {
    print('Avatar tap en $index');
    if (_players[index].imagen == null && _players[index].avatar == null) {
      _showAvatarOptions(index);
    } else {
      _confirmDeletePhoto(index);
    }
  }

  void _showAvatarOptions(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF23606E),
        title: Text(
          'Seleccionar avatar para ${_players[index].nombre}',
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
                'Elegir avatar creado',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _chooseAvatar(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                'Tomar foto',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(index);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseAvatar(int index) async {
    try {
      // Load available avatar assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map<String, dynamic>.from(
        const JsonDecoder().convert(manifestContent) as Map<String, dynamic>,
      );
      
      final avatarPaths = manifestMap.keys
        .where((String key) => key.startsWith('assets/avatars/') && 
               (key.endsWith('.png') || key.endsWith('.jpg') || 
                key.endsWith('.jpeg') || key.endsWith('.gif') || 
                key.endsWith('.webp')) &&
               !key.endsWith('.md'))
        .toList();
      
      if (avatarPaths.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay avatars disponibles. Agrega imágenes a assets/avatars/'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Get list of already used avatars (excluding current player)
      final usedAvatars = _players
          .asMap()
          .entries
          .where((entry) => entry.key != index && entry.value.avatar != null)
          .map((entry) => entry.value.avatar!)
          .toSet();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF23606E),
            title: Text(
              'Elegir avatar para ${_players[index].nombre}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: avatarPaths.length,
                itemBuilder: (context, avatarIndex) {
                  final avatarPath = avatarPaths[avatarIndex];
                  final isUsed = usedAvatars.contains(avatarPath);
                  final isCurrentlySelected = _players[index].avatar == avatarPath;
                  
                  return GestureDetector(
                    onTap: isUsed && !isCurrentlySelected ? null : () {
                      setState(() {
                        _players[index] = Player(
                          id: _players[index].id,
                          nombre: _players[index].nombre,
                          avatar: avatarPath,
                        );
                      });
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrentlySelected 
                              ? Colors.greenAccent
                              : isUsed 
                                  ? Colors.redAccent
                                  : Colors.white24,
                          width: isCurrentlySelected || isUsed ? 3 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ColorFiltered(
                              colorFilter: isUsed && !isCurrentlySelected
                                  ? ColorFilter.mode(
                                      Colors.black.withOpacity(0.6),
                                      BlendMode.darken,
                                    )
                                  : const ColorFilter.mode(
                                      Colors.transparent,
                                      BlendMode.multiply,
                                    ),
                              child: Image.asset(
                                avatarPath,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                          if (isUsed && !isCurrentlySelected)
                            const Center(
                              child: Icon(
                                Icons.block,
                                color: Colors.redAccent,
                                size: 32,
                              ),
                            ),
                          if (isCurrentlySelected)
                            const Positioned(
                              top: 4,
                              right: 4,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.greenAccent,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
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
            ],
          ),
        );
      }
    } catch (e) {
      print('Error loading avatars: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar avatars. Asegúrate de tener imágenes en assets/avatars/'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          _players[index] = Player(
            id: _players[index].id,
            nombre: _players[index].nombre,
            imagen: File(photo.path),
          );
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
          '¿Quieres eliminar a ${_players[index].nombre}?',
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
          '¿Quieres eliminar la foto de ${_players[index].nombre}?',
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
                _players[index] = Player(
                  id: _players[index].id,
                  nombre: _players[index].nombre,
                );
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
                              onTap: () => _confirmDelete(index),
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
