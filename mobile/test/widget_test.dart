import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets(
    'RoomStylo brand preview loads successfully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const RoomStyloApp(),
      );

      expect(
        find.text(
          'VISUALIZE  •  STYLE  •  YOUR SPACE',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'Transform your room into a space\n'
              'that feels truly yours.',
        ),
        findsOneWidget,
      );
    },
  );
}