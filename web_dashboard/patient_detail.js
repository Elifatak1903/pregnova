import { db } from "./app.js";
import { t } from "./i18n.js";

import {
  collection,
  query,
  where,
  orderBy,
  onSnapshot
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const params = new URLSearchParams(window.location.search);
const uid = params.get("uid");
const name = params.get("name");

const nameEl = document.getElementById("patientName");
const list = document.getElementById("measurementsList");

/* NAME */
if (nameEl) {
  nameEl.innerText = name || t("patient");
}

/* UID YOKSA */
if (!uid) {
  console.error("UID missing");

  if (nameEl) {
    nameEl.innerText = t("patientNotFound");
  }
}

/* DATA */
let sugarChart;
let bpChart;

let dates = [];
let sugars = [];
let systolic = [];
let diastolic = [];

/* QUERY */
if (uid) {

  const q = query(
    collection(db, "risk_olcumleri"),
    where("uid", "==", uid),
    orderBy("tarih", "desc")
  );

  onSnapshot(q, (snapshot) => {

    if (!list) return;

    list.innerHTML = "";

    dates = [];
    sugars = [];
    systolic = [];
    diastolic = [];

    snapshot.forEach(doc => {

      const data = doc.data();
      const stres = data.stresSeviyesi || "-";
      const tokluk = data.toklukSeker || "-";

      const basAgrisi = data.basAgrisi;
      const gorme = data.gormeBozuklugu;
      const sislik = data.sislik;
      const karin = data.karinKasilma;
      const bel = data.belAgrisi;
      const akinti = data.akinti;

      if (!data?.tarih) return;

      const date = data.tarih.toDate();

      dates.push(date.toLocaleDateString());

      sugars.push(data.aclikSeker || 0);
      systolic.push(data.sistolik || 0);
      diastolic.push(data.diastolik || 0);

      const div = document.createElement("div");
      div.className = "measurement-card";

      div.innerHTML = `
        <b>${date.toLocaleString()}</b>

        <div class="measurement-grid">
          <div class="measurement-item">
            ${t("bloodPressure")}: ${data.sistolik || "-"} / ${data.diastolik || "-"}
          </div>

          <div class="measurement-item">
            ${t("fastingSugar")}: ${data.aclikSeker || "-"}
          </div>

          <div class="measurement-item">
            ${t("postprandialSugar")}: ${tokluk}
          </div>

          <div class="measurement-item">
            ${t("stress")}: ${stres}
          </div>
        </div>

        <div class="symptoms">
          ${t("headache")}: ${boolText(basAgrisi)} <br>
          ${t("vision")}: ${boolText(gorme)} <br>
          ${t("swelling")}: ${boolText(sislik)} <br>
          ${t("abdominalContraction")}: ${boolText(karin)} <br>
          ${t("backPain")}: ${boolText(bel)} <br>
          ${t("discharge")}: ${boolText(akinti)}
        </div>

        <div class="risk">
          ${t("preeclampsia")}: ${colorRisk(data.preeklampsiRisk)} <br>
          ${t("diabetes")}: ${colorRisk(data.diyabetRisk)} <br>
          ${t("preterm")}: ${colorRisk(data.pretermRisk)}
        </div>
      `;

      list.appendChild(div);
    });

    drawChart();
  });
}

/* RISK */
function colorRisk(risk) {

  if (!risk) return "-";

  if (risk === "HIGH") return `<span style="color:#EF5350">${t("high")}</span>`;
  if (risk === "MEDIUM") return `<span style="color:#FFA000">${t("medium")}</span>`;

  return `<span style="color:#00BFA5">${t("low")}</span>`;
}

function boolText(val) {
  if (val === true) return `<span style="color:#EF5350">${t("exists")}</span>`;
  if (val === false) return `<span style="color:#00BFA5">${t("none")}</span>`;
  return "-";
}

/* CHART */
function drawChart() {

  const sugarCtx = document.getElementById("sugarChart");
  const bpCtx = document.getElementById("bpChart");

  if (!sugarCtx || !bpCtx) {
    console.warn("Canvas not found");
    return;
  }

  /* ŞEKER */
  if (sugarChart) sugarChart.destroy();

  sugarChart = new Chart(sugarCtx, {
    type: "line",
    data: {
      labels: dates,
      datasets: [{
        label: t("bloodSugar"),
        data: sugars,
        tension: 0.3
      }]
    }
  });

  /* TANSİYON */
  if (bpChart) bpChart.destroy();

  bpChart = new Chart(bpCtx, {
    type: "line",
    data: {
      labels: dates,
      datasets: [
        {
          label: t("systolic"),
          data: systolic,
          tension: 0.3
        },
        {
          label: t("diastolic"),
          data: diastolic,
          tension: 0.3
        }
      ]
    }
  });
}
