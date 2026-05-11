import {
  collection,
  query,
  where,
  orderBy,
  getDocs
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";
import { t } from "./i18n.js";

const db = window.db;
const auth = window.auth;

async function loadHistory(user) {

  const q = query(
    collection(db, "risk_olcumleri"),
    where("uid", "==", user.uid),
    orderBy("tarih", "desc")
  );

  const snap = await getDocs(q);

  const container = document.getElementById("historyList");
  if (!container) return;

  container.innerHTML = "";

  if (snap.empty) {
    container.innerHTML = `<p>${t("noMeasurements")}</p>`;
    return;
  }

  snap.forEach(docSnap => {

    const d = docSnap.data();

    let date = t("unknown");

    if (d.tarih?.seconds) {
      date = new Date(d.tarih.seconds * 1000)
        .toLocaleString("tr-TR");
    }

    container.innerHTML += `
      <div class="history-card">

        <div class="date">${date}</div>

        <div class="risk-row">
          <span>${t("preeclampsia")}</span>
          <span class="badge ${d.preeklampsiRisk}">
            ${riskText(d.preeklampsiRisk)}
          </span>
        </div>

        <div class="risk-row">
          <span>${t("diabetes")}</span>
          <span class="badge ${d.diyabetRisk}">
            ${riskText(d.diyabetRisk)}
          </span>
        </div>

        <div class="risk-row">
          <span>${t("preterm")}</span>
          <span class="badge ${d.pretermRisk}">
            ${riskText(d.pretermRisk)}
          </span>
        </div>

      </div>
    `;
  });
}

function riskText(value) {
  if (value === "HIGH") return t("high");
  if (value === "MEDIUM") return t("medium");
  if (value === "LOW") return t("low");
  return value || "-";
}

onAuthStateChanged(auth, (user) => {
  if (user) {
    loadHistory(user);
  }
});
