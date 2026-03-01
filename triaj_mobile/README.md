# triaj_mobile

MTS (Manchester Triage System) ve STS (Türkiye Sağlık Bakanlığı triyaj akışı)
algoritmalarını aynı bulgu seti üzerinde çalıştıran ve sonuçları karşılaştıran
Flutter mobil uygulaması.

## Öne çıkanlar

- STS için 5 adımlı karar ağacı (Kırmızı K1/K2, Sarı K1/K2, Yeşil)
- MTS için discriminator sıralı sınıflama (Red/Orange/Yellow/Green/Blue)
- MTS şema kartı seçimi + şemaya özel alt kırılım soruları
- Akış sonunda iki sistemi aynı anda hesaplayan karşılaştırma modülü
- Kademe farkı ve güvenli (daha acil) öneri üreten analiz kartı
- Cevap geçmişi ve retriyaj için yeniden başlatma desteği
- Google ile Firebase Auth giriş/çıkış desteği
- Firebase Firestore üzerinde kullanıcı profili, uygulama ayarları ve vaka kayıtlarını saklayan tipli veri modeli
- Modern pastel (mor/turuncu) arayüz + açık/koyu tema

## Çalıştırma

```bash
flutter pub get
flutter run
```

## Firebase Kurulum

1. Firebase Console'da bir proje oluştur.
2. `Authentication > Sign-in method` içinde `Google` sağlayıcısını aktif et.
3. `Firestore Database` oluştur (`production` veya `test` mode).
4. Android/iOS için uygulamaları Firebase'e ekle:
`google-services.json` ve/veya `GoogleService-Info.plist` dosyalarını projeye yerleştir.
5. Uygulamayı yeniden başlat:

```bash
flutter clean
flutter pub get
flutter run
```


6. Firestore güvenlik kurallarını deploy et:

```bash
firebase deploy --only firestore:rules
```

Not:
- Firebase başlatılamazsa uygulama yine açılır; auth ve bulut kayıtları devre dışı kalır.
- Google ile giriş yapıldığında kullanıcı profili/ayarları ve tamamlanan vakalar Firestore
  `users/{uid}` hiyerarşisine yazılır; aynı vaka kaydı `triage_records` altında da uyumluluk için tutulur.


## Firestore Veri Modeli

Uygulama, verileri aşağıdaki yapıda saklar:

- `users/{uid}`
  - Kullanıcı profili (`email`, `displayName`, `photoUrl`, `providerIds`, `lastLoginAt`)
- `users/{uid}/meta/settings`
  - Uygulama ayarları (`themeMode`, `evalOrder`, `mtsStopAtFirstYes`)
- `users/{uid}/triage_records/{recordId}`
  - Vaka kayıtları (hasta özeti, STS/MTS sonucu, süre, uyum analizi, discriminator)
- `triage_records/{recordId}`
  - Geriye dönük uyumluluk için vaka kaydı aynası

Model sınıfları: `lib/data/models/firestore_models.dart`
Repository: `lib/services/triage_record_repository.dart`
Rules: `firestore.rules`

## Doğrulama

```bash
flutter analyze
flutter test
```

## Not

Bu uygulama eğitim ve karar destek amaçlıdır. Klinik uygulamada yerel protokol,
kurum yönergeleri ve uzman hekim değerlendirmesi esas alınmalıdır.
