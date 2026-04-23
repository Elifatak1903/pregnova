import { FoodUnits } from "./foodUnits.js";

export const NutritionEngine = {

  dailyNeeds: {
    "Protein": 75,
    "Demir": 27,
    "Kalsiyum": 1000,
    "Omega-3": 1.4,
    "Folik asit": 600,
    "C vitamini": 85,
    "B12 vitamini": 2.6,
  },

  maxRequirements: {
    "Demir": 45,
    "Folik asit": 1000,
    "Kalsiyum": 2500,
    "Omega-3": 3
  },

  supplementNutrition: {
    "demir": {"Demir": 27},
    "folik asit": {"Folik asit": 400},
    "omega 3": {"Omega-3": 1.4},
    "b12": {"B12 vitamini": 2.6},
    "kalsiyum": {"Kalsiyum": 500}
  },

  foodNutrition: {
    "yumurta": {"Protein": 13, "B12 vitamini": 1.1, "Kalori": 155},
    "süt": {"Protein": 3.4, "Kalsiyum": 120, "Kalori": 42},
    "yoğurt": {"Protein": 4, "Kalsiyum": 110, "Kalori": 59},
    "peynir": {"Protein": 25, "Kalsiyum": 700, "Kalori": 402},

    "tavuk": {"Protein": 27, "Kalori": 239},
    "et": {"Protein": 26, "Demir": 2.6, "Kalori": 250},
    "karaciğer": {"Protein": 20, "Demir": 6.5, "B12 vitamini": 16, "Kalori": 175},
    "balık": {"Protein": 22, "Omega-3": 1.2, "Kalori": 206},

    "mercimek": {"Protein": 9, "Demir": 3.3, "Kalori": 116},
    "kuru fasulye": {"Protein": 9, "Demir": 2.1, "Kalori": 127},
    "nohut": {"Protein": 8.9, "Demir": 2.9, "Kalori": 164},
    "bulgur": {"Protein": 3.1, "Kalori": 83},
    "pirinç": {"Protein": 2.7, "Kalori": 130},

    "ıspanak": {"Demir": 2.7, "Folik asit": 190, "Kalori": 23},
    "brokoli": {"C vitamini": 89, "Folik asit": 63, "Kalori": 34},
    "karalahana": {"C vitamini": 120, "Kalori": 49},
    "havuç": {"C vitamini": 6, "Kalori": 41},
    "domates": {"C vitamini": 14, "Kalori": 18},
    "salatalık": {"C vitamini": 3, "Kalori": 16},

    "patates": {"C vitamini": 19, "Kalori": 77},
    "tatlı patates": {"C vitamini": 22, "Kalori": 86},
    "kabak": {"C vitamini": 17, "Kalori": 17},
    "patlıcan": {"C vitamini": 2, "Kalori": 25},
    "biber": {"C vitamini": 120, "Kalori": 31},

    "portakal": {"C vitamini": 53, "Kalori": 47},
    "mandalina": {"C vitamini": 27, "Kalori": 53},
    "limon": {"C vitamini": 53, "Kalori": 29},
    "muz": {"C vitamini": 9, "Kalori": 89},
    "elma": {"C vitamini": 4, "Kalori": 52},
    "armut": {"C vitamini": 4, "Kalori": 57},

    "çilek": {"C vitamini": 59, "Kalori": 32},
    "avokado": {"Sağlıklı yağlar": 15, "Kalori": 160},
    "ceviz": {"Omega-3": 9, "Kalori": 654},
    "badem": {"Protein": 21, "Magnezyum": 270, "Kalori": 579},
    "fındık": {"Protein": 15, "Kalori": 628},

    "ayran": {"Kalsiyum": 120, "Kalori": 37},
    "tarhana": {"Protein": 3, "Kalori": 60},
    "mercimek çorbası": {"Protein": 4, "Kalori": 65},
    "menemen": {"Protein": 5, "Kalori": 100},
    "lahmacun": {"Protein": 12, "Demir": 2, "Kalori": 250},

    "dolma": {"Lif": 2, "Kalori": 150},
    "sarma": {"Lif": 2, "Kalori": 120},
    "çiğ köfte": {"Protein": 8, "Demir": 2, "Kalori": 180},

    "tam tahıl ekmek": {"Protein": 9, "Kalori": 247},
    "beyaz ekmek": {"Protein": 8, "Kalori": 265},

    "makarna": {"Protein": 5, "Kalori": 131},
    "pizza": {"Protein": 11, "Kalori": 266},

    "kuruyemiş": {"Protein": 20, "Kalori": 600},
    "keten": {"Omega-3": 22, "Kalori": 534},

    "kiraz": {"C vitamini": 7, "Kalori": 50},
    "vişne": {"C vitamini": 10, "Kalori": 50},
    "erik": {"C vitamini": 9, "Kalori": 46},
    "şeftali": {"C vitamini": 6, "Kalori": 39},
    "kayısı": {"C vitamini": 10, "Kalori": 48},
    "incir": {"Lif": 2.9, "Kalori": 74},
    "nar": {"C vitamini": 10, "Kalori": 83},
    "ananas": {"C vitamini": 47, "Kalori": 50},
    "kivi": {"C vitamini": 92, "Kalori": 61},

    "mantar": {"Protein": 3, "Kalori": 22},
    "marul": {"Folik asit": 73, "Kalori": 15},
    "roka": {"C vitamini": 15, "Kalori": 25},
    "maydanoz": {"C vitamini": 133, "Kalori": 36},
    "dereotu": {"C vitamini": 85, "Kalori": 43},
    "pırasa": {"C vitamini": 12, "Kalori": 61},
    "soğan": {"C vitamini": 7, "Kalori": 40},
    "sarımsak": {"C vitamini": 31, "Kalori": 149},
    "bezelye": {"Protein": 5, "Kalori": 81},
    "mısır": {"Protein": 3.2, "Kalori": 96},

    "somon": {"Protein": 20, "Omega-3": 2.2, "Kalori": 208},
    "ton balığı": {"Protein": 23, "Kalori": 132},
    "hamsi": {"Protein": 20, "Omega-3": 1.5, "Kalori": 131},
    "sardalya": {"Protein": 21, "Omega-3": 1.4, "Kalori": 208},
    "karides": {"Protein": 24, "Kalori": 99},

    "kaşar peyniri": {"Protein": 25, "Kalsiyum": 700, "Kalori": 402},
    "beyaz peynir": {"Protein": 14, "Kalsiyum": 500, "Kalori": 264},
    "mozarella": {"Protein": 22, "Kalsiyum": 505, "Kalori": 280},
    "kefir": {"Protein": 3.5, "Kalsiyum": 120, "Kalori": 41},
    "dondurma": {"Kalsiyum": 100, "Kalori": 207},

    "yulaf": {"Protein": 17, "Lif": 10, "Kalori": 389},
    "yulaf ezmesi": {"Protein": 17, "Lif": 10, "Kalori": 389},
    "kinoa": {"Protein": 14, "Kalori": 120},
    "arpa": {"Protein": 12, "Kalori": 354},
    "çavdar": {"Protein": 10, "Kalori": 335},

    "fıstık": {"Protein": 26, "Kalori": 567},
    "antep fıstığı": {"Protein": 20, "Kalori": 562},
    "kajü": {"Protein": 18, "Kalori": 553},
    "kabak çekirdeği": {"Protein": 19, "Kalori": 559},
    "ay çekirdeği": {"Protein": 21, "Kalori": 584},

    "sucuk": {"Protein": 16, "Kalori": 301},
    "sosis": {"Protein": 12, "Kalori": 269},
    "salam": {"Protein": 22, "Kalori": 336},
    "köfte": {"Protein": 17, "Kalori": 250},
    "döner": {"Protein": 19, "Kalori": 215},

    "hamburger": {"Protein": 17, "Kalori": 295},
    "tost": {"Protein": 12, "Kalori": 300},
    "omlet": {"Protein": 11, "Kalori": 154},
    "pankek": {"Protein": 6, "Kalori": 227},
    "waffle": {"Protein": 6, "Kalori": 291},

  },

  analyzeFoods(foods, supplements) {

    let totalNutrients = {};
    let consumed = new Set();
    let missing = [];
    let excess = [];
    let totalCalories = 0;

    foods.forEach(food => {

      const name = food.name.toLowerCase().trim();

      if (this.foodNutrition[name]) {

        const nutrients = this.foodNutrition[name];

        Object.entries(nutrients).forEach(([nutrient, value]) => {

          const total = +(value * (food.amount / 100)).toFixed(2);

          totalNutrients[nutrient] =
            (totalNutrients[nutrient] || 0) + total;

          consumed.add(nutrient);

          if (nutrient === "Kalori") {
            totalCalories += total;
          }
        });
      }
    });

    supplements.forEach(sup => {

      const name = sup.name
        .toLowerCase()
        .replace("-", " ")
        .trim();

      if (this.supplementNutrition[name]) {

        const nutrients = this.supplementNutrition[name];

        Object.entries(nutrients).forEach(([n, v]) => {
          totalNutrients[n] =
            (totalNutrients[n] || 0) + (v * (sup.amount || 1));

          consumed.add(n);
        });
      }
    });

    Object.entries(this.dailyNeeds).forEach(([n, need]) => {
      if ((totalNutrients[n] || 0) < need) {
        missing.push(n);
      }
    });

    Object.entries(this.maxRequirements).forEach(([n, max]) => {
      if ((totalNutrients[n] || 0) > max) {
        excess.push(n);
      }
    });

    return {
      consumedNutrients: [...consumed],
      missingNutrients: missing,
      excessNutrients: excess,
      totalCalories: Math.round(totalCalories)
    };
  }
};