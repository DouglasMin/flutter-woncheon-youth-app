import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/core/router/app_router.dart';

void main() {
  test('notice routes are stacked outside tab branches', () {
    expect(AppRoutes.notices, '/notices');
    expect(AppRoutes.noticeDetail('NOTICE01'), '/notices/NOTICE01');
  });
}
