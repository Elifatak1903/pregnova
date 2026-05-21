import { auth, db } from "./app.js";
import { t } from "./i18n.js";

import {
  collection,
  deleteField,
  doc,
  addDoc,
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
const selectedMeasurementId = params.get("measurementId");

const nameEl = document.getElementById("patientName");
const list = document.getElementById("measurementsList");
const patientMenuButton = document.getElementById("patientMenuButton");
const patientMenu = document.getElementById("patientMenu");
const assignRiskButton = document.getElementById("assignRiskButton");
const feedbackButton = document.getElementById("feedbackButton");
const removePatientButton = document.getElementById("removePatientButton");
const riskModal = document.getElementById("riskModal");
const cancelRiskButton = document.getElementById("cancelRiskButton");
const saveRiskButton = document.getElementById("saveRiskButton");
const riskPreeclampsia = document.getElementById("riskPreeclampsia");
const riskDiabetes = document.getElementById("riskDiabetes");
const riskPreterm = document.getElementById("riskPreterm");
const doctorRiskTags = document.getElementById("doctorRiskTags");
const patientInfo = document.getElementById("patientInfo");
const measurementDateFilter = document.getElementById("measurementDateFilter");

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
feedbackButton?.addEventListener("click", openFeedbackChat);
removePatientButton?.addEventListener("click", removePatientFromDoctor);

if (uid) {
  loadDoctorRiskFlags();
}

/* DATA */
let sugarChart;
let bpChart;
let weightChart;

let dates = [];
let fastingSugars = [];
let postMealSugars = [];
let systolic = [];
let diastolic = [];
let weights = [];
let allMeasurements = [];
let selectedMeasurementDate = "all";
let appliedSelectedMeasurement = false;
let patientProfileWeight = 0;

/* QUERY */
if (uid) {
  loadPatientInfo();

  const q = query(
    collection(db, "risk_olcumleri"),
    where("uid", "==", uid),
    orderBy("tarih", "desc")
  );

  onSnapshot(q, (snapshot) => {

    if (!list) return;

    allMeasurements = snapshot.docs
      .map(docSnap => ({ id: docSnap.id, data: docSnap.data() }))
      .filter(item => toDate(item.data.tarih))
      .sort((a, b) => toDate(b.data.tarih) - toDate(a.data.tarih));

    applySelectedMeasurementDate();
    renderMeasurementDateFilter();
    renderMeasurements();
    prepareLast7DayCharts();
    drawChart();
  });
}

function applySelectedMeasurementDate() {
  if (!selectedMeasurementId || appliedSelectedMeasurement) return;

  const selected = allMeasurements.find(item => item.id === selectedMeasurementId);
  const date = toDate(selected?.data?.tarih);

  if (!date) return;

  selectedMeasurementDate = dayKey(date);
  appliedSelectedMeasurement = true;
}

async function loadPatientInfo() {
  if (!uid || !patientInfo) return;

  const snapshot = await getDoc(doc(db, "users", uid));
  if (!snapshot.exists()) {
    patientInfo.innerText = t("patientNotFound");
    return;
  }

  const data = snapshot.data();
  patientProfileWeight = Number(data.kilo) || 0;
  if (nameEl) {
    nameEl.innerText = `${data.name || ""} ${data.surname || ""}`.trim() || name || t("patient");
  }

  patientInfo.innerHTML = renderPatientInfo(data);
}

function renderPatientInfo(data) {
  const chronicDiseases = [
    data.chronicHypertension === true ? t("chronicHypertension") : null,
    data.diabetes === true ? t("diabetes") : null,
    data.thyroidDisease === true ? t("thyroidDisease") : null
  ].filter(Boolean);

  const riskLevel = formatRiskLevel(data.riskLevel);
  const followUpRisks = doctorRiskLabels(normalizeDoctorRiskFlags(data.doctorRiskFlags));
  const allergies = formatTextValue(data.alerjiler || data.allergies);

  return `
    <div class="client-info-grid">
      ${infoItem(t("week"), formatTextValue(data.hafta || data.pregnancyWeek || data.gebelikHaftasi))}
      ${infoItem(t("currentWeight"), formatTextValue(data.kilo), "kg")}
      ${infoItem(t("height"), formatTextValue(data.boy), "cm")}
      ${infoItem(t("bmi"), formatTextValue(data.bmi))}
      ${infoItem(t("allergies"), allergies, "", allergies === t("none") ? "" : "danger")}
      ${infoItem(t("chronicDisease"), chronicDiseases.length ? chronicDiseases.join(", ") : t("none"), "", chronicDiseases.length ? "warning" : "")}
      ${infoItem(t("riskStatus"), riskLevel.label, "", riskLevel.tone)}
      ${infoItem(t("followUpRisks"), followUpRisks.length ? followUpRisks.join(", ") : t("none"), "", followUpRisks.length ? "danger" : "")}
    </div>
  `;
}

function formatRiskLevel(rawRiskLevel) {
  const normalized = String(rawRiskLevel || "").trim().toLowerCase();

  if (["high", "high_risk", "yüksek", "yuksek"].includes(normalized)) {
    return { label: t("highRisk"), tone: "danger" };
  }

  if (["medium", "orta"].includes(normalized)) {
    return { label: t("mediumRisk"), tone: "warning" };
  }

  if (["low", "normal", "düşük", "dusuk"].includes(normalized)) {
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

function renderMeasurementDateFilter() {
  if (!measurementDateFilter) return;

  const currentValue = selectedMeasurementDate;
  const dayKeys = [...new Set(allMeasurements.map(item => dayKey(toDate(item.data.tarih))))];

  measurementDateFilter.innerHTML = `
    <option value="all">${t("all")}</option>
    ${dayKeys.map(key => `<option value="${key}">${key}</option>`).join("")}
  `;

  selectedMeasurementDate = dayKeys.includes(currentValue) ? currentValue : "all";
  measurementDateFilter.value = selectedMeasurementDate;
}

measurementDateFilter?.addEventListener("change", () => {
  selectedMeasurementDate = measurementDateFilter.value;
  renderMeasurements();
});

function renderMeasurements() {
  if (!list) return;

  const visibleMeasurements = selectedMeasurementDate === "all"
    ? allMeasurements
    : allMeasurements.filter(item => dayKey(toDate(item.data.tarih)) === selectedMeasurementDate);

  list.innerHTML = "";

  if (!visibleMeasurements.length) {
    list.innerHTML = t("noMeasurements");
    return;
  }

  visibleMeasurements.forEach(({ id, data }) => {
      const stres = data.stresSeviyesi ?? data.stres ?? "-";
      const tokluk = data.toklukSeker ?? "-";

      const basAgrisi = data.basAgrisi;
      const gorme = data.gormeBozuklugu ?? data.gorme;
      const sislik = data.sislik;
      const karin = data.karinKasilma ?? data.kasilma;
      const bel = data.belAgrisi ?? data.bel;
      const akinti = data.akinti;

      const date = toDate(data.tarih);
      if (!date) return;

      const div = document.createElement("div");
      div.className = "measurement-card";
      div.id = `measurement-${id}`;
      if (id === selectedMeasurementId) div.classList.add("selected-measurement");

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

  if (selectedMeasurementId) {
    setTimeout(() => {
      const selectedCard = document.getElementById(`measurement-${selectedMeasurementId}`);
      if (!selectedCard) return;

      selectedCard.scrollIntoView({ behavior: "smooth", block: "center" });
      selectedCard.animate([
        { transform: "scale(1)" },
        { transform: "scale(1.02)" },
        { transform: "scale(1)" }
      ], { duration: 450 });
    }, 250);
  }
}

function prepareLast7DayCharts() {
  const today = new Date();
  const start = startOfDay(new Date(today.getFullYear(), today.getMonth(), today.getDate() - 6));
  const end = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 23, 59, 59);
  const dayMap = new Map();

  for (let i = 0; i < 7; i++) {
    const date = new Date(start);
    date.setDate(start.getDate() + i);
    dayMap.set(dayKey(date), {
      date,
      fasting: 0,
      postMeal: 0,
      systolic: 0,
      diastolic: 0,
      weight: null
    });
  }

  allMeasurements
    .map(item => ({ data: item.data, date: toDate(item.data.tarih) }))
    .filter(item => item.date && item.date >= start && item.date <= end)
    .sort((a, b) => a.date - b.date)
    .forEach(({ data, date }) => {
      const row = dayMap.get(dayKey(date));
      if (!row) return;

      row.fasting = Number(data.aclikSeker) || row.fasting;
      row.postMeal = Number(data.toklukSeker) || row.postMeal;
      row.systolic = Number(data.sistolik) || row.systolic;
      row.diastolic = Number(data.diastolik) || row.diastolic;
      const measurementWeight = Number(data.kilo) || 0;
      if (measurementWeight > 0) {
        row.weight = measurementWeight;
      }
    });

  const rows = Array.from(dayMap.values());
  dates = rows.map(row => row.date.toLocaleDateString());
  fastingSugars = rows.map(row => row.fasting);
  postMealSugars = rows.map(row => row.postMeal);
  systolic = rows.map(row => row.systolic);
  diastolic = rows.map(row => row.diastolic);
  weights = rows.map(row => {
    if (row.weight && row.weight > 0) {
      return row.weight;
    }
    return patientProfileWeight;
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
  const normalized = normalizeBool(val);
  if (normalized === true) return `<span style="color:#EF5350">${t("exists")}</span>`;
  return `<span style="color:#00BFA5">${t("none")}</span>`;
}

function normalizeBool(value) {
  if (value === null || value === undefined) return false;
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value !== 0;

  const text = String(value).trim().toLowerCase();
  if (["true", "evet", "var", "yes", "1"].includes(text)) return true;
  return false;
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

async function openFeedbackChat() {
  if (!uid) return;

  const doctorId = auth.currentUser?.uid;
  if (!doctorId) {
    window.location.href = "login.html";
    return;
  }

  patientMenu?.classList.add("hidden");

  const chatId = await getOrCreateChat(doctorId, uid);
  window.location.href = `messages_gynecologist.html?chatId=${encodeURIComponent(chatId)}`;
}

async function getOrCreateChat(currentUserId, otherUserId) {
  const chatSnapshot = await getDocs(query(
    collection(db, "chats"),
    where("users", "array-contains", currentUserId)
  ));

  for (const chatDoc of chatSnapshot.docs) {
    const users = chatDoc.data().users || [];
    if (users.includes(otherUserId)) {
      return chatDoc.id;
    }
  }

  const newChat = await addDoc(collection(db, "chats"), {
    users: [currentUserId, otherUserId],
    lastMessage: "",
    lastMessageTime: serverTimestamp()
  });

  return newChat.id;
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

  const labels = doctorRiskLabels(flags);

  doctorRiskTags.innerHTML = labels
    .map(label => `<span>${label}</span>`)
    .join("");
}

function doctorRiskLabels(flags) {
  return [
    flags.preeklampsi ? t("preeclampsiaFollowUp") : null,
    flags.diabetes ? t("diabetesFollowUp") : null,
    flags.preterm ? t("pretermFollowUp") : null
  ].filter(Boolean);
}

function toDate(value) {
  if (!value) return null;
  if (value.toDate) return value.toDate();
  if (value.seconds) return new Date(value.seconds * 1000);

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function dayKey(date) {
  if (!date) return "";
  return startOfDay(date).toLocaleDateString();
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
        label: t("fastingSugar"),
        data: fastingSugars,
        tension: 0.3
      }, {
        label: t("postprandialSugar"),
        data: postMealSugars,
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

  const weightCtx = document.getElementById("weightChart");
  if (!weightCtx) return;

  if (weightChart) weightChart.destroy();

  weightChart = new Chart(weightCtx, {
    type: "line",
    data: {
      labels: dates,
      datasets: [{
        label: t("weight"),
        data: weights,
        tension: 0.3
      }]
    }
  });
}
