import 'dart:async';

import 'package:mc_domain/mc_domain.dart';

/// Tiempo máximo de espera para la generación de template con IA.
///
/// El endpoint /ai/ai/generate-template puede tener alta latencia.
/// Pasado este límite se lanza [AIGenerationTimeoutException].
const _kDefaultAiTimeout = Duration(seconds: 30);

/// El servicio de IA superó el tiempo límite de respuesta.
class AIGenerationTimeoutException implements Exception {
  final String message;

  const AIGenerationTimeoutException([
    this.message = 'La generación con IA superó el tiempo de espera.',
  ]);

  @override
  String toString() => 'AIGenerationTimeoutException: $message';
}

class GenerateTemplateWithAIUseCase {
  final QuickstartRepository _repository;
  final Duration _timeout;

  GenerateTemplateWithAIUseCase(
    this._repository, {
    Duration timeout = _kDefaultAiTimeout,
  }) : _timeout = timeout;

  /// Genera un [BusinessTypeTemplate] a partir de una descripción en lenguaje
  /// natural enviada al ai-gateway.
  ///
  /// Lanza [AIGenerationTimeoutException] si la respuesta supera [_timeout].
  /// Cualquier otro error del repositorio se propaga sin modificar.
  Future<BusinessTypeTemplate> execute(
    String description,
    String businessTypeId,
  ) async {
    try {
      return await _repository
          .generateTemplateWithAI(description, businessTypeId)
          .timeout(_timeout);
    } on TimeoutException {
      throw const AIGenerationTimeoutException();
    }
  }
}
