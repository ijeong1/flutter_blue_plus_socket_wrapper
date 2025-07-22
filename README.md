# 🔌 BLE Socket Wrapper

An intuitive wrapper for [`flutter_blue_plus`](https://pub.dev/packages/flutter_blue_plus) that abstracts away the complexities of BLE (Bluetooth Low Energy) communication into a simple, socket-like interface.

---

## 🚀 The Problem & The Solution

While `flutter_blue_plus` is powerful, it requires significant boilerplate code for basic data transmission.  
This package streamlines the entire process into a single `connect()` method and a simple data `Stream`.

### ❌ Before (Standard `flutter_blue_plus`)
```dart
// 1. Scan for devices
// 2. Manually select one
await device.connect();

// 3. Discover services
List<BluetoothService> svcs = await device.discoverServices();

// 4. Find the right service and characteristics
await rxChar.setNotifyValue(true);
rxChar.onValueReceived.listen(/*...*/);

// 5. Write data
await txChar.write(/*...*/);
```

### ✅ After (Using `ble_socket_wrapper`)
```dart
final socket = await BleSocket.connect("YOUR_DEVICE_ID");

socket.stream.listen((data) {
  print("RX: $data");
});

socket.send([0xDE, 0xAD, 0xBE, 0xEF]);
```

---

## ⚠️ Device Prerequisites

This package is designed for BLE peripherals with a specific GATT profile.

Your device **must** expose the following UUIDs:

| Type               | UUID                                      | Properties  |
|--------------------|-------------------------------------------|-------------|
| **Service**        | `0000ffe0-0000-1000-8000-00805f9b34fb`    | -           |
| **TX Characteristic** | `0000ffe1-0000-1000-8000-00805f9b34fb` | Write       |
| **RX Characteristic** | `0000ffe2-0000-1000-8000-00805f9b34fb` | Notify      |

---

## 📦 Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  ble_socket_wrapper: ^0.0.1 # Check for the latest version on pub.dev
```

Then, run:

```bash
flutter pub get
```

---

## 💻 Usage Example

```dart
import 'package:ble_socket_wrapper/ble_socket_wrapper.dart';
import 'dart:async';

final String deviceId = "XX:XX:XX:XX:XX:XX";
BleSocket? socket;
StreamSubscription? dataSubscription;

Future<void> connectAndCommunicate() async {
  try {
    print("Attempting to connect...");
    socket = await BleSocket.connect(deviceId);
    print("✅ Connected!");

    dataSubscription = socket!.stream.listen((data) {
      print("RX: $data");
    }, onError: (error) {
      print("🔴 Stream Error: $error");
    });

    final dataToSend = [0x68, 0x65, 0x6c, 0x6c, 0x6f]; // "hello"
    print("TX: Sending $dataToSend");
    await socket!.send(dataToSend);

  } catch (e) {
    print("🔴 Connection or setup failed: $e");
  }
}

void dispose() {
  print("Closing connection...");
  dataSubscription?.cancel();
  socket?.close();
}
```

---

## 🛠️ API Reference

| Member                             | Description                                                                 |
|------------------------------------|-----------------------------------------------------------------------------|
| `static Future<BleSocket> connect(String deviceId)` | Connects to the device, performs setup, and returns a `BleSocket` instance. |
| `Stream<List<int>> get stream`     | A broadcast stream emitting received byte lists from the peripheral.       |
| `Future<void> send(List<int> data)`| Sends bytes to the device's TX characteristic.                             |
| `Future<void> close()`             | Disconnects, unsubscribes from notifications, and releases resources.      |

---
