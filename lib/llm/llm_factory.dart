import 'openai_client.dart';
import 'claude_client.dart';
import 'deepseek_client.dart';
import 'base_llm_client.dart';
import 'package:ChatMcp/provider/provider_manager.dart';
import 'package:logging/logging.dart';

enum LLMProvider { openAI, claude, llama, deepSeek }

class LLMFactory {
  static BaseLLMClient create(LLMProvider provider,
      {required String apiKey, required String baseUrl}) {
    switch (provider) {
      case LLMProvider.openAI:
        return OpenAIClient(apiKey: apiKey, baseUrl: baseUrl);
      case LLMProvider.claude:
        return ClaudeClient(apiKey: apiKey, baseUrl: baseUrl);
      case LLMProvider.deepSeek:
        return DeepSeekClient(apiKey: apiKey, baseUrl: baseUrl);
      default:
        throw Exception('Unsupported LLM provider');
    }
  }
}

class LLMFactoryHelper {
  static final modelMapping = {
    'gpt': 'openai',
    'o1': 'openai',
    'o3': 'openai',
    'sonnet': 'claude',
    'haiku': 'claude',
    'deepseek': 'deepseek',
  };

  static final Map<String, LLMProvider> providerMap = {
    "openai": LLMProvider.openAI,
    "claude": LLMProvider.claude,
    "deepseek": LLMProvider.deepSeek,
  };

  static BaseLLMClient createFromModel(String currentModel) {
    // 根据模型名称判断 provider
    final provider = LLMFactoryHelper.modelMapping.entries.firstWhere(
      (entry) => currentModel.startsWith(entry.key),
      orElse: () => throw ArgumentError("Unknown model type: $currentModel"),
    );

    // 获取配置信息
    final apiKey =
        ProviderManager.settingsProvider.apiSettings[provider.key]?.apiKey ??
            '';
    final baseUrl = ProviderManager
            .settingsProvider.apiSettings[provider.key]?.apiEndpoint ??
        '';

    Logger.root.fine(
        'Using API Key: ****** for provider: ${provider.toString()} model: $currentModel');

    // 创建 LLM 客户端
    return LLMFactory.create(
        LLMFactoryHelper.providerMap[provider.value] ??
            (throw ArgumentError("Unknown provider: $provider")),
        apiKey: apiKey,
        baseUrl: baseUrl);
  }

  static Future<List<String>> getAvailableModels() async {
    List<String> models = [];
    for (var provider in LLMFactoryHelper.providerMap.entries) {
      final apiKey =
          ProviderManager.settingsProvider.apiSettings[provider.key]?.apiKey ??
              '';
      final baseUrl = ProviderManager
              .settingsProvider.apiSettings[provider.key]?.apiEndpoint ??
          '';
      final client =
          LLMFactory.create(provider.value, apiKey: apiKey, baseUrl: baseUrl);
      models.addAll(await client.models());
    }

    return models;
  }
}
