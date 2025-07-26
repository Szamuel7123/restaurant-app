import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:html' as html; // For web camera permission prompt

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  String? scannedTableId;
  MobileScannerController controller = MobileScannerController();
  String? errorMessage;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    // For web, prompt user for camera access
    if (identical(0, 0.0)) {
      // Not web
      // MobileScanner will handle permission automatically
      setState(() {
        _permissionChecked = true;
      });
      return;
    } else {
      // Web: try to access camera to trigger browser prompt
      try {
        await html.window.navigator.mediaDevices?.getUserMedia({'video': true});
        setState(() {
          _permissionChecked = true;
        });
      } catch (e) {
        setState(() {
          errorMessage = 'Camera permission denied. Please allow camera access in your browser settings.';
          _permissionChecked = true;
        });
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.first;
    if (barcode.rawValue != null && scannedTableId == null) {
      setState(() {
        scannedTableId = barcode.rawValue;
      });
      controller.stop();
      Navigator.pop(context, scannedTableId);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionChecked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Table QR Code')),
      body: errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 4,
                  child: MobileScanner(
                    controller: controller,
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Camera error: $error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Back'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: scannedTableId == null
                        ? const Text('Scan the QR code on your table')
                        : Text('Table ID: $scannedTableId'),
                  ),
                ),
              ],
            ),
    );
  }
} 