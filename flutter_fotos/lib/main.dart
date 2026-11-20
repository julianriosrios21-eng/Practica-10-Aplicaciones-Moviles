import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: SubirFotoPage()),
  );
}

class SubirFotoPage extends StatefulWidget {
  const SubirFotoPage({super.key});

  @override
  State<SubirFotoPage> createState() => _SubirFotoPageState();
}

class _SubirFotoPageState extends State<SubirFotoPage> {
  Uint8List? _imagen;
  String _nombreImagen = "foto.jpg";

  final TextEditingController _descripcionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool _subiendo = false;

  // Chrome utiliza localhost.
  // Emulador Android utiliza 10.0.2.2.
  // Para celular fisico, sustituir por la IP de tu PC.
  final String apiUrl = kIsWeb
      ? "http://localhost:8000/fotos"
      : "http://10.0.2.2:8000/fotos";

  // Seleccionar o tomar fotografía
  Future<void> _tomarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      );

      if (foto != null) {
        final bytes = await foto.readAsBytes();

        if (!mounted) return;

        setState(() {
          _imagen = bytes;
          _nombreImagen = foto.name;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al seleccionar imagen: $e")),
      );
    }
  }

  // Enviar fotografía a FastAPI
  Future<void> _subirApi() async {
    if (_imagen == null || _descripcionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Por favor selecciona una foto y escribe una descripción",
          ),
        ),
      );
      return;
    }

    setState(() {
      _subiendo = true;
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      request.fields['descripcion'] = _descripcionController.text.trim();

      request.files.add(
        http.MultipartFile.fromBytes('file', _imagen!, filename: _nombreImagen),
      );

      var response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto subida correctamente")),
        );

        setState(() {
          _imagen = null;
          _descripcionController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al subir: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error de conexión: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _subiendo = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Subir Foto"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Vista previa
              _imagen == null
                  ? const Text(
                      "No hay imagen seleccionada",
                      style: TextStyle(fontSize: 16),
                    )
                  : Image.memory(_imagen!, height: 200, fit: BoxFit.cover),

              const SizedBox(height: 20),

              // Descripción
              TextField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: "Descripción"),
              ),

              const SizedBox(height: 20),

              // Seleccionar foto
              ElevatedButton(
                onPressed: _tomarFoto,
                child: Text(kIsWeb ? "Seleccionar Foto" : "Tomar Foto"),
              ),

              const SizedBox(height: 10),

              // Subir a API
              _subiendo
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _subirApi,
                      child: const Text("Subir a API"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
