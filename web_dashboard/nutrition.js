import { FoodUnits } from "./foodUnits.js";
import { NutritionEngine } from "./nutritionEngine.js";
import { SupplementUnits } from "./supplementUnits.js";
import { t } from "./i18n.js";

import {
  collection,
  addDoc,
  doc,
  getDoc,
  serverTimestamp,
  getDocs,
  query,
  where,
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;

let besinListesi = [];
let takviyeListesi = [];

const supNameInput = document.getElementById("supName");

if (supNameInput) {
  supNameInput.addEventListener("input", function () {

    const name = this.value.toLowerCase().trim();
    const unitInput = document.getElementById("supUnit");

    const info = SupplementUnits[name];

    unitInput.value = info ? info.unit : "";
  });
}

window.addFood = function () {

  const name = document.getElementById("foodName").value.trim();
  const amount = +document.getElementById("foodAmount").value;
  const unit = document.getElementById("foodUnit").value;

  if (!name || amount <= 0) return;

  besinListesi.push({
    ad: name,
    miktar: amount,
    format: unit
  });

  document.getElementById("foodName").value = "";
  document.getElementById("foodAmount").value = "";

  renderList();
  renderPreview();
};

window.addSupplement = function () {

  const name = document.getElementById("supName").value.trim().toLowerCase();
  const amount = +document.getElementById("supAmount").value;
  const unit = document.getElementById("supUnit").value;

  if (!name || amount <= 0) return;

  if (!SupplementUnits[name]) {
    alert(t("invalidSupplement"));
    return;
  }

  takviyeListesi.push({
    ad: name,
    miktar: amount,
    birim: unit
  });

  document.getElementById("supName").value = "";
  document.getElementById("supAmount").value = "";
  document.getElementById("supUnit").value = "";

  renderList();
  renderPreview();
};

function renderList() {

  const foodList = document.getElementById("foodList");
  const supList = document.getElementById("supList");

  if (!foodList || !supList) return;

  foodList.innerHTML = "";
  supList.innerHTML = "";

  besinListesi.forEach((item, index) => {
    foodList.innerHTML += `
      <div class="list-item">
        <span>${item.ad} (${item.miktar} ${item.format})</span>
        <button class="delete-btn" onclick="removeFood(${index})">x</button>
      </div>
    `;
  });

  takviyeListesi.forEach((item, index) => {
    supList.innerHTML += `
      <div class="list-item">
        <span>${item.ad} (${item.miktar}${item.birim ? " " + item.birim : ""})</span>
        <button class="delete-btn" onclick="removeSup(${index})">x</button>
      </div>
    `;
  });
}

function renderPreview() {
  if (besinListesi.length === 0 && takviyeListesi.length === 0) {
    const resultBox = document.getElementById("resultBox");
    if (resultBox) resultBox.classList.add("hidden-result");
    return;
  }

  const foods = besinListesi.map(item => {
    const gram = (FoodUnits.units[item.format] || 1) * item.miktar;

    return {
      name: item.ad.toLowerCase(),
      amount: gram
    };
  });

  const sups = takviyeListesi.map(item => {
    const info = SupplementUnits[item.ad];

    return {
      name: item.ad,
      amount: item.miktar,
      unit: info ? info.unit : ""
    };
  });

  const result = NutritionEngine.analyzeFoods(foods, sups);

  if (typeof window.showResult === "function") {
    window.showResult(result);
  }
}

window.removeFood = function (i) {
  besinListesi.splice(i, 1);
  renderList();
  renderPreview();
};

window.removeSup = function (i) {
  takviyeListesi.splice(i, 1);
  renderList();
  renderPreview();
};

window.saveAnalysis = async function () {

  if (besinListesi.length === 0) {
    alert(t("pleaseAddFood"));
    return;
  }

  const user = auth.currentUser;
  if (!user) {
    alert(t("userNotFound"));
    return;
  }

  const foods = besinListesi.map(item => {
    const gram = (FoodUnits.units[item.format] || 1) * item.miktar;

    return {
      name: item.ad.toLowerCase(),
      amount: gram
    };
  });

  const sups = takviyeListesi.map(item => {

    const info = SupplementUnits[item.ad];

    return {
      name: item.ad,
      amount: item.miktar,
      unit: info ? info.unit : ""
    };
  });

  const result = NutritionEngine.analyzeFoods(foods, sups);
  const dailyInputs = await getTodayNutritionInputs(user.uid);
  const dailyResult = NutritionEngine.analyzeFoods(
    [...dailyInputs.foods, ...foods],
    [...dailyInputs.supplements, ...sups]
  );

  const userDoc = await getDoc(doc(db, "users", user.uid));
  const userData = userDoc.data() || {};
  const dietitianId = userData.assignedDietitian || null;

  await addDoc(collection(db, "besin_analizleri"), {
    uid: user.uid,
    dietitianId,
    besinler: besinListesi,
    takviyeler: takviyeListesi,
    kalori: result.totalCalories,
    consumedNutrients: dailyResult.consumedNutrients,
    missingNutrients: dailyResult.missingNutrients,
    excessNutrients: dailyResult.excessNutrients,
    totalNutrients: dailyResult.totalNutrients,
    createdAt: serverTimestamp(),
    tarih: serverTimestamp()
  });

  showResult(result, dailyResult);
  clearAnalysisForm();
};

function clearAnalysisForm() {
  besinListesi = [];
  takviyeListesi = [];

  const foodName = document.getElementById("foodName");
  const foodAmount = document.getElementById("foodAmount");
  const foodUnit = document.getElementById("foodUnit");
  const supName = document.getElementById("supName");
  const supAmount = document.getElementById("supAmount");
  const supUnit = document.getElementById("supUnit");

  if (foodName) foodName.value = "";
  if (foodAmount) foodAmount.value = "";
  if (foodUnit) foodUnit.selectedIndex = 0;
  if (supName) supName.value = "";
  if (supAmount) supAmount.value = "";
  if (supUnit) supUnit.value = "";

  renderList();
}

async function getTodayNutritionInputs(uid) {
  const start = new Date();
  start.setHours(0, 0, 0, 0);

  const q = query(
    collection(db, "besin_analizleri"),
    where("uid", "==", uid)
  );

  const snap = await getDocs(q);
  const foods = [];
  const supplements = [];

  snap.forEach(docSnap => {
    const data = docSnap.data();
    const rawDate = data.createdAt || data.tarih;
    const date = rawDate?.toDate ? rawDate.toDate() : rawDate ? new Date(rawDate) : null;

    if (!date || date < start) return;

    (data.besinler || []).forEach(item => {
      const gram = (FoodUnits.units[item.format] || 1) * Number(item.miktar || 0);

      foods.push({
        name: String(item.ad || "").toLowerCase(),
        amount: gram
      });
    });

    (data.takviyeler || []).forEach(item => {
      const info = SupplementUnits[item.ad];

      supplements.push({
        name: item.ad,
        amount: Number(item.miktar || 0),
        unit: info ? info.unit : ""
      });
    });
  });

  return { foods, supplements };
}
