class WeeklyNotificationMessage {
  const WeeklyNotificationMessage._();

  static const firstTrimesterEndWeek = 13;
  static const secondTrimesterStartWeek = 14;
  static const secondTrimesterEndWeek = 27;
  static const thirdTrimesterStartWeek = 28;
  static const maxPregnancyWeek = 42;

  static String messageFor({
    required int week,
    required String languageCode,
  }) {
    final normalizedWeek = week.clamp(1, maxPregnancyWeek);
    final isEnglish = languageCode.toLowerCase().startsWith('en');

    if (normalizedWeek <= firstTrimesterEndWeek) {
      return isEnglish
          ? 'First trimester: follow regular antenatal care and use iron-folic acid as advised. Seek care for bleeding, severe headache or abdominal pain.'
          : '1. trimester: düzenli gebelik takibini sürdür ve demir-folik asidi sağlık uzmanının önerdiği şekilde kullan. Kanama, şiddetli baş ağrısı veya karın ağrısında sağlık kuruluşuna başvur.';
    }

    if (normalizedWeek >= secondTrimesterStartWeek &&
        normalizedWeek <= secondTrimesterEndWeek) {
      return isEnglish
          ? 'Second trimester: keep tracking blood pressure, glucose and nutrition. Ask your doctor about calcium if your dietary calcium intake is low.'
          : '2. trimester: tansiyon, kan şekeri ve beslenme takibini sürdür. Kalsiyum alımın düşükse doktoruna danış.';
    }

    // Weeks 28-42 are treated as the third trimester.
    if (normalizedWeek < thirdTrimesterStartWeek) {
      return isEnglish
          ? 'Continue regular pregnancy follow-up and contact your doctor if you notice warning signs.'
          : 'DÃ¼zenli gebelik takibini sÃ¼rdÃ¼r ve uyarÄ± belirtilerinde doktorunla iletiÅŸime geÃ§.';
    }

    return isEnglish
        ? 'Third trimester: continue antenatal follow-up and watch danger signs such as bleeding, severe headache, abdominal pain or reduced baby movement.'
        : '3. trimester: gebelik kontrollerini sürdür; kanama, şiddetli baş ağrısı, karın ağrısı veya bebek hareketlerinde azalma gibi tehlike belirtilerine dikkat et.';
  }
}
