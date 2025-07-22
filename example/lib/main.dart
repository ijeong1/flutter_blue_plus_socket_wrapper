import 'package:flutter/material.dart';
import 'package:ble_socket_wrapper/ble_socket_wrapper.dart'; // Import our package
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

void main() {
  // It's recommended to set the log level for debugging purposes.
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BleSocket Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BleSocket? _socket;
  StreamSubscription? _dataSubscription;
  
  // IMPORTANT: Replace this with the actual device ID of your peripheral.
  final String myTestDeviceId = "XX:XX:XX:XX:XX:XX"; 
  
  List<String> receivedDataLogs = [];
  bool isConnecting = false;
  bool get isConnected => _socket != null;

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _socket?.close();
    super.dispose();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void connect() async {
    if (isConnected || isConnecting) return;

    setState(() {
      isConnecting = true;
      receivedDataLogs.add("Connecting to $myTestDeviceId...");
    });

    try {
      // 1. Connect to the device to create a socket
      final socket = await BleSocket.connect(myTestDeviceId);
      
      setState(() {
        _socket = socket;
        isConnecting = false;
        receivedDataLogs.add("✅ Connection successful!");
      });
      _showSnackbar("Connected!");

      // 2. Start listening for incoming data
      _dataSubscription = socket.stream.listen((data) {
        setState(() {
          // Display received data as a hex string
          final hexString = data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ');
          receivedDataLogs.add("RX: $hexString");
        });
      }, onError: (error) {
        _showSnackbar("Stream Error: $error");
        disconnect();
      });

    } catch (e) {
      _showSnackbar("Connection Failed: $e");
      setState(() {
        isConnecting = false;
        receivedDataLogs.add("❌ Connection failed.");
      });
    }
  }

  void sendData() {
    if (!isConnected) {
      _showSnackbar("Not connected to any device.");
      return;
    }
    // 3. Send some sample data
    final dataToSend = [0x01, 0x02, 0x03, 0x04];
    _socket?.send(dataToSend);
    setState(() {
      receivedDataLogs.add("TX: ${dataToSend.toString()}");
    });
  }

  void disconnect() {
    if (!isConnected) return;
    
    // 4. Close the connection and clean up resources
    _dataSubscription?.cancel();
    _socket?.close();
    setState(() {
      _socket = null;
      receivedDataLogs.add("🔌 Disconnected.");
    });
    _showSnackbar("Disconnected");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BleSocket Wrapper Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isConnected || isConnecting ? null : connect,
                  child: isConnecting ? CircularProgressIndicator(color: Colors.white) : Text("Connect"),
                ),
                ElevatedButton(
                  onPressed: isConnected ? sendData : null,
                  child: Text("Send Data"),
                ),
                ElevatedButton(
                  onPressed: isConnected ? disconnect : null,
                  child: Text("Disconnect"),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text("Connection Log", style: Theme.of(context).textTheme.headlineSmall),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: receivedDataLogs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      receivedDataLogs[index],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: receivedDataLogs[index].contains("❌") ? Colors.red : Colors.black,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}