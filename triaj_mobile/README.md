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
- Koyu temalı modern arayüz, ikon destekli kartlar ve stilize input container'ları

## Çalıştırma

```bash
flutter pub get
flutter run
```

## Doğrulama

```bash
flutter analyze
flutter test
```

## Not

Bu uygulama eğitim ve karar destek amaçlıdır. Klinik uygulamada yerel protokol,
kurum yönergeleri ve uzman hekim değerlendirmesi esas alınmalıdır.
