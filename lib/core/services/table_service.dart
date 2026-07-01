import 'package:dio/dio.dart';
import '../../models/models.dart';
import 'dio_client.dart';

class TableService {
  final DioClient _dioClient;

  TableService(this._dioClient);

  /// GET /api/v1/admin/tables
  Future<List<PosTable>> fetchTables(String branchId) async {
    final response = await _dioClient.dio.get(
      '/api/v1/admin/tables',
      queryParameters: {
        'branch_id': branchId,
        'is_active': true,
        'limit': 100,
      },
    );
    _assertSuccess(response);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => PosTable.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/admin/tables/floors
  Future<List<TableFloor>> fetchFloors() async {
    final response = await _dioClient.dio.get(
      '/api/v1/admin/tables/floors',
    );
    _assertSuccess(response);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => TableFloor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/admin/tables/sections
  Future<List<TableSection>> fetchSections({String? branchId}) async {
    final response = await _dioClient.dio.get(
      '/api/v1/admin/tables/sections',
      queryParameters: branchId != null ? {'branchId': branchId} : null,
    );
    _assertSuccess(response);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => TableSection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/admin/tables/:tableId/vacate
  Future<void> vacateTable(String tableId) async {
    final response = await _dioClient.dio.post(
      '/api/v1/admin/tables/$tableId/vacate',
    );
    _assertSuccess(response);
  }

  void _assertSuccess(Response<dynamic> response) {
    if (response.data == null || response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Tables API returned an unexpected response',
      );
    }
  }
}
