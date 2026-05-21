import {
  deleteField,
  doc,
  getDoc,
  collection,
  query,
  where,
  getDocs,
  serverTimestamp,
  updateDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import { FoodUnits } from "./foodUnits.js";
import { NutritionEngine } from "./nutritionEngine.js";
import { SupplementUnits } from "./supplementUnits.js";
import { displaySupplementName } from "./nutritionDisplay.js";
import { t } from "./i18n.js";

let db;

/* URL'den id al */
const urlParams = new URLSearchParams(window.location.search);
const clientId = urlParams.get("id");

/* CHART INSTANCES */
let weightChart;
let calorieChart;
let clientProfileWeight = 0;
const clientMenuButton = document.getElementById("clientMenuButton");
const clientMenu = document.getElementById("clientMenu");
const removeClientButton = document.getElementById("removeClientButton");

clientMenuButton?.addEventListener("click", (event) => {
  event.stopPropagation();
  clientMenu?.classList.toggle("hidden");
});

window.addEventListener("click", () => clientMenu?.classList.add("hidden"));
removeClientButton?.addEventListener("click", removeClientFromDietitian);

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

function last7DayRows() {
  const today = new Date();
  const start = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 6);

  return Array.from({ length: 7 }, (_, index) => {
    const date = new Date(start);
    date.setDate(start.getDate() + index);
    return {
      date,
      key: date.toLocaleDateString()
    };
  });
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
    clientProfileWeight = getNumber(data.kilo);

    patientName.innerText =
      `${data.name || ""} ${data.surname || ""}`.trim() || "-";

    patientInfo.innerHTML = renderClientInfo(data);

    console.log("UI güncellendi:", patientName.innerText, patientInfo.innerText);

  } catch (err) {
    console.error("USER ERROR:", err);

    patientName.innerText = "Bilgi yükleme hatası";
    patientInfo.innerText = err.message;
  }
}

function renderClientInfo(data) {
  const chronicDiseases = [
    data.chronicHypertension === true ? t("chronicHypertension") : null,
    data.diabetes === true ? t("diabetes") : null,
    data.thyroidDisease === true ? t("thyroidDisease") : null
  ].filter(Boolean);

  const followUpRisks = doctorRiskLabels(data.doctorRiskFlags);
  const allergies = formatTextValue(data.alerjiler || data.allergies);
  const riskLevel = formatRiskLevel(data.riskLevel);

  return `
    <div class="client-info-grid">
      ${infoItem(t("week"), formatTextValue(data.hafta || data.pregnancyWeek || data.gebelikHaftasi))}
      ${infoItem(t("currentWeight"), formatTextValue(data.kilo), "kg")}
      ${infoItem(t("height"), formatTextValue(data.boy), "cm")}
      ${infoItem(t("bmi"), formatTextValue(data.bmi))}
      ${infoItem(t("allergies"), allergies, "", allergies === t("none") ? "" : "danger")}
      ${infoItem(
        t("chronicDisease"),
        chronicDiseases.length ? chronicDiseases.join(", ") : t("none"),
        "",
        chronicDiseases.length ? "warning" : ""
      )}
      ${infoItem(
        t("riskStatus"),
        riskLevel.label,
        "",
        riskLevel.tone
      )}
      ${infoItem(
        t("followUpRisks"),
        followUpRisks.length ? followUpRisks.join(", ") : t("none"),
        "",
        followUpRisks.length ? "danger" : ""
      )}
    </div>
  `;
}

function formatRiskLevel(rawRiskLevel) {
  const normalized = String(rawRiskLevel || "").trim().toLowerCase();

  if (normalized === "high" || normalized === "high_risk" || normalized === "yüksek") {
    return { label: t("highRisk"), tone: "danger" };
  }

  if (normalized === "medium" || normalized === "orta") {
    return { label: t("mediumRisk"), tone: "warning" };
  }

  if (normalized === "low" || normalized === "normal" || normalized === "düşük") {
    return { label: t("lowRisk"), tone: "" };
  }

  return { label: t("normal"), tone: "" };
}

