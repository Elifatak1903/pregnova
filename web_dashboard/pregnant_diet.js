import {
  collection,
  query,
  where,
  orderBy,
  limit,
  onSnapshot
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

const db = window.db;
const auth = window.auth;

const state = document.getElementById("dietState");
const plan = document.getElementById("dietPlan");
const summary = document.getElementById("dietSummary");
const summaryDate = document.getElementById("summaryDate");
const modal = document.getElementById("dietModal");
const modalTitle = document.getElementById("modalTitle");

let currentDiet = null;
let currentDietDate = "-";

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
    orderBy("createdAt", "desc"),
    limit(1)
  );

  onSnapshot(q, (snapshot) => {
    if (snapshot.empty) {
      state.textContent = "Henüz diyet planın yok.";
      state.classList.remove("hidden");
      summary.classList.add("hidden");
      return;
    }

    currentDiet = snapshot.docs[0].data();
    currentDietDate = formatDate(currentDiet.createdAt);

    state.classList.add("hidden");
    summary.classList.remove("hidden");
    summaryDate.textContent = currentDietDate;
  }, (error) => {
    console.error("Diyet planı yüklenemedi:", error);
    state.textContent = "Diyet planı yüklenirken bir hata oluştu.";
    state.classList.remove("hidden");
    summary.classList.add("hidden");
  });
}

window.openDietModal = function () {
  if (!currentDiet) return;

  modalTitle.textContent = `Diyet Detayı - ${currentDietDate}`;

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

function formatDate(timestamp) {
  if (!timestamp) return "-";

  const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);

  return date.toLocaleDateString("tr-TR", {
    day: "2-digit",
    month: "long",
    year: "numeric"
  });
}
