import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In tr, this message translates to:
  /// **'PregNova'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// No description provided for @messages.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar'**
  String get messages;

  /// No description provided for @message.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj'**
  String get message;

  /// No description provided for @account.
  ///
  /// In tr, this message translates to:
  /// **'Hesabım'**
  String get account;

  /// No description provided for @accountSettingsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap ayarlarını buradan yönetebilirsin'**
  String get accountSettingsSubtitle;

  /// No description provided for @accountShort.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get accountShort;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış'**
  String get logout;

  /// No description provided for @logoutAction.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logoutAction;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @searchExpert.
  ///
  /// In tr, this message translates to:
  /// **'Uzman Ara'**
  String get searchExpert;

  /// No description provided for @diet.
  ///
  /// In tr, this message translates to:
  /// **'Diyet'**
  String get diet;

  /// No description provided for @clients.
  ///
  /// In tr, this message translates to:
  /// **'Danışanlar'**
  String get clients;

  /// No description provided for @requests.
  ///
  /// In tr, this message translates to:
  /// **'İstekler'**
  String get requests;

  /// No description provided for @changePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Değiştir'**
  String get changePassword;

  /// No description provided for @editInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bilgileri Düzenle'**
  String get editInfo;

  /// No description provided for @expertiseInfo.
  ///
  /// In tr, this message translates to:
  /// **'Uzmanlık Bilgileri'**
  String get expertiseInfo;

  /// No description provided for @expertiseArea.
  ///
  /// In tr, this message translates to:
  /// **'Uzmanlık Alanı'**
  String get expertiseArea;

  /// No description provided for @experience.
  ///
  /// In tr, this message translates to:
  /// **'Deneyim'**
  String get experience;

  /// No description provided for @institution.
  ///
  /// In tr, this message translates to:
  /// **'Çalıştığı Kurum'**
  String get institution;

  /// No description provided for @licenseNumber.
  ///
  /// In tr, this message translates to:
  /// **'Lisans No'**
  String get licenseNumber;

  /// No description provided for @diplomaDocuments.
  ///
  /// In tr, this message translates to:
  /// **'Diploma / Belgeler'**
  String get diplomaDocuments;

  /// No description provided for @diplomaUploaded.
  ///
  /// In tr, this message translates to:
  /// **'Diploma yüklendi'**
  String get diplomaUploaded;

  /// No description provided for @noDiplomaAdded.
  ///
  /// In tr, this message translates to:
  /// **'Henüz diploma eklenmemiş'**
  String get noDiplomaAdded;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Sistem dili'**
  String get systemLanguage;

  /// No description provided for @turkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get english;

  /// No description provided for @selectLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil Seç'**
  String get selectLanguage;

  /// No description provided for @languageUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Dil güncellendi'**
  String get languageUpdated;

  /// No description provided for @pregnancyInfoTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gebelik Bilgileri'**
  String get pregnancyInfoTitle;

  /// No description provided for @pregnancyInfoPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Gebelik bilgilerini doldurmak ister misin?\n\nBu bilgiler sana daha doğru öneriler sunmamızı sağlar.'**
  String get pregnancyInfoPrompt;

  /// No description provided for @later.
  ///
  /// In tr, this message translates to:
  /// **'Daha Sonra'**
  String get later;

  /// No description provided for @fillNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi Doldur'**
  String get fillNow;

  /// No description provided for @weeklyInfoTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hafta {week} Bilgilendirmesi'**
  String weeklyInfoTitle(int week);

  /// No description provided for @weeklyInfoMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu haftada demir ve protein ihtiyacın artıyor. Beslenmene dikkat et.'**
  String get weeklyInfoMessage;

  /// No description provided for @welcomeMother.
  ///
  /// In tr, this message translates to:
  /// **'Hoş geldin anne'**
  String get welcomeMother;

  /// No description provided for @pregnantHomeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık ve beslenme takibini kolayca yapabilirsin.'**
  String get pregnantHomeSubtitle;

  /// No description provided for @current.
  ///
  /// In tr, this message translates to:
  /// **'Şu an'**
  String get current;

  /// No description provided for @pregnancyWeek.
  ///
  /// In tr, this message translates to:
  /// **'{week}. Hafta'**
  String pregnancyWeek(Object week);

  /// No description provided for @riskMeasurement.
  ///
  /// In tr, this message translates to:
  /// **'Risk Ölçüm'**
  String get riskMeasurement;

  /// No description provided for @nutritionAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'Besin Analizi'**
  String get nutritionAnalysis;

  /// No description provided for @lastMeasurementHistory.
  ///
  /// In tr, this message translates to:
  /// **'Son Ölçüm Geçmişi'**
  String get lastMeasurementHistory;

  /// No description provided for @nutritionSupplementHistory.
  ///
  /// In tr, this message translates to:
  /// **'Besin & Takviye Geçmişi'**
  String get nutritionSupplementHistory;

  /// No description provided for @latestRiskStatus.
  ///
  /// In tr, this message translates to:
  /// **'Son Risk Durumu'**
  String get latestRiskStatus;

  /// No description provided for @diabetes.
  ///
  /// In tr, this message translates to:
  /// **'Diyabet'**
  String get diabetes;

  /// No description provided for @riskTrackingForm.
  ///
  /// In tr, this message translates to:
  /// **'Risk Takip Formu'**
  String get riskTrackingForm;

  /// No description provided for @riskResult.
  ///
  /// In tr, this message translates to:
  /// **'Risk Sonucu'**
  String get riskResult;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @saved.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedildi'**
  String get saved;

  /// No description provided for @errorWithMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {message}'**
  String errorWithMessage(Object message);

  /// No description provided for @diastolicMustBeLower.
  ///
  /// In tr, this message translates to:
  /// **'Küçük tansiyon büyükten küçük olmalıdır'**
  String get diastolicMustBeLower;

  /// No description provided for @riskDataSaved.
  ///
  /// In tr, this message translates to:
  /// **'Risk verileri kaydedildi'**
  String get riskDataSaved;

  /// No description provided for @currentWeightKg.
  ///
  /// In tr, this message translates to:
  /// **'Güncel Kilo (kg)'**
  String get currentWeightKg;

  /// No description provided for @preeklampsiTracking.
  ///
  /// In tr, this message translates to:
  /// **'Preeklampsi Takibi'**
  String get preeklampsiTracking;

  /// No description provided for @systolicExample.
  ///
  /// In tr, this message translates to:
  /// **'Sistolik (Örnek: 120)'**
  String get systolicExample;

  /// No description provided for @diastolicExample.
  ///
  /// In tr, this message translates to:
  /// **'Diastolik (Örnek: 80)'**
  String get diastolicExample;

  /// No description provided for @severeHeadache.
  ///
  /// In tr, this message translates to:
  /// **'Şiddetli baş ağrısı'**
  String get severeHeadache;

  /// No description provided for @visionProblem.
  ///
  /// In tr, this message translates to:
  /// **'Görme bozukluğu'**
  String get visionProblem;

  /// No description provided for @handFaceSwelling.
  ///
  /// In tr, this message translates to:
  /// **'El/Yüz şişmesi'**
  String get handFaceSwelling;

  /// No description provided for @gestationalDiabetes.
  ///
  /// In tr, this message translates to:
  /// **'Gestasyonel Diyabet'**
  String get gestationalDiabetes;

  /// No description provided for @fastingBloodSugar.
  ///
  /// In tr, this message translates to:
  /// **'Açlık kan şekeri'**
  String get fastingBloodSugar;

  /// No description provided for @postMealBloodSugar.
  ///
  /// In tr, this message translates to:
  /// **'Tokluk kan şekeri'**
  String get postMealBloodSugar;

  /// No description provided for @excessiveThirst.
  ///
  /// In tr, this message translates to:
  /// **'Aşırı susama'**
  String get excessiveThirst;

  /// No description provided for @frequentUrination.
  ///
  /// In tr, this message translates to:
  /// **'Sık idrar'**
  String get frequentUrination;

  /// No description provided for @pretermRisk.
  ///
  /// In tr, this message translates to:
  /// **'Preterm Riski'**
  String get pretermRisk;

  /// No description provided for @contraction.
  ///
  /// In tr, this message translates to:
  /// **'Karın kasılması'**
  String get contraction;

  /// No description provided for @increasedDischarge.
  ///
  /// In tr, this message translates to:
  /// **'Akıntı artışı'**
  String get increasedDischarge;

  /// No description provided for @backPain.
  ///
  /// In tr, this message translates to:
  /// **'Bel ağrısı'**
  String get backPain;

  /// No description provided for @stressLevel.
  ///
  /// In tr, this message translates to:
  /// **'Stres Seviyesi'**
  String get stressLevel;

  /// No description provided for @requiredField.
  ///
  /// In tr, this message translates to:
  /// **'Bu alan boş bırakılamaz'**
  String get requiredField;

  /// No description provided for @enterValidNumber.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli sayı giriniz'**
  String get enterValidNumber;

  /// No description provided for @enterValidValueExample.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir değer giriniz (örn: {example})'**
  String enterValidValueExample(Object example);

  /// No description provided for @riskHistory.
  ///
  /// In tr, this message translates to:
  /// **'Risk Geçmişi'**
  String get riskHistory;

  /// No description provided for @noRiskRecordYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz risk kaydı yok'**
  String get noRiskRecordYet;

  /// No description provided for @bloodPressure.
  ///
  /// In tr, this message translates to:
  /// **'Tansiyon'**
  String get bloodPressure;

  /// No description provided for @riskOutcome.
  ///
  /// In tr, this message translates to:
  /// **'Risk Sonucu'**
  String get riskOutcome;

  /// No description provided for @fasting.
  ///
  /// In tr, this message translates to:
  /// **'Açlık'**
  String get fasting;

  /// No description provided for @postMeal.
  ///
  /// In tr, this message translates to:
  /// **'Tokluk'**
  String get postMeal;

  /// No description provided for @preterm.
  ///
  /// In tr, this message translates to:
  /// **'Preterm'**
  String get preterm;

  /// No description provided for @stress.
  ///
  /// In tr, this message translates to:
  /// **'Stres'**
  String get stress;

  /// No description provided for @yes.
  ///
  /// In tr, this message translates to:
  /// **'Evet'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In tr, this message translates to:
  /// **'Hayır'**
  String get no;

  /// No description provided for @nutritionSupplementAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'Besin ve Takviye Analizi'**
  String get nutritionSupplementAnalysis;

  /// No description provided for @foodEntry.
  ///
  /// In tr, this message translates to:
  /// **'Besin Girişi'**
  String get foodEntry;

  /// No description provided for @foodName.
  ///
  /// In tr, this message translates to:
  /// **'Besin Adı'**
  String get foodName;

  /// No description provided for @amount.
  ///
  /// In tr, this message translates to:
  /// **'Miktar'**
  String get amount;

  /// No description provided for @addFood.
  ///
  /// In tr, this message translates to:
  /// **'Besin Ekle'**
  String get addFood;

  /// No description provided for @supplementEntry.
  ///
  /// In tr, this message translates to:
  /// **'Takviye Girişi'**
  String get supplementEntry;

  /// No description provided for @supplementName.
  ///
  /// In tr, this message translates to:
  /// **'Takviye Adı'**
  String get supplementName;

  /// No description provided for @addSupplement.
  ///
  /// In tr, this message translates to:
  /// **'Takviye Ekle'**
  String get addSupplement;

  /// No description provided for @enteredFoods.
  ///
  /// In tr, this message translates to:
  /// **'Girilen Besinler'**
  String get enteredFoods;

  /// No description provided for @enteredSupplements.
  ///
  /// In tr, this message translates to:
  /// **'Girilen Takviyeler'**
  String get enteredSupplements;

  /// No description provided for @saveDay.
  ///
  /// In tr, this message translates to:
  /// **'Günü Kaydet'**
  String get saveDay;

  /// No description provided for @noDietitianAssigned.
  ///
  /// In tr, this message translates to:
  /// **'Henüz diyetisyen atanmadı'**
  String get noDietitianAssigned;

  /// No description provided for @consumedNutrients.
  ///
  /// In tr, this message translates to:
  /// **'Alınan Besin Öğeleri'**
  String get consumedNutrients;

  /// No description provided for @missingNutrients.
  ///
  /// In tr, this message translates to:
  /// **'Eksik Besin Öğeleri'**
  String get missingNutrients;

  /// No description provided for @excessNutrients.
  ///
  /// In tr, this message translates to:
  /// **'Fazla Besin Öğeleri'**
  String get excessNutrients;

  /// No description provided for @noItemsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ekleme yok'**
  String get noItemsYet;

  /// No description provided for @noRecordYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kayıt yok'**
  String get noRecordYet;

  /// No description provided for @dailyTotalAnalysisResult.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Toplam Analiz Sonucu'**
  String get dailyTotalAnalysisResult;

  /// No description provided for @totalCalories.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Kalori: {calories} kcal'**
  String totalCalories(Object calories);

  /// No description provided for @analysisWithTime.
  ///
  /// In tr, this message translates to:
  /// **'{index}. Analiz - {time}'**
  String analysisWithTime(int index, String time);

  /// No description provided for @calories.
  ///
  /// In tr, this message translates to:
  /// **'Kalori: {calories} kcal'**
  String calories(Object calories);

  /// No description provided for @profileInfo.
  ///
  /// In tr, this message translates to:
  /// **'Profil Bilgileri'**
  String get profileInfo;

  /// No description provided for @personalInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel Bilgiler'**
  String get personalInfo;

  /// No description provided for @age.
  ///
  /// In tr, this message translates to:
  /// **'Yaş'**
  String get age;

  /// No description provided for @ageRangeValidation.
  ///
  /// In tr, this message translates to:
  /// **'15-50 arası yaş giriniz'**
  String get ageRangeValidation;

  /// No description provided for @pregnancyWeekInput.
  ///
  /// In tr, this message translates to:
  /// **'Hamilelik Haftası'**
  String get pregnancyWeekInput;

  /// No description provided for @pregnancyWeekRangeValidation.
  ///
  /// In tr, this message translates to:
  /// **'1-42 arası hafta giriniz'**
  String get pregnancyWeekRangeValidation;

  /// No description provided for @heightCm.
  ///
  /// In tr, this message translates to:
  /// **'Boy (cm)'**
  String get heightCm;

  /// No description provided for @allergies.
  ///
  /// In tr, this message translates to:
  /// **'Alerjiler'**
  String get allergies;

  /// No description provided for @allergiesExample.
  ///
  /// In tr, this message translates to:
  /// **'Alerjiler (örn: fıstık, süt)'**
  String get allergiesExample;

  /// No description provided for @riskFactors.
  ///
  /// In tr, this message translates to:
  /// **'Risk Faktörleri'**
  String get riskFactors;

  /// No description provided for @chronicRiskFactors.
  ///
  /// In tr, this message translates to:
  /// **'Kronik / Risk Faktörleri'**
  String get chronicRiskFactors;

  /// No description provided for @chronicHypertension.
  ///
  /// In tr, this message translates to:
  /// **'Kronik Hipertansiyon'**
  String get chronicHypertension;

  /// No description provided for @thyroidDisease.
  ///
  /// In tr, this message translates to:
  /// **'Tiroid Hastalığı'**
  String get thyroidDisease;

  /// No description provided for @previousPretermBirth.
  ///
  /// In tr, this message translates to:
  /// **'Önceki Preterm Doğum'**
  String get previousPretermBirth;

  /// No description provided for @previousPreterm.
  ///
  /// In tr, this message translates to:
  /// **'Önceki Preterm'**
  String get previousPreterm;

  /// No description provided for @multiplePregnancy.
  ///
  /// In tr, this message translates to:
  /// **'Çoğul Gebelik'**
  String get multiplePregnancy;

  /// No description provided for @multiplePregnancyDetail.
  ///
  /// In tr, this message translates to:
  /// **'Çoğul Gebelik (İkiz vb.)'**
  String get multiplePregnancyDetail;

  /// No description provided for @smoking.
  ///
  /// In tr, this message translates to:
  /// **'Sigara'**
  String get smoking;

  /// No description provided for @smokingUse.
  ///
  /// In tr, this message translates to:
  /// **'Sigara Kullanımı'**
  String get smokingUse;

  /// No description provided for @saveAndContinue.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet ve Devam Et'**
  String get saveAndContinue;

  /// No description provided for @infoUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Bilgiler güncellendi'**
  String get infoUpdated;

  /// No description provided for @errorOccurredWithMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hata oluştu: {message}'**
  String errorOccurredWithMessage(Object message);

  /// No description provided for @dataNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Veri bulunamadı'**
  String get dataNotFound;

  /// No description provided for @exists.
  ///
  /// In tr, this message translates to:
  /// **'Var'**
  String get exists;

  /// No description provided for @notExists.
  ///
  /// In tr, this message translates to:
  /// **'Yok'**
  String get notExists;

  /// No description provided for @notSpecified.
  ///
  /// In tr, this message translates to:
  /// **'Belirtilmemiş'**
  String get notSpecified;

  /// No description provided for @chooseSuitableExpert.
  ///
  /// In tr, this message translates to:
  /// **'Size uygun uzmanı seçin'**
  String get chooseSuitableExpert;

  /// No description provided for @searchNameHint.
  ///
  /// In tr, this message translates to:
  /// **'İsim ara...'**
  String get searchNameHint;

  /// No description provided for @all.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get all;

  /// No description provided for @dietitian.
  ///
  /// In tr, this message translates to:
  /// **'Diyetisyen'**
  String get dietitian;

  /// No description provided for @gynecologist.
  ///
  /// In tr, this message translates to:
  /// **'Jinekolog'**
  String get gynecologist;

  /// No description provided for @expert.
  ///
  /// In tr, this message translates to:
  /// **'Uzman'**
  String get expert;

  /// No description provided for @noInstitutionInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kurum bilgisi yok'**
  String get noInstitutionInfo;

  /// No description provided for @assignedClient.
  ///
  /// In tr, this message translates to:
  /// **'Danışan'**
  String get assignedClient;

  /// No description provided for @pending.
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get pending;

  /// No description provided for @request.
  ///
  /// In tr, this message translates to:
  /// **'İstek'**
  String get request;

  /// No description provided for @requestSent.
  ///
  /// In tr, this message translates to:
  /// **'İstek gönderildi'**
  String get requestSent;

  /// No description provided for @noExpertYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz uzman yok'**
  String get noExpertYet;

  /// No description provided for @doctor.
  ///
  /// In tr, this message translates to:
  /// **'Doktor'**
  String get doctor;

  /// No description provided for @writeMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj yaz...'**
  String get writeMessage;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @notLoggedIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapılmamış'**
  String get notLoggedIn;

  /// No description provided for @noNotificationsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bildirim yok'**
  String get noNotificationsYet;

  /// No description provided for @justNow.
  ///
  /// In tr, this message translates to:
  /// **'Az önce'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} dk önce'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} saat önce'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} gün önce'**
  String daysAgo(int count);

  /// No description provided for @secondsAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} sn önce'**
  String secondsAgo(int count);

  /// No description provided for @selectClient.
  ///
  /// In tr, this message translates to:
  /// **'Danışan Seç'**
  String get selectClient;

  /// No description provided for @noClientFound.
  ///
  /// In tr, this message translates to:
  /// **'Danışan bulunamadı'**
  String get noClientFound;

  /// No description provided for @recentAnalyses.
  ///
  /// In tr, this message translates to:
  /// **'Son Analizler'**
  String get recentAnalyses;

  /// No description provided for @noAnalysisLast7Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 günde analiz yok'**
  String get noAnalysisLast7Days;

  /// No description provided for @recentMeasurements.
  ///
  /// In tr, this message translates to:
  /// **'Son Ölçümler'**
  String get recentMeasurements;

  /// No description provided for @noRecords.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt yok'**
  String get noRecords;

  /// No description provided for @detailedReview.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı İncele'**
  String get detailedReview;

  /// No description provided for @noData.
  ///
  /// In tr, this message translates to:
  /// **'Veri yok'**
  String get noData;

  /// No description provided for @noPendingRequests.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen istek yok'**
  String get noPendingRequests;

  /// No description provided for @pendingRequest.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen İstek'**
  String get pendingRequest;

  /// No description provided for @patientId.
  ///
  /// In tr, this message translates to:
  /// **'Hasta ID'**
  String get patientId;

  /// No description provided for @requestId.
  ///
  /// In tr, this message translates to:
  /// **'İstek ID'**
  String get requestId;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get phone;

  /// No description provided for @heightWeight.
  ///
  /// In tr, this message translates to:
  /// **'Boy/Kilo'**
  String get heightWeight;

  /// No description provided for @bmi.
  ///
  /// In tr, this message translates to:
  /// **'BMI'**
  String get bmi;

  /// No description provided for @risk.
  ///
  /// In tr, this message translates to:
  /// **'Risk'**
  String get risk;

  /// No description provided for @allergy.
  ///
  /// In tr, this message translates to:
  /// **'Alerji'**
  String get allergy;

  /// No description provided for @weekLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hafta {week}'**
  String weekLabel(Object week);

  /// No description provided for @accept.
  ///
  /// In tr, this message translates to:
  /// **'Kabul'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get reject;

  /// No description provided for @welcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'PregNova\'ya Hoş Geldin'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hamilelik sürecini güvenle takip edebilmen için\nsağlık, beslenme ve egzersiz tek yerde'**
  String get welcomeSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In tr, this message translates to:
  /// **'Kullanmaya Başla'**
  String get getStarted;

  /// No description provided for @login.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// No description provided for @register.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get register;

  /// No description provided for @emailField.
  ///
  /// In tr, this message translates to:
  /// **'Email'**
  String get emailField;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @noAccountRegister.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız yok mu? Kayıt olun'**
  String get noAccountRegister;

  /// No description provided for @loginError.
  ///
  /// In tr, this message translates to:
  /// **'Giriş hatası'**
  String get loginError;

  /// No description provided for @fullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get fullName;

  /// No description provided for @fillAllFields.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen tüm alanları doldurun'**
  String get fillAllFields;

  /// No description provided for @passwordMinLength.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı'**
  String get passwordMinLength;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In tr, this message translates to:
  /// **'Bu email zaten kayıtlı'**
  String get emailAlreadyInUse;

  /// No description provided for @invalidEmail.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz email adresi'**
  String get invalidEmail;

  /// No description provided for @weakPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre çok zayıf'**
  String get weakPassword;

  /// No description provided for @registerFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt başarısız'**
  String get registerFailed;

  /// No description provided for @unexpectedError.
  ///
  /// In tr, this message translates to:
  /// **'Beklenmeyen bir hata oluştu'**
  String get unexpectedError;

  /// No description provided for @gynecologistPanel.
  ///
  /// In tr, this message translates to:
  /// **'Jinekolog Paneli'**
  String get gynecologistPanel;

  /// No description provided for @highRisk.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek Risk'**
  String get highRisk;

  /// No description provided for @mediumRisk.
  ///
  /// In tr, this message translates to:
  /// **'Orta Risk'**
  String get mediumRisk;

  /// No description provided for @normalRisk.
  ///
  /// In tr, this message translates to:
  /// **'Normal'**
  String get normalRisk;

  /// No description provided for @riskStatus.
  ///
  /// In tr, this message translates to:
  /// **'Risk Durumu'**
  String get riskStatus;

  /// No description provided for @highRiskPatientWarning.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek riskli hasta uyarısı'**
  String get highRiskPatientWarning;

  /// No description provided for @highRiskPatientCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} hastada yüksek risk tespit edildi.'**
  String highRiskPatientCount(Object count);

  /// No description provided for @review.
  ///
  /// In tr, this message translates to:
  /// **'İncele'**
  String get review;

  /// No description provided for @last7Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 Gün'**
  String get last7Days;

  /// No description provided for @activeThisWeekSummary.
  ///
  /// In tr, this message translates to:
  /// **'{measurements} ölçüm\n{patients} hasta'**
  String activeThisWeekSummary(Object measurements, Object patients);

  /// No description provided for @consultationRequests.
  ///
  /// In tr, this message translates to:
  /// **'Danışma İstekleri'**
  String get consultationRequests;

  /// No description provided for @recentActivities.
  ///
  /// In tr, this message translates to:
  /// **'Son Aktiviteler'**
  String get recentActivities;

  /// No description provided for @noActivityYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz aktivite yok'**
  String get noActivityYet;

  /// No description provided for @newMeasurementSent.
  ///
  /// In tr, this message translates to:
  /// **'{name} yeni ölçüm gönderdi'**
  String newMeasurementSent(String name);

  /// No description provided for @noClientsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz danışan bulunmuyor'**
  String get noClientsYet;

  /// No description provided for @riskDistribution.
  ///
  /// In tr, this message translates to:
  /// **'Risk Dağılımı'**
  String get riskDistribution;

  /// No description provided for @documentPreviewUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Belge önizlenemedi. Dosya PDF ise web panelinden bağlantı olarak açılabilir.'**
  String get documentPreviewUnavailable;

  /// No description provided for @dietitianPanel.
  ///
  /// In tr, this message translates to:
  /// **'Diyetisyen Paneli'**
  String get dietitianPanel;

  /// No description provided for @activeLast7Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 Gün Aktif'**
  String get activeLast7Days;

  /// No description provided for @nutritionModule.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme Modülü'**
  String get nutritionModule;

  /// No description provided for @open.
  ///
  /// In tr, this message translates to:
  /// **'Aç'**
  String get open;

  /// No description provided for @newAnalysisSent.
  ///
  /// In tr, this message translates to:
  /// **'{name} yeni analiz gönderdi'**
  String newAnalysisSent(String name);

  /// No description provided for @noDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih yok'**
  String get noDate;

  /// No description provided for @currentPassword.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut Şifre'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifre'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifre (Tekrar)'**
  String get confirmNewPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut şifre giriniz'**
  String get enterCurrentPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre giriniz'**
  String get enterNewPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor'**
  String get passwordsDoNotMatch;

  /// No description provided for @updatePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi Güncelle'**
  String get updatePassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Şifre başarıyla değiştirildi'**
  String get passwordUpdated;

  /// No description provided for @userNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı bulunamadı.'**
  String get userNotFound;

  /// No description provided for @genericError.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu.'**
  String get genericError;

  /// No description provided for @wrongCurrentPassword.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut şifre yanlış.'**
  String get wrongCurrentPassword;

  /// No description provided for @newPasswordWeak.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre çok zayıf.'**
  String get newPasswordWeak;

  /// No description provided for @recentLoginRequired.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen tekrar giriş yapın.'**
  String get recentLoginRequired;

  /// No description provided for @expertApplication.
  ///
  /// In tr, this message translates to:
  /// **'Uzman Başvurusu'**
  String get expertApplication;

  /// No description provided for @uploadDocumentPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen belge yükleyin'**
  String get uploadDocumentPrompt;

  /// No description provided for @applicationAlreadyPending.
  ///
  /// In tr, this message translates to:
  /// **'Zaten başvurunuz inceleniyor'**
  String get applicationAlreadyPending;

  /// No description provided for @alreadyExpert.
  ///
  /// In tr, this message translates to:
  /// **'Zaten uzmansınız!'**
  String get alreadyExpert;

  /// No description provided for @expertApplicationReceivedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uzman Başvurusu Alındı'**
  String get expertApplicationReceivedTitle;

  /// No description provided for @expertApplicationReceivedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Başvurun alındı. Admin onayı bekleniyor'**
  String get expertApplicationReceivedMessage;

  /// No description provided for @applicationReceived.
  ///
  /// In tr, this message translates to:
  /// **'Başvurun alındı'**
  String get applicationReceived;

  /// No description provided for @applicationPendingStatus.
  ///
  /// In tr, this message translates to:
  /// **'Başvurunuz inceleniyor...'**
  String get applicationPendingStatus;

  /// No description provided for @applicationApprovedStatus.
  ///
  /// In tr, this message translates to:
  /// **'Zaten uzmansınız!'**
  String get applicationApprovedStatus;

  /// No description provided for @applicationRejectedStatus.
  ///
  /// In tr, this message translates to:
  /// **'Başvurunuz reddedildi. Tekrar deneyebilirsiniz.'**
  String get applicationRejectedStatus;

  /// No description provided for @licenseRegistryNumber.
  ///
  /// In tr, this message translates to:
  /// **'Lisans / Sicil No'**
  String get licenseRegistryNumber;

  /// No description provided for @city.
  ///
  /// In tr, this message translates to:
  /// **'Şehir'**
  String get city;

  /// No description provided for @uploadDocument.
  ///
  /// In tr, this message translates to:
  /// **'Belge Yükle'**
  String get uploadDocument;

  /// No description provided for @selectedFileName.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen dosya: {fileName}'**
  String selectedFileName(String fileName);

  /// No description provided for @submitApplication.
  ///
  /// In tr, this message translates to:
  /// **'Başvuruyu Gönder'**
  String get submitApplication;

  /// No description provided for @expertApplications.
  ///
  /// In tr, this message translates to:
  /// **'Uzman Başvuruları'**
  String get expertApplications;

  /// No description provided for @applicationDetail.
  ///
  /// In tr, this message translates to:
  /// **'Başvuru Detayı'**
  String get applicationDetail;

  /// No description provided for @viewDiploma.
  ///
  /// In tr, this message translates to:
  /// **'Diplomayı Gör'**
  String get viewDiploma;

  /// No description provided for @diploma.
  ///
  /// In tr, this message translates to:
  /// **'Diploma'**
  String get diploma;

  /// No description provided for @noDiplomaDocument.
  ///
  /// In tr, this message translates to:
  /// **'Diploma/belge bulunamadı'**
  String get noDiplomaDocument;

  /// No description provided for @approve.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get approve;

  /// No description provided for @applicationRejected.
  ///
  /// In tr, this message translates to:
  /// **'Başvuru reddedildi'**
  String get applicationRejected;

  /// No description provided for @expertApproved.
  ///
  /// In tr, this message translates to:
  /// **'Uzman onaylandı'**
  String get expertApproved;

  /// No description provided for @applicationApprovedNotificationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başvurun Onaylandı'**
  String get applicationApprovedNotificationTitle;

  /// No description provided for @applicationApprovedNotificationMessage.
  ///
  /// In tr, this message translates to:
  /// **'Artık PregNova’da uzman olarak giriş yapabilirsin.'**
  String get applicationApprovedNotificationMessage;

  /// No description provided for @noApplicationFound.
  ///
  /// In tr, this message translates to:
  /// **'Başvuru bulunamadı'**
  String get noApplicationFound;

  /// No description provided for @noApplicationsWithStatus.
  ///
  /// In tr, this message translates to:
  /// **'{status} başvuru yok'**
  String noApplicationsWithStatus(String status);

  /// No description provided for @approvedStatus.
  ///
  /// In tr, this message translates to:
  /// **'Onaylanan'**
  String get approvedStatus;

  /// No description provided for @rejectedStatus.
  ///
  /// In tr, this message translates to:
  /// **'Reddedilen'**
  String get rejectedStatus;

  /// No description provided for @pendingStatus.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen'**
  String get pendingStatus;

  /// No description provided for @role.
  ///
  /// In tr, this message translates to:
  /// **'Rol'**
  String get role;

  /// No description provided for @status.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get status;

  /// No description provided for @applicationApproved.
  ///
  /// In tr, this message translates to:
  /// **'Başvuru onaylandı'**
  String get applicationApproved;

  /// No description provided for @applicationRejectedShort.
  ///
  /// In tr, this message translates to:
  /// **'Başvuru reddedildi'**
  String get applicationRejectedShort;

  /// No description provided for @applicationPending.
  ///
  /// In tr, this message translates to:
  /// **'Başvuru beklemede'**
  String get applicationPending;

  /// No description provided for @approvalError.
  ///
  /// In tr, this message translates to:
  /// **'Onay hatası: {message}'**
  String approvalError(Object message);

  /// No description provided for @adminPanel.
  ///
  /// In tr, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @welcomeAdmin.
  ///
  /// In tr, this message translates to:
  /// **'Hoş geldin Admin'**
  String get welcomeAdmin;

  /// No description provided for @systemTrackingApprovalManagement.
  ///
  /// In tr, this message translates to:
  /// **'Sistem takibi ve onay yönetimi'**
  String get systemTrackingApprovalManagement;

  /// No description provided for @pendingApplication.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen\nBaşvuru'**
  String get pendingApplication;

  /// No description provided for @totalUsers.
  ///
  /// In tr, this message translates to:
  /// **'Toplam\nKullanıcı'**
  String get totalUsers;

  /// No description provided for @activeExpert.
  ///
  /// In tr, this message translates to:
  /// **'Aktif\nUzman'**
  String get activeExpert;

  /// No description provided for @systemReports.
  ///
  /// In tr, this message translates to:
  /// **'Sistem\nRaporları'**
  String get systemReports;

  /// No description provided for @adminActions.
  ///
  /// In tr, this message translates to:
  /// **'Admin İşlemleri'**
  String get adminActions;

  /// No description provided for @expertApplicationsActionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uzman başvurularını onayla veya reddet'**
  String get expertApplicationsActionSubtitle;

  /// No description provided for @userManagement.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Yönetimi'**
  String get userManagement;

  /// No description provided for @viewAllUsers.
  ///
  /// In tr, this message translates to:
  /// **'Tüm kullanıcıları görüntüle'**
  String get viewAllUsers;

  /// No description provided for @users.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcılar'**
  String get users;

  /// No description provided for @searchUser.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı ara...'**
  String get searchUser;

  /// No description provided for @pregnantRole.
  ///
  /// In tr, this message translates to:
  /// **'Hamile'**
  String get pregnantRole;

  /// No description provided for @doctorRole.
  ///
  /// In tr, this message translates to:
  /// **'Doktor'**
  String get doctorRole;

  /// No description provided for @userFallback.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get userFallback;

  /// No description provided for @createdAt.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Tarihi'**
  String get createdAt;

  /// No description provided for @refresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get refresh;

  /// No description provided for @systemSummary.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Özeti'**
  String get systemSummary;

  /// No description provided for @noRiskData.
  ///
  /// In tr, this message translates to:
  /// **'Risk verisi yok'**
  String get noRiskData;

  /// No description provided for @riskRateNeedsAttention.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek risk oranı dikkat gerektiriyor.'**
  String get riskRateNeedsAttention;

  /// No description provided for @riskRateIncreasing.
  ///
  /// In tr, this message translates to:
  /// **'Risk oranında artış gözlemleniyor.'**
  String get riskRateIncreasing;

  /// No description provided for @systemStable.
  ///
  /// In tr, this message translates to:
  /// **'Sistem stabil durumda.'**
  String get systemStable;

  /// No description provided for @totalRiskMeasurements.
  ///
  /// In tr, this message translates to:
  /// **'Toplam risk ölçümü'**
  String get totalRiskMeasurements;

  /// No description provided for @totalNutritionAnalyses.
  ///
  /// In tr, this message translates to:
  /// **'Toplam besin analizi'**
  String get totalNutritionAnalyses;

  /// No description provided for @pendingExpertApplications.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen uzman başvurusu'**
  String get pendingExpertApplications;

  /// No description provided for @approvedExpertApplications.
  ///
  /// In tr, this message translates to:
  /// **'Onaylanan uzman başvurusu'**
  String get approvedExpertApplications;

  /// No description provided for @rejectedExpertApplications.
  ///
  /// In tr, this message translates to:
  /// **'Reddedilen uzman başvurusu'**
  String get rejectedExpertApplications;

  /// No description provided for @lowRisk.
  ///
  /// In tr, this message translates to:
  /// **'Düşük Risk'**
  String get lowRisk;

  /// No description provided for @systemInsight.
  ///
  /// In tr, this message translates to:
  /// **'Sistem İçgörüsü'**
  String get systemInsight;

  /// No description provided for @highRiskPercent.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek risk oranı: {percent}%'**
  String highRiskPercent(String percent);

  /// No description provided for @createDietPlan.
  ///
  /// In tr, this message translates to:
  /// **'Diyet Planı Oluştur'**
  String get createDietPlan;

  /// No description provided for @dietPlanSaved.
  ///
  /// In tr, this message translates to:
  /// **'Diyet planı kaydedildi'**
  String get dietPlanSaved;

  /// No description provided for @breakfast.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı'**
  String get breakfast;

  /// No description provided for @snack1.
  ///
  /// In tr, this message translates to:
  /// **'Ara Öğün 1'**
  String get snack1;

  /// No description provided for @lunch.
  ///
  /// In tr, this message translates to:
  /// **'Öğle'**
  String get lunch;

  /// No description provided for @snack2.
  ///
  /// In tr, this message translates to:
  /// **'Ara Öğün 2'**
  String get snack2;

  /// No description provided for @dinner.
  ///
  /// In tr, this message translates to:
  /// **'Akşam'**
  String get dinner;

  /// No description provided for @nightSnack.
  ///
  /// In tr, this message translates to:
  /// **'Gece'**
  String get nightSnack;

  /// No description provided for @notes.
  ///
  /// In tr, this message translates to:
  /// **'Notlar'**
  String get notes;

  /// No description provided for @writeFieldHint.
  ///
  /// In tr, this message translates to:
  /// **'{field} yaz...'**
  String writeFieldHint(String field);

  /// No description provided for @patientDetail.
  ///
  /// In tr, this message translates to:
  /// **'Hasta Detayı'**
  String get patientDetail;

  /// No description provided for @clientDetail.
  ///
  /// In tr, this message translates to:
  /// **'Danışan Detayı'**
  String get clientDetail;

  /// No description provided for @last7DaysMeasurementCharts.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 Gün Ölçüm Grafikleri'**
  String get last7DaysMeasurementCharts;

  /// No description provided for @noMeasurementFound.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm bulunamadı'**
  String get noMeasurementFound;

  /// No description provided for @viewDetailedClinicalAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı Klinik Analizi Gör'**
  String get viewDetailedClinicalAnalysis;

  /// No description provided for @bloodPressureChartSystolic.
  ///
  /// In tr, this message translates to:
  /// **'Tansiyon Grafiği (Sistolik)'**
  String get bloodPressureChartSystolic;

  /// No description provided for @bloodSugarFastingPostMeal.
  ///
  /// In tr, this message translates to:
  /// **'Kan Şekeri (Açlık / Tokluk)'**
  String get bloodSugarFastingPostMeal;

  /// No description provided for @weightChangeChart.
  ///
  /// In tr, this message translates to:
  /// **'Kilo Değişim Grafiği'**
  String get weightChangeChart;

  /// No description provided for @personalHealthInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kişi Sağlık Bilgileri'**
  String get personalHealthInfo;

  /// No description provided for @chronicDisease.
  ///
  /// In tr, this message translates to:
  /// **'Kronik Hastalık'**
  String get chronicDisease;

  /// No description provided for @hypertension.
  ///
  /// In tr, this message translates to:
  /// **'Hipertansiyon'**
  String get hypertension;

  /// No description provided for @swelling.
  ///
  /// In tr, this message translates to:
  /// **'Şişlik'**
  String get swelling;

  /// No description provided for @discharge.
  ///
  /// In tr, this message translates to:
  /// **'Akıntı'**
  String get discharge;

  /// No description provided for @weightChart.
  ///
  /// In tr, this message translates to:
  /// **'Kilo Grafiği'**
  String get weightChart;

  /// No description provided for @calorieChart.
  ///
  /// In tr, this message translates to:
  /// **'Kalori Grafiği'**
  String get calorieChart;

  /// No description provided for @analysisHistory.
  ///
  /// In tr, this message translates to:
  /// **'Analiz Geçmişi'**
  String get analysisHistory;

  /// No description provided for @noAnalysisYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz analiz yok'**
  String get noAnalysisYet;

  /// No description provided for @dataCouldNotBeLoaded.
  ///
  /// In tr, this message translates to:
  /// **'Veri alınamadı'**
  String get dataCouldNotBeLoaded;

  /// No description provided for @dailyTotalCalories.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Toplam: {calories} kcal'**
  String dailyTotalCalories(Object calories);

  /// No description provided for @supplements.
  ///
  /// In tr, this message translates to:
  /// **'Takviyeler'**
  String get supplements;

  /// No description provided for @nutritionAnalysisDetail.
  ///
  /// In tr, this message translates to:
  /// **'Besin Analizi Detayı'**
  String get nutritionAnalysisDetail;

  /// No description provided for @analysisNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Analiz bulunamadı'**
  String get analysisNotFound;

  /// No description provided for @consumedFoods.
  ///
  /// In tr, this message translates to:
  /// **'Tüketilen Besinler'**
  String get consumedFoods;

  /// No description provided for @noDietPlanYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz diyet planın yok'**
  String get noDietPlanYet;

  /// No description provided for @myDietPlan.
  ///
  /// In tr, this message translates to:
  /// **'Diyet Planım'**
  String get myDietPlan;

  /// No description provided for @viewCurrentDietPlan.
  ///
  /// In tr, this message translates to:
  /// **'Güncel diyet planını görüntüle'**
  String get viewCurrentDietPlan;

  /// No description provided for @viewDietPlanButton.
  ///
  /// In tr, this message translates to:
  /// **'{date} - Diyeti Gör'**
  String viewDietPlanButton(String date);

  /// No description provided for @dietDetailWithDate.
  ///
  /// In tr, this message translates to:
  /// **'Diyet Detayı - {date}'**
  String dietDetailWithDate(String date);

  /// No description provided for @uploadDiploma.
  ///
  /// In tr, this message translates to:
  /// **'Diploma Yükle'**
  String get uploadDiploma;

  /// No description provided for @uploadError.
  ///
  /// In tr, this message translates to:
  /// **'Yükleme hatası'**
  String get uploadError;

  /// No description provided for @enterFieldHint.
  ///
  /// In tr, this message translates to:
  /// **'{field} gir...'**
  String enterFieldHint(String field);

  /// No description provided for @noMessagesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz mesaj yok'**
  String get noMessagesYet;

  /// No description provided for @enterWeekInfo.
  ///
  /// In tr, this message translates to:
  /// **'Hafta Bilgisi Gir'**
  String get enterWeekInfo;

  /// No description provided for @whichPregnancyWeek.
  ///
  /// In tr, this message translates to:
  /// **'Kaçıncı haftadasın?'**
  String get whichPregnancyWeek;

  /// No description provided for @pregnancyStart.
  ///
  /// In tr, this message translates to:
  /// **'Gebelik Başlangıç'**
  String get pregnancyStart;

  /// No description provided for @welcomeUser.
  ///
  /// In tr, this message translates to:
  /// **'Hoş geldiniz, {user}'**
  String welcomeUser(String user);

  /// No description provided for @welcomeExpert.
  ///
  /// In tr, this message translates to:
  /// **'Hoş geldin'**
  String get welcomeExpert;

  /// No description provided for @missingNutrition.
  ///
  /// In tr, this message translates to:
  /// **'Eksik Besin'**
  String get missingNutrition;

  /// No description provided for @riskyPatient.
  ///
  /// In tr, this message translates to:
  /// **'Riskli Hasta'**
  String get riskyPatient;

  /// No description provided for @clientUid.
  ///
  /// In tr, this message translates to:
  /// **'Danışan UID: {uid}'**
  String clientUid(String uid);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
