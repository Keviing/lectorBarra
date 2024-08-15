import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription? camera;

  const MyApp({Key? key, this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: camera == null ? PlaceholderScreen() : BarcodeScannerScreen(camera: camera!),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Placeholder Screen'),
      ),
      body: Center(child: Text('No camera available for testing')),
    );
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  final CameraDescription camera;

  const BarcodeScannerScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isScanning = false;
  String _barcode = 'Escanea un código de barras';
  int _codeCount = 0; // Variable para contar los códigos detectados

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scanBarcode() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
    });

    try {
      final picture = await _controller.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);

      final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        setState(() {
          _codeCount += barcodes.length; // Incrementa el contador con el número de códigos detectados
          _barcode = barcodes.first.displayValue.toString();
          print('Número total de códigos detectados: $_codeCount');
        });
      } else {
        setState(() {
          _barcode = 'No se encontró ningún código de barras';
        });
      }
    } catch (e) {
      setState(() {
        _barcode = 'Error al escanear el código de barras: $e';
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Barcode Scanner'),
    ),
    body: FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width * 4 / 3, // Ajusta el tamaño del contenedor aquí
                child: CameraPreview(_controller),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _scanBarcode,
                child: const Text('Escanear Código de Barras'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text('Código detectado: $_barcode'),
                      const SizedBox(height: 20),
                      Text('Número total de códigos detectados: $_codeCount'),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    ),
  );
}

}
