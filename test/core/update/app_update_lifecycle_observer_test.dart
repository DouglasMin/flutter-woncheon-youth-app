import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/core/update/app_update_lifecycle_observer.dart';

void main() {
  testWidgets('runs update check when app resumes', (tester) async {
    late BuildContext capturedContext;
    var checkCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final observer = AppUpdateLifecycleObserver(
      contextProvider: () => capturedContext,
      checkUpdate: (_) async {
        checkCount += 1;
      },
    );

    final changeLifecycleState = observer.didChangeAppLifecycleState;
    changeLifecycleState(AppLifecycleState.paused);
    changeLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(checkCount, 1);
  });

  testWidgets('does not start another update check while one is in flight', (
    tester,
  ) async {
    late BuildContext capturedContext;
    var checkCount = 0;
    final completer = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final observer = AppUpdateLifecycleObserver(
      contextProvider: () => capturedContext,
      checkUpdate: (_) {
        checkCount += 1;
        return completer.future;
      },
    );

    final changeLifecycleState = observer.didChangeAppLifecycleState;
    changeLifecycleState(AppLifecycleState.resumed);
    changeLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(checkCount, 1);

    completer.complete();
    await tester.pump();
  });
}
