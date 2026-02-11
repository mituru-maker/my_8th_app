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
    final prefs = await SharedPreferences.getInstance();
    // Force reload latest value
    await prefs.reload();
    _apiKey = prefs.getString(AppConstants.apiKeyStorageKey);
    
    // Don't auto-initialize model, require user to set API key each time
    print('ApiService: Initialized (API key requires manual input)');
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
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(AppConstants.apiKeyStorageKey, apiKey);
      await prefs.reload(); // For immediate reflection in web version
      
      if (result) {
        _apiKey = apiKey;
        // Don't auto-initialize model, wait for user to trigger analysis
        print('ApiService: API Key saved (model will be initialized on first use)');
      }
      return result;
    } catch (e) {
      print('ApiService: Error saving API key: $e');
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
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty && _model != null;
}
