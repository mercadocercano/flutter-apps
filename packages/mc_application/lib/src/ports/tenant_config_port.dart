abstract interface class TenantConfigPort {
  Future<String?> getConfig(String key);
  Future<void> setConfig(String key, String value);
}
