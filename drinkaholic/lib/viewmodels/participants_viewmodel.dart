import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:drinkaholic/models/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ParticipantsViewmodel extends ChangeNotifier {
  BuildContext? _context;

  // Getter y setter para el contexto
  BuildContext? get context => _context;
  set context(BuildContext? ctx) => _context = ctx;

  final List<Player> _players = [
    Player(id: 1, nombre: 'James'),
    Player(id: 2, nombre: 'Laura'),
    Player(id: 3, nombre: 'Karl'),
    Player(id: 4, nombre: 'Helen'),
  ];

  int _nextPlayerId = 5;
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Getters
  List<Player> get players => _players;
  TextEditingController get controller => _controller;
  ImagePicker get picker => _picker;

  // Setters
  set players(List<Player> value) {
    _players
      ..clear()
      ..addAll(value);
    notifyListeners();
  }

  set controller(TextEditingController value) {
    // No es común cambiar el controller, pero si lo necesitas:
    // _controller = value; // Si _controller no es final
    notifyListeners();
  }

  set picker(ImagePicker value) {
    // No es común cambiar el picker, pero si lo necesitas:
    // _picker = value; // Si _picker no es final
    notifyListeners();
  }

  void addPlayer() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      _players.add(Player(id: _nextPlayerId++, nombre: name));
      _controller.clear();
      notifyListeners();
    }
  }

  void removePlayer(int index) {
    final imagen = _players[index].imagen;
    if (imagen != null && imagen.existsSync()) {
      imagen.deleteSync();
    }
    _players.removeAt(index);
    notifyListeners();
  }

   void onAvatarTap(int index) {
    print('Avatar tap en $index');
    if (_players[index].imagen == null && _players[index].avatar == null) {
      showAvatarOptions(index);
    } else {
      confirmDeletePhoto(index);
    }
  }

  void showAvatarOptions(int index) {
    showDialog(
      context: _context!,
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
                chooseAvatar(index);
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
                pickImage(index);
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
  

  Future<void> chooseAvatar(int index) async {
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
        if (context != null) {
          ScaffoldMessenger.of(context!).showSnackBar(
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
      
      if (context != null) {
        showDialog(
          context: context!,
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
                      _players[index] = Player(
                        id: _players[index].id,
                        nombre: _players[index].nombre,
                        avatar: avatarPath,
                      );
                      notifyListeners(); // Notifica a la UI el cambio
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 200,
                      height: 60,
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage(
                            'assets/images/button_background.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Liga',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      _showExitConfirmationDialog(context);
                    },
                    child: Container(
                      width: 200,
                      height: 60,
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage(
                            'assets/images/button_background.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Salir',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error loading avatars: $e');
      if (context != null) {
        ScaffoldMessenger.of(context!).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar avatars. Asegúrate de tener imágenes en assets/avatars/'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> pickImage(int index) async {
    print('Intentando pedir permiso de cámara');
    final status = await Permission.camera.request();
    print('Permiso de cámara: $status');
    if (status.isGranted) {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
      );
      print('Foto tomada: ${photo?.path}');
      if (photo != null && context != null) {
        _players[index] = Player(
          id: _players[index].id,
          nombre: _players[index].nombre,
          imagen: File(photo.path),
        );
        notifyListeners(); // Notifica a la UI el cambio
      }
    } else if (status.isDenied || status.isPermanentlyDenied) {
      if (context != null) {
        ScaffoldMessenger.of(context!).showSnackBar(
          const SnackBar(
            content: Text('Debes dar permiso de cámara para tomar una foto.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
   }

  void confirmDeletePhoto(int index) {
    showDialog(
      context: context!,
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
              _players[index] = Player(
                id: _players[index].id,
                nombre: _players[index].nombre,
              );
              notifyListeners(); // Notifica a la UI el cambio
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

   void confirmDelete(int index) {
  showDialog(
    context: context!,
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
            removePlayer(index); // Usa removePlayer que llama a notifyListeners()
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}

}