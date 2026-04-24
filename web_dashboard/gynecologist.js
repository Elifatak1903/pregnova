import { initializeApp } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-app.js";

import {
  getFirestore,
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
  getAuth,
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

/* FIREBASE */
const app = initializeApp({
  apiKey: "AIzaSyBHVmFtmXLe6BcN620XCmjv9vMOkcjeFdM",
  authDomain: "pregnova-38391.firebaseapp.com",
  projectId: "pregnova-38391"
});

const db = getFirestore(app);
const auth = getAuth(app);

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

  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  const weeklySnap = await getDocs(query(
    collection(db,"risk_olcumleri"),
    where("tarih", ">=", Timestamp.fromDate(sevenDaysAgo))
  ));

  document.getElementById("weekly").innerText =
    weeklySnap.size + " ölçüm";
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
    container.innerHTML = "Henüz veri yok";
    return;
  }

  for (const item of snapshot.docs) {

    const data = item.data();
    const uid = data.uid;

    let name = "Hasta";

    if (uid) {
      const userRef = doc(db, "users", uid);
      const userDoc = await getDoc(userRef);

      const user = userDoc.data();
      name = user?.name || "Hasta";
    }

    const div = document.createElement("div");
    div.className = "activity-item";

    div.innerHTML = `
      <b>${name}</b> yeni ölçüm gönderdi
      <br>
      <span class="time">${timeAgo(data.tarih)}</span>
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
      labels: ["Normal", "Orta", "Yüksek"],
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
        Normal
      </div>
      <b>${normalCount}</b>
    </div>

    <div class="legend-item">
      <div class="legend-left">
        <div class="legend-color" style="background:#FFA000"></div>
        Orta
      </div>
      <b>${mediumCount}</b>
    </div>

    <div class="legend-item">
      <div class="legend-left">
        <div class="legend-color" style="background:#EF5350"></div>
        Yüksek
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

  if (diff < 60) return diff + " sn önce";
  if (diff < 3600) return Math.floor(diff/60) + " dk önce";
  if (diff < 86400) return Math.floor(diff/3600) + " saat önce";

  return Math.floor(diff/86400) + " gün önce";
}