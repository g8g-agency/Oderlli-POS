import 'package:dio/dio.dart';
import '../../models/models.dart'; // Ensure correct models are used
import 'dio_client.dart';

class BillingService {
  final DioClient _dioClient;

  BillingService(this._dioClient);

  /// GET /api/v1/billing/projections/table/:tableId
  Future<List<dynamic>> fetchTableProjection(String tableId) async {
    final response = await _dioClient.dio.get('/api/v1/billing/projections/table/$tableId');
    _assertSuccess(response);
    return response.data['data']['projections'] as List<dynamic>;
  }

  /// POST /api/v1/billing/bills/aggregate
  Future<Map<String, dynamic>> aggregateOrdersIntoBill({
    required String tableId,
    required List<String> orderIds,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/billing/bills/aggregate',
      data: {
        'tableId': tableId,
        'orderIds': orderIds,
        'sessionId': null, // Assuming backend handles this if null
      },
    );
    _assertSuccess(response);
    return response.data['data']['bill'] as Map<String, dynamic>;
  }

  /// GET /api/v1/billing/bills/:id
  Future<Map<String, dynamic>> getBillDetails(String billId) async {
    final response = await _dioClient.dio.get('/api/v1/billing/bills/$billId');
    _assertSuccess(response);
    return response.data['data']['bill'] as Map<String, dynamic>;
  }

  /// POST /api/v1/billing/bills/:id/settle
  Future<Map<String, dynamic>> settleBill({
    required String billId,
    required String paymentMethod,
    required int amountMinor,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/billing/bills/$billId/settle',
      data: {
        'paymentMethod': paymentMethod,
        'amountMinor': amountMinor,
      },
    );
    _assertSuccess(response);
    return response.data['data']['updatedBill'] as Map<String, dynamic>;
  }

  void _assertSuccess(Response<dynamic> response) {
    if (response.data == null || (response.data['status'] != 'success' && response.data['success'] != true)) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Billing API returned an unexpected response',
      );
    }
  }
}
