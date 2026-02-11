# AI Image Analyzer

A Flutter application that uses Google's Gemini 3.0 Flash AI model to analyze images and provide detailed descriptions in Japanese.

## Features

- 🖼️ **Image Selection**: Pick images from your device gallery
- 🤖 **AI Analysis**: Analyze images using Gemini 3.0 Flash model
- 🔐 **Secure API Key Management**: Store API keys safely using SharedPreferences
- 🌐 **Web Compatible**: Works seamlessly in web browsers
- 📱 **Responsive Design**: Optimized for both mobile and desktop
- 🔄 **Robust Fallback**: Automatic model switching for maximum compatibility

## AI Model

This application uses **Gemini 3.0 Flash** (`gemini-3-flash-preview`) as the primary AI model with automatic fallback to:

- `gemini-1.5-flash` (stable version)
- `gemini-2.0-flash-exp` (experimental)

## Setup Instructions

### Prerequisites

- Flutter SDK (>= 3.6.0)
- Google AI Studio API Key

### 1. Get API Key

1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Create a new API key
3. Copy the key for use in the app

### 2. Run the App

#### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd my_8th_app

# Install dependencies
flutter pub get

# Run on Chrome (recommended)
flutter run -d chrome

# Or run on mobile device
flutter run
```

#### GitHub Pages

The app is deployed and available at:
```
https://<username>.github.io/my_8th_app/
```

### 3. Configure API Key

1. Open the app
2. Click the settings icon (⚙️) in the top-right corner
3. Enter your Gemini API key
4. Click "保存" (Save)

## Usage

1. **Select Image**: Tap "画像を選択" to choose an image from your gallery
2. **Preview**: The selected image will be displayed on screen
3. **Analyze**: Tap "画像を分析する" to start AI analysis
4. **View Results**: The analysis results will appear in Japanese below the image

## Technical Details

### Architecture

- **Singleton Pattern**: `ApiService` manages AI model initialization and API calls
- **Model Fallback System**: Automatically tries different Gemini models until one works
- **Web Compatibility**: Uses `Image.memory` for cross-platform image display
- **Secure Storage**: API keys stored locally using `SharedPreferences`

### Key Dependencies

- `google_generative_ai`: Google Gemini AI SDK
- `image_picker`: Cross-platform image selection
- `shared_preferences`: Local data storage
- `flutter`: UI framework

### Safety Settings

The app configures Gemini AI with unrestricted content analysis:
- Harassment: None
- Hate Speech: None  
- Sexually Explicit: None
- Dangerous Content: None

## Error Handling

The app includes comprehensive error handling:

- **Model Not Found**: Automatically falls back to available models
- **API Key Issues**: Clear error messages and setup guidance
- **Network Errors**: User-friendly error notifications
- **Image Processing**: Graceful handling of unsupported formats

## Development

### Project Structure

```
lib/
├── main.dart              # Main application UI
├── api_service.dart       # AI service management
└── constants.dart         # App constants and model config
```

### Building for Production

```bash
# Build for web deployment
flutter build web --release

# Using peanut for GitHub Pages
flutter pub global run peanut --extra-args "--base-href=/my_8th_app/"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is for educational and demonstration purposes.

## Support

For issues or questions:

1. Check the error messages in the app
2. Ensure your API key is valid
3. Verify internet connectivity
4. Try restarting the app

---

**Note**: This app requires an active internet connection and valid Google Gemini API key to function.
