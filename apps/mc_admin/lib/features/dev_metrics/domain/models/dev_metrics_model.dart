class DeployCount {
  final int ok;
  final int fail;

  const DeployCount({required this.ok, required this.fail});

  int get total => ok + fail;

  factory DeployCount.fromJson(Map<String, dynamic> json) => DeployCount(
        ok: (json['ok'] as num?)?.toInt() ?? 0,
        fail: (json['fail'] as num?)?.toInt() ?? 0,
      );
}

class DevMetrics {
  final int totalSessions;
  final int totalAgentCalls;
  final int totalDeploys;
  final Map<String, int> callsByStage;
  final Map<String, int> callsByScenario;
  final Map<String, int> callsBySpec;
  final Map<String, int> callsByLevel;

  /// e.g. {"2026-05-28": 3} — sorted ascending
  final Map<String, int> sessionsByDay;

  /// keyed by service name
  final Map<String, DeployCount> deploysByService;

  const DevMetrics({
    required this.totalSessions,
    required this.totalAgentCalls,
    required this.totalDeploys,
    required this.callsByStage,
    required this.callsByScenario,
    required this.callsBySpec,
    required this.callsByLevel,
    required this.sessionsByDay,
    required this.deploysByService,
  });

  factory DevMetrics.fromJson(Map<String, dynamic> json) {
    Map<String, int> _intMap(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }

    final sessionsByDay = <String, int>{};
    final rawDays = json['sessions_by_day'];
    if (rawDays is List) {
      for (final item in rawDays) {
        if (item is Map<String, dynamic>) {
          final day = item['day'] as String? ?? '';
          final count = (item['count'] as num?)?.toInt() ?? 0;
          if (day.isNotEmpty) sessionsByDay[day] = count;
        }
      }
    }

    final deploysByService = <String, DeployCount>{};
    final rawDeploys = json['deploys_by_service'];
    if (rawDeploys is Map) {
      rawDeploys.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          deploysByService[k.toString()] = DeployCount.fromJson(v);
        }
      });
    }

    return DevMetrics(
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      totalAgentCalls: (json['total_agent_calls'] as num?)?.toInt() ?? 0,
      totalDeploys: (json['total_deploys'] as num?)?.toInt() ?? 0,
      callsByStage: _intMap(json['calls_by_stage']),
      callsByScenario: _intMap(json['calls_by_scenario']),
      callsBySpec: _intMap(json['calls_by_spec']),
      callsByLevel: _intMap(json['calls_by_level']),
      sessionsByDay: sessionsByDay,
      deploysByService: deploysByService,
    );
  }

  static DevMetrics empty() => const DevMetrics(
        totalSessions: 0,
        totalAgentCalls: 0,
        totalDeploys: 0,
        callsByStage: {},
        callsByScenario: {},
        callsBySpec: {},
        callsByLevel: {},
        sessionsByDay: {},
        deploysByService: {},
      );
}
