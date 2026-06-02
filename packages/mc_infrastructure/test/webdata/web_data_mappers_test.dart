import 'package:mc_domain/mc_domain.dart';
import 'package:mc_infrastructure/mc_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  // -------------------------------------------------------------------------
  // Fixtures
  // -------------------------------------------------------------------------

  final baseSourceJson = <String, dynamic>{
    'id': 'src-uuid-1',
    'name': 'MercadoLibre Ferretería',
    'url': 'https://mercadolibre.com.ar/ferreteria',
    'status': 'active',
    'schedule': '0 8 * * *',
    'business_type_ids': ['bt-1', 'bt-2'],
    'created_at': '2024-06-15T10:00:00Z',
    'updated_at': '2024-06-15T10:00:00Z',
  };

  final baseJobJson = <String, dynamic>{
    'id': 'job-uuid-1',
    'source_id': 'src-uuid-1',
    'status': 'running',
    'progress': 0.45,
    'products_found': 120,
    'error_log': null,
    'started_at': '2024-06-15T10:00:00Z',
    'finished_at': null,
  };

  final baseProductJson = <String, dynamic>{
    'id': 'prod-uuid-1',
    'source_id': 'src-uuid-1',
    'name': 'Martillo Stanley 16oz',
    'price': 4500.0,
    'image_url': 'https://example.com/img.jpg',
    'url': 'https://mercadolibre.com.ar/martillo',
    'business_type_id': 'bt-1',
    'scraped_at': '2024-06-15T10:00:00Z',
    'price_history': [
      {
        'date': '2024-06-01T00:00:00Z',
        'price': 4200.0,
        'variation_percent': null,
      },
      {
        'date': '2024-06-15T00:00:00Z',
        'price': 4500.0,
        'variation_percent': 7.14,
      },
    ],
  };

  final baseDashboardJson = <String, dynamic>{
    'active_sources': 5,
    'inactive_sources': 2,
    'jobs_today': 10,
    'total_products': 3500,
    'success_rate': 0.87,
  };

  // -------------------------------------------------------------------------
  // dashboardStatsFromJson
  // -------------------------------------------------------------------------

  group('dashboardStatsFromJson', () {
    test('mapea todos los campos correctamente', () {
      final stats = dashboardStatsFromJson(baseDashboardJson);
      expect(stats.activeSources, 5);
      expect(stats.inactiveSources, 2);
      expect(stats.jobsToday, 10);
      expect(stats.totalProducts, 3500);
      expect(stats.successRate, closeTo(0.87, 0.001));
    });

    test('acepta wrapper con clave "stats"', () {
      final stats = dashboardStatsFromJson({
        'stats': baseDashboardJson,
      });
      expect(stats.activeSources, 5);
    });

    test('defaults a cero cuando faltan campos', () {
      final stats = dashboardStatsFromJson(<String, dynamic>{});
      expect(stats.activeSources, 0);
      expect(stats.successRate, 0.0);
    });
  });

  // -------------------------------------------------------------------------
  // webSourceFromJson
  // -------------------------------------------------------------------------

  group('webSourceFromJson', () {
    test('mapea todos los campos correctamente', () {
      final source = webSourceFromJson(baseSourceJson);
      expect(source.id, 'src-uuid-1');
      expect(source.name, 'MercadoLibre Ferretería');
      expect(source.url, 'https://mercadolibre.com.ar/ferreteria');
      expect(source.status, WebSourceStatus.active);
      expect(source.schedule, '0 8 * * *');
      expect(source.businessTypeIds, ['bt-1', 'bt-2']);
    });

    test('schedule null cuando está ausente', () {
      final json = Map<String, dynamic>.from(baseSourceJson)
        ..remove('schedule');
      final source = webSourceFromJson(json);
      expect(source.schedule, isNull);
    });

    test('status desconocido mapea a inactive', () {
      final json = Map<String, dynamic>.from(baseSourceJson)
        ..['status'] = 'unknown_status';
      final source = webSourceFromJson(json);
      expect(source.status, WebSourceStatus.inactive);
    });

    test('businessTypeIds vacío cuando está ausente', () {
      final json = Map<String, dynamic>.from(baseSourceJson)
        ..remove('business_type_ids');
      final source = webSourceFromJson(json);
      expect(source.businessTypeIds, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // webSourceToJson
  // -------------------------------------------------------------------------

  group('webSourceToJson', () {
    test('serializa campos obligatorios', () {
      final source = webSourceFromJson(baseSourceJson);
      final json = webSourceToJson(source);
      expect(json['name'], 'MercadoLibre Ferretería');
      expect(json['url'], 'https://mercadolibre.com.ar/ferreteria');
      expect(json['status'], 'active');
      expect(json['business_type_ids'], ['bt-1', 'bt-2']);
      expect(json['schedule'], '0 8 * * *');
    });

    test('omite schedule si es null', () {
      final json = Map<String, dynamic>.from(baseSourceJson)
        ..remove('schedule');
      final source = webSourceFromJson(json);
      final serialized = webSourceToJson(source);
      expect(serialized.containsKey('schedule'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // paginatedSourcesFromJson
  // -------------------------------------------------------------------------

  group('paginatedSourcesFromJson', () {
    test('mapea lista y paginación', () {
      final json = <String, dynamic>{
        'sources': [baseSourceJson, baseSourceJson],
        'pagination': {
          'total': 10,
          'page': 1,
          'page_size': 20,
          'total_pages': 1,
        },
      };
      final result = paginatedSourcesFromJson(json);
      expect(result.items, hasLength(2));
      expect(result.totalCount, 10);
      expect(result.page, 1);
    });

    test('tolera lista vacía', () {
      final result = paginatedSourcesFromJson(<String, dynamic>{});
      expect(result.items, isEmpty);
      expect(result.totalCount, 0);
    });
  });

  // -------------------------------------------------------------------------
  // webJobFromJson
  // -------------------------------------------------------------------------

  group('webJobFromJson', () {
    test('mapea todos los campos correctamente', () {
      final job = webJobFromJson(baseJobJson);
      expect(job.id, 'job-uuid-1');
      expect(job.sourceId, 'src-uuid-1');
      expect(job.status, WebJobStatus.running);
      expect(job.progress, closeTo(0.45, 0.001));
      expect(job.productsFound, 120);
      expect(job.errorLog, isNull);
      expect(job.finishedAt, isNull);
    });

    test('acepta wrapper con clave "job"', () {
      final job = webJobFromJson({'job': baseJobJson});
      expect(job.id, 'job-uuid-1');
    });

    test('finishedAt se parsea cuando está presente', () {
      final json = Map<String, dynamic>.from(baseJobJson)
        ..['finished_at'] = '2024-06-15T11:00:00Z'
        ..['status'] = 'completed';
      final job = webJobFromJson(json);
      expect(job.finishedAt, isNotNull);
      expect(job.status, WebJobStatus.completed);
    });

    test('status desconocido mapea a running', () {
      final json = Map<String, dynamic>.from(baseJobJson)
        ..['status'] = 'pending';
      final job = webJobFromJson(json);
      expect(job.status, WebJobStatus.running);
    });
  });

  // -------------------------------------------------------------------------
  // paginatedJobsFromJson
  // -------------------------------------------------------------------------

  group('paginatedJobsFromJson', () {
    test('mapea lista y paginación', () {
      final json = <String, dynamic>{
        'jobs': [baseJobJson],
        'pagination': {
          'total': 5,
          'page': 2,
          'page_size': 10,
          'total_pages': 1,
        },
      };
      final result = paginatedJobsFromJson(json);
      expect(result.items, hasLength(1));
      expect(result.totalCount, 5);
      expect(result.page, 2);
    });
  });

  // -------------------------------------------------------------------------
  // webProductFromJson
  // -------------------------------------------------------------------------

  group('webProductFromJson', () {
    test('mapea todos los campos correctamente', () {
      final product = webProductFromJson(baseProductJson);
      expect(product.id, 'prod-uuid-1');
      expect(product.sourceId, 'src-uuid-1');
      expect(product.name, 'Martillo Stanley 16oz');
      expect(product.price, closeTo(4500.0, 0.001));
      expect(product.imageUrl, 'https://example.com/img.jpg');
      expect(product.businessTypeId, 'bt-1');
      expect(product.priceHistory, hasLength(2));
    });

    test('acepta wrapper con clave "product"', () {
      final product = webProductFromJson({'product': baseProductJson});
      expect(product.id, 'prod-uuid-1');
    });

    test('businessTypeId null cuando está ausente', () {
      final json = Map<String, dynamic>.from(baseProductJson)
        ..remove('business_type_id');
      final product = webProductFromJson(json);
      expect(product.businessTypeId, isNull);
    });

    test('priceHistory vacío cuando está ausente', () {
      final json = Map<String, dynamic>.from(baseProductJson)
        ..remove('price_history');
      final product = webProductFromJson(json);
      expect(product.priceHistory, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // webProductToJson
  // -------------------------------------------------------------------------

  group('webProductToJson', () {
    test('serializa campos obligatorios', () {
      final product = webProductFromJson(baseProductJson);
      final json = webProductToJson(product);
      expect(json['name'], 'Martillo Stanley 16oz');
      expect(json['price'], closeTo(4500.0, 0.001));
      expect(json['url'], 'https://mercadolibre.com.ar/martillo');
      expect(json['business_type_id'], 'bt-1');
    });

    test('omite imageUrl si es null', () {
      final json = Map<String, dynamic>.from(baseProductJson)
        ..remove('image_url');
      final product = webProductFromJson(json);
      final serialized = webProductToJson(product);
      expect(serialized.containsKey('image_url'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // pricePointFromJson / priceHistoryFromJson
  // -------------------------------------------------------------------------

  group('pricePointFromJson', () {
    test('mapea date, price y variationPercent', () {
      final point = pricePointFromJson({
        'date': '2024-06-15T00:00:00Z',
        'price': 4500.0,
        'variation_percent': 7.14,
      });
      expect(point.price, closeTo(4500.0, 0.001));
      expect(point.variationPercent, closeTo(7.14, 0.001));
      expect(point.isPriceIncrease, isTrue);
    });

    test('variationPercent null en primer punto', () {
      final point = pricePointFromJson({
        'date': '2024-06-01T00:00:00Z',
        'price': 4200.0,
        'variation_percent': null,
      });
      expect(point.variationPercent, isNull);
    });
  });

  group('priceHistoryFromJson', () {
    test('parsea la lista completa', () {
      final history = priceHistoryFromJson({
        'price_history': [
          {
            'date': '2024-06-01T00:00:00Z',
            'price': 4200.0,
            'variation_percent': null,
          },
          {
            'date': '2024-06-15T00:00:00Z',
            'price': 4500.0,
            'variation_percent': 7.14,
          },
        ],
      });
      expect(history, hasLength(2));
      expect(history.last.price, closeTo(4500.0, 0.001));
    });

    test('lista vacía cuando key ausente', () {
      final history = priceHistoryFromJson(<String, dynamic>{});
      expect(history, isEmpty);
    });
  });
}
