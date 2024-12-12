import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityCheck extends StatefulWidget {
  final Widget child;

  const ConnectivityCheck({Key? key, required this.child}) : super(key: key);

  @override
  _ConnectivityCheckState createState() => _ConnectivityCheckState();
}

class _ConnectivityCheckState extends State<ConnectivityCheck> {
  late Stream<ConnectivityResult> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: _connectivityStream,
      builder: (context, snapshot) {
        // Determine connectivity status
        final bool isConnected = snapshot.data == ConnectivityResult.mobile ||
            snapshot.data == ConnectivityResult.wifi;

        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading state while checking connectivity
          return _buildLoadingScreen();
        }

        if (isConnected) {
          // Proceed to the app when connected
          return widget.child;
        } else {
          // Show no connection screen when disconnected
          return _buildNoConnectionScreen();
        }
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildNoConnectionScreen() {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text(
                "No Internet Connection",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please enable WiFi or Mobile Data to proceed.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Optionally, force a rebuild to check connectivity again
                  setState(() {});
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
