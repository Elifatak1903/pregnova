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

let allMeasurements = [];
let groupedMeasurements = [];
let selectedDay = "all";

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

  allMeasurements = [];

  snap.forEach(docSnap => {
    allMeasurements.push(docSnap.data());
  });

  window.measurementDetails = allMeasurements;

  groupedMeasurements = groupByDay(allMeasurements);

  renderDayFilter();
  renderFilteredHistory();
}

function renderDayFilter() {
  const select = document.getElementById("dayFilter");
  if (!select) return;

  select.innerHTML = `
    <option value="all">Tüm Günler</option>
  `;

  groupedMeasurements.forEach((group, index) => {
    select.innerHTML += `
      <option value="${index}">
        ${group.dayLabel}
      </option>
    `;
  });

  select.value = selectedDay;
}

window.filterByDay = function(value) {
  selectedDay = value;
  renderFilteredHistory();
};

function renderFilteredHistory() {
  const container = document.getElementById("historyList");
  if (!container) return;

  container.innerHTML = "";

  const groupsToRender =
    selectedDay === "all"
      ? groupedMeasurements
      : [groupedMeasurements[Number(selectedDay)]].filter(Boolean);

  groupsToRender.forEach(group => {
    container.innerHTML += `
      <div class="day-card">
        <h3 class="day-title">${group.dayLabel}</h3>

        ${group.items
          .map(item => renderMeasurementCard(item.data, item.index, item.timeLabel))
          .join("")}
      </div>
    `;
  });
}

function groupByDay(measurements) {
  const groups = {};

  measurements.forEach((data, index) => {
    const date = getDateFromMeasurement(data);

    const dayLabel = date
      ? date.toLocaleDateString("tr-TR", {
          day: "2-digit",
          month: "long",
          year: "numeric"
        })
      : t("unknown");

    const timeLabel = date
      ? date.toLocaleTimeString("tr-TR", {
          hour: "2-digit",
          minute: "2-digit"
        })
      : "-";

    if (!groups[dayLabel]) {
      groups[dayLabel] = [];
    }

    groups[dayLabel].push({
      data,
      index,
      timeLabel
    });
  });

  return Object.entries(groups).map(([dayLabel, items]) => ({
    dayLabel,
    items
  }));
}

function renderMeasurementCard(d, index, timeLabel) {
  return `
    <div class="history-card">

      <div class="history-top">
        <div class="date">Ölçüm - ${timeLabel}</div>
        <button class="detail-btn" onclick="showMeasurementDetail(${index})">
          Detay
        </button>
      </div>

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

      <div id="detail-${index}" class="inline-detail hidden"></div>

    </div>
  `;
}

function getDateFromMeasurement(data) {
  const raw = data.tarih || data.createdAt;

  if (raw?.seconds) return new Date(raw.seconds * 1000);
  if (raw?.toDate) return raw.toDate();
  if (raw) return new Date(raw);

  return null;
}

function riskText(value) {
  if (value === "HIGH") return t("high");
  if (value === "MEDIUM") return t("medium");
  if (value === "LOW") return t("low");
  return value || "-";
}

function yesNo(value) {
  return value === true ? "Evet" : "Hayır";
}

window.showMeasurementDetail = function(index) {
  const d = window.measurementDetails?.[index];
  if (!d) return;

  const box = document.getElementById(`detail-${index}`);
  if (!box) return;

  const isOpen = !box.classList.contains("hidden");

  document.querySelectorAll(".inline-detail").forEach(item => {
    item.classList.add("hidden");
    item.innerHTML = "";
  });

  if (isOpen) return;

  box.innerHTML = `
    <div class="detail-grid">

      <div class="detail-item">
        <span>Kilo</span>
        <strong>${d.kilo ?? "-"}</strong>
      </div>

      <div class="detail-item">
        <span>Tansiyon</span>
        <strong>${d.sistolik ?? "-"} / ${d.diastolik ?? "-"}</strong>
      </div>

      <div class="detail-item">
        <span>Açlık Şekeri</span>
        <strong>${d.aclikSeker ?? "-"}</strong>
      </div>

      <div class="detail-item">
        <span>Tokluk Şekeri</span>
        <strong>${d.toklukSeker ?? "-"}</strong>
      </div>

      <div class="detail-item">
        <span>Baş Ağrısı</span>
        <strong>${yesNo(d.basAgrisi)}</strong>
      </div>

      <div class="detail-item">
        <span>Görme Bozukluğu</span>
        <strong>${yesNo(d.gormeBozuklugu ?? d.gorme)}</strong>
      </div>

      <div class="detail-item">
        <span>Şişlik</span>
        <strong>${yesNo(d.sislik)}</strong>
      </div>

      <div class="detail-item">
        <span>Aşırı Susama</span>
        <strong>${yesNo(d.asiriSusama ?? d.susama)}</strong>
      </div>

      <div class="detail-item">
        <span>Sık İdrar</span>
        <strong>${yesNo(d.sikIdrar ?? d.idrar)}</strong>
      </div>

      <div class="detail-item">
        <span>Karın Kasılması</span>
        <strong>${yesNo(d.karinKasilma ?? d.kasilma)}</strong>
      </div>

      <div class="detail-item">
        <span>Akıntı</span>
        <strong>${yesNo(d.akinti)}</strong>
      </div>

      <div class="detail-item">
        <span>Bel Ağrısı</span>
        <strong>${yesNo(d.belAgrisi ?? d.bel)}</strong>
      </div>

      <div class="detail-item">
        <span>Stres Seviyesi</span>
        <strong>${d.stresSeviyesi ?? d.stres ?? "-"}</strong>
      </div>

    </div>
  `;

  box.classList.remove("hidden");
};

onAuthStateChanged(auth, (user) => {
  if (user) {
    loadHistory(user);
  }
});