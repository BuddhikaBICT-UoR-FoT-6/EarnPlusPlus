import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../config/app_config.dart';
import '../domain/investment_summary_dto.dart';

// The SmartInsightController handles only the NLP query state and logic,
// strictly separating it from the InvestmentController (CRUD operations)
// to satisfy the Single Responsibility Principle (SRP).
class SmartInsightController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _insights = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get insights => _insights;

  Future<void> askPortfolio(String query, List<InvestmentSummaryDto> investments) async {
    if (query.trim().isEmpty) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (AppConfig.geminiApiKey.isEmpty) {
        throw Exception('Gemini API Key is not configured.');
      }

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: AppConfig.geminiApiKey,
      );

      final portfolioString = investments.map((inv) {
        return '- ${inv.name}: \$${inv.currentValue.toStringAsFixed(2)} (P/L: ${inv.plPercent.toStringAsFixed(2)}%)';
      }).join('\n');

      final prompt = '''
You are a financial AI analyzing a user's offline investment portfolio.
The user has the following investments:
$portfolioString

The user asks: "$query"

Based on the portfolio data and the user's query, provide 1 to 3 insightful observations.
You MUST respond ONLY with a valid JSON array of objects. Do NOT wrap the JSON in Markdown formatting like ```json.
Each object must have exactly two string properties: "tag" (max 3 words) and "description" (max 2 sentences).
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Received empty response from AI.');
      }

      String rawJson = response.text!.trim();
      // Safely strip out Markdown wrapping if the AI ignores instructions
      if (rawJson.startsWith('```json')) {
        rawJson = rawJson.replaceFirst('```json', '').trim();
      }
      if (rawJson.startsWith('```')) {
        rawJson = rawJson.replaceFirst('```', '').trim();
      }
      if (rawJson.endsWith('```')) {
        rawJson = rawJson.substring(0, rawJson.length - 3).trim();
      }

      final List<dynamic> jsonArray = jsonDecode(rawJson);
      
      _insights = jsonArray.map((e) => {
        'tag': e['tag'] ?? 'Insight',
        'description': e['description'] ?? 'No description provided.',
      }).toList();

    } catch (e) {
      _error = 'Failed to generate insights. Please try again.';
      debugPrint('Gemini API Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
