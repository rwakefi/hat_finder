import 'package:flutter/material.dart';
import 'hat_input_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final logoHeight = (constraints.maxHeight * 0.30).clamp(100.0, 220.0);
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: logoHeight,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Find Your Perfect Hat',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                            ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Search or identify hats based on their Crown and Brim properties.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                      const SizedBox(height: 48),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const HatInputScreen()),
                          );
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Start Searching'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),

    );
  }
}
