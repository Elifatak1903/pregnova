import { auth, db } from "./app.js";
import { t, getLanguage } from "./i18n.js";

import {
  collection,
  doc,
  getDoc,
  onSnapshot,
  query,
  where
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

const list = document.getElementById("dietHistoryList");
const searchInput = document.getElementById("searchInput");

let allPlans = [];

onAuthStateChanged(auth, (user) => {
  if (!user) {
    window.location.href = "login.html";
    return;
  }

  loadDietHistory(user.uid);
});

searchInput?.addEventListener("input", renderDietHistory);

function loadDietHistory(dietitianId) {
  const q = query(
    collection(db, "diet_plans"),
    where("dietitianId", "==", dietitianId)
  );

  onSnapshot(q, async (snapshot) => {
    allPlans = await Promise.all(snapshot.docs.map(async (docSnap) => {
      const data = docSnap.data();
      const client = await loadClient(data.clientId);

      return {
        id: docSnap.id,
        ...data,
        clientName: client.name,
        clientSurname: client.surname
      };
    }));

    allPlans.sort((a, b) => readTime(b.createdAt) - readTime(a.createdAt));

    renderDietHistory();
  }, (error) => {
    console.error("Diet history could not be loaded:", error);
    list.innerHTML = t("dietPlanLoadError");
  });
}

function readTime(timestamp) {
  if (!timestamp) return 0;
  if (timestamp.toDate) return timestamp.toDate().getTime();
  if (timestamp.seconds) return timestamp.seconds * 1000;

  const date = new Date(timestamp);
  return Number.isNaN(date.getTime()) ? 0 : date.getTime();
}

async function loadClient(clientId) {
  if (!clientId) return { name: t("patient"), surname: "" };

  const snapshot = await getDoc(doc(db, "users", clientId));
  const data = snapshot.data() || {};

  return {
    name: data.name || t("patient"),
    surname: data.surname || ""
  };
}

function renderDietHistory() {
  if (!list) return;

  const search = searchInput?.value?.trim().toLowerCase() || "";
  const filtered = allPlans.filter(plan => {
    if (!search) return true;
    const fullName = `${plan.clientName || ""} ${plan.clientSurname || ""}`.toLowerCase();
    return fullName.includes(search);
  });

  if (filtered.length === 0) {
    list.innerHTML = `<div class="empty-state">${t("noDietHistory")}</div>`;
    return;
  }

  list.innerHTML = filtered.map(renderPlanCard).join("");
}

function renderPlanCard(plan) {
  const clientName = `${plan.clientName || ""} ${plan.clientSurname || ""}`.trim() || t("patient");
  const date = formatDate(plan.createdAt);
  const meals = [
    ["breakfast", plan.kahvalti],
    ["snack1", plan.ara1],
    ["lunch", plan.ogle],
    ["snack2", plan.ara2],
    ["dinner", plan.aksam],
    ["night", plan.gece]
  ].filter(([, value]) => hasText(value));

  return `
    <article class="diet-plan-card">
      <div class="diet-plan-header">
        <div>
          <h2>${clientName}</h2>
          <p>${date}</p>
        </div>
        <button type="button" onclick="window.location.href='create_diet.html?id=${encodeURIComponent(plan.clientId || "")}'">
          ${t("writeDiet")}
        </button>
      </div>

      <div class="meal-summary">
        ${meals.map(([key, value]) => `
          <div class="meal-row">
            <span>${t(key)}</span>
            <strong>${escapeHtml(value)}</strong>
          </div>
        `).join("") || `<div class="meal-row"><span>${t("notes")}</span><strong>-</strong></div>`}
      </div>

      ${hasText(plan.notlar) ? `
        <div class="diet-notes">
          <span>${t("notes")}</span>
          <p>${escapeHtml(plan.notlar)}</p>
        </div>
      ` : ""}
    </article>
  `;
}

function hasText(value) {
  return Boolean(value && value.toString().trim());
}

function formatDate(timestamp) {
  if (!timestamp) return "-";

  const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
  const locale = getLanguage() === "tr" ? "tr-TR" : "en-US";

  return date.toLocaleString(locale, {
    day: "2-digit",
    month: "long",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit"
  });
}

function escapeHtml(value) {
  return value
    .toString()
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}
