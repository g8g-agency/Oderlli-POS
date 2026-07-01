import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';
import '../providers/auth_provider.dart';

class ManagerOverrideDialog extends ConsumerStatefulWidget {
  const ManagerOverrideDialog({super.key, required this.actionName});

  final String actionName;

  @override
  ConsumerState<ManagerOverrideDialog> createState() => _ManagerOverrideDialogState();
}

class _ManagerOverrideDialogState extends ConsumerState<ManagerOverrideDialog> {
  bool _isVerifying = false;
  String? _errorMessage;
  final _employeeIdController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _employeeIdController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    final employeeId = _employeeIdController.text.trim();
    final pin = _pinController.text.trim();

    if (employeeId.isEmpty || pin.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both ID and PIN';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authProvider);
      final secureStorage = ref.read(secureStorageProvider);
      final dio = ref.read(dioClientProvider).dio;

      final staffToken = await secureStorage.getRuntimeToken();
      final tenantId = authState.tenantId;
      final branchId = authState.branchId;

      if (tenantId == null || branchId == null) {
        setState(() {
          _errorMessage = 'Session error. Please restart the app.';
        });
        return;
      }

      final response = await dio.post(
        '/auth/staff/login',
        data: {
          'tenantId': tenantId,
          'branchId': branchId,
          'employeeId': employeeId,
          'pin': pin,
        },
        options: Options(
          headers: {
            if (staffToken != null) 'Authorization': 'Bearer $staffToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        if (body != null && body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>;
          final runtimeToken = data['runtime_token'] as String?;
          if (runtimeToken != null && runtimeToken.isNotEmpty) {
            // Decode JWT to read the role claim
            final parts = runtimeToken.split('.');
            if (parts.length == 3) {
              final payloadPart = parts[1];
              final normalized = base64Url.normalize(payloadPart);
              final decodedPayload = utf8.decode(base64Url.decode(normalized));
              final payloadMap = jsonDecode(decodedPayload) as Map<String, dynamic>;
              final role = payloadMap['role']?.toString().toLowerCase() ?? '';

              if (role == 'manager' || role == 'admin' || role == 'restaurant_admin') {
                if (mounted) {
                  Navigator.pop(context, true);
                }
                return;
              } else {
                if (mounted) {
                  setState(() {
                    _errorMessage = 'Staff member does not have manager access';
                    _pinController.clear();
                  });
                }
                return;
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _errorMessage = 'Verification failed. Try again.';
          _pinController.clear();
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            _errorMessage = 'Incorrect ID or PIN. Try again.';
          } else {
            _errorMessage = 'Verification failed. Check connection.';
          }
          _pinController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Verification failed. Check connection.';
          _pinController.clear();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLG.r)),
      title: const Text('Manager approval required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Authorize: "${widget.actionName}"',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          Gap(16.h),
          TextField(
            controller: _employeeIdController,
            decoration: const InputDecoration(labelText: 'Manager employee ID'),
            keyboardType: TextInputType.number,
            enabled: !_isVerifying,
          ),
          Gap(12.h),
          TextField(
            controller: _pinController,
            decoration: InputDecoration(
              labelText: 'Manager PIN',
              errorText: _errorMessage,
            ),
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            enabled: !_isVerifying,
            onSubmitted: (_) => _verifyPin(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isVerifying ? null : _verifyPin,
          child: _isVerifying
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Approve'),
        ),
      ],
    );
  }
}
