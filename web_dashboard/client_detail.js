import {
  doc,
  getDoc,
  collection,
  query,
  where,
  getDocs
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import { FoodUnits } from "./foodUnits.js";
import { NutritionEngine } from "./nutritionEngine.js";
import { SupplementUnits } from "./supplementUnits.js";
import { t } from "./i18n.js";

let db;

/* URL'den id al */
const urlParams = new URLSearchParams(window.location.search);
const clientId = urlParams.get("id");

/* CHART INSTANCES */
let weightChart;
let calorieChart;

function toDate(value) {
  if (!value) return null;
  if (value.toDate) return value.toDate();
  if (value.seconds) return new Date(value.seconds * 1000);

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function getNumber(value) {
  const number = Number(value);
  return Number.isFinite(number) ? number : 0;
}

function canRenderCharts() {
  return typeof window.Chart === "function";
}

/* USER BİLGİ */
async function loadUser() {
  console.log("loadUser başladı");
  console.log("clientId:", clientId);
  console.log("db:", db);

  const patientName = document.getElementById("patientName");
  const patientInfo = document.getElementById("patientInfo");

  console.log("patientName element:", patientName);
  console.log("patientInfo element:", patientInfo);

  try {
    const ref = doc(db, "users", clientId);
    console.log("users ref path:", ref.path);

    const snap = await getDoc(ref);

    console.log("snap exists:", snap.exists());
    console.log("snap id:", snap.id);
    console.log("snap data:", snap.data());

    if (!snap.exists()) {
      patientName.innerText = "Danışan bulunamadı";
      patientInfo.innerText = `clientId: ${clientId}`;
      return;
    }

    const data = snap.data();

    patientName.innerText =
      `${data.name || ""} ${data.surname || ""}`.trim() || "-";

    patientInfo.innerText =
      `${t("week")}: ${data.hafta || "-"} | ${t("weight")}: ${data.kilo || "-"}`;

    console.log("UI güncellendi:", patientName.innerText, patientInfo.innerText);

  } catch (err) {
    console.error("USER ERROR:", err);

    patientName.innerText = "Bilgi yükleme hatası";
    patientInfo.innerText = err.message;
  }
}

/* KİLO GRAFİĞİ */
async function loadWeightChart() {
  try {

    const q = query(
      collection(db, "risk_olcumleri"),
      where("uid", "==", clientId)
    );

    const snap = await getDocs(q);

    const rows = snap.docs
      .map(docSnap => {
        const data = docSnap.data();
        return {
          date: toDate(data.tarih),
          weight: getNumber(data.kilo)
        };
      })
      .filter(row => row.date)
      .sort((a, b) => a.date - b.date);

    const labels = rows.map(row => row.date.toLocaleDateString());
    const values = rows.map(row => row.weight);

    if (weightChart) weightChart.destroy();
    if (!canRenderCharts()) return;

    weightChart = new Chart(document.getElementById("weightChart"), {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: t("weight"),
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
      where("uid", "==", clientId)
    );

    const snap = await getDocs(q);

    const dailyCalories = new Map();

    snap.docs
      .map(docSnap => {
        const data = docSnap.data();
        return {
          date: toDate(data.createdAt || data.tarih),
          calorie: getNumber(data.kalori)
        };
      })
      .filter(row => row.date)
      .sort((a, b) => a.date - b.date)
      .forEach(row => {
        const key = row.date.toLocaleDateString();

        dailyCalories.set(
          key,
          (dailyCalories.get(key) || 0) + row.calorie
        );
      });

    const labels = Array.from(dailyCalories.keys());
    const values = Array.from(dailyCalories.values());

    if (calorieChart) calorieChart.destroy();
    if (!canRenderCharts()) return;

    calorieChart = new Chart(document.getElementById("calorieChart"), {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: t("dailyTotalCalories"),
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
      container.innerHTML = t("noAnalyses");
      return;
    }

    container.innerHTML = "";
    const groups = new Map();

    snap.forEach(docSnap => {
      const data = docSnap.data();
      const date = getAnalysisDate(data);
      if (!date) return;

      const key = date.toLocaleDateString();
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
        <div><b>${t("dailyTotal")}:</b> ${total.calorie.toFixed(0)} kcal</div>
        <div style="color:#EF5350">
          ${t("missing")}: ${total.missing.slice(0,4).join(", ") || "-"}
        </div>
        <div style="color:#00B894">
          ${t("consumed")}: ${total.consumed.slice(0,4).join(", ") || "-"}
        </div>
      `;

      container.appendChild(div);
    });

  } catch (err) {
    console.error("ANALYSIS ERROR:", err);
    container.innerHTML = t("genericError");
  }
}

function renderAnalysisLine(item, index) {
  const data = item.data;
  const time = item.date.toLocaleTimeString(undefined, {
    hour: "2-digit",
    minute: "2-digit"
  });
  const supplements = getArray(data.takviyeler)
    .map(item => item.ad || item.name)
    .filter(Boolean)
    .slice(0, 2)
    .join(", ") || "-";

  return `
    <div style="margin-top:10px">
      <b>${t("analysisNumber", { number: index + 1, time })}</b>
      <div>${t("calories")}: ${getNumber(data.kalori)} kcal</div>
      <div>${t("supplements")}: ${supplements}</div>
    </div>
  `;
}

function getAnalysisDate(data) {
  const raw = data.createdAt || data.tarih;
  return toDate(raw);
}

function getArray(value) {
  return Array.isArray(value) ? value : [];
}

function summarizeAnalysisDay(items) {
  const foods = [];
  const supplements = [];

  items.forEach(({ data }) => {
    getArray(data.besinler).forEach(item => {
      if (!item || typeof item !== "object") return;

      const name = String(item.ad || item.name || "").trim().toLowerCase();
      if (!name) return;

      const unit = item.format || item.birim || item.unit || "gram";
      const amount = getNumber(item.miktar ?? item.amount);
      const gram = (FoodUnits.units[unit] || 1) * amount;

      foods.push({
        name,
        amount: gram
      });
    });

    getArray(data.takviyeler).forEach(item => {
      if (!item || typeof item !== "object") return;

      const name = String(item.ad || item.name || "").trim().toLowerCase();
      if (!name) return;

      const amount = getNumber(item.miktar ?? item.amount);
      const info = SupplementUnits[name];

      supplements.push({
        name,
        amount: info ? amount * info.value : amount,
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
    document.getElementById("patientName").innerText = t("clientNotFound");
    document.getElementById("patientInfo").innerText = "";
    return;
  }

  await loadUser();
  await loadWeightChart();
  await loadCalorieChart();
  await loadAnalysis();
}

function waitForFirebase() {
  if (window.db) {
    db = window.db;
    init();
  } else {
    setTimeout(waitForFirebase, 100);
  }
}

waitForFirebase();
