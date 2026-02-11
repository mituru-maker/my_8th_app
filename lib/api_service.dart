import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import 'constants.dart';

class ApiService {
  // Singleton implementation
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  GenerativeModel? _model;
  String? _apiKey;

  // Initialize: called on app startup or after settings change
  Future<void> initialize() async {
    try {
      print('ApiService: Initializing...');
      final prefs = await SharedPreferences.getInstance();
      
      // Force reload latest value
      await prefs.reload();
      _apiKey = prefs.getString(AppConstants.apiKeyStorageKey);
      
      print('ApiService: Initialization complete');
      print('ApiService: API key found: ${_apiKey != null ? "yes" : "no"}');
      if (_apiKey != null) {
        print('ApiService: API key length: ${_apiKey!.length}');
      }
      
      // Don't auto-initialize model, require user to set API key each time
      print('ApiService: Ready for manual API key input');
    } catch (e) {
      print('ApiService: Initialization error: $e');
      _apiKey = null;
    }
  }

  void _initializeModel() {
    if (_apiKey == null || _apiKey!.isEmpty) return;

    print('ApiService: Attempting to initialize with available models...');

    // Try each model candidate until one works
    for (int i = 0; i < AppConstants.modelCandidates.length; i++) {
      final modelName = AppConstants.getModelName(i);
      final cleanModelName = AppConstants.cleanModelName(modelName);
      
      try {
        print('ApiService: Trying model: $cleanModelName');
        
        _model = GenerativeModel(
          model: cleanModelName,
          apiKey: _apiKey!,
          safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
          ],
        );
        
        print('ApiService: Successfully initialized with: $cleanModelName');
        return; // Success, exit the loop
        
      } catch (e) {
        print('ApiService: Model $cleanModelName failed: $e');
        if (i == AppConstants.modelCandidates.length - 1) {
          // Last model failed, set model to null
          _model = null;
          print('ApiService: All models failed, no model available');
        }
      }
    }
  }

  Future<bool> saveApiKey(String apiKey) async {
    try {
      print('ApiService: Attempting to save API key...');
      final prefs = await SharedPreferences.getInstance();
      
      // Clear any existing key first
      await prefs.remove(AppConstants.apiKeyStorageKey);
      
      // Save new key
      final result = await prefs.setString(AppConstants.apiKeyStorageKey, apiKey);
      
      // Force reload for web
      await prefs.reload();
      
      // Verify the key was saved
      final savedKey = prefs.getString(AppConstants.apiKeyStorageKey);
      
      if (result && savedKey == apiKey) {
        _apiKey = apiKey;
        print('ApiService: API Key saved successfully');
        print('ApiService: Key length: ${apiKey.length}');
        return true;
      } else {
        print('ApiService: Failed to save API key');
        print('ApiService: Save result: $result');
        print('ApiService: Saved key verification: ${savedKey != null ? "success" : "failed"}');
        return false;
      }
    } catch (e) {
      print('ApiService: Error saving API key: $e');
      print('ApiService: Error type: ${e.runtimeType}');
      return false;
    }
  }

  Future<bool> testConnection() async {
    // Force model regeneration before test
    _initializeModel();
    if (_model == null) return false;

    try {
      final response = await _model!.generateContent([Content.text('Hi')]);
      return response.text != null;
    } catch (e) {
      print('ApiService: Test failed: $e');
      return false;
    }
  }

  Future<String> analyzeImage({
    required String prompt,
    required Uint8List imageBytes,
  }) async {
    // Reload latest key just before execution
    await initialize();
    
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('APIキーが設定されていません。設定画面でAPIキーを入力してください。');
    }

    // Initialize model on first use
    _initializeModel();
    
    if (_model == null) {
      throw Exception('モデルの初期化に失敗しました。APIキーを確認してください。');
    }

    // Try with current model first, then fallback to other models if needed
    for (int i = 0; i < AppConstants.modelCandidates.length; i++) {
      final modelName = AppConstants.getModelName(i);
      final cleanModelName = AppConstants.cleanModelName(modelName);
      
      try {
        print('ApiService: Analyzing with model: $cleanModelName');
        
        // Always re-initialize model for each attempt
        _model = GenerativeModel(
          model: cleanModelName,
          apiKey: _apiKey!,
          safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
          ],
        );

        List<Content> contents = [
          Content.multi([
            TextPart(prompt), 
            DataPart('image/jpeg', imageBytes)
          ])
        ];

        final response = await _model!.generateContent(contents);
        final result = response.text ?? 'レスポンスが空でした。';
        
        print('ApiService: Successfully analyzed with: $cleanModelName');
        
        // Clear API key after successful use for security
        await clearApiKey();
        
        return result;
        
      } catch (e) {
        print('ApiService: Analysis failed with $cleanModelName: $e');
        if (i == AppConstants.modelCandidates.length - 1) {
          // Last model failed
          throw Exception('すべてのモデルで画像分析に失敗しました: $e');
        }
      }
    }
    
    throw Exception('有効なモデルが見つかりませんでした');
  }

  // Clear API key for security
  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.apiKeyStorageKey);
    _apiKey = null;
    _model = null;
    print('ApiService: API key cleared for security');
  }

  // Legacy methods for backward compatibility
  static Future<void> saveApiKeyLegacy(String apiKey) async {
    final instance = ApiService();
    await instance.saveApiKey(apiKey);
  }

  static Future<String?> getApiKey() async {
    final instance = ApiService();
    await instance.initialize();
    return instance._apiKey;
  }

  static Future<void> removeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.apiKeyStorageKey);
  }

  String? get apiKey => _apiKey;
  bool get isConfigured {
    // Check if we have a non-empty API key
    final hasKey = _apiKey != null && _apiKey!.isNotEmpty;
    print('ApiService: isConfigured check - hasKey: $hasKey');
    return hasKey;
  }
}
