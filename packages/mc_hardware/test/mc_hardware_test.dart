import 'package:mc_hardware/mc_hardware.dart';
import 'package:test/test.dart';

void main() {
  test('TestMcHardware_LibraryImports_WithoutErrors', () {
    // Package vacío — este test garantiza que dart test no falle por
    // ausencia de test() calls, y que la librería importa limpiamente.
    expect(true, isTrue);
  });
}
