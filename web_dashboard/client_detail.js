import {
  doc,
  getDoc,
  collection,
  query,
  where,
  getDocs,
  orderBy
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;

/* URL'den id al */
const urlParams = new URLSearchParams(window.location.search);
const clientId = urlParams.get("id");

/* CHART INSTANCES */
let weightChart;
let calorieChart;

/* USER BİLGİ */
async function loadUser() {
  try {
    const snap = await getDoc(doc(db, "users", clientId));

    if (!snap.exists()) return;

    const data = snap.data();

    document.getElementById("patientName").innerText =
      `${data.name || ""} ${data.surname || ""}`;

    document.getElementById("patientInfo").innerText =
      `Hafta: ${data.hafta || "-"} | Kilo: ${data.kilo || "-"}`;

  } catch (err) {
    console.error("USER ERROR:", err);
  }
}

/* KİLO GRAFİĞİ */
async function loadWeightChart() {
  try {

    const q = query(
      collection(db, "risk_olcumleri"),
      where("uid", "==", clientId),
      orderBy("tarih")
    );

    const snap = await getDocs(q);

    const labels = [];
    const values = [];

    snap.forEach(docSnap => {
      const d = docSnap.data();

      if (!d.tarih) return;

      const date = d.tarih.toDate
        ? d.tarih.toDate()
        : new Date(d.tarih);

      labels.push(date.toLocaleDateString("tr-TR"));
      values.push(d.kilo || 0);
    });

    if (weightChart) weightChart.destroy();

    weightChart = new Chart(document.getElementById("weightChart"), {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "Kilo",
          data: values,
          tension: 0.3
        }]
      }
    });

  } catch (err) {
    console.error("WEIGHT CHART ERROR:", err);
  }
}

/* KALORİ GRAFİĞİ */
async function loadCalorieChart() {
  try {

    const q = query(
      collection(db, "besin_analizleri"),
      where("uid", "==", clientId),
      orderBy("createdAt")
    );

    const snap = await getDocs(q);

    const labels = [];
    const values = [];

    snap.forEach(docSnap => {
      const d = docSnap.data();

      if (!d.createdAt) return;

      const date = d.createdAt.toDate
        ? d.createdAt.toDate()
        : new Date(d.createdAt);

      labels.push(date.toLocaleDateString("tr-TR"));
      values.push(d.kalori || 0);
    });

    if (calorieChart) calorieChart.destroy();

    calorieChart = new Chart(document.getElementById("calorieChart"), {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "Kalori",
          data: values,
          tension: 0.3
        }]
      }
    });

  } catch (err) {
    console.error("CALORIE CHART ERROR:", err);
  }
}

/* ANALİZ LİSTESİ */
async function loadAnalysis() {
  const container = document.getElementById("analysisList");

  try {

    const q = query(
      collection(db, "besin_analizleri"),
      where("uid", "==", clientId),
      orderBy("createdAt", "desc")
    );

    const snap = await getDocs(q);

    if (snap.empty) {
      container.innerHTML = "Henüz analiz yok";
      return;
    }

    container.innerHTML = "";

    snap.forEach(docSnap => {

      const data = docSnap.data();

      const date = data.createdAt?.toDate
        ? data.createdAt.toDate()
        : new Date(data.createdAt);

      const div = document.createElement("div");
      div.className = "analysis-item";

      div.innerHTML = `
        <b>${date.toLocaleString("tr-TR")}</b>

        <div>Kalori: ${data.kalori || 0} kcal</div>

        <div style="color:#EF5350">
          Eksikler: ${(data.missingNutrients || []).slice(0,2).join(", ") || "-"}
        </div>

        <div style="color:#00B894">
          Takviyeler: ${(data.takviyeler || []).map(t => t.ad).slice(0,2).join(", ") || "-"}
        </div>
      `;

      container.appendChild(div);
    });

  } catch (err) {
    console.error("ANALYSIS ERROR:", err);
    container.innerHTML = "Hata oluştu";
  }
}

/* INIT */
async function init() {

  if (!clientId) {
    alert("Danışan bulunamadı");
    return;
  }

  await loadUser();
  await loadWeightChart();
  await loadCalorieChart();
  await loadAnalysis();
}

init();