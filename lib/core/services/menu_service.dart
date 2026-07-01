import 'package:dio/dio.dart';
import '../../models/models.dart';
import 'dio_client.dart';

class MenuService {
  final DioClient _dioClient;

  MenuService(this._dioClient);

  /// GET /api/tenants/:tenantId/menu/categories/tree
  Future<List<MenuCategory>> fetchCategoryTree(String tenantId) async {
    final response = await _dioClient.dio.get(
      '/tenants/$tenantId/menu/categories/tree',
    );
    _assertSuccess(response);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/tenants/:tenantId/menu/branch/:branchId
  /// Returns the fully resolved effective menu for the branch.
  Future<List<EffectiveMenuItem>> fetchEffectiveMenu(
    String tenantId,
    String branchId, {
    String? categoryId,
    String? search,
  }) async {
    final response = await _dioClient.dio.get(
      '/tenants/$tenantId/menu/branch/$branchId',
      queryParameters: <String, dynamic>{
        // ignore: use_null_aware_elements
        if (categoryId != null) 'category_id': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
        'include_unavailable': false,
      },
    );
    _assertSuccess(response);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => EffectiveMenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _assertSuccess(Response<dynamic> response) {
    if (response.data == null || response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Menu API returned an unexpected response',
      );
    }
  }
}
