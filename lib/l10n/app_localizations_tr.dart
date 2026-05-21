// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'PregNova';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get messages => 'Mesajlar';

  @override
  String get message => 'Mesaj';

  @override
  String get account => 'Hesabım';

  @override
  String get accountSettingsSubtitle =>
      'Hesap ayarlarını buradan yönetebilirsin';

  @override
  String get accountShort => 'Hesap';

  @override
  String get logout => 'Çıkış';

  @override
  String get logoutAction => 'Çıkış Yap';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'İptal';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get searchExpert => 'Uzman Ara';

  @override
  String get diet => 'Diyet';

  @override
  String get clients => 'Danışanlar';

  @override
  String get requests => 'İstekler';

  @override
  String get changePassword => 'Şifre Değiştir';

  @override
  String get editInfo => 'Bilgileri Düzenle';

  @override
  String get expertiseInfo => 'Uzmanlık Bilgileri';

  @override
  String get expertiseArea => 'Uzmanlık Alanı';

  @override
  String get experience => 'Deneyim';

  @override
  String get institution => 'Çalıştığı Kurum';

  @override
  String get licenseNumber => 'Lisans No';

  @override
  String get diplomaDocuments => 'Diploma / Belgeler';

  @override
  String get diplomaUploaded => 'Diploma yüklendi';

  @override
  String get noDiplomaAdded => 'Henüz diploma eklenmemiş';

  @override
  String get settings => 'Ayarlar';

  @override
  String get language => 'Dil';

  @override
  String get systemLanguage => 'Sistem dili';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'İngilizce';

  @override
  String get selectLanguage => 'Dil Seç';

  @override
  String get languageUpdated => 'Dil güncellendi';

  @override
  String get pregnancyInfoTitle => 'Gebelik Bilgileri';

  @override
  String get pregnancyInfoPrompt =>
      'Gebelik bilgilerini doldurmak ister misin?\n\nBu bilgiler sana daha doğru öneriler sunmamızı sağlar.';

  @override
  String get later => 'Daha Sonra';

  @override
  String get fillNow => 'Şimdi Doldur';

  @override
  String weeklyInfoTitle(int week) {
    return 'Hafta $week Bilgilendirmesi';
  }

  @override
  String get weeklyInfoMessage =>
      'Bu haftada demir ve protein ihtiyacın artıyor. Beslenmene dikkat et.';

  @override
  String get welcomeMother => 'Hoş geldin anne';

  @override
  String get pregnantHomeSubtitle =>
      'Sağlık ve beslenme takibini kolayca yapabilirsin.';

  @override
  String get current => 'Şu an';

  @override
  String pregnancyWeek(Object week) {
    return '$week. Hafta';
  }

  @override
  String get riskMeasurement => 'Risk Ölçüm';

  @override
  String get nutritionAnalysis => 'Beslenme Analizi';

  @override
  String get lastMeasurementHistory => 'Son Ölçüm Geçmişi';

  @override
  String get nutritionSupplementHistory => 'Besin ve Takviye Geçmişi';

  @override
  String get latestRiskStatus => 'Son Risk Durumu';

  @override
  String get diabetes => 'Diyabet';

  @override
  String get riskTrackingForm => 'Risk Takip Formu';

  @override
  String get riskResult => 'Risk Sonucu';

  @override
  String get ok => 'Tamam';

  @override
  String get saved => 'Kaydedildi';

  @override
  String errorWithMessage(Object message) {
    return 'Hata: $message';
  }

  @override
  String get diastolicMustBeLower => 'Küçük tansiyon büyükten küçük olmalıdır';

  @override
  String get riskDataSaved => 'Risk verileri kaydedildi';

  @override
  String get currentWeightKg => 'Güncel Kilo (kg)';

  @override
  String get preeklampsiTracking => 'Preeklampsi Takibi';

  @override
  String get preeclampsiaMeasurementHint =>
      'Tansiyon değerleri risk değerlendirmesi için önemlidir.';

  @override
  String get systolicExample => 'Sistolik (Örnek: 120)';

  @override
  String get diastolicExample => 'Diastolik (Örnek: 80)';

  @override
  String get severeHeadache => 'Şiddetli baş ağrısı';

  @override
  String get visionProblem => 'Görme bozukluğu';

  @override
  String get handFaceSwelling => 'El/Yüz şişmesi';

  @override
  String get gestationalDiabetes => 'Gestasyonel Diyabet';

  @override
  String get diabetesMeasurementHint =>
      'Diyabet riskinin değerlendirilebilmesi için açlık veya tokluk şekerinden en az birini giriniz.';

  @override
  String get fastingBloodSugar => 'Açlık kan şekeri';

  @override
  String get postMealBloodSugar => 'Tokluk kan şekeri';

  @override
  String get excessiveThirst => 'Aşırı susama';

  @override
  String get frequentUrination => 'Sık idrar';

  @override
  String get pretermRisk => 'Preterm Riski';

  @override
  String get pretermMeasurementHint =>
      'Belirti varsa işaretleyiniz; stres seviyesini mevcut durumunuza göre seçiniz.';

  @override
  String get contraction => 'Karın kasılması';

  @override
  String get increasedDischarge => 'Akıntı artışı';

  @override
  String get backPain => 'Bel ağrısı';

  @override
  String get stressLevel => 'Stres Seviyesi';

  @override
  String get requiredField => 'Bu alan boş bırakılamaz';

  @override
  String get enterValidNumber => 'Geçerli sayı giriniz';

  @override
  String enterValidValueExample(Object example) {
    return 'Geçerli bir değer giriniz (örn: $example)';
  }

  @override
  String get riskHistory => 'Risk Geçmişi';

  @override
  String get noRiskRecordYet => 'Henüz risk kaydı yok';

  @override
  String get bloodPressure => 'Tansiyon';

  @override
  String get riskOutcome => 'Risk Sonucu';

  @override
  String get fasting => 'Açlık';

  @override
  String get postMeal => 'Tokluk';

  @override
  String get preterm => 'Preterm';

  @override
  String get stress => 'Stres';

  @override
  String get yes => 'Evet';

  @override
  String get no => 'Hayır';

  @override
  String get nutritionSupplementAnalysis => 'Besin ve Takviye Analizi';

  @override
  String get foodEntry => 'Besin Girişi';

  @override
  String get foodName => 'Besin Adı';

  @override
  String get amount => 'Miktar';

  @override
  String get addFood => 'Besin Ekle';

  @override
  String get supplementEntry => 'Takviye Girişi';

  @override
  String get supplementName => 'Takviye Adı';

  @override
  String get addSupplement => 'Takviye Ekle';

  @override
  String get enteredFoods => 'Girilen Besinler';

  @override
  String get enteredSupplements => 'Girilen Takviyeler';

  @override
  String get saveDay => 'Günü Kaydet';

  @override
  String get noDietitianAssigned => 'Henüz diyetisyen atanmadı';

  @override
  String get consumedNutrients => 'Alınan Besin Öğeleri';

  @override
  String get missingNutrients => 'Eksik Besin Öğeleri';

  @override
  String get excessNutrients => 'Fazla Besin Öğeleri';

  @override
  String get noItemsYet => 'Henüz ekleme yok';

  @override
  String get noRecordYet => 'Henüz kayıt yok';

  @override
  String get dailyTotalAnalysisResult => 'Günlük Toplam Analiz Sonucu';

  @override
  String totalCalories(Object calories) {
    return 'Toplam Kalori: $calories kcal';
  }

  @override
  String analysisWithTime(int index, String time) {
    return '$index. Analiz - $time';
  }

  @override
  String calories(Object calories) {
    return 'Kalori: $calories kcal';
  }

  @override
  String get profileInfo => 'Profil Bilgileri';

  @override
  String get personalInfo => 'Kişisel Bilgiler';

  @override
  String get age => 'Yaş';

  @override
  String get ageRangeValidation => '15-50 arası yaş giriniz';

  @override
  String get pregnancyWeekInput => 'Hamilelik Haftası';

  @override
  String get pregnancyWeekRangeValidation => '1-42 arası hafta giriniz';

  @override
  String get heightCm => 'Boy (cm)';

  @override
  String get allergies => 'Alerjiler';

  @override
  String get allergiesExample => 'Alerjiler (örn: fıstık, süt)';

  @override
  String get riskFactors => 'Risk Faktörleri';

  @override
  String get chronicRiskFactors => 'Kronik / Risk Faktörleri';

  @override
  String get chronicHypertension => 'Kronik Hipertansiyon';

  @override
  String get thyroidDisease => 'Tiroid Hastalığı';

  @override
  String get previousPretermBirth => 'Önceki Preterm Doğum';

  @override
  String get previousPreterm => 'Önceki Preterm';

  @override
  String get multiplePregnancy => 'Çoğul Gebelik';

  @override
  String get multiplePregnancyDetail => 'Çoğul Gebelik (İkiz vb.)';

  @override
  String get smoking => 'Sigara';

  @override
  String get smokingUse => 'Sigara Kullanımı';

  @override
  String get saveAndContinue => 'Kaydet ve Devam Et';

  @override
  String get infoUpdated => 'Bilgiler güncellendi';

  @override
  String errorOccurredWithMessage(Object message) {
    return 'Hata oluştu: $message';
  }

  @override
  String get dataNotFound => 'Veri bulunamadı';

  @override
  String get exists => 'Var';

  @override
  String get notExists => 'Yok';

  @override
  String get notSpecified => 'Belirtilmemiş';

  @override
  String get chooseSuitableExpert => 'Size uygun uzmanı seçin';

  @override
  String get searchNameHint => 'İsim ara...';

  @override
  String get all => 'Tümü';

  @override
  String get dietitian => 'Diyetisyen';

  @override
  String get gynecologist => 'Jinekolog';

  @override
  String get expert => 'Uzman';

  @override
  String get noInstitutionInfo => 'Kurum bilgisi yok';

  @override
  String get assignedClient => 'Danışan';

  @override
  String get pending => 'Beklemede';

  @override
  String get request => 'İstek';

  @override
  String get requestSent => 'İstek gönderildi';

  @override
  String get noExpertYet => 'Henüz uzman yok';

  @override
  String get doctor => 'Doktor';

  @override
  String get writeMessage => 'Mesaj yaz...';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get notLoggedIn => 'Giriş yapılmamış';

  @override
  String get noNotificationsYet => 'Henüz bildirim yok';

  @override
  String get justNow => 'Az önce';

  @override
  String minutesAgo(int count) {
    return '$count dk önce';
  }

  @override
  String hoursAgo(int count) {
    return '$count saat önce';
  }

  @override
  String daysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String secondsAgo(int count) {
    return '$count sn önce';
  }

  @override
  String get selectClient => 'Danışan Seç';

  @override
  String get noClientFound => 'Danışan bulunamadı';

  @override
  String get recentAnalyses => 'Son Analizler';

  @override
  String get noAnalysisLast7Days => 'Son 7 günde analiz yok';

  @override
  String get recentMeasurements => 'Son Ölçümler';

  @override
  String get noRecords => 'Kayıt yok';

  @override
  String get detailedReview => 'Detaylı İncele';

  @override
  String get noData => 'Veri yok';

  @override
  String get noPendingRequests => 'Bekleyen istek yok';

  @override
  String get pendingRequest => 'Bekleyen İstek';

  @override
  String get patientId => 'Hasta ID';

  @override
  String get requestId => 'İstek ID';

  @override
  String get email => 'E-posta';

  @override
  String get phone => 'Telefon';

  @override
  String get heightWeight => 'Boy/Kilo';

  @override
  String get bmi => 'BMI';

  @override
  String get risk => 'Risk';

  @override
  String get allergy => 'Alerji';

  @override
  String weekLabel(Object week) {
    return 'Hafta $week';
  }

  @override
  String get accept => 'Kabul';

  @override
  String get reject => 'Reddet';

  @override
  String get welcomeTitle => 'PregNova\'ya Hoş Geldin';

  @override
  String get welcomeSubtitle =>
      'Hamilelik sürecini güvenle takip edebilmen için\nsağlık, beslenme ve egzersiz tek yerde';

  @override
  String get getStarted => 'Kullanmaya Başla';

  @override
  String get login => 'Giriş Yap';

  @override
  String get register => 'Kayıt Ol';

  @override
  String get emailField => 'Email';

  @override
  String get password => 'Şifre';

  @override
  String get noAccountRegister => 'Hesabınız yok mu? Kayıt olun';

  @override
  String get loginError => 'Giriş hatası';

  @override
  String get fullName => 'Ad Soyad';

  @override
  String get fillAllFields => 'Lütfen tüm alanları doldurun';

  @override
  String get passwordMinLength => 'Şifre en az 6 karakter olmalı';

  @override
  String get emailAlreadyInUse => 'Bu email zaten kayıtlı';

  @override
  String get invalidEmail => 'Geçersiz email adresi';

  @override
  String get weakPassword => 'Şifre çok zayıf';

  @override
  String get registerFailed => 'Kayıt başarısız';

  @override
  String get unexpectedError => 'Beklenmeyen bir hata oluştu';

  @override
  String get gynecologistPanel => 'Jinekolog Paneli';

  @override
  String get highRisk => 'Yüksek Risk';

  @override
  String get mediumRisk => 'Orta Risk';

  @override
  String get normalRisk => 'Normal';

  @override
  String get riskStatus => 'Risk Durumu';

  @override
  String get highRiskPatientWarning => 'Yüksek riskli hasta uyarısı';

  @override
  String highRiskPatientCount(Object count) {
    return '$count hastada yüksek risk tespit edildi.';
  }

  @override
  String get review => 'İncele';

  @override
  String get last7Days => 'Son 7 Gün';

  @override
  String activeThisWeekSummary(Object measurements, Object patients) {
    return '$measurements ölçüm\n$patients hasta';
  }

  @override
  String get consultationRequests => 'Danışma İstekleri';

  @override
  String get recentActivities => 'Son Aktiviteler';

  @override
  String get noActivityYet => 'Henüz aktivite yok';

  @override
  String newMeasurementSent(String name) {
    return '$name yeni ölçüm gönderdi';
  }

  @override
  String get noClientsYet => 'Henüz danışan bulunmuyor';

  @override
  String get riskDistribution => 'Risk Dağılımı';

  @override
  String get documentPreviewUnavailable =>
      'Belge önizlenemedi. Dosya PDF ise web panelinden bağlantı olarak açılabilir.';

  @override
  String get dietitianPanel => 'Diyetisyen Paneli';

  @override
  String get activeLast7Days => 'Son 7 Gün Aktif';

  @override
  String get nutritionModule => 'Beslenme Modülü';

  @override
  String get open => 'Aç';

  @override
  String newAnalysisSent(String name) {
    return '$name yeni analiz gönderdi';
  }

  @override
  String get noDate => 'Tarih yok';

  @override
  String get currentPassword => 'Mevcut Şifre';

  @override
  String get newPassword => 'Yeni Şifre';

  @override
  String get confirmNewPassword => 'Yeni Şifre (Tekrar)';

  @override
  String get enterCurrentPassword => 'Mevcut şifre giriniz';

  @override
  String get enterNewPassword => 'Yeni şifre giriniz';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get updatePassword => 'Şifreyi Güncelle';

  @override
  String get passwordUpdated => 'Şifre başarıyla değiştirildi';

  @override
  String get userNotFound => 'Kullanıcı bulunamadı.';

  @override
  String get genericError => 'Bir hata oluştu.';

  @override
  String get wrongCurrentPassword => 'Mevcut şifre yanlış.';

  @override
  String get newPasswordWeak => 'Yeni şifre çok zayıf.';

  @override
  String get recentLoginRequired => 'Lütfen tekrar giriş yapın.';

  @override
  String get expertApplication => 'Uzman Başvurusu';

  @override
  String get uploadDocumentPrompt => 'Lütfen belge yükleyin';

  @override
  String get applicationAlreadyPending => 'Zaten başvurunuz inceleniyor';

  @override
  String get alreadyExpert => 'Zaten uzmansınız!';

  @override
  String get expertApplicationReceivedTitle => 'Uzman Başvurusu Alındı';

  @override
  String get expertApplicationReceivedMessage =>
      'Başvurun alındı. Admin onayı bekleniyor';

  @override
  String get applicationReceived => 'Başvurun alındı';

  @override
  String get applicationPendingStatus => 'Başvurunuz inceleniyor...';

  @override
  String get applicationApprovedStatus => 'Zaten uzmansınız!';

  @override
  String get applicationRejectedStatus =>
      'Başvurunuz reddedildi. Tekrar deneyebilirsiniz.';

  @override
  String get licenseRegistryNumber => 'Lisans / Sicil No';

  @override
  String get city => 'Şehir';

  @override
  String get uploadDocument => 'Belge Yükle';

  @override
  String selectedFileName(String fileName) {
    return 'Seçilen dosya: $fileName';
  }

  @override
  String get submitApplication => 'Başvuruyu Gönder';

  @override
  String get expertApplications => 'Uzman Başvuruları';

  @override
  String get applicationDetail => 'Başvuru Detayı';

  @override
  String get viewDiploma => 'Diplomayı Gör';

  @override
  String get diploma => 'Diploma';

  @override
  String get noDiplomaDocument => 'Diploma/belge bulunamadı';

  @override
  String get approve => 'Onayla';

  @override
  String get applicationRejected => 'Başvuru reddedildi';

  @override
  String get expertApproved => 'Uzman onaylandı';

  @override
  String get applicationApprovedNotificationTitle => 'Başvurun Onaylandı';

  @override
  String get applicationApprovedNotificationMessage =>
      'Artık PregNova’da uzman olarak giriş yapabilirsin.';

  @override
  String get noApplicationFound => 'Başvuru bulunamadı';

  @override
  String noApplicationsWithStatus(String status) {
    return '$status başvuru yok';
  }

  @override
  String get approvedStatus => 'Onaylanan';

  @override
  String get rejectedStatus => 'Reddedilen';

  @override
  String get pendingStatus => 'Bekleyen';

  @override
  String get role => 'Rol';

  @override
  String get status => 'Durum';

  @override
  String get applicationApproved => 'Başvuru onaylandı';

  @override
  String get applicationRejectedShort => 'Başvuru reddedildi';

  @override
  String get applicationPending => 'Başvuru beklemede';

  @override
  String approvalError(Object message) {
    return 'Onay hatası: $message';
  }

  @override
  String get abcd => 'naber';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get welcomeAdmin => 'Hoş geldin Admin';

  @override
  String get systemTrackingApprovalManagement =>
      'Sistem takibi ve onay yönetimi';

  @override
  String get pendingApplication => 'Bekleyen\nBaşvuru';

  @override
  String get totalUsers => 'Toplam\nKullanıcı';

  @override
  String get activeExpert => 'Aktif\nUzman';

  @override
  String get systemReports => 'Sistem\nRaporları';

  @override
  String get adminActions => 'Admin İşlemleri';

  @override
  String get expertApplicationsActionSubtitle =>
      'Uzman başvurularını onayla veya reddet';

  @override
  String get userManagement => 'Kullanıcı Yönetimi';

  @override
  String get viewAllUsers => 'Tüm kullanıcıları görüntüle';

  @override
  String get users => 'Kullanıcılar';

  @override
  String get searchUser => 'Kullanıcı ara...';

  @override
  String get pregnantRole => 'Hamile';

  @override
  String get doctorRole => 'Doktor';

  @override
  String get userFallback => 'Kullanıcı';

  @override
  String get createdAt => 'Kayıt Tarihi';

  @override
  String get refresh => 'Yenile';

  @override
  String get systemSummary => 'Sistem Özeti';

  @override
  String get noRiskData => 'Risk verisi yok';

  @override
  String get riskRateNeedsAttention => 'Yüksek risk oranı dikkat gerektiriyor.';

  @override
  String get riskRateIncreasing => 'Risk oranında artış gözlemleniyor.';

  @override
  String get systemStable => 'Sistem stabil durumda.';

  @override
  String get totalRiskMeasurements => 'Toplam risk ölçümü';

  @override
  String get totalNutritionAnalyses => 'Toplam besin analizi';

  @override
  String get pendingExpertApplications => 'Bekleyen uzman başvurusu';

  @override
  String get approvedExpertApplications => 'Onaylanan uzman başvurusu';

  @override
  String get rejectedExpertApplications => 'Reddedilen uzman başvurusu';

  @override
  String get lowRisk => 'Düşük Risk';

  @override
  String get systemInsight => 'Sistem İçgörüsü';

  @override
  String highRiskPercent(String percent) {
    return 'Yüksek risk oranı: $percent%';
  }

  @override
  String get createDietPlan => 'Diyet Planı Oluştur';

  @override
  String get dietPlanSaved => 'Diyet planı kaydedildi';

  @override
  String get breakfast => 'Kahvaltı';

  @override
  String get snack1 => 'Ara Öğün 1';

  @override
  String get lunch => 'Öğle';

  @override
  String get snack2 => 'Ara Öğün 2';

  @override
  String get dinner => 'Akşam';

  @override
  String get nightSnack => 'Gece';

  @override
  String get notes => 'Notlar';

  @override
  String writeFieldHint(String field) {
    return '$field yaz...';
  }

  @override
  String get patientDetail => 'Hasta Detayı';

  @override
  String get clientDetail => 'Danışan Detayı';

  @override
  String get last7DaysMeasurementCharts => 'Son 7 Gün Ölçüm Grafikleri';

  @override
  String get noMeasurementFound => 'Ölçüm bulunamadı';

  @override
  String get viewDetailedClinicalAnalysis => 'Detaylı Klinik Analizi Gör';

  @override
  String get bloodPressureChartSystolic => 'Tansiyon Grafiği (Sistolik)';

  @override
  String get bloodSugarFastingPostMeal => 'Kan Şekeri (Açlık / Tokluk)';

  @override
  String get weightChangeChart => 'Kilo Değişim Grafiği';

  @override
  String get personalHealthInfo => 'Kişi Sağlık Bilgileri';

  @override
  String get chronicDisease => 'Kronik Hastalık';

  @override
  String get hypertension => 'Hipertansiyon';

  @override
  String get swelling => 'Şişlik';

  @override
  String get discharge => 'Akıntı';

  @override
  String get weightChart => 'Kilo Grafiği';

  @override
  String get calorieChart => 'Kalori Grafiği';

  @override
  String get analysisHistory => 'Analiz Geçmişi';

  @override
  String get noAnalysisYet => 'Henüz analiz yok';

  @override
  String get dataCouldNotBeLoaded => 'Veri alınamadı';

  @override
  String dailyTotalCalories(Object calories) {
    return 'Günlük Toplam: $calories kcal';
  }

  @override
  String get supplements => 'Takviyeler';

  @override
  String get nutritionAnalysisDetail => 'Beslenme Analizi Detayı';

  @override
  String get analysisNotFound => 'Analiz bulunamadı';

  @override
  String get consumedFoods => 'Tüketilen Besinler';

  @override
  String get noDietPlanYet => 'Henüz diyet planın yok';

  @override
  String get myDietPlan => 'Diyet Planım';

  @override
  String get viewCurrentDietPlan => 'Güncel diyet planını görüntüle';

  @override
  String viewDietPlanButton(String date) {
    return '$date - Diyeti Gör';
  }

  @override
  String dietDetailWithDate(String date) {
    return 'Diyet Detayı - $date';
  }

  @override
  String get uploadDiploma => 'Diploma Yükle';

  @override
  String get uploadError => 'Yükleme hatası';

  @override
  String enterFieldHint(String field) {
    return '$field gir...';
  }

  @override
  String get noMessagesYet => 'Henüz mesaj yok';

  @override
  String get enterWeekInfo => 'Hafta Bilgisi Gir';

  @override
  String get whichPregnancyWeek => 'Kaçıncı haftadasın?';

  @override
  String get pregnancyStart => 'Gebelik Başlangıç';

  @override
  String welcomeUser(String user) {
    return 'Hoş geldiniz, $user';
  }

  @override
  String get welcomeExpert => 'Hoş geldin';

  @override
  String get missingNutrition => 'Eksik Besin Öğesi';

  @override
  String get riskyPatient => 'Riskli Hasta';

  @override
  String clientUid(String uid) {
    return 'Danışan UID: $uid';
  }
}
