import {
  collection,
  query,
  where,
  getDocs,
  doc,
  getDoc,
  orderBy,
  Timestamp
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";
import { t, getLanguage } from "./i18n.js";
import { FoodUnits } from "./foodUnits.js";
import { NutritionEngine } from "./nutritionEngine.js";
import { displaySupplementName } from "./nutritionDisplay.js";

const db = window.db;
const auth = window.auth;
const params = new URLSearchParams(window.location.search);
const selectedUid = params.get("uid");
const selectedDateMs = Number(params.get("date") || "");

let allDocs = [];
let selectedDateKey = "";

auth.onAuthStateChanged(async (user) => {
  if (!user) return location.href = "login.html";

  await loadAnalyses(user.uid);
});

async function loadAnalyses(uid) {
  const container = document.getElementById("analysisList");

  try {
    const clientIds = await loadClientIds(uid);

    if (clientIds.size === 0) {
      container.innerHTML = `<div class="empty-state">${t("noClientsYet")}</div>`;
      return;
    }

    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const q = query(
      collection(db, "besin_analizleri"),
      where("createdAt", ">", Timestamp.fromDate(sevenDaysAgo)),
      orderBy("createdAt", "desc")
    );

    const snap = await getDocs(q);

    allDocs = snap.docs
      .map(docSnap => ({ id: docSnap.id, data: docSnap.data() }))
      .filter(item => clientIds.has(item.data.uid) && readDate(item.data));

    if (allDocs.length === 0) {
      container.innerHTML = `<div class="empty-state">${t("noAnalysesLast7Days")}</div>`;
      return;
    }

    selectedDateKey = initialDateKey(allDocs);
    renderDateFilter(allDocs);
    await renderAnalyses();
  } catch (err) {
    console.error(err);
    container.innerHTML = `<div class="empty-state">${t("genericError")}</div>`;
  }
}

async function loadClientIds(uid) {
  const usersSnap = await getDocs(
    query(collection(db, "users"), where("assignedDietitian", "==", uid))
  );

  const ids = new Set(usersSnap.docs.map(docSnap => docSnap.id));

  const requestSnap = await getDocs(
    query(
      collection(db, "expert_requests"),
      where("expertId", "==", uid),
      where("status", "==", "approved")
    )
  );

  requestSnap.docs.forEach(docSnap => {
    const clientId = docSnap.data().clientId;
    if (clientId) ids.add(clientId);
  });

  return ids;
}

function renderDateFilter(items) {
  const container = document.getElementById("analysisList");
  const dates = [...new Set(items.map(item => dayKey(readDate(item.data))))];

  const filter = document.createElement("select");
  filter.className = "date-filter";
  filter.value = selectedDateKey;
  filter.innerHTML = dates
    .map(key => `<option value="${key}">${formatDay(key)}</option>`)
    .join("");

  filter.addEventListener("change", async () => {
    selectedDateKey = filter.value;
    await renderAnalyses();
  });

  container.innerHTML = "";
  container.appendChild(filter);

  const list = document.createElement("div");
  list.id = "analysisCards";
  container.appendChild(list);
}

async function renderAnalyses() {
  const list = document.getElementById("analysisCards");
  const items = allDocs.filter(item => dayKey(readDate(item.data)) === selectedDateKey);

  list.innerHTML = "";

  for (const [index, item] of items.entries()) {
    const data = item.data;
    const patientId = data.uid;
    const user = await loadUser(patientId);
    const date = readDate(data);
    const summary = summaryFromAnalysis(data);

    const card = document.createElement("div");
    card.className = [
      "analysis-full-card",
      selectedUid === patientId ? "selected" : ""
    ].join(" ");

    card.innerHTML = `
      <div class="analysis-top">
        <div>
          <strong>${fullName(user) || patientId}</strong>
          <span>${t("analysisNumber", { number: index + 1, time: formatTime(date) })}</span>
        </div>
        <button type="button" class="detail-btn">${t("detailedReview")} →</button>
      </div>

      ${section(t("foods"), listItems(data.besinler))}
      ${section(t("supplements"), listItems(data.takviyeler, true))}

      <div class="daily-summary">
        <h3>${t("dailyTotalAnalysisResult")}</h3>
        <p>${t("dailyTotalCalories")}: <b>${Math.round(summary.calorie)}</b></p>
        ${nutrientBlock(t("consumedNutrients"), summary.consumed, "ok")}
        ${nutrientBlock(t("missingNutrients"), summary.missing, "warn")}
        ${nutrientBlock(t("excessNutrients"), summary.excess, "danger")}
      </div>
    `;

    card.querySelector(".detail-btn").addEventListener("click", () => {
      window.location.href = `client_detail.html?id=${encodeURIComponent(patientId)}`;
    });

    list.appendChild(card);
  }

  focusSelected();
}

async function loadUser(uid) {
  if (!uid) return {};
  const userSnap = await getDoc(doc(db, "users", uid));
  return userSnap.exists() ? userSnap.data() : {};
}

function fullName(user) {
  return `${user?.name || ""} ${user?.surname || ""}`.trim();
}

function section(title, rows) {
  if (!rows) return "";

  return `
    <div class="analysis-section">
      <h4>${title}</h4>
      ${rows}
    </div>
  `;
}

function listItems(items, isSupplement = false) {
  const values = Array.isArray(items) ? items : [];
  if (values.length === 0) return "";

  return values.map(raw => {
    const item = raw && typeof raw === "object" ? raw : {};
    const name = item.ad || item.name || "-";
    return `
      <div class="food-line">
        <span>${isSupplement ? displaySupplementName(name) : name}</span>
        <b>${item.miktar ?? item.amount ?? ""} ${item.format || item.birim || item.unit || ""}</b>
      </div>
    `;
  }).join("");
}

function nutrientBlock(title, values, tone) {
  if (!Array.isArray(values) || values.length === 0) return "";

  return `
    <div class="nutrient-block ${tone}">
      <h4>${title}</h4>
      ${values.map(value => `<span>${value}</span>`).join("")}
    </div>
  `;
}

function summaryFromAnalysis(data) {
  const consumed = arrayOfText(data.consumedNutrients);
  const missing = arrayOfText(data.missingNutrients);
  const excess = arrayOfText(data.excessNutrients);

  if (consumed.length || missing.length || excess.length) {
    return {
      calorie: numberValue(data.kalori),
      consumed,
      missing,
      excess
    };
  }

  const foods = [];
  const supplements = [];

  (Array.isArray(data.besinler) ? data.besinler : []).forEach(raw => {
    if (!raw || typeof raw !== "object") return;
    const unitGram = FoodUnits.units[raw.format] || 1;
    const amount = Number(raw.miktar) || 0;
    foods.push({ name: raw.ad, amount: unitGram * amount });
  });

  (Array.isArray(data.takviyeler) ? data.takviyeler : []).forEach(raw => {
    if (!raw || typeof raw !== "object") return;
    supplements.push({ name: raw.ad, amount: Number(raw.miktar) || 1 });
  });

  const result = NutritionEngine.analyzeFoods(foods, supplements);

  return {
    calorie: Number(result.totalCalories) || 0,
    consumed: arrayOfText(result.consumedNutrients),
    missing: arrayOfText(result.missingNutrients),
    excess: arrayOfText(result.excessNutrients)
  };
}

function arrayOfText(value) {
  return Array.isArray(value) ? value.map(item => String(item)) : [];
}

function numberValue(value) {
  return Number(value) || 0;
}

function initialDateKey(items) {
  if (selectedDateMs) {
    return dayKey(new Date(selectedDateMs));
  }

  return dayKey(readDate(items[0].data));
}

function readDate(data) {
  const raw = data.createdAt || data.tarih;
  if (!raw) return null;
  if (raw.toDate) return raw.toDate();
  const date = new Date(raw);
  return Number.isNaN(date.getTime()) ? null : date;
}

function dayKey(date) {
  return [
    date.getFullYear(),
    String(date.getMonth() + 1).padStart(2, "0"),
    String(date.getDate()).padStart(2, "0")
  ].join("-");
}

function formatDay(key) {
  const [year, month, day] = key.split("-").map(Number);
  return new Date(year, month - 1, day).toLocaleDateString(
    getLanguage() === "tr" ? "tr-TR" : "en-US"
  );
}

function formatTime(date) {
  if (!date) return "-";
  return date.toLocaleTimeString(
    getLanguage() === "tr" ? "tr-TR" : "en-US",
    { hour: "2-digit", minute: "2-digit" }
  );
}

function focusSelected() {
  if (!selectedUid) return;
  const selected = document.querySelector(".analysis-full-card.selected");
  selected?.scrollIntoView({ behavior: "smooth", block: "center" });
}
