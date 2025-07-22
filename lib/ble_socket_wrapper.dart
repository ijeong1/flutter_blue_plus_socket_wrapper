import 'dart:async';
import 'package.flutter_blue_plus.dart';

// These UUIDs must exactly match the firmware on the BLE peripheral device.
final Guid SERVICE_UUID = Guid("0000ffe0-0000-1000-8000-00805f9b34fb");
final Guid TX_CHARACTERISTIC_UUID = Guid("0000ffe1-0000-1000-8000-00805f9b34fb"); // For writing data (Transmit)
final Guid RX_CHARACTERISTIC_UUID = Guid("0000ffe2-0000-1000-8000-00805f9b34fb"); // For receiving data (Receive/Notify)

class BleSocket {
  final BluetoothDevice _device;
  late final BluetoothCharacteristic _txCharacteristic;
  late final BluetoothCharacteristic _rxCharacteristic;
  late final StreamController<List<int>> _dataStreamController;
  late final StreamSubscription<List<int>> _notificationSubscription;

  // Private constructor
  BleSocket._(this._device, this._txCharacteristic, this._rxCharacteristic) {
    _dataStreamController = StreamController<List<int>>.broadcast();
  }

  /// Connects to a BLE device and returns a ready-to-use BleSocket instance.
  /// Throws an exception if the required services/characteristics are not found.
  static Future<BleSocket> connect(String deviceId) async {
    final device = BluetoothDevice.fromId(deviceId);
    
    // The latest version of flutter_blue_plus (1.35.5) recommends setting the MTU
    // right after connecting for optimal performance.
    await device.connect(mtu: 512);

    try {
      List<BluetoothService> services = await device.discoverServices();
      final service = services.firstWhere((s) => s.uuid == SERVICE_UUID);
      final tx = service.characteristics.firstWhere((c) => c.uuid == TX_CHARACTERISTIC_UUID);
      final rx = service.characteristics.firstWhere((c) => c.uuid == RX_CHARACTERISTIC_UUID);

      final socket = BleSocket._(device, tx, rx);
      await rx.setNotifyValue(true);
      socket._notificationSubscription = rx.onValueReceived.listen(socket._onDataReceived);
      
      return socket;
    } catch (e) {
      await device.disconnect();
      throw Exception('Failed to find required services/characteristics or setup failed: $e');
    }
  }

  // The stream of incoming data from the device.
  Stream<List<int>> get stream => _dataStreamController.stream;

  // Internal method called when data is received from the device.
  void _onDataReceived(List<int> data) {
    if (data.isNotEmpty) {
      _dataStreamController.add(data);
    }
  }

  /// Sends data to the BLE device.
  ///
  /// For larger data, this method should be enhanced to handle fragmentation
  /// based on the MTU size.
  Future<void> send(List<int> data) async {
    // Use `withoutResponse: true` for faster, UDP-like communication (no ACK).
    await _txCharacteristic.write(data, withoutResponse: true);
    
    // Use `withoutResponse: false` (default) for reliable, TCP-like communication (waits for ACK).
    // await _txCharacteristic.write(data);
  }

  /// Disconnects from the device and releases all resources.
  Future<void> close() async {
    await _notificationSubscription.cancel();
    _dataStreamController.close();
    await _device.disconnect();
  }
}