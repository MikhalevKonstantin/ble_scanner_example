import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> _devicesList = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _devicesList = results.map((result) => result.device).toList();
      setState(() {});
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      print('Error starting scan: $e');
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      print('Connected to device: ${device.remoteId}');

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      print('Discovered ${services.length} services');

      // For each service, print info and subscribe to notify characteristics
      for (BluetoothService service in services) {
        print('Service UUID: ${service.uuid}');

        for (BluetoothCharacteristic characteristic in service.characteristics) {
          print('  Characteristic UUID: ${characteristic.uuid}');
          print('  Properties: ');
          print('    Read: ${characteristic.properties.read}');
          print('    Write: ${characteristic.properties.write}');
          print('    Notify: ${characteristic.properties.notify}');
          print('    Indicate: ${characteristic.properties.indicate}');

          // Subscribe to notifications if available
          if (characteristic.properties.notify || characteristic.properties.indicate) {
            try {
              await characteristic.setNotifyValue(true);
              characteristic.onValueReceived.listen((value) {
                print('Received notification from ${characteristic.uuid}: $value');
              });
              print('Subscribed to ${characteristic.uuid}');
            } catch (e) {
              print('Error subscribing to characteristic ${characteristic.uuid}: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Scanner'),
        actions: [
          _isScanning
              ? IconButton(
            icon: const Icon(Icons.stop),
            onPressed: _stopScan,
          )
              : IconButton(
            icon: const Icon(Icons.search),
            onPressed: _startScan,
          )
        ],
      ),
      body: ListView.builder(
        itemCount: _devicesList.length,
        itemBuilder: (context, index) {
          BluetoothDevice device = _devicesList[index];
          return ListTile(
            title: Text(device.platformName),
            subtitle: Text(device.remoteId.toString()),
            onTap: () => _connectToDevice(device),
          );
        },
      ),
    );
  }
}