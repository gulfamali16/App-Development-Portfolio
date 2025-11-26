
# 📱 BMI CALCULATOR APP - COMPLETE DOCUMENTATION

## 🎯 PROJECT OVERVIEW
A beautiful, modern BMI (Body Mass Index) Calculator built with Flutter. This app features a dark gradient theme, gender-based calculations, and provides personalized health insights.

---

## 📂 PROJECT STRUCTURE

```
bmi_calculator/
│
├── lib/
│   ├── main.dart                    # Main application file with InputPage
│   ├── CalculatorBrain.dart         # BMI calculation logic
│   ├── resultfile.dart              # Result page display
│   ├── constantfile.dart            # All app constants
│   ├── IconCard.dart                # Reusable icon card widget
│   └── RepeatContainerCode.dart     # Reusable container widget
│
└── pubspec.yaml                     # Flutter dependencies
```

---

## 📋 FILE DESCRIPTIONS

### 1️⃣ **main.dart**
- **Purpose**: Main entry point and input page
- **Contains**:
  - `BMICalculatorApp` - MaterialApp setup
  - `Gender` enum - Male/Female selection
  - `InputPage` - Main input screen with UI
  - `_InputPageState` - State management for inputs

**Key Features**:
- Beautiful gradient background (dark blue theme)
- Custom styled AppBar with gradient text
- Gender selection (Male/Female) with active/inactive states
- Height slider (54-272 cm)
- Weight input with +/- buttons (1-300 kg)
- Age input with +/- buttons (1-120 years)
- Calculate button navigates to result page

---

### 2️⃣ **CalculatorBrain.dart**
- **Purpose**: BMI calculation logic with gender and age adjustments
- **Class**: `CalculatorBrain`

**Methods**:
- `calculateBMI()` - Calculates BMI with gender/age adjustments
  - Formula: `weight(kg) / (height(m))²`
  - Male adjustment: +2% (more muscle mass)
  - Female adjustment: -2% (different body composition)
  - Age > 50: +1% (slower metabolism)
  - Age < 20: -1% (faster metabolism)

- `getResult()` - Returns BMI category
  - Underweight: < 18.5
  - Normal: 18.5 - 24.9
  - Overweight: ≥ 25

- `getInterpretation()` - Returns personalized health message

- `getResultColor()` - Returns color based on BMI
  - Green: Normal
  - Orange: Underweight
  - Red: Overweight

---

### 3️⃣ **resultfile.dart**
- **Purpose**: Display BMI calculation results
- **Class**: `ResultFile` (StatelessWidget)

**Parameters**:
- `bmiResult` - Calculated BMI value (String)
- `resultText` - Category (Normal/Overweight/Underweight)
- `interpretation` - Personalized health message
- `resultColor` - Dynamic color based on result

**Features**:
- Beautiful gradient background matching theme
- Large BMI number display (100px font)
- Color-coded result status
- Detailed interpretation message
- "ReCALCULATE" button (Navigator.pop back to input)

---

### 4️⃣ **constantfile.dart**
- **Purpose**: Centralized constants for consistent styling

**Color Constants**:
```dart
kActiveCardColor = #1E1E2E      // Active container color
kInactiveCardColor = #111328    // Inactive container color
kBottomContainerColor = #EB1555 // Red button color
```

**Text Style Constants**:
```dart
kLabelTextStyle     // 18px, bold, white70
kNumberTextStyle    // 45px, w900, white
```

**Size Constants**:
```dart
kContainerMargin = 10.0
kContainerBorderRadius = 10.0
kIconSize = 70.0
kSpaceBetweenIconAndLabel = 10.0
```

**Range Constants**:
```dart
kMinHeight = 54.0
kMaxHeight = 272.0
kMinWeight = 1
kMaxWeight = 300
kMinAge = 1
kMaxAge = 120
```

---

### 5️⃣ **IconCard.dart**
- **Purpose**: Reusable widget for displaying icon with label
- **Class**: `IconCard` (StatelessWidget)

