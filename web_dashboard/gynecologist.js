import { auth, db } from "./app.js";

import {
  collection,
  getDocs,
  query,
  where,
  Timestamp,
  orderBy,
  limit,
  getDoc,
  doc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";
import { t } from "./i18n.js";

/* AUTH */
onAuthStateChanged(auth, async (user) => {

  if (!user) {
    window.location.href = "login.html";
    return;
  }

  const uid = user.uid;

  await loadDashboard(uid);
  await loadActivity();
  await loadChart();
});

async function loadDashboard(uid) {

  const approvedSnap = await getDocs(query(
    collection(db,"expert_requests"),
    where("expertId","==", uid),
    where("status","==","approved")
  ));

  document.getElementById("approved").innerText = approvedSnap.size;

  const pendingSnap = await getDocs(query(
    collection(db,"expert_requests"),
    where("expertId","==", uid),
    where("status","==","pending")
  ));

  document.getElementById("pending").innerText = pendingSnap.size;

  const riskSnap = await getDocs(query(
    collection(db,"risk_olcumleri"),
    where("preeklampsiRisk","==","HIGH")
  ));

  const unique = new Set();

  riskSnap.forEach(d => {
    const data = d.data();
    if (data.uid) unique.add(data.uid);
  });

  document.getElementById("highRisk").innerText = unique.size;
  updateHighRiskBanner(unique.size);

  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  const weeklySnap = await getDocs(query(
    collection(db,"risk_olcumleri"),
    where("tarih", ">=", Timestamp.fromDate(sevenDaysAgo))
  ));

  document.getElementById("weekly").innerText =
    t("measurementsCount", { count: weeklySnap.size });
}

function updateHighRiskBanner(count) {
  const banner = document.getElementById("highRiskBanner");
  const textEl = document.getElementById("highRiskBannerText");

  if (!banner || !textEl) return;

  textEl.innerText = t("highRiskPatientDetected", { count });
  banner.classList.toggle("hidden", count <= 0);
}

async function loadActivity() {

  const container = document.getElementById("activity");

  const snapshot = await getDocs(
    query(
      collection(db, "risk_olcumleri"),
      orderBy("tarih", "desc"),
      limit(5)
    )
  );

  container.innerHTML = "";

  if (snapshot.empty) {
    container.innerHTML = t("noDataYet");
    return;
  }

  for (const item of snapshot.docs) {

    const data = item.data();
    const uid = data.uid;

    let name = t("patient");
    let surname = "";

    if (uid) {
      const userDoc = await getDoc(doc(db, "users", uid));
      const user = userDoc.data();

      name = user?.name || t("patient");
      surname = user?.surname || "";
    }

    const div = document.createElement("div");
    div.className = "activity-item clickable";

    div.onclick = () => {

      document.querySelectorAll(".measurement-card")
        .forEach(el => el.classList.remove("selected"));

      div.classList.add("selected");

      setTimeout(() => {
        window.location.href =
          `son_olcumler.html?uid=${uid}&tarih=${data.tarih.seconds}`;
      }, 150);

    };

    div.innerHTML = `
      <div class="activity-content">
        <b>${name} ${surname}</b> ${t("sentNewMeasurement")}
        <br>
        <span class="time">${timeAgo(data.tarih)}</span>
      </div>
    `;

    container.appendChild(div);
  }
}

async function loadChart() {

  const normal = await getDocs(query(
    collection(db,"users"),
    where("riskLevel","==","normal")
  ));

  const medium = await getDocs(query(
    collection(db,"users"),
    where("riskLevel","==","medium")
  ));

  const high = await getDocs(query(
    collection(db,"users"),
    where("riskLevel","==","high")
  ));

  const ctx = document.getElementById("chart");

  new Chart(ctx, {
    type: "doughnut",
    data: {
      labels: [t("normal"), t("medium"), t("high")],
      datasets: [{
        data: [normal.size, medium.size, high.size],
        backgroundColor: ["#00BFA5", "#FFA000", "#EF5350"]
      }]
    },
    options: {
      responsive: false,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: 'bottom'
        }
      }
    }
  });
  createLegend(normal.size, medium.size, high.size);
}

function createLegend(normalCount, mediumCount, highCount) {

  const legend = document.getElementById("riskLegend");

  legend.innerHTML = `
    <div class="legend-item">
      <div class="legend-left">
        <div class="legend-color" style="background:#00BFA5"></div>
        ${t("normal")}
      </div>
      <b>${normalCount}</b>
    </div>

    <div class="legend-item">
      <div class="legend-left">
        <div class="legend-color" style="background:#FFA000"></div>
        ${t("medium")}
      </div>
      <b>${mediumCount}</b>
    </div>

    <div class="legend-item">
      <div class="legend-left">
        <div class="legend-color" style="background:#EF5350"></div>
        ${t("high")}
      </div>
      <b>${highCount}</b>
    </div>
  `;
}

function timeAgo(timestamp) {

  if (!timestamp) return "-";

  const now = new Date();
  const date = timestamp.toDate();

  const diff = Math.floor((now - date) / 1000);

  if (diff < 60) return t("secondsAgo", { count: diff });
  if (diff < 3600) return t("minutesAgo", { count: Math.floor(diff / 60) });
  if (diff < 86400) return t("hoursAgo", { count: Math.floor(diff / 3600) });

  return t("daysAgo", { count: Math.floor(diff / 86400) });
}
