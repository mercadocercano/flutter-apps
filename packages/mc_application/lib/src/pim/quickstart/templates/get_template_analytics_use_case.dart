import 'package:mc_domain/mc_domain.dart';

class GetTemplateAnalyticsUseCase {
  final QuickstartRepository _repository;

  GetTemplateAnalyticsUseCase(this._repository);

  Future<TemplateAnalytics> execute(String id) {
    return _repository.getTemplateAnalytics(id);
  }
}
