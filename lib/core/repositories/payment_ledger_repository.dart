import 'package:dio/dio.dart';
import '../services/dio_client.dart';
import '../../models/models.dart';

class PaymentLedgerRepository {
  final DioClient _dioClient;

  PaymentLedgerRepository(this._dioClient);

  Future<PaymentLedger> fetchLedger(
    String branchId,
    DateTime from,
    DateTime to,
  ) async {
    final response = await _dioClient.dio.get(
      '/api/v1/runtime/payments/ledger',
      queryParameters: {
        'branchId': branchId,
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      },
    );

    if (response.data == null || response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Payment ledger API returned an unexpected response',
      );
    }

    final data = response.data['data'] as List<dynamic>;
    final records = data
        .map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaymentLedger.fromRecords(records);
  }
}
