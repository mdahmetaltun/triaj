import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:triaj_mobile/app.dart';

void main() {
  testWidgets('jsx-like flow reaches result screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TriageMobileApp());

    expect(find.text('TRİYAJ KARAR SİSTEMİ'), findsWidgets);
    expect(find.text('Triyaj Karar Destek Sistemi'), findsOneWidget);

    await tester.tap(find.text('＋ Yeni Vaka Başlat'));
    await tester.pumpAndSettle();

    expect(find.text('Hasta Bilgileri'), findsOneWidget);
    await tester.tap(find.text('İleri → MTS Şema Seç'));
    await tester.pumpAndSettle();

    expect(find.text('Baş Şikayet / MTS Şeması'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Göğüs Ağrısı'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Göğüs Ağrısı'));
    await tester.pumpAndSettle();

    expect(find.text('Sağlık Bakanlığı (STS) Değerlendirmesi'), findsOneWidget);
    await tester.tap(find.text('Kırmızı-2').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Manchester Triage (MTS) · Göğüs Ağrısı'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('✓ Evet'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('✓ Evet').first);
    await tester.pumpAndSettle();

    expect(find.text('VAKA KAYDEDİLDİ'), findsOneWidget);
    expect(find.text('＋ Yeni Vaka'), findsOneWidget);
    expect(find.text('📊 Tüm Raporlar'), findsOneWidget);
  });
}
