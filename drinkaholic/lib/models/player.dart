import 'dart:io';

class Player {
  final int id;
  final String nombre;
  final File? imagen; // imagen es nullable
  final String? avatar; // avatar también es nullable

  Player({required this.id, required this.nombre, this.imagen, this.avatar});
}
