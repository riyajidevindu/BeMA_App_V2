import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';

void showSuccessSnackBarMessage(
  BuildContext context,
  String message,
) {
  final snackBarSuccess = SnackBar(
    /// set behavior to SnackBarBehavior.fixed to display snackbar at the top
    behavior: SnackBarBehavior.fixed,
    backgroundColor: Colors.transparent,
    content: AwesomeSnackbarContent(
      title: 'Success',
      message: message,
      contentType: ContentType.success,
      inMaterialBanner: true,
    ),
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBarSuccess);
}

void showErrorSnackBarMessage(
  BuildContext context,
  String message,
) {
  final snackBarSuccess = SnackBar(
    /// set behavior to SnackBarBehavior.fixed to display snackbar at the top
    behavior: SnackBarBehavior.fixed,
    backgroundColor: Colors.transparent,
    content: AwesomeSnackbarContent(
      title: 'Error',
      message: message,
      contentType: ContentType.failure,
      inMaterialBanner: true,
    ),
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBarSuccess);
}
