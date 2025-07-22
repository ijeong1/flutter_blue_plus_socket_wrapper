import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// 1. 'const'を'final'に変更しました。
// These UUIDs must exactly match the firmware on the BLE peripheral device.
final serviceUuid = Guid("0000ffe0-0000-1000-8000-00805f9b34fb");
final txCharacteristicUuid = Guid("0000ffe1-0000-1000-8000-00805f9b34fb"); // For writing data (Transmit)
final rxCharacteristicUuid = Guid("0000ffe2-0000-1000-8000-00805f9b34fb"); // For receiving data (Receive/Notify)

class BleSocket {
  final BluetoothDevice _device;
  late final BluetoothCharacteristic _txCharacteristic;
  // 2. Unused '_rxCharacteristic' field has been removed.
  late final StreamController<List<int>> _dataStreamController;
  late final StreamSubscription<List<int>> _notificationSubscription;

  // 3. Removed '_rxCharacteristic' from the constructor.
  BleSocket._(this._device, this._txCharacteristic) {
    _dataStreamController = StreamController<List<int>>.broadcast();
  }

  /// Connects to a BLE device and returns a ready-to-use BleSocket instance.
  /// Throws an exception if the required services/characteristics are not found.
  static Future<BleSocket> connect(String deviceId) async {
    final device = BluetoothDevice.fromId(deviceId);
    
    await device.connect(mtu: 512);

    try {
      List<BluetoothService> services = await device.discoverServices();
      final service = services.firstWhere((s) => s.uuid == serviceUuid);
      final tx = service.characteristics.firstWhere((c) => c.uuid == txCharacteristicUuid);
      final rx = service.characteristics.firstWhere((c) => c.uuid == rxCharacteristicUuid);

      // 4. Updated the constructor call.
      final socket = BleSocket._(device, tx);
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
  Future<void> send(List<int> data) async {
    await _txCharacteristic.write(data, withoutResponse: true);
  }

  /// Disconnects from the device and releases all resources.
  Future<void> close() async {
    await _notificationSubscription.cancel();
    _dataStreamController.close();
    await _device.disconnect();
  }
}