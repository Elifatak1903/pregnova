import { FoodUnits } from "./foodUnits.js";
import { NutritionEngine } from "./nutritionEngine.js";
import { SupplementUnits } from "./supplementUnits.js";

import {
  collection,
  addDoc,
  doc,
  getDoc,
  serverTimestamp
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
};

window.addSupplement = function () {

  const name = document.getElementById("supName").value.trim().toLowerCase();
  const amount = +document.getElementById("supAmount").value;
  const unit = document.getElementById("supUnit").value;

  if (!name || amount <= 0) return;

  if (!SupplementUnits[name]) {
    alert("Geçerli bir takviye girin ❌");
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
        <button class="delete-btn" onclick="removeFood(${index})">✖</button>
      </div>
    `;
  });

  takviyeListesi.forEach((item, index) => {
    supList.innerHTML += `
      <div class="list-item">
        <span>${item.ad} (${item.miktar}${item.birim ? " " + item.birim : ""})</span>
        <button class="delete-btn" onclick="removeSup(${index})">✖</button>
      </div>
    `;
  });
}

window.removeFood = function (i) {
  besinListesi.splice(i, 1);
  renderList();
};

window.removeSup = function (i) {
  takviyeListesi.splice(i, 1);
  renderList();
};

window.saveAnalysis = async function () {

  if (besinListesi.length === 0) {
    alert("Lütfen besin ekleyin ❌");
    return;
  }

  const user = auth.currentUser;
  if (!user) {
    alert("Kullanıcı bulunamadı ❌");
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
      amount: info
        ? item.miktar * info.value
        : item.miktar,
      unit: info ? info.unit : ""
    };
  });

  const result = NutritionEngine.analyzeFoods(foods, sups);

  const userDoc = await getDoc(doc(db, "users", user.uid));
  const userData = userDoc.data() || {};
  const dietitianId = userData.assignedDietitian || null;

  await addDoc(collection(db, "besin_analizleri"), {
    uid: user.uid,
    dietitianId,
    besinler: besinListesi,
    takviyeler: takviyeListesi,
    kalori: result.totalCalories,
    consumedNutrients: result.consumedNutrients,
    missingNutrients: result.missingNutrients,
    excessNutrients: result.excessNutrients,
    tarih: Timestamp.now()
  });

  showResult(result);
};