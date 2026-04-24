import { initializeApp } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-app.js";

import {
  getFirestore,
  collection,
  query,
  where,
  orderBy,
  onSnapshot
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

/* FIREBASE */
const app = initializeApp({
  apiKey: "AIzaSyBHVmFtmXLe6BcN620XCmjv9vMOkcjeFdM",
  authDomain: "pregnova-38391.firebaseapp.com",
  projectId: "pregnova-38391"
});

const db = getFirestore(app);

const params = new URLSearchParams(window.location.search);
const uid = params.get("uid");
const name = params.get("name");

console.log("FULL URL:", window.location.href);
console.log("UID:", uid);
console.log("NAME:", name);

const nameEl = document.getElementById("patientName");
const list = document.getElementById("measurementsList");

/* NAME */
if (nameEl) {
  nameEl.innerText = name || "Hasta";
}

/* UID YOKSA */
if (!uid) {
  console.error("UID gelmedi ❌");

  if (nameEl) {
    nameEl.innerText = "Hasta bulunamadı";
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
            Tansiyon: ${data.sistolik || "-"} / ${data.diastolik || "-"}
          </div>

          <div class="measurement-item">
            Açlık: ${data.aclikSeker || "-"}
          </div>

          <div class="measurement-item">
            Tokluk: ${tokluk}
          </div>

          <div class="measurement-item">
            Stres: ${stres}
          </div>
        </div>

        <div class="symptoms">
          Baş ağrısı: ${boolText(basAgrisi)} <br>
          Görme: ${boolText(gorme)} <br>
          Şişlik: ${boolText(sislik)} <br>
          Karın kasılması: ${boolText(karin)} <br>
          Bel ağrısı: ${boolText(bel)} <br>
          Akıntı: ${boolText(akinti)}
        </div>

        <div class="risk">
          Preeklampsi: ${colorRisk(data.preeklampsiRisk)} <br>
          Diyabet: ${colorRisk(data.diyabetRisk)} <br>
          Preterm: ${colorRisk(data.pretermRisk)}
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

  if (risk === "HIGH") return `<span style="color:#EF5350">Yüksek</span>`;
  if (risk === "MEDIUM") return `<span style="color:#FFA000">Orta</span>`;

  return `<span style="color:#00BFA5">Düşük</span>`;
}

function boolText(val) {
  if (val === true) return `<span style="color:#EF5350">Var</span>`;
  if (val === false) return `<span style="color:#00BFA5">Yok</span>`;
  return "-";
}

/* CHART */
function drawChart() {

  const sugarCtx = document.getElementById("sugarChart");
  const bpCtx = document.getElementById("bpChart");

  if (!sugarCtx || !bpCtx) {
    console.warn("Canvas bulunamadı ⚠️");
    return;
  }

  /* ŞEKER */
  if (sugarChart) sugarChart.destroy();

  sugarChart = new Chart(sugarCtx, {
    type: "line",
    data: {
      labels: dates,
      datasets: [{
        label: "Kan Şekeri",
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
          label: "Sistolik",
          data: systolic,
          tension: 0.3
        },
        {
          label: "Diastolik",
          data: diastolic,
          tension: 0.3
        }
      ]
    }
  });

  console.log("Grafikler çizildi 🔥");
}