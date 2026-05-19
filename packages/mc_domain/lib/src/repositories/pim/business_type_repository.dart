import '../../models/pim/business_type.dart';

abstract class BusinessTypeRepository {
  Future<List<BusinessType>> getAll();
  Future<BusinessType?> getById(String id);
  Future<BusinessType> create(BusinessType businessType);
  Future<BusinessType> update(BusinessType businessType);
  Future<void> delete(String id);
}