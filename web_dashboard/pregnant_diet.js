import {
  collection,
  query,
  where,
  orderBy,
  onSnapshot
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";
import { t, getLanguage } from "./i18n.js";

const db = window.db;
const auth = window.auth;

const state = document.getElementById("dietState");
const plan = document.getElementById("dietPlan");
const summary = document.getElementById("dietSummary");
const summaryDate = document.getElementById("summaryDate");
const modal = document.getElementById("dietModal");
const modalTitle = document.getElementById("modalTitle");
const previousDietSection = document.getElementById("previousDietSection");
const previousDietList = document.getElementById("previousDietList");

let currentDiet = null;
let currentDietDate = "-";
let allDiets = [];

onAuthStateChanged(auth, (user) => {
  if (!user) {
    window.location.href = "login.html";
    return;
  }

  loadDietPlan(user.uid);
});

function loadDietPlan(uid) {
  const q = query(
    collection(db, "diet_plans"),
    where("clientId", "==", uid),
    orderBy("createdAt", "desc")
  );

  onSnapshot(q, (snapshot) => {
    if (snapshot.empty) {
      state.textContent = t("noDietPlan");
      state.classList.remove("hidden");
      summary.classList.add("hidden");
      return;
    }

    allDiets = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    currentDiet = allDiets[0];
    currentDietDate = formatDate(currentDiet.createdAt);

    state.classList.add("hidden");
    summary.classList.remove("hidden");
    summaryDate.textContent = currentDietDate;
    renderPreviousDiets();
  }, (error) => {
    console.error("Diet plan could not be loaded:", error);
    state.textContent = t("dietPlanLoadError");
    state.classList.remove("hidden");
    summary.classList.add("hidden");
  });
}

window.openDietModal = function () {
  if (!currentDiet) return;

  modalTitle.textContent = t("dietDetailTitle", { date: currentDietDate });

  document.querySelectorAll(".meal-card").forEach((card) => {
    const field = card.dataset.field;
    const text = (currentDiet[field] || "").toString().trim();

    if (!text) {
      card.classList.add("hidden");
      return;
    }

    card.classList.remove("hidden");
    card.querySelector("p").textContent = text;
  });

  modal.classList.remove("hidden");
};

window.closeDietModal = function () {
  modal.classList.add("hidden");
};

summary.addEventListener("click", () => {
  window.openDietModal();
});

function renderPreviousDiets() {
  const previous = allDiets.slice(1);

  if (!previousDietSection || !previousDietList) return;

  if (previous.length === 0) {
    previousDietSection.classList.add("hidden");
    previousDietList.innerHTML = "";
    return;
  }

  previousDietSection.classList.remove("hidden");
  previousDietList.innerHTML = previous.map((diet, index) => `
    <button class="diet-summary previous-diet-card" type="button" data-index="${index + 1}">
      <div class="summary-left">
        <div class="summary-icon">D</div>
        <div>
          <span>${formatDate(diet.createdAt)}</span>
          <p data-i18n="previousDietPlan">${t("previousDietPlan")}</p>
        </div>
      </div>
      <b>${t("viewDiet")}</b>
    </button>
  `).join("");

  previousDietList.querySelectorAll("[data-index]").forEach(button => {
    button.addEventListener("click", () => {
      const index = Number(button.dataset.index);
      openDietByIndex(index);
    });
  });
}

function openDietByIndex(index) {
  const diet = allDiets[index];
  if (!diet) return;

  currentDiet = diet;
  currentDietDate = formatDate(diet.createdAt);
  window.openDietModal();

  currentDiet = allDiets[0];
  currentDietDate = formatDate(currentDiet.createdAt);
}

function formatDate(timestamp) {
  if (!timestamp) return "-";

  const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);

  const locale = getLanguage() === "tr" ? "tr-TR" : "en-US";

  return date.toLocaleDateString(locale, {
    day: "2-digit",
    month: "long",
    year: "numeric"
  });
}
