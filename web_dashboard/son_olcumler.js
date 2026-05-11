import { db } from "./app.js";
import { t } from "./i18n.js";

import {
  collection,
  query,
  orderBy,
  onSnapshot,
  getDoc,
  doc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

document.addEventListener("DOMContentLoaded", () => {
  const list = document.getElementById("measurementsList");
  const filter = document.getElementById("dateFilter");

  if (!list || !filter) {
    console.error("Required measurement list elements were not found");
    return;
  }

  const params = new URLSearchParams(window.location.search);
  const selectedUid = params.get("uid");
  const selectedTarih = params.get("tarih");
  const selectedDateFromUrl = selectedTarih
    ? new Date(Number(selectedTarih) * 1000).toLocaleDateString()
    : null;

  let allDocs = [];
  let selectedDate = null;

  const q = query(
    collection(db, "risk_olcumleri"),
    orderBy("tarih", "desc")
  );

  onSnapshot(q, async (snapshot) => {
    if (snapshot.empty) {
      list.innerHTML = `<p>${t("noMeasurements")}</p>`;
      return;
    }

    allDocs = snapshot.docs;

    const dates = [...new Set(allDocs.map(d =>
      d.data().tarih.toDate().toLocaleDateString()
    ))];

    if (!selectedDate) {
      selectedDate = selectedDateFromUrl || dates[0];
    }

    filter.innerHTML = "";

    dates.forEach(d => {
      const opt = document.createElement("option");
      opt.value = d;
      opt.innerText = d;
      filter.appendChild(opt);
    });

    filter.value = selectedDate;

    renderList();

    filter.onchange = () => {
      selectedDate = filter.value;
      renderList();
    };
  }, (error) => {
    console.error("Firestore error:", error);
  });

  async function renderList() {
    list.innerHTML = "";

    const filtered = allDocs.filter(item => {
      const d = item.data().tarih.toDate().toLocaleDateString();
      return d === selectedDate;
    });

    for (let index = 0; index < filtered.length; index++) {
      const docSnap = filtered[index];
      const data = docSnap.data();
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
      div.className = "measurement-card";
      div.id = `item-${data.tarih.seconds}`;

      div.innerHTML = `
        <div class="measurement-full-card">
          <div class="top">
            <b>${name} ${surname}</b>
            <span class="time">${formatDate(data.tarih)}</span>
          </div>

          <div class="info">
            <div>${t("bloodPressure")}: ${data.sistolik || "-"} / ${data.diastolik || "-"}</div>
            <div>${t("fastingSugar")}: ${data.aclikSeker || "-"}</div>
            <div>${t("postprandialSugar")}: ${data.toklukSeker || "-"}</div>
            <div>${t("stress")}: ${data.stresSeviyesi || "-"}</div>
          </div>

          <div class="risk">
            ${t("preeclampsia")}: ${formatRiskText(data.preeklampsiRisk ?? "-")} <br>
            ${t("diabetes")}: ${formatRiskText(data.diyabetRisk ?? "-")} <br>
            ${t("preterm")}: ${formatRiskText(data.pretermRisk ?? "-")}
          </div>

          <div class="action">
            <button onclick="goDetail('${uid}', '${name}', '${surname}', ${index})">
              ${t("detailedReview")} &rsaquo;
            </button>
          </div>
        </div>
      `;

      list.appendChild(div);

      if (
        selectedUid &&
        selectedTarih &&
        selectedUid == uid &&
        Number(selectedTarih) === data.tarih.seconds
      ) {
        setTimeout(() => {
          div.scrollIntoView({
            behavior: "smooth",
            block: "center"
          });

          div.style.border = "2px solid #7C4DFF";
          div.style.background = "rgba(124,77,255,0.1)";

          div.animate([
            { transform: "scale(1)" },
            { transform: "scale(1.03)" },
            { transform: "scale(1)" }
          ], { duration: 400 });
        }, 400);
      }
    }
  }
});

function timeAgo(timestamp) {
  if (!timestamp) return "";

  const now = new Date();
  const date = timestamp.toDate();
  const diff = (now - date) / 1000;

  if (diff < 60) return t("secondsAgo", { count: Math.floor(diff) });
  if (diff < 3600) return t("minutesAgo", { count: Math.floor(diff / 60) });
  if (diff < 86400) return t("hoursAgo", { count: Math.floor(diff / 3600) });

  return t("daysAgo", { count: Math.floor(diff / 86400) });
}

function formatDate(timestamp) {
  if (!timestamp) return "";

  const d = timestamp.toDate();

  return d.toLocaleString(undefined, {
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
        <h4>${t("measurements")}</h4>
        <div class="measurements-grid">
          ${measurementsHTML || "<p>-</p>"}
        </div>
      </div>

      <div class="popup-divider"></div>

      <div class="popup-right">
        <h4>${t("riskAnalysis")}</h4>
        ${risksHTML || "<p>-</p>"}
      </div>
    </div>
  `;
};

function formatKey(key) {
  const labels = {
    sistolik: t("systolic"),
    diastolik: t("diastolic"),
    aclikSeker: t("fastingSugar"),
    toklukSeker: t("postprandialSugar"),
    stresSeviyesi: t("stress"),
    basAgrisi: t("headache"),
    gormeBozuklugu: t("visionProblem"),
    sislik: t("swelling"),
    karinKasilma: t("abdominalContraction"),
    belAgrisi: t("backPain"),
    akinti: t("discharge"),
    kilo: t("weight"),
    boy: t("height"),
    nabiz: t("pulse"),
    preeklampsiRisk: t("preeclampsia"),
    diyabetRisk: t("diabetes"),
    pretermRisk: t("preterm")
  };

  return labels[key] || key
    .replace(/([A-Z])/g, " $1")
    .replace(/^./, str => str.toUpperCase());
}

function formatRisk(risk) {
  const riskLevel = getRiskLevel(risk);

  if (riskLevel === "high")
    return `<span style="color:#EF5350; font-weight:bold;">${t("high")}</span>`;

  if (riskLevel === "medium")
    return `<span style="color:#FFA000; font-weight:bold;">${t("medium")}</span>`;

  if (riskLevel === "low")
    return `<span style="color:#00BFA5; font-weight:bold;">${t("low")}</span>`;

  return risk || "-";
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
  if (value === true) return t("exists");
  if (value === false) return t("none");

  if (value === null || value === undefined) return "-";

  if (key === "kilo") return value + " kg";
  if (key === "boy") return value + " cm";
  if (key === "nabiz") return value + " bpm";

  return value;
}

function getRiskClass(risk) {
  return getRiskLevel(risk) || "";
}

function formatRiskText(risk) {
  const riskLevel = getRiskLevel(risk);

  if (riskLevel === "high") return t("high");
  if (riskLevel === "medium") return t("medium");
  if (riskLevel === "low") return t("low");

  return risk || "-";
}

function getRiskLevel(risk) {
  if (!risk) return "";

  const r = String(risk).toLowerCase();

  if (r.includes("high")) return "high";
  if (r.includes("medium")) return "medium";
  if (r.includes("low")) return "low";

  return "";
}

window.goDetail = function(uid, name, surname, index) {
  const fullName = encodeURIComponent(`${name} ${surname}`.trim());
  window.location.href =
    `patient_detail.html?uid=${encodeURIComponent(uid)}&name=${fullName}&index=${index}`;
};
