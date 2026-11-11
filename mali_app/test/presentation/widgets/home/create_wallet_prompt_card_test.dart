import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/presentation/theme/app_theme.dart';
import 'package:mali_app/presentation/widgets/home/create_wallet_prompt_card.dart';

void main() {
  testWidgets('invokes create wallet callback when tapped', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: CreateWalletPromptCard(
            onCreateWallet: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.byKey(CreateWalletPromptCard.cardKey), findsOneWidget);
    expect(find.text('Create your first wallet'), findsOneWidget);

    await tester.tap(find.byKey(CreateWalletPromptCard.cardKey));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