**Parameters**:
- `icon` - IconData (e.g., Icons.male_rounded)
- `label` - String label text

**Usage**: Used in Male/Female gender selection containers

---

### 6️⃣ **RepeatContainerCode.dart**
- **Purpose**: Reusable container with GestureDetector
- **Class**: `RepeatContainerCode` (StatelessWidget)

**Parameters**:
- `colors` - Background color
- `cardWidget` - Child widget to display
- `onPress` - Optional callback function

**Features**:
- Built-in GestureDetector
- Consistent margin and border radius
- Used throughout app for all containers

---

## 🎨 DESIGN FEATURES

### Color Scheme
- **Primary**: Cyan (#00D9FF)
- **Secondary**: Purple (#7B61FF)
- **Background**: Dark blue gradient (#0F0F1E to #16213E)
- **Active Cards**: #1E1E2E
- **Inactive Cards**: #111328
- **Button**: Red (#EB1555)

### Typography
- **App Title**: 22px, bold, gradient text
- **Labels**: 18px, bold, white70
- **Numbers**: 45px, w900, white
- **Result BMI**: 100px, w900, white

### UI Components
1. **Custom AppBar** - Glassmorphism effect with gradient border
2. **Gender Cards** - Interactive with active/inactive states
3. **Height Slider** - Cyan accent with smooth interaction
4. **Increment Buttons** - Circular avatars with +/- icons
5. **Calculate Button** - Full-width red button at bottom

---

## 🔄 USER FLOW

```
1. App Launch → InputPage
   ↓
2. Select Gender (Male/Female)
   ↓
3. Adjust Height (Slider: 54-272 cm)
   ↓
4. Set Weight (+/- buttons: 1-300 kg)
   ↓
5. Set Age (+/- buttons: 1-120 years)
   ↓
6. Tap "CALCULATE" Button
   ↓
7. Navigate to ResultFile
   ↓
8. View BMI Result + Interpretation
   ↓
9. Tap "ReCALCULATE" → Back to InputPage
```

---

## 📊 BMI CALCULATION LOGIC

### Base Formula
```
BMI = weight(kg) / (height(m))²
```

### Gender Adjustments
- **Male**: BMI × 1.02 (more muscle mass)
- **Female**: BMI × 0.98 (different body composition)

### Age Adjustments
- **Age > 50**: BMI × 1.01 (slower metabolism)
- **Age < 20**: BMI × 0.99 (faster metabolism)

### BMI Categories
| Category | BMI Range | Color |
|----------|-----------|-------|
| Underweight | < 18.5 | Orange |
| Normal | 18.5 - 24.9 | Green |
| Overweight | 25 - 29.9 | Red |
| Obesity | ≥ 30 | Red |

---

## 🛠️ TECHNICAL IMPLEMENTATION

### State Management
- **StatefulWidget** for InputPage
- **setState()** for reactive UI updates
- State variables: `selectedGender`, `height`, `weight`, `age`

### Navigation
```dart
Navigator.push() - Go to result page
Navigator.pop() - Return to input page
```

### Widget Reusability
- **IconCard** - Gender selection icons
- **RepeatContainerCode** - All containers
- Consistent styling via constants

---

## 🚀 KEY FEATURES

✅ **Gender-Based Calculation** - Different adjustments for male/female
✅ **Age Consideration** - Age affects BMI interpretation
✅ **Beautiful UI** - Modern dark gradient theme
✅ **Interactive Inputs** - Slider + increment buttons
✅ **Real-Time Updates** - Instant UI feedback
✅ **Personalized Results** - Custom health messages
✅ **Color-Coded Results** - Visual health indicators
✅ **Reusable Components** - Clean, maintainable code
✅ **No Overflow Errors** - Optimized for all screens
✅ **Smooth Navigation** - Push/pop between pages

---

## 📱 SCREENS

### Screen 1: Input Page
- Gender selection (Male/Female)
- Height slider with cm display
- Weight counter with +/- buttons
- Age counter with +/- buttons
- Calculate button

### Screen 2: Result Page
- "Your Result" title
- Result category (Normal/Overweight/Underweight)
- Large BMI number
- Detailed interpretation message
- ReCALCULATE button

---

## 🎯 CODE BEST PRACTICES

1. ✅ **Separation of Concerns** - Logic separated from UI
2. ✅ **Constants File** - Centralized styling values
3. ✅ **Reusable Widgets** - DRY principle followed
4. ✅ **Proper Naming** - Clear, descriptive names
5. ✅ **Comments** - Code documentation included
6. ✅ **Type Safety** - Enum for gender selection
7. ✅ **Null Safety** - Gender? nullable type
8. ✅ **Clean Architecture** - Organized file structure

---

## 🔧 DEPENDENCIES

```yaml
dependencies:
  flutter:
    sdk: flutter
  # No external packages required - Pure Flutter!
```

---

## 📝 USAGE INSTRUCTIONS

### For Users:
1. Open app
2. Select your gender (Male/Female)
3. Adjust height slider to your height
4. Use +/- buttons to set weight
5. Use +/- buttons to set age
6. Tap "CALCULATE"
7. View your BMI result and health advice
8. Tap "ReCALCULATE" to try again

### For Developers:
1. Clone repository
2. Run `flutter pub get`
3. Run `flutter run`
4. Customize constants in `constantfile.dart`
5. Modify BMI logic in `CalculatorBrain.dart`

---

## 🎨 CUSTOMIZATION OPTIONS

### Change Colors
Edit `constantfile.dart`:
```dart
const Color kActiveCardColor = Color(0xFFYOURCOLOR);
```

### Adjust BMI Ranges
Edit `CalculatorBrain.dart`:
```dart
if (_bmi >= YOUR_VALUE) {
  return 'YOUR_CATEGORY';
}
```

### Modify Messages
Edit `getInterpretation()` in `CalculatorBrain.dart`

---

## 🐛 TROUBLESHOOTING

**Overflow Errors?**
- Reduce font sizes in constantfile.dart
- Decrease container margins
- Adjust icon sizes

**Navigation Issues?**
- Check import statements
- Verify ResultFile parameters match

**Calculation Wrong?**
- Verify height is in cm (not meters)
- Check weight is in kg (not lbs)

---

## 📌 FUTURE ENHANCEMENTS

- 💾 Save BMI history
- 📊 BMI trend charts
- 🎯 Set weight goals
- 📅 Track progress over time
- 🌍 Multiple languages
- 📤 Share results
- 🏋️ Exercise recommendations
- 🥗 Diet suggestions

---

## 👨‍💻 DEVELOPER NOTES

**Version**: 1.0.0
**Flutter SDK**: Compatible with Flutter 3.0+
**Platform**: iOS & Android
**Architecture**: Clean Architecture with reusable components
**State Management**: setState (Stateful Widget)

---

## 📄 LICENSE

MIT License - Free to use and modify

---

## 🙏 ACKNOWLEDGMENTS

Built with ❤️ using Flutter
Modern UI inspired by fitness apps
Gender/age adjustments based on health research

---

## 📞 SUPPORT

For issues or questions:
- Check code comments
- Review this documentation
- Test with different inputs
- Debug with Flutter DevTools

---

## ✅ TESTING CHECKLIST

- [ ] Gender selection works
- [ ] Height slider moves smoothly
- [ ] Weight +/- buttons increment/decrement
- [ ] Age +/- buttons increment/decrement
- [ ] Calculate button navigates to result
- [ ] BMI calculates correctly
- [ ] Result page displays all info
- [ ] ReCALCULATE returns to input
- [ ] No overflow errors on small screens
- [ ] Colors match theme
- [ ] Text is readable
- [ ] Buttons respond to taps

## ✅ ScreenShots

<p align="center">
  <img src="https://github.com/user-attachments/assets/5189b7a5-3f29-4d77-8b61-380dbd7a5c04" width="45%" />
  <img src="https://github.com/user-attachments/assets/618f82b6-8fb2-48b8-ab6b-502c19521e4f" width="45%" />
</p>



