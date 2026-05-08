import {
  doc,
  getDoc,
  collection,
  query,
  where,
  getDocs,
  orderBy
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import { FoodUnits } from "./foodUnits.js";
import { NutritionEngine } from "./nutritionEngine.js";
import { SupplementUnits } from "./supplementUnits.js";

const db = window.db;

/* URL'den id al */
const urlParams = new URLSearchParams(window.location.search);
const clientId = urlParams.get("id");

/* CHART INSTANCES */
let weightChart;
let calorieChart;

/* USER BİLGİ */
async function loadUser() {
  try {
    const snap = await getDoc(doc(db, "users", clientId));

    if (!snap.exists()) return;

    const data = snap.data();

    document.getElementById("patientName").innerText =
      `${data.name || ""} ${data.surname || ""}`;

    document.getElementById("patientInfo").innerText =
      `Hafta: ${data.hafta || "-"} | Kilo: ${data.kilo || "-"}`;

  } catch (err) {
    console.error("USER ERROR:", err);
  }
}

/* KİLO GRAFİĞİ */
async function loadWeightChart() {
  try {

    const q = query(
      collection(db, "risk_olcumleri"),
      where("uid", "==", clientId),
      orderBy("tarih")
    );

    const snap = await getDocs(q);

    const labels = [];
    const values = [];

    snap.forEach(docSnap => {
      const d = docSnap.data();

      if (!d.tarih) return;

      const date = d.tarih.toDate
        ? d.tarih.toDate()
        : new Date(d.tarih);

      labels.push(date.toLocaleDateString("tr-TR"));
      values.push(d.kilo || 0);
    });

    if (weightChart) weightChart.destroy();

    weightChart = new Chart(document.getElementById("weightChart"), {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "Kilo",
          data: values,
          tension: 0.3
        }]
      }
    });

  } catch (err) {
    console.error("WEIGHT CHART ERROR:", err);
  }
}

/* KALORİ GRAFİĞİ */
async function loadCalorieChart() {
  try {

    const q = query(
      collection(db, "besin_analizleri"),
      where("uid", "==", clientId),
      orderBy("createdAt")
    );

    const snap = await getDocs(q);

    const dailyCalories = new Map();

    snap.forEach(docSnap => {
      const d = docSnap.data();

      if (!d.createdAt) return;

      const date = d.createdAt.toDate
        ? d.createdAt.toDate()
        : new Date(d.createdAt);

      const key = date.toLocaleDateString("tr-TR");
      const kalori = Number(d.kalori) || 0;

      dailyCalories.set(
        key,
        (dailyCalories.get(key) || 0) + kalori
      );
    });

    const labels = Array.from(dailyCalories.keys());
    const values = Array.from(dailyCalories.values());

    if (calorieChart) calorieChart.destroy();

    calorieChart = new Chart(document.getElementById("calorieChart"), {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "Günlük Toplam Kalori",
          data: values,
          tension: 0.3
        }]
      }
    });

  } catch (err) {
    console.error("CALORIE CHART ERROR:", err);
  }
}

/* ANALİZ LİSTESİ */
async function loadAnalysis() {
  const container = document.getElementById("analysisList");

  try {

    const q = query(
      collection(db, "besin_analizleri"),
      where("uid", "==", clientId)
    );

    const snap = await getDocs(q);

    if (snap.empty) {
      container.innerHTML = "Henüz analiz yok";
      return;
    }

    container.innerHTML = "";
    const groups = new Map();

    snap.forEach(docSnap => {
      const data = docSnap.data();
      const date = getAnalysisDate(data);
      if (!date) return;

      const key = date.toLocaleDateString("tr-TR");
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key).push({ data, date });
    });

    Array.from(groups.entries())
      .sort((a, b) => b[1][0].date - a[1][0].date)
      .forEach(([day, items]) => {
      items.sort((a, b) => a.date - b.date);
      const total = summarizeAnalysisDay(items);

      const div = document.createElement("div");
      div.className = "analysis-item";
      div.innerHTML = `
        <b>${day}</b>
        ${items.map((item, index) => renderAnalysisLine(item, index)).join("")}
        <hr>
        <div><b>Günlük Toplam:</b> ${total.calorie.toFixed(0)} kcal</div>
        <div style="color:#EF5350">
          Eksikler: ${total.missing.slice(0,4).join(", ") || "-"}
        </div>
        <div style="color:#00B894">
          Alınanlar: ${total.consumed.slice(0,4).join(", ") || "-"}
        </div>
      `;

      container.appendChild(div);
    });

  } catch (err) {
    console.error("ANALYSIS ERROR:", err);
    container.innerHTML = "Hata oluştu";
  }
}

function renderAnalysisLine(item, index) {
  const data = item.data;
  const time = item.date.toLocaleTimeString("tr-TR", {
    hour: "2-digit",
    minute: "2-digit"
  });
  const takviyeler = (data.takviyeler || []).map(t => t.ad).slice(0, 2).join(", ") || "-";

  return `
    <div style="margin-top:10px">
      <b>${index + 1}. Analiz - ${time}</b>
      <div>Kalori: ${data.kalori || 0} kcal</div>
      <div>Takviyeler: ${takviyeler}</div>
    </div>
  `;
}

function getAnalysisDate(data) {
  const raw = data.createdAt || data.tarih;
  if (raw?.toDate) return raw.toDate();
  if (raw?.seconds) return new Date(raw.seconds * 1000);
  return raw ? new Date(raw) : null;
}

function summarizeAnalysisDay(items) {
  const foods = [];
  const supplements = [];

  items.forEach(({ data }) => {
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
        amount: info ? Number(item.miktar || 0) * info.value : Number(item.miktar || 0),
        unit: info ? info.unit : ""
      });
    });
  });

  const result = NutritionEngine.analyzeFoods(foods, supplements);

  return {
    calorie: result.totalCalories || 0,
    consumed: result.consumedNutrients || [],
    missing: result.missingNutrients || []
  };
}

/* INIT */
async function init() {

  if (!clientId) {
    alert("Danışan bulunamadı");
    return;
  }

  await loadUser();
  await loadWeightChart();
  await loadCalorieChart();
  await loadAnalysis();
}

init();
