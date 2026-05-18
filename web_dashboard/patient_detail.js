import { auth, db } from "./app.js";
import { t } from "./i18n.js";

import {
  collection,
  deleteField,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  onSnapshot,
  serverTimestamp,
  updateDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const params = new URLSearchParams(window.location.search);
const uid = params.get("uid");
const name = params.get("name");

const nameEl = document.getElementById("patientName");
const list = document.getElementById("measurementsList");
const patientMenuButton = document.getElementById("patientMenuButton");
const patientMenu = document.getElementById("patientMenu");
const assignRiskButton = document.getElementById("assignRiskButton");
const removePatientButton = document.getElementById("removePatientButton");
const riskModal = document.getElementById("riskModal");
const cancelRiskButton = document.getElementById("cancelRiskButton");
const saveRiskButton = document.getElementById("saveRiskButton");
const riskPreeclampsia = document.getElementById("riskPreeclampsia");
const riskDiabetes = document.getElementById("riskDiabetes");
const riskPreterm = document.getElementById("riskPreterm");
const doctorRiskTags = document.getElementById("doctorRiskTags");

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

patientMenuButton?.addEventListener("click", (event) => {
  event.stopPropagation();
  patientMenu?.classList.toggle("hidden");
});

window.addEventListener("click", () => patientMenu?.classList.add("hidden"));

assignRiskButton?.addEventListener("click", async () => {
  patientMenu?.classList.add("hidden");
  await loadDoctorRiskFlags();
  riskModal?.classList.remove("hidden");
});

cancelRiskButton?.addEventListener("click", () => {
  riskModal?.classList.add("hidden");
});

saveRiskButton?.addEventListener("click", saveDoctorRiskFlags);
removePatientButton?.addEventListener("click", removePatientFromDoctor);

if (uid) {
  loadDoctorRiskFlags();
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

async function loadDoctorRiskFlags() {
  if (!uid) return;

  const snapshot = await getDoc(doc(db, "users", uid));
  const flags = normalizeDoctorRiskFlags(snapshot.data()?.doctorRiskFlags);

  if (riskPreeclampsia) riskPreeclampsia.checked = flags.preeklampsi;
  if (riskDiabetes) riskDiabetes.checked = flags.diabetes;
  if (riskPreterm) riskPreterm.checked = flags.preterm;

  renderDoctorRiskTags(flags);
}

async function saveDoctorRiskFlags() {
  if (!uid) return;

  const flags = {
    preeklampsi: riskPreeclampsia?.checked === true,
    diabetes: riskDiabetes?.checked === true,
    preterm: riskPreterm?.checked === true
  };

  await updateDoc(doc(db, "users", uid), {
    doctorRiskFlags: flags,
    doctorRiskUpdatedAt: serverTimestamp()
  });

  renderDoctorRiskTags(flags);
  riskModal?.classList.add("hidden");
  alert(t("saved"));
}

async function removePatientFromDoctor() {
  if (!uid) return;

  const doctorId = auth.currentUser?.uid;
  if (!doctorId) {
    window.location.href = "login.html";
    return;
  }

  const confirmed = confirm(t("removePatientConfirm"));
  if (!confirmed) return;

  const requestSnapshot = await getDocs(query(
    collection(db, "expert_requests"),
    where("expertId", "==", doctorId),
    where("clientId", "==", uid),
    where("status", "==", "approved")
  ));

  await Promise.all(requestSnapshot.docs.map(requestDoc => updateDoc(requestDoc.ref, {
    status: "removed",
    removedAt: serverTimestamp()
  })));

  await updateDoc(doc(db, "users", uid), {
    assignedDoctor: deleteField(),
    doctorRiskFlags: deleteField(),
    doctorRiskUpdatedAt: deleteField()
  });

  window.location.href = "patients.html";
}

function normalizeDoctorRiskFlags(flags) {
  if (!flags || typeof flags !== "object") {
    return {
      preeklampsi: false,
      diabetes: false,
      preterm: false
    };
  }

  return {
    preeklampsi: flags.preeklampsi === true,
    diabetes: flags.diabetes === true,
    preterm: flags.preterm === true
  };
}

function renderDoctorRiskTags(flags) {
  if (!doctorRiskTags) return;

  const labels = [
    flags.preeklampsi ? t("preeclampsiaFollowUp") : null,
    flags.diabetes ? t("diabetesFollowUp") : null,
    flags.preterm ? t("pretermFollowUp") : null
  ].filter(Boolean);

  doctorRiskTags.innerHTML = labels
    .map(label => `<span>${label}</span>`)
    .join("");
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
