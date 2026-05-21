import { getLanguage } from "./i18n.js";

const supplementLabels = {
  "demir": { tr: "Demir", en: "Iron" },
  "iron": { tr: "Demir", en: "Iron" },
  "folik asit": { tr: "Folik asit", en: "Folic acid" },
  "folic acid": { tr: "Folik asit", en: "Folic acid" },
  "vitamin d": { tr: "D vitamini", en: "Vitamin D" },
  "kalsiyum": { tr: "Kalsiyum", en: "Calcium" },
  "calcium": { tr: "Kalsiyum", en: "Calcium" },
  "omega 3": { tr: "Omega 3", en: "Omega 3" },
  "omega-3": { tr: "Omega 3", en: "Omega 3" },
  "protein": { tr: "Protein", en: "Protein" },
  "b12": { tr: "B12 vitamini", en: "Vitamin B12" },
  "vitamin b12": { tr: "B12 vitamini", en: "Vitamin B12" },
  "b12 vitamin": { tr: "B12 vitamini", en: "Vitamin B12" },
  "magnezyum": { tr: "Magnezyum", en: "Magnesium" },
  "magnesium": { tr: "Magnezyum", en: "Magnesium" },
  "çinko": { tr: "Çinko", en: "Zinc" },
  "cinko": { tr: "Çinko", en: "Zinc" },
  "zinc": { tr: "Çinko", en: "Zinc" }
};

export function displaySupplementName(rawName) {
  const name = String(rawName || "").trim();
  const key = name.toLocaleLowerCase("tr-TR");
  const label = supplementLabels[key];

  if (!label) return name || "-";

  return getLanguage() === "en" ? label.en : label.tr;
}