function infoItem(label, value, suffix = "", tone = "") {
  const displayValue = value === "-" || value === t("none")
    ? value
    : `${value}${suffix ? ` ${suffix}` : ""}`;

  return `
    <div class="client-info-item ${tone}">
      <span>${label}</span>
      <strong>${displayValue}</strong>
    </div>
  `;
}

function formatTextValue(value) {
  const text = value?.toString().trim();
  return text ? text : t("none");
}

function doctorRiskLabels(flags) {
  if (!flags || typeof flags !== "object") return [];

  return [
    flags.preeklampsi === true ? t("preeclampsiaFollowUp") : null,
    flags.diabetes === true ? t("diabetesFollowUp") : null,
    flags.preterm === true ? t("pretermFollowUp") : null
  ].filter(Boolean);
}

async function removeClientFromDietitian() {
  if (!clientId) return;

  const dietitianId = window.auth?.currentUser?.uid;
  if (!dietitianId) {
    window.location.href = "login.html";
    return;
  }

  const confirmed = confirm(t("removePatientConfirm"));
  if (!confirmed) return;

  const requestSnapshot = await getDocs(query(
    collection(db, "expert_requests"),
    where("expertId", "==", dietitianId),
    where("clientId", "==", clientId),
    where("status", "==", "approved")
  ));

  await Promise.all(requestSnapshot.docs.map(requestDoc => updateDoc(requestDoc.ref, {
    status: "removed",
    removedAt: serverTimestamp()
  })));

  await updateDoc(doc(db, "users", clientId), {
    assignedDietitian: deleteField()
  });

  window.location.href = "dietitian_clients.html";
}

/* KİLO GRAFİĞİ */
async function loadWeightChart() {
  try {

    const q = query(
      collection(db, "risk_olcumleri"),
      where("uid", "==", clientId)
    );

    const snap = await getDocs(q);

    const dayRows = last7DayRows();
    const start = dayRows[0].date;
    const end = new Date();
    end.setHours(23, 59, 59, 999);
    const weightByDay = new Map(dayRows.map(row => [row.key, null]));
    let latestMeasurementWeight = 0;
    let latestMeasurementDate = null;

    snap.docs
      .map(docSnap => {
        const data = docSnap.data();
        return {
          date: toDate(data.tarih),
          weight: getNumber(data.kilo)
        };
      })
      .filter(row => row.date)
      .filter(row => row.date >= start && row.date <= end)
      .sort((a, b) => a.date - b.date)
      .forEach(row => {
        if (row.weight > 0) {
          if (!latestMeasurementDate || row.date > latestMeasurementDate) {
            latestMeasurementDate = row.date;
            latestMeasurementWeight = row.weight;
          }
          weightByDay.set(row.date.toLocaleDateString(), row.weight);
        }
      });

    const labels = dayRows.map(row => row.key);
    const values = dayRows.map(row => {
      const dayWeight = weightByDay.get(row.key);
      if (dayWeight && dayWeight > 0) {
        return dayWeight;
      }
      return clientProfileWeight > 0 ? clientProfileWeight : latestMeasurementWeight;
    });

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

    const dayRows = last7DayRows();
    const start = dayRows[0].date;
    const end = new Date();
    end.setHours(23, 59, 59, 999);
    const dailyCalories = new Map(dayRows.map(row => [row.key, 0]));

    snap.docs
      .map(docSnap => {
        const data = docSnap.data();
        return {
          date: toDate(data.createdAt || data.tarih),
          calorie: getNumber(data.kalori)
        };
      })
      .filter(row => row.date)
      .filter(row => row.date >= start && row.date <= end)
      .sort((a, b) => a.date - b.date)
      .forEach(row => {
        const key = row.date.toLocaleDateString();

        dailyCalories.set(
          key,
          (dailyCalories.get(key) || 0) + row.calorie
        );
      });

    const labels = dayRows.map(row => row.key);
    const values = dayRows.map(row => dailyCalories.get(row.key) || 0);

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
    .map(item => displaySupplementName(item.ad || item.name))
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
