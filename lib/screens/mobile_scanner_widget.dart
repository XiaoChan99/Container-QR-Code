import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MobileScannerWidget extends StatefulWidget {
  final Function(String) onScanned;

  const MobileScannerWidget({super.key, required this.onScanned});

  @override
  State<MobileScannerWidget> createState() => _MobileScannerWidgetState();
}

class _MobileScannerWidgetState extends State<MobileScannerWidget> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: cameraController,
          onDetect: (capture) {
            if (!isScanning) return;
            
            final barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                setState(() {
                  isScanning = false;
                });
                widget.onScanned(barcode.rawValue!);
                break;
              }
            }
          },
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Row(
            children: [
              IconButton(
                icon: ValueListenableBuilder(
                  valueListenable: cameraController.torchState,
                  builder: (context, state, child) {
                    return Icon(
                      state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    );
                  },
                ),
                onPressed: () => cameraController.toggleTorch(),
              ),
              IconButton(
                icon: ValueListenableBuilder(
                  valueListenable: cameraController.cameraFacingState,
                  builder: (context, state, child) {
                    return Icon(
                      state == CameraFacing.front ? Icons.camera_front : Icons.camera_rear,
                      color: Colors.white,
                    );
                  },
                ),
                onPressed: () => cameraController.switchCamera(),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              isScanning ? 'Align QR code within frame' : 'Processing...',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}