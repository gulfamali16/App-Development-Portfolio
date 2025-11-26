# Weather App Documentation

## 📱 Overview
A beautiful, heavily animated weather application built with Flutter that provides real-time weather information for cities worldwide. The app features dynamic backgrounds, particle animations, and smooth transitions that change based on weather conditions.

---

## 🎯 Features

### Core Functionality
- **Real-time Weather Data**: Fetches current weather information from OpenWeatherMap API
- **City Search**: Search any city worldwide to get weather updates
- **Metric Units**: Displays temperature in Celsius and wind speed in m/s

### Visual Features
- **Dynamic Backgrounds**: Gradient backgrounds that change based on weather conditions
  - Clear sky: Bright blue gradient
  - Cloudy: Gray-blue gradient
  - Rainy: Dark gray gradient
  - Snowy: Light blue-white gradient
  - Foggy/Misty: Gray gradient
  - Thunderstorm: Very dark gradient

- **Particle Animations**: 
  - Rain drops for rainy weather
  - Snowflakes for snowy weather
  - Floating particles for clear/cloudy weather

- **Smooth Animations**:
  - Fade-in effects when data loads
  - Slide-up transitions for weather cards
  - Scale animations for error messages
  - Animated temperature counter
  - Staggered animations for weather details

---

## 🏗️ Architecture

### File Structure
```
lib/
└── main.dart (Single file application)
```

### Main Components

#### 1. **WeatherApp** (Root Widget)
- StatelessWidget
- Sets up MaterialApp with theme
- Entry point of the application

#### 2. **WeatherHome** (Main Screen)
- StatefulWidget
- Manages the home screen UI
- Handles user interactions

#### 3. **_WeatherHomeState** (Business Logic)
- Manages application state
- Handles API calls
- Controls all animations
- Updates UI based on data

#### 4. **ParticlePainter** (Custom Painter)
- Creates animated particle effects
- Renders rain, snow, or ambient particles
- Updates continuously based on weather

#### 5. **WeatherData** (Data Model)
- Represents weather information
- Parses JSON from API
- Provides clean data interface

---

## 🔧 Technical Details

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0  # For API requests
```

### API Integration
- **API**: OpenWeatherMap Current Weather API
- **Endpoint**: `https://api.openweathermap.org/data/2.5/weather`
- **Parameters**:
  - `q`: City name
  - `appid`: API key
  - `units`: metric (Celsius)

### Animation Controllers
The app uses three main animation controllers:

1. **_fadeController** (800ms)
   - Controls fade-in opacity
   - Used for weather card appearance

2. **_slideController** (600ms)
   - Controls slide-up animation
   - Uses easeOutCubic curve

3. **_particleController** (20 seconds)
   - Continuous loop for particles
   - Creates ambient weather effects

---

## 📊 State Management

### State Variables
```dart
bool _loading          // Loading indicator state
String? _error         // Error message
WeatherData? _data     // Weather information
TextEditingController _cityCtrl  // Search input
```

### State Flow
1. User enters city name
2. `_loading` set to true
3. API request made
4. On success: `_data` populated, animations triggered
5. On error: `_error` message displayed
6. `_loading` set to false

---

## 🎨 UI Components

### Search Bar
- Frosted glass effect with transparency
- Search icon on left
- Forward arrow button on right
- Submits on Enter key or button tap

### Weather Card
Displays:
- City name (large, light font)
- Weather description (uppercase, spaced)
- Weather icon (animated scale-in)
- Temperature (animated counter, 72px)
- Three info tiles:
  - Feels like temperature
  - Humidity percentage
  - Wind speed
- Last update timestamp

### Loading State
- Centered circular progress indicator
- "Fetching weather..." text
- White color with transparency

### Error State
- Icon with error symbol
- Error message in glass container
- Scale-in animation

### Empty State
- Cloud icon
- "Search for a city" prompt
- Subtle fade-in animation

---

## 🌈 Color Schemes

### Weather-Based Gradients

| Weather Condition | Top Color | Bottom Color |
|------------------|-----------|--------------|
| Clear | `#4facfe` | `#00f2fe` |
| Cloudy | `#6a85b6` | `#bac8e0` |
| Rainy | `#536976` | `#292e49` |
| Thunderstorm | `#2c3e50` | `#000000` |
| Snow | `#e0eafc` | `#cfdef3` |
| Fog/Mist | `#bdc3c7` | `#8e9eab` |
| Default | `#1e3c72` | `#2a5298` |

---

## 🔄 Data Flow

```
User Input → Search Button → API Request
                ↓
         HTTP Response
                ↓
         JSON Parsing
                ↓
      WeatherData Model
                ↓
         setState()
                ↓
    Trigger Animations
                ↓
         Update UI
```

---

## 📱 Responsive Design

- Uses `SafeArea` for device compatibility
- `ConstrainedBox` limits max width on tablets
- `SingleChildScrollView` for small screens
- Adaptive padding and spacing
- Works on all screen sizes

---

## 🎭 Animation Details

### Entry Animations
1. **Title**: Fade-in + slide-down (600ms)
2. **Search Bar**: Visible from start
3. **Weather Card**: Fade + slide-up (800ms total)

### Weather Card Animations
1. City name appears
2. Icon scales from 50% to 100% (800ms)
3. Temperature counts up from 0 (1200ms)
4. Info tiles stagger in (600ms each)

### Continuous Animations
- Particles move continuously (20s loop)
- Background transitions smoothly (1000ms)

---

## ⚙️ Configuration

### API Key Setup
```dart
static const String _apiKey = 'YOUR_API_KEY_HERE';
```

Replace with your OpenWeatherMap API key.

### Getting API Key
1. Visit [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for free account
3. Generate API key
4. Copy key to `_apiKey` constant

---

## 🐛 Error Handling

### Network Errors
- Catches connection failures
- Displays: "Network error. Check connection."

### API Errors
- Parses error messages from API
- Common: "City not found"
- Shows in animated error container

### Input Validation
- Checks for empty city name
- Shows: "Please enter a city name"

---

## 🚀 Usage Guide

### Running the App
```bash
# Get dependencies
flutter pub get

# Run on connected device
flutter run

# Build for release (Android)
flutter build apk --release

# Build for release (iOS)
flutter build ios --release
```

### Using the App
1. Launch the app
2. Type city name in search bar
3. Press Enter or tap arrow button
4. View animated weather information
5. Search again for different city

---

## 🎯 Key Methods

### `_fetchWeather(String city)`
- Validates input
- Makes HTTP GET request
- Parses JSON response
- Updates state with result
- Triggers animations on success

### `_getTopColor()` / `_getBottomColor()`
- Returns colors based on weather
- Creates dynamic gradient
- Checks weather description keywords

### `WeatherData.fromJson(Map json)`
- Factory constructor
- Parses API response
- Handles null values safely
- Formats timestamp

---

## 💡 Customization Tips

### Change Animation Speed
```dart
// Make animations faster
duration: const Duration(milliseconds: 400)

// Make animations slower
duration: const Duration(milliseconds: 1200)
```

### Add More Weather Conditions
```dart
if (desc.contains('windy')) return const Color(0xFFYOURCOLOR);
```

### Adjust Particle Density
```dart
// More particles
for (int i = 0; i < 100; i++)

// Fewer particles
for (int i = 0; i < 20; i++)
```

### Change Temperature Unit
```dart
// In API URL
units=imperial  // Fahrenheit
units=metric    // Celsius (current)
```

---

## 📋 Requirements

- **Flutter SDK**: >=3.0.0 <4.0.0
- **Dart**: 3.0+
- **Platform**: iOS, Android, Web, Desktop
- **Internet**: Required for API calls

---

## 🔒 Permissions

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS (Info.plist)
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## 🎨 Design Principles

1. **Minimalism**: Single screen, focused experience
2. **Clarity**: Clear hierarchy and readable typography
3. **Responsiveness**: Smooth animations provide feedback
4. **Atmosphere**: Design matches weather conditions
5. **Accessibility**: High contrast, readable fonts

---

## 🐛 Known Limitations

- Requires internet connection
- API has rate limits (free tier)
- Weather data updates every 10 minutes (API side)
- Particle animations may impact battery on older devices

---

## 🚀 Future Enhancements

- [ ] Add location-based auto-detection
- [ ] Implement weather forecast (5-day)
- [ ] Add favorite cities
- [ ] Include hourly weather
- [ ] Add weather alerts
- [ ] Implement dark/light theme toggle
- [ ] Cache last searched city
- [ ] Add more particle effects
- [ ] Include sunrise/sunset times
- [ ] Add UV index and air quality

---

## 📞 Support

For issues or questions:
1. Check API key is valid
2. Verify internet connection
3. Ensure dependencies are installed
4. Check Flutter version compatibility

---

## 📄 License

This app uses OpenWeatherMap API. Make sure to comply with their [terms of service](https://openweathermap.org/terms).

---

## 🙏 Credits

- **Weather Data**: OpenWeatherMap API
- **Framework**: Flutter by Google
- **Icons**: Material Icons
- **Design**: Custom gradient and animation implementation

---

**Version**: 1.0.0  
**Last Updated**: November 2025 
**Compatibility**: Flutter 3.0+

**Screen Shots**

<p align="center">
  <img src="https://github.com/user-attachments/assets/29085539-57ee-44ab-8660-052a67435f45" width="30%" style="margin-right:10px;" />
  <img src="https://github.com/user-attachments/assets/fc1f23e7-1067-45f7-8dd2-b1a463f43932" width="30%" style="margin-right:10px;" />
  <img src="https://github.com/user-attachments/assets/f57befc0-73fa-443f-bf4c-50ad4fe3ee10" width="30%" />
</p>

