import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const WeatherHome(),
    );
  }
}

class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> with TickerProviderStateMixin {
  final TextEditingController _cityCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  WeatherData? _data;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const String _apiKey = '6e825bd12e3b14c47cc76f6a31bbdae0';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _fetchWeather(String city) async {
    if (city.trim().isEmpty) {
      setState(() {
        _error = 'Please enter a city name';
        _data = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final uri = Uri.parse('$_baseUrl?q=$city&appid=$_apiKey&units=metric');

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final parsed = WeatherData.fromJson(json);
        setState(() => _data = parsed);
        _fadeController.forward(from: 0);
        _slideController.forward(from: 0);
      } else {
        String msg = 'City not found';
        try {
          final j = jsonDecode(res.body);
          if (j is Map && j['message'] is String) msg = j['message'];
        } catch (_) {}
        setState(() {
          _error = msg;
          _data = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Check connection.';
        _data = null;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Color _getTopColor() {
    if (_data == null) return const Color(0xFF1e3c72);
    final desc = _data!.description.toLowerCase();
    if (desc.contains('clear')) return const Color(0xFF4facfe);
    if (desc.contains('cloud')) return const Color(0xFF6a85b6);
    if (desc.contains('rain') || desc.contains('drizzle')) return const Color(0xFF536976);
    if (desc.contains('thunder')) return const Color(0xFF2c3e50);
    if (desc.contains('snow')) return const Color(0xFFe0eafc);
    if (desc.contains('mist') || desc.contains('fog')) return const Color(0xFFbdc3c7);
    return const Color(0xFF1e3c72);
  }

  Color _getBottomColor() {
    if (_data == null) return const Color(0xFF2a5298);
    final desc = _data!.description.toLowerCase();
    if (desc.contains('clear')) return const Color(0xFF00f2fe);
    if (desc.contains('cloud')) return const Color(0xFFbac8e0);
    if (desc.contains('rain') || desc.contains('drizzle')) return const Color(0xFF292e49);
    if (desc.contains('thunder')) return const Color(0xFF000000);
    if (desc.contains('snow')) return const Color(0xFFcfdef3);
    if (desc.contains('mist') || desc.contains('fog')) return const Color(0xFF8e9eab);
    return const Color(0xFF2a5298);
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 1000),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_getTopColor(), _getBottomColor()],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particleController.value, _data?.description),
                  size: Size.infinite,
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        'Weather',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(0.95),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildSearchBar(),
                    const SizedBox(height: 30),
                    if (_loading)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  color: Colors.white.withOpacity(0.9),
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Fetching weather...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_error != null)
                      Expanded(
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.scale(
                                  scale: 0.8 + (0.2 * value),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 50,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (_data != null)
                        Expanded(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildWeatherCard(),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Center(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value * 0.6,
                                  child: child,
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_outlined,
                                    size: 100,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Search for a city',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _cityCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _fetchWeather(_cityCtrl.text),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Enter city name...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.7),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Material(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(26),
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () => _fetchWeather(_cityCtrl.text),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_data == null) return const SizedBox();

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _data!.city,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _data!.description.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 20),
                if (_data!.iconUrl != null)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.5 + (0.5 * value),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Image.network(
                      _data!.iconUrl!,
                      width: 120,
                      height: 120,
                    ),
                  ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: _data!.temp),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      '${value.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        height: 1,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoTile(
                      Icons.thermostat,
                      'Feels like',
                      '${_data!.feelsLike.toStringAsFixed(1)}°C',
                    ),
                    _buildInfoTile(
                      Icons.water_drop,
                      'Humidity',
                      '${_data!.humidity}%',
                    ),
                    _buildInfoTile(
                      Icons.air,
                      'Wind',
                      '${_data!.wind.toStringAsFixed(1)} m/s',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Updated: ${_data!.updatedAt}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.9),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animation;
  final String? weatherDesc;

  ParticlePainter(this.animation, this.weatherDesc);

  @override
  void paint(Canvas canvas, Size size) {
    if (weatherDesc == null) return;

    final desc = weatherDesc!.toLowerCase();
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    if (desc.contains('rain') || desc.contains('drizzle')) {
      for (int i = 0; i < 50; i++) {
        final x = (i * 37) % size.width;
        final y = ((animation * size.height * 2) + (i * 71)) % size.height;
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + 15),
          paint,
        );
      }
    } else if (desc.contains('snow')) {
      paint.style = PaintingStyle.fill;
      for (int i = 0; i < 30; i++) {
        final x = (i * 53 + animation * 20) % size.width;
        final y = ((animation * size.height) + (i * 97)) % size.height;
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    } else {
      for (int i = 0; i < 20; i++) {
        final x = (i * 71 + math.sin(animation * math.pi * 2 + i) * 30) % size.width;
        final y = (i * 89) % size.height;
        canvas.drawCircle(
          Offset(x, y),
          2,
          paint..color = Colors.white.withOpacity(0.15),
        );
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class WeatherData {
  final String city;
  final double temp;
  final double feelsLike;
  final int humidity;
  final double wind;
  final String description;
  final String? iconUrl;
  final String updatedAt;

  WeatherData({
    required this.city,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.wind,
    required this.description,
    required this.iconUrl,
    required this.updatedAt,
  });

  factory WeatherData.fromJson(Map<String, dynamic> j) {
    final weather = (j['weather'] as List).isNotEmpty ? j['weather'][0] : null;
    final main = j['main'] ?? {};
    final wind = j['wind'] ?? {};
    final city = j['name'] ?? '';
    final iconCode = (weather != null && weather['icon'] != null)
        ? weather['icon'] as String
        : '';
    final iconUrl = iconCode.isNotEmpty
        ? 'https://openweathermap.org/img/wn/$iconCode@4x.png'
        : null;

    final dt = j['dt'] is int
        ? DateTime.fromMillisecondsSinceEpoch(j['dt'] * 1000, isUtc: true).toLocal()
        : DateTime.now();

    return WeatherData(
      city: city,
      temp: (main['temp'] as num?)?.toDouble() ?? 0,
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0,
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      wind: (wind['speed'] as num?)?.toDouble() ?? 0,
      description: (weather != null ? (weather['description'] ?? '') : '').toString(),
      iconUrl: iconUrl,
      updatedAt: '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
    );
  }
}