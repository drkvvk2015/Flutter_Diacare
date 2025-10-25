import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  // Bluetooth
  List<BluetoothDevice> _bluetoothDevices = [];
  bool _isScanningBluetooth = false;

  // WiFi
  List<WiFiAccessPoint> _wifiDevices = [];
  bool _isScanningWiFi = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _scanBluetoothDevices() async {
    if (!mounted) return;
    setState(() {
      _isScanningBluetooth = true;
      _bluetoothDevices = [];
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;
        setState(() {
          _bluetoothDevices = results.map((r) => r.device).toList();
        });
      });
      await Future.delayed(const Duration(seconds: 4));
      await FlutterBluePlus.stopScan();
      await subscription.cancel();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Bluetooth scan failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanningBluetooth = false;
        });
      }
    }
  }

  Future<void> _scanWiFiDevices() async {
    if (!mounted) return;
    setState(() {
      _isScanningWiFi = true;
      _wifiDevices = [];
    });
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Check and request location permissions (required for WiFi scanning)
      final locationPermission = await Permission.location.request();
      if (!locationPermission.isGranted) {
        if (!mounted) return;
        setState(() => _isScanningWiFi = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Location permission required for WiFi scanning'),
          ),
        );
        return;
      }

      // Check if WiFi scanning is supported and available
      final canScan = await WiFiScan.instance.canGetScannedResults();
      if (canScan != CanGetScannedResults.yes) {
        if (!mounted) return;
        setState(() => _isScanningWiFi = false);
        messenger.showSnackBar(
          SnackBar(content: Text('WiFi scanning not available: $canScan')),
        );
        return;
      }

      // Start scanning
      final startScan = await WiFiScan.instance.startScan();
      if (!startScan) {
        if (!mounted) return;
        setState(() => _isScanningWiFi = false);
        messenger.showSnackBar(
          const SnackBar(content: Text('Cannot start WiFi scan')),
        );
        return;
      }

      // listen to scanned results
      final subscription = WiFiScan.instance.onScannedResultsAvailable
          .listen((result) {
        if (!mounted) return;
        setState(() {
          _wifiDevices = result;
        });
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 5));
      await subscription.cancel();

    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('WiFi scan failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanningWiFi = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Management')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bluetooth Devices',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: _isScanningBluetooth ? null : _scanBluetoothDevices,
                child: _isScanningBluetooth
                    ? const CircularProgressIndicator()
                    : const Text('Scan Bluetooth'),
              ),
              ..._bluetoothDevices.map(
                (device) => ListTile(
                  title: Text(
                    device.platformName.isNotEmpty
                        ? device.platformName
                        : device.remoteId.toString(),
                  ),
                  subtitle: Text(device.remoteId.toString()),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        // await device.connect(license: License.bluetoothLe); // mocked pairing, skip API call
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Paired with ${device.platformName.isNotEmpty ? device.platformName : device.remoteId} (mocked)',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to pair: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Pair'),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'WiFi Devices',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: _isScanningWiFi ? null : _scanWiFiDevices,
                child: _isScanningWiFi
                    ? const CircularProgressIndicator()
                    : const Text('Scan WiFi'),
              ),
              ..._wifiDevices.map(
                (network) => ListTile(
                  title: Text(network.ssid),
                  subtitle: Text('Signal: ${network.level} dBm'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        // TODO: Handle WiFi pairing and data import
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Paired with ${network.ssid} (mocked)',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to pair: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Pair'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
