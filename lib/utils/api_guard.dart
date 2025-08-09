import 'dart:async';
import 'package:flutter/material.dart';
import '../helpers/api_exception.dart';
import '../helpers/snack_bar_helper.dart';

Future<T?> guardApi<T>(
  BuildContext context,
  Future<T> future, {
  String? successMessage,
  String? genericError = 'Something went wrong',
}) async {
  try {
    final result = await future.timeout(const Duration(seconds: 20));
    if (successMessage != null && successMessage.isNotEmpty) {
      showSnack(context, successMessage, kind: SnackKind.success);
    }
    return result;
  } on ApiException catch (e) {
    // 4xx/5xx from server — error
    showSnack(context, e.message.isNotEmpty ? e.message : genericError!,
        kind: SnackKind.error);
  } on TimeoutException {
    showSnack(context, 'Request timed out. Please try again.',
        kind: SnackKind.warning);
  } catch (e) {
    showSnack(context, genericError!, kind: SnackKind.error);
  }
  return null;
}
