import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';

class FlightsScreen extends StatefulWidget {
  const FlightsScreen({super.key});

  @override
  State<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends State<FlightsScreen> {
  late FlutterEarthGlobeController _controller;

  @override
  void initState() {
    super.initState();
    // Настраиваем глобус: крутится сам, зум средний
    _controller = FlutterEarthGlobeController(
      rotationSpeed: 0.05,
      isRotating: true,
      zoom: 0.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Делаем глубокий черный фон, чтобы 3D глобус смотрелся дорого
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Airline Terminal",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Глобус на задний план
          Center(
            child: FlutterEarthGlobe(controller: _controller, radius: 150),
          ),
          // 2. Слой поверх глобуса с твоими рейсами
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "🌍 Весь мир у твоих ног",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Здесь будет список рейсов (Flight List)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1), // Эффект стекла
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Тут скоро будут рейсы...",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
