class NutritionEngine {

  static Map<String, double> dailyNeeds = {
    "Protein": 75,
    "Demir": 27,
    "Kalsiyum": 1000,
    "Omega-3": 1.4,
    "Folik asit": 600,
    "C vitamini": 85,
    "B12 vitamini": 2.6,
  };

  static Map<String, double> maxRequirements = {

    "Demir": 45,
    "Folik asit": 1000,
    "Kalsiyum": 2500,
    "D vitamini": 100,
    "B12 vitamini": 10,
    "Magnezyum": 400,
    "Çinko": 40,
    "Omega-3": 3

  };

  static Map<String, Map<String, double>> supplementNutrition = {

    "demir": {"Demir": 27},
    "folik asit": {"Folik asit": 400},
    "omega 3": {"Omega-3": 1.4},
    "b12": {"B12 vitamini": 2.6},
    "kalsiyum": {"Kalsiyum": 500},
    "d vitamini": {"D vitamini": 15},
    "magnezyum": {"Magnezyum": 300},
    "çinko": {"Çinko": 10}

  };

  static Map<String, Map<String, double>> foodNutrition = {

    "yumurta": {"Protein": 13, "B12 vitamini": 1.1},
    "süt": {"Protein": 3.4, "Kalsiyum": 120},
    "yoğurt": {"Protein": 4, "Kalsiyum": 110},
    "peynir": {"Protein": 25, "Kalsiyum": 700},

    "tavuk": {"Protein": 27},
    "et": {"Protein": 26, "Demir": 2.6},
    "karaciğer": {"Protein": 20, "Demir": 6.5, "B12 vitamini": 16},
    "balık": {"Protein": 22, "Omega-3": 1.2},

    "mercimek": {"Protein": 9, "Demir": 3.3},
    "kuru fasulye": {"Protein": 9, "Demir": 2.1},
    "nohut": {"Protein": 8.9, "Demir": 2.9},
    "bulgur": {"Protein": 3.1},
    "pirinç": {"Protein": 2.7},

    "ıspanak": {"Demir": 2.7, "Folik asit": 190},
    "brokoli": {"C vitamini": 89, "Folik asit": 63},
    "karalahana": {"C vitamini": 120},
    "havuç": {"C vitamini": 6},
    "domates": {"C vitamini": 14},
    "salatalık": {"C vitamini": 3},

    "patates": {"C vitamini": 19},
    "tatlı patates": {"C vitamini": 22},
    "kabak": {"C vitamini": 17},
    "patlıcan": {"C vitamini": 2},
    "biber": {"C vitamini": 120},

    "portakal": {"C vitamini": 53},
    "mandalina": {"C vitamini": 27},
    "limon": {"C vitamini": 53},
    "muz": {"C vitamini": 9},
    "elma": {"C vitamini": 4},
    "armut": {"C vitamini": 4},

    "çilek": {"C vitamini": 59},
    "avokado": {"Sağlıklı yağlar": 15},
    "ceviz": {"Omega-3": 9},
    "badem": {"Protein": 21, "Magnezyum": 270},
    "fındık": {"Protein": 15},

    "ayran": {"Kalsiyum": 120},
    "tarhana": {"Protein": 3},
    "mercimek çorbası": {"Protein": 4},
    "menemen": {"Protein": 5},
    "lahmacun": {"Protein": 12, "Demir": 2},

    "dolma": {"Lif": 2},
    "sarma": {"Lif": 2},
    "çiğ köfte": {"Protein": 8, "Demir": 2},

    "tam tahıl ekmek": {"Protein": 9},
    "beyaz ekmek": {"Protein": 8},

    "makarna": {"Protein": 5},
    "pizza": {"Protein": 11},

    "kuruyemiş": {"Protein": 20},
    "keten": {"Omega-3": 22},

    "muz": {"C vitamini": 9},
    "kiraz": {"C vitamini": 7},
    "vişne": {"C vitamini": 10},
    "erik": {"C vitamini": 9},
    "şeftali": {"C vitamini": 6},
    "kayısı": {"C vitamini": 10},
    "incir": {"Lif": 2.9},
    "nar": {"C vitamini": 10},
    "ananas": {"C vitamini": 47},
    "kivi": {"C vitamini": 92},

    "mantar": {"Protein": 3},
    "marul": {"Folik asit": 73},
    "roka": {"C vitamini": 15},
    "maydanoz": {"C vitamini": 133},
    "dereotu": {"C vitamini": 85},
    "pırasa": {"C vitamini": 12},
    "soğan": {"C vitamini": 7},
    "sarımsak": {"C vitamini": 31},
    "bezelye": {"Protein": 5},
    "mısır": {"Protein": 3.2},

    "somon": {"Protein": 20, "Omega-3": 2.2},
    "ton balığı": {"Protein": 23},
    "hamsi": {"Protein": 20, "Omega-3": 1.5},
    "sardalya": {"Protein": 21, "Omega-3": 1.4},
    "karides": {"Protein": 24},

    "kaşar peyniri": {"Protein": 25, "Kalsiyum": 700},
    "beyaz peynir": {"Protein": 14, "Kalsiyum": 500},
    "mozarella": {"Protein": 22, "Kalsiyum": 505},
    "kefir": {"Protein": 3.5, "Kalsiyum": 120},
    "dondurma": {"Kalsiyum": 100},

    "yulaf": {"Protein": 17, "Lif": 10},
    "yulaf ezmesi": {"Protein": 17, "Lif": 10},
    "kinoa": {"Protein": 14},
    "arpa": {"Protein": 12},
    "çavdar": {"Protein": 10},

    "fıstık": {"Protein": 26},
    "antep fıstığı": {"Protein": 20},
    "kajü": {"Protein": 18},
    "kabak çekirdeği": {"Protein": 19},
    "ay çekirdeği": {"Protein": 21},

    "sucuk": {"Protein": 16},
    "sosis": {"Protein": 12},
    "salam": {"Protein": 22},
    "köfte": {"Protein": 17},
    "döner": {"Protein": 19},

    "hamburger": {"Protein": 17},
    "tost": {"Protein": 12},
    "omlet": {"Protein": 11},
    "pankek": {"Protein": 6},
    "waffle": {"Protein": 6}

  };

