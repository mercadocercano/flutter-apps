import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

WebJob buildWebJob({
  String id = 'job-1',
  String sourceId = 'src-1',
  WebJobStatus status = WebJobStatus.running,
  double progress = 0.0,
  int productsFound = 0,
  String? errorLog,
  DateTime? startedAt,
  DateTime? finishedAt,
}) {
  return WebJob(
    id: id,
    sourceId: sourceId,
    status: status,
    progress: progress,
    productsFound: productsFound,
    errorLog: errorLog,
    startedAt: startedAt ?? DateTime(2026, 1, 15, 10, 0),
    finishedAt: finishedAt,
  );
}

void main() {
  group('WebJob entity', () {
    test('construye correctamente con campos obligatorios', () {
      final job = buildWebJob();
      expect(job.id, 'job-1');
      expect(job.sourceId, 'src-1');
      expect(job.status, WebJobStatus.running);
      expect(job.progress, 0.0);
      expect(job.productsFound, 0);
      expect(job.errorLog, isNull);
      expect(job.finishedAt, isNull);
    });

    test('construye con todos los campos opcionales', () {
      final finished = DateTime(2026, 1, 15, 10, 30);
      final job = buildWebJob(
        status: WebJobStatus.completed,
        progress: 1.0,
        productsFound: 150,
        finishedAt: finished,
      );
      expect(job.progress, 1.0);
      expect(job.productsFound, 150);
      expect(job.finishedAt, finished);
    });

    test('igualdad por valor (Equatable)', () {
      final j1 = buildWebJob();
      final j2 = buildWebJob();
      expect(j1, equals(j2));
    });

    test('distintos ids generan entidades distintas', () {
      final j1 = buildWebJob(id: 'job-1');
      final j2 = buildWebJob(id: 'job-2');
      expect(j1, isNot(equals(j2)));
    });

    group('isActive', () {
      test('true cuando status es running', () {
        final job = buildWebJob(status: WebJobStatus.running);
        expect(job.isActive, isTrue);
      });

      test('false cuando status es completed', () {
        final job = buildWebJob(status: WebJobStatus.completed);
        expect(job.isActive, isFalse);
      });

      test('false cuando status es failed', () {
        final job = buildWebJob(status: WebJobStatus.failed);
        expect(job.isActive, isFalse);
      });

      test('false cuando status es cancelled', () {
        final job = buildWebJob(status: WebJobStatus.cancelled);
        expect(job.isActive, isFalse);
      });
    });

    group('durationSeconds', () {
      test('null cuando finishedAt es null (job en curso)', () {
        final job = buildWebJob(finishedAt: null);
        expect(job.durationSeconds, isNull);
      });

      test('calcula duración correctamente cuando finishedAt está presente', () {
        final started = DateTime(2026, 1, 15, 10, 0, 0);
        final finished = DateTime(2026, 1, 15, 10, 5, 30);
        final job = buildWebJob(startedAt: started, finishedAt: finished);
        expect(job.durationSeconds, 330); // 5 minutos y 30 segundos
      });

      test('duración de 0 segundos cuando start == finish', () {
        final moment = DateTime(2026, 1, 15, 10, 0, 0);
        final job = buildWebJob(startedAt: moment, finishedAt: moment);
        expect(job.durationSeconds, 0);
      });
    });

    group('copyWith', () {
      test('cambia el status y progress', () {
        final original = buildWebJob(status: WebJobStatus.running, progress: 0.5);
        final updated = original.copyWith(
          status: WebJobStatus.completed,
          progress: 1.0,
        );
        expect(updated.status, WebJobStatus.completed);
        expect(updated.progress, 1.0);
        expect(updated.id, original.id);
      });

      test('cambia productsFound', () {
        final original = buildWebJob(productsFound: 0);
        final updated = original.copyWith(productsFound: 42);
        expect(updated.productsFound, 42);
        expect(updated.id, original.id);
      });

      test('asigna errorLog', () {
        final original = buildWebJob(errorLog: null);
        final updated = original.copyWith(errorLog: 'timeout al conectar');
        expect(updated.errorLog, 'timeout al conectar');
        expect(updated.id, original.id);
      });

      test('asigna finishedAt', () {
        final original = buildWebJob(finishedAt: null);
        final finished = DateTime(2026, 1, 15, 11, 0);
        final updated = original.copyWith(finishedAt: finished);
        expect(updated.finishedAt, finished);
        expect(updated.id, original.id);
      });

      test('sin argumentos devuelve entidad equivalente', () {
        final original = buildWebJob();
        final copy = original.copyWith();
        expect(copy, equals(original));
      });
    });

    test('props incluye todos los campos', () {
      final started = DateTime(2026, 1, 15, 10, 0);
      final job = WebJob(
        id: 'job-1',
        sourceId: 'src-1',
        status: WebJobStatus.failed,
        progress: 0.8,
        productsFound: 80,
        errorLog: 'error de red',
        startedAt: started,
        finishedAt: null,
      );
      expect(
        job.props,
        containsAll([
          job.id,
          job.sourceId,
          job.status,
          job.progress,
          job.productsFound,
          job.errorLog,
          job.startedAt,
        ]),
      );
    });
  });
}
