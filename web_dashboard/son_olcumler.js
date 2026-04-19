import { initializeApp } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-app.js";

import {
  getFirestore,
  collection,
  query,
  where,
  orderBy,
  onSnapshot,
  Timestamp,
  getDoc,
  doc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

/* FIREBASE */
const app = initializeApp({
  apiKey: "AIzaSyBHVmFtmXLe6BcN620XCmjv9vMOkcjeFdM",
  authDomain: "pregnova-38391.firebaseapp.com",
  projectId: "pregnova-38391"
});

const db = getFirestore(app);

/* DOM LOAD */
document.addEventListener("DOMContentLoaded", () => {

  const list = document.getElementById("measurementsList");

  if (!list) {
    console.error("❌ measurementsList bulunamadı");
    return;
  }

  /* SON 7 GÜN */
  const sevenDaysAgo = Timestamp.fromDate(
    new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
  );

  /* QUERY */
  const q = query(
    collection(db, "risk_olcumleri"),
    where("tarih", ">", sevenDaysAgo),
    orderBy("tarih", "desc")
  );

  /* REALTIME */
  onSnapshot(q, (snapshot) => {

    list.innerHTML = "";

    if (snapshot.empty) {
      list.innerHTML = "<p>Son 7 günde ölçüm yok</p>";
      return;
    }

    snapshot.forEach(async (docSnap) => {

      const data = docSnap.data();
      const uid = data.uid;

      /* USER ÇEK */
      let name = "Hasta";
      let surname = "";

      if (uid) {
        const userDoc = await getDoc(doc(db, "users", uid));
        const user = userDoc.data();

        name = user?.name || "Hasta";
        surname = user?.surname || "";
      }

      const div = document.createElement("div");
      div.className = "measurement-card";

      div.innerHTML = `
        <div class="left">
          <div class="avatar">❤️</div>
          <div>
            <b>${name} ${surname}</b>
            <div class="time">${formatDate(data.tarih)}</div>
          </div>
        </div>
        <div>➡️</div>
      `;

      /* TIKLAYINCA POPUP */
      div.onclick = () => openPopup(data, name, surname);

      list.appendChild(div);
    });

  }, (error) => {
    console.error("Firestore hata:", error);
  });

});

/* TIME FORMAT */
function timeAgo(timestamp) {

  if (!timestamp) return "";

  const now = new Date();
  const date = timestamp.toDate();
  const diff = (now - date) / 1000;

  if (diff < 60) return Math.floor(diff) + " sn önce";
  if (diff < 3600) return Math.floor(diff / 60) + " dk önce";
  if (diff < 86400) return Math.floor(diff / 3600) + " saat önce";

  return Math.floor(diff / 86400) + " gün önce";
}

function formatDate(timestamp) {

  if (!timestamp) return "";

  const d = timestamp.toDate();

  return d.toLocaleString("tr-TR", {
    day: "2-digit",
    month: "2-digit",
    hour: "2-digit",
    minute: "2-digit"
  });
}

window.openPopup = function (data, name, surname) {

  document.getElementById("popup").classList.remove("hidden");

  document.getElementById("popupName").innerText =
    name + " " + surname;

  let measurementsHTML = "";
  let risksHTML = "";

  for (const key in data) {

    const value = data[key];

    if (key === "uid" || key === "tarih") continue;

    if (key.toLowerCase().includes("risk")) {
      risksHTML += `
        <div class="risk-card ${getRiskClass(value)}">
          <span class="risk-title">${formatKey(key)}</span>
          <span class="risk-value">${formatRiskText(value)}</span>
        </div>
      `;
    } else {
      measurementsHTML += `
        <div class="measurement-item">
          <span class="label">${formatKey(key)}</span>
          <span class="value">${formatValue(key, value) ?? "-"}</span>
        </div>
      `;
    }
  }

  document.getElementById("popupData").innerHTML = `
    <div class="popup-grid">

      <div class="popup-left">
        <h4>🩺 Ölçümler</h4>
        <div class="measurements-grid">
          ${measurementsHTML || "<p>-</p>"}
        </div>
      </div>

      <div class="popup-divider"></div>

      <div class="popup-right">
        <h4>⚠️ Risk Analizi</h4>
        ${risksHTML || "<p>-</p>"}
      </div>

    </div>
  `;
};

function formatKey(key) {

  return key
    .replace(/([A-Z])/g, " $1")
    .replace(/^./, str => str.toUpperCase());
}

function formatRisk(risk) {

  if (!risk) return "-";

  const r = risk.toLowerCase();

  if (r.includes("high") || r.includes("yüksek"))
    return `<span style="color:#EF5350; font-weight:bold;">Yüksek</span>`;

  if (r.includes("medium") || r.includes("orta"))
    return `<span style="color:#FFA000; font-weight:bold;">Orta</span>`;

  if (r.includes("low") || r.includes("düşük"))
    return `<span style="color:#00BFA5; font-weight:bold;">Düşük</span>`;

  return risk;
}

window.closePopup = function () {
  document.getElementById("popup").classList.add("hidden");
};

window.addEventListener("click", (e) => {
  const popup = document.getElementById("popup");
  if (e.target === popup) {
    popup.classList.add("hidden");
  }
});

function formatValue(key, value) {

  if (value === true) return "Var";
  if (value === false) return "Yok";

  if (value === null || value === undefined) return "-";

  if (key === "kilo") return value + " kg";
  if (key === "boy") return value + " cm";
  if (key === "nabiz") return value + " bpm";

  return value;
}

function getRiskClass(risk) {
  if (!risk) return "";

  const r = risk.toLowerCase();

  if (r.includes("high") || r.includes("yüksek")) return "high";
  if (r.includes("medium") || r.includes("orta")) return "medium";
  return "low";
}

function formatRiskText(risk) {
  if (!risk) return "-";

  const r = risk.toLowerCase();

  if (r.includes("high") || r.includes("yüksek")) return "Yüksek";
  if (r.includes("medium") || r.includes("orta")) return "Orta";
  if (r.includes("low") || r.includes("düşük")) return "Düşük";

  return risk;
}