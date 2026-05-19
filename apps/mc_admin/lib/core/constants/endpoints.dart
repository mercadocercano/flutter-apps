/// Constants for API endpoints
class Endpoints {
  static const String kongBase = 'http://localhost:8001';
  static const String pimApi = '/api/pim';
  
  static const String marketplaceBrands = '$pimApi/marketplace-brands';
  static const String marketplaceCategories = '$pimApi/marketplace/categories';
  static const String businessTypes = '$pimApi/business-types';
  static const String businessTypeTemplates = '$pimApi/business-type-templates';
}