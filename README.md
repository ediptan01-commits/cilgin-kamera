# Çılgın Kamera 📸

Türkçe arayüzlü Android Flutter MVP: ön/arka kamera, fotoğraf çekimi, Doğal / Siyah beyaz / Gün batımı / Buz gibi renkleri, bağımsız ayna anahtarı, fotoğraf inceleme, galeriye kaydetme ve sistem paylaşım menüsü.

## Çalıştırma

Flutter **3.35.7** (Dart 3.9.2), Java 17, Android SDK ve Android API 24+ gerekir. Fiziksel Android cihaz önerilir.

```sh
flutter pub get
flutter run
```

Android proje dosyaları dahildir; flutter create gerekmez. Uygulama kimliği: com.cilginkamera.cilgin_kamera. Yalnızca Android yapılandırıldı.

## APK indir

1. Bu depoda **Actions → Android APK** sayfasını aç.
2. main gönderimi otomatik başlatır. İstersen **Run workflow → main → Run workflow** seç.
3. Yeşil tamamlanan çalıştırmayı aç. **Artifacts → cilgin-kamera-debug-apk** arşivini indir.
4. Arşivden app-debug.apk dosyasını çıkartıp Android telefona taşı ve yükle. İstenirse dosyayı açtığın uygulamaya bilinmeyen uygulama yükleme izni ver.

Artifact 14 gün tutulur. Bu bir debug APK; Play Store yayını veya üretim imzası değildir. Workflow biçim kontrolü, analiz ve testlerden sonra APK oluşturur. Başarısız kontrolde artifact üretilmez. Yeşil Actions çalıştırması derlemeyi doğrular; kamera donanımı fiziksel cihazda ayrıca denenmelidir.

## Filtreler dosyaya uygulanır

lib/effects.dart içindeki aynı renk matrisi canlı önizlemede ve piksel işleme aşamasında kullanılır. EXIF yönü düzeltilir, uzun kenar en fazla 2048 piksele indirilir, ayna ve renk matrisi uygulanır, JPEG %92 kaliteyle üretilir. İşleme ayrı isolate içinde yapılır.

İnceleme ekranı bu JPEG dosyasını açar. Kaydet ve Paylaş aynı işlenmiş dosya yolunu kullanır. Ön kameranın varsayılan önizleme aynası dengelenir; ayna anahtarı açıkken çıktı da yatay çevrilir. Sensörün HDR/renk işlemesi ve ekran renk yönetimi küçük önizleme/JPEG farklarına yol açabilir. Tam sensör çözünürlüğü korunmaz.

## İzinler ve gizlilik

- İlk açılışta kamera izni istenir. Red durumunda açıklama, tekrar deneme ve uygulama ayarları düğmeleri vardır.
- Ses/video kaydı yoktur; enableAudio false, mikrofon izni istenmez.
- Android 10 ve altında galeriye yazma izni kaydederken istenir. Yeni Android sürümlerinde MediaStore kullanılır; fotoğraf arşivini okuma izni gerekmez.
- Arka plana geçince kamera bırakılır; dönüşte yeniden açılır. Çekim sırasında kontroller kilitlenir.
- Fotoğraflar sunucuya gönderilmez. Paylaşımı kullanıcı sistem menüsünden yapar.
- Kaydedilmemiş işlenmiş kareler uygulama önbelleğindedir; Android bunları silebilir. Alıcı uygulama sonradan okuyabileceği için paylaşılan dosya hemen silinmez. Önbellek Android uygulama ayarlarından temizlenebilir.
- Ham çekim işleme sonunda silinir. Yeniden kodlanan JPEG'e kaynak EXIF/GPS bilgileri kopyalanmaz.
- AI, yüz bükme/yüz algılama, reklam SDK'sı, AdMob kimliği, API anahtarı veya gizli bilgi yoktur.

## Doğrulama

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Testler gerçek JPEG piksellerinde gri ton, sıcak/soğuk renk, aynalama, geçersiz veri, matris uzunluğu ve Türkçe inceleme ekranını kontrol eder. Donanım, galeri ve paylaşım uygulamaları cihazda denenmelidir.

### Telefonda kabul kontrolü

- İlk kamera iznini reddet; açıklama, tekrar deneme ve ayarlardan izin verip dönüşü dene.
- Ön/arka kamerada her renk ve ayna kombinasyonuyla yazılı/asimetrik bir nesne çek. Önizleme, inceleme, galeri ve paylaşılan fotoğrafın yönünü karşılaştır.
- Hızlı tekrar çekime ve kamera değişimine dokun; işlem sırasında kilitli olmalılar.
- Ana ekrana gidip dön; ekranı kilitle/aç; paylaşım menüsünü iptal et.
- Küçük ekran, düşük bellek, kamerasız emülatör, dolu depolama ve Android 10 galeri izni reddini kontrol et.

Paket belgeleri: [camera](https://pub.dev/packages/camera/versions/0.11.2), [gal](https://pub.dev/packages/gal/versions/2.3.2), [share_plus](https://pub.dev/packages/share_plus/versions/11.1.0).
