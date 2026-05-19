/// Constantes del POS — valores fijos de negocio y UI.
abstract final class PosConstants {
  static const List<int> denominations = [500, 1000, 2000, 5000, 10000];
  static const int topSellingCount = 8;
}

enum PosSyncStatus { synced, syncing, offline }
