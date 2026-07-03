import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woncheon_youth/features/auth/presentation/register_request_page.dart';

void main() {
  testWidgets('register request page builds without text field assertions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterRequestPage())),
    );

    expect(find.text('새신자 등록 요청'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
  });
}
