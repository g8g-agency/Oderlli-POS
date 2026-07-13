import 'package:dio/dio.dart';
import '../../models/models.dart';
import 'dio_client.dart';

class OrderService {
  final DioClient? _dioClient;

  OrderService(this._dioClient);

  DioClient get dioClient => _dioClient!;

  /// POST /api/v1/orders/checkout
  Future<Order> checkout({
    required String staffToken,
    required String mutationId,
    required String idempotencyKey,
    required int expectedCartRevision,
    required Map<String, dynamic> mutationEnvelopeBody,
  }) async {
    final response = await dioClient.dio.post(
      '/api/v1/orders/checkout',
      data: mutationEnvelopeBody,
      options: Options(
        headers: {
          'Authorization': 'Bearer $staffToken',
          'X-Mutation-Id': mutationId,
          'X-Expected-Cart-Revision': expectedCartRevision.toString(),
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
    _assertSuccess(response);
    
    final rawOrder = response.data['data']['order'] as Map<String, dynamic>;
    return Order.fromJson(rawOrder);
  }

  /// GET /api/v1/orders
  Future<List<OrderSummary>> fetchOrders({
    required String branchId,
    String? status,
  }) async {
    final response = await dioClient.dio.get(
      '/api/v1/orders',
      queryParameters: {
        'branchId': branchId,
        if (status != null) 'status': status,
      },
    );
    _assertSuccess(response);
    
    final rawOrders = (response.data['data']['orders'] as List<dynamic>?) ?? [];
    return rawOrders
        .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/orders/:id
  Future<OrderDetail> fetchOrderDetail(String orderId) async {
    final response = await dioClient.dio.get(
      '/api/v1/orders/$orderId',
    );
    _assertSuccess(response);
    
    final rawOrder = response.data['data']['order'] as Map<String, dynamic>;
    return OrderDetail.fromJson(rawOrder);
  }

  void _assertSuccess(Response<dynamic> response) {
    if (response.data == null || (response.data['success'] != true && response.data['status'] != 'success')) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Orders API returned an unexpected response',
      );
    }
  }
}