  static Map<String, dynamic> analyzeFoods(
      List<Map<String, dynamic>> foods,
      List<Map<String, dynamic>> supplements) {

    Set<String> consumedNutrients = {};
    List<Map<String, dynamic>> foodDetails = [];
    Map<String, double> totalNutrients = {};

    for (var food in foods) {

      String name = food["name"].toLowerCase();
      double gram = food["amount"];

      List<String> nutrients = [];

      if (foodNutrition.containsKey(name)) {

        var nutrition = foodNutrition[name]!;

        nutrition.forEach((nutrient, value) {

          nutrients.add(nutrient);
          consumedNutrients.add(nutrient);

          double total = value * (gram / 100);

          totalNutrients[nutrient] =
              (totalNutrients[nutrient] ?? 0) + total;

        });
      }

      for (var sup in supplements) {

        String name = sup["name"].toLowerCase().trim();

        if (supplementNutrition.containsKey(name)) {

          var nutrients = supplementNutrition[name]!;

          nutrients.forEach((nutrient, value) {

            totalNutrients[nutrient] =
                (totalNutrients[nutrient] ?? 0) + value;

            consumedNutrients.add(nutrient);

          });

        }
      }

      if (nutrients.isEmpty) {
        nutrients.add("Diğer besin öğeleri");
      }

      foodDetails.add({
        "name": food["name"],
        "amount": gram,
        "nutrients": nutrients.join(", ")
      });
    }

    List<String> missingNutrients = [];

    dailyNeeds.forEach((nutrient, need) {

      double taken = totalNutrients[nutrient] ?? 0;

      if (taken < need) {
        missingNutrients.add(nutrient);
      }

    });

    List<String> excessNutrients = [];

    maxRequirements.forEach((nutrient, maxValue) {

      if ((totalNutrients[nutrient] ?? 0) > maxValue) {

        excessNutrients.add(nutrient);

      }

    });

    return {
      "foodDetails": foodDetails,
      "consumedNutrients": consumedNutrients.toList(),
      "missingNutrients": missingNutrients,
      "totalNutrients": totalNutrients,
      "excessNutrients": excessNutrients
    };
  }
}