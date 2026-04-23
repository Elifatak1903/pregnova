import { initializeApp } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-app.js";

import {
  getFirestore,
  collection,
  getDocs,
  query,
  where,
  getDoc,
  doc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  getAuth,
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

/* FIREBASE (TEK SEFER!) */
const app = initializeApp({
  apiKey: "AIzaSyBHVmFtmXLe6BcN620XCmjv9vMOkcjeFdM",
  authDomain: "pregnova-38391.firebaseapp.com",
  projectId: "pregnova-38391"
});

const db = getFirestore(app);
const auth = getAuth(app);

/* GLOBAL */
let allPatients = [];

/* AUTH */
onAuthStateChanged(auth, async (user) => {

  if (!user) {
    window.location.href = "login.html";
    return;
  }

  const uid = user.uid;

  await loadPatients(uid);

  /*  NULL HATASI ENGELİ */
  const searchInput = document.getElementById("searchInput");
  const filterSelect = document.getElementById("filterSelect");

  if (searchInput) {
    searchInput.addEventListener("input", filterPatients);
  }

  if (filterSelect) {
    filterSelect.addEventListener("change", filterPatients);
  }
});

/* HASTALARI YÜKLE */
async function loadPatients(uid) {

  const container = document.getElementById("list");

  if (!container) return;

  container.innerHTML = "Yükleniyor...";

  const snap = await getDocs(query(
    collection(db, "expert_requests"),
    where("expertId", "==", uid),
    where("status", "==", "approved")
  ));

  container.innerHTML = "";
  allPatients = [];

  let high = 0, medium = 0, normal = 0;

  for (const item of snap.docs) {

    const clientId = item.data().clientId;

    const userDoc = await getDoc(doc(db, "users", clientId));
    const data = userDoc.data();

    const name = data?.name || "";
    const surname = data?.surname || "";
    const hafta = data?.hafta || "-";
    const risk = (data?.riskLevel || "normal").toLowerCase();

    if (risk === "high") high++;
    else if (risk === "medium") medium++;
    else normal++;

    allPatients.push({
      uid: clientId,
      name,
      surname,
      hafta,
      risk
    });
  }

  renderPatients(allPatients);

  /* SAYILAR */
  setText("totalCount", allPatients.length);
  setText("highCount", high);
  setText("mediumCount", medium);
  setText("normalCount", normal);
}

/* RENDER */
function renderPatients(list) {

  const container = document.getElementById("list");
  if (!container) return;

  container.innerHTML = "";

  const searchValue = document.getElementById("searchInput")?.value || "";

  list.forEach(p => {

    let color = "#00BFA5";
    let text = "Normal";

    if (p.risk === "medium") {
      color = "#FFA000";
      text = "Orta";
    }

    if (p.risk === "high") {
      color = "#EF5350";
      text = "Yüksek";
    }

    const fullName = `${p.name} ${p.surname}`;
    const highlightedName = highlight(fullName, searchValue);

    const div = document.createElement("div");
    div.className = "patient-card";

    div.innerHTML = `
      <b>${highlightedName}</b><br>
      Hafta: ${p.hafta}<br>
      <span style="color:${color}">
        Risk: ${text}
      </span>
    `;

    /* DETAY SAYFASI */
    div.onclick = () => {

      if (!p.uid) {
        console.error("UID yok ❌");
        return;
      }

      const fullName = p.name + " " + p.surname;

      console.log("Gidiyor:", p.uid);

      window.location.href =
        "/patient_detail.html?uid=" + encodeURIComponent(p.uid) +
        "&name=" + encodeURIComponent(fullName);
    };

    container.appendChild(div);
  });
}

/* SEARCH + FILTER */
function filterPatients() {

  const value = document.getElementById("searchInput")?.value.toLowerCase().trim() || "";

  let result = [...allPatients];

  if (value) {
    result = result.filter(p => {
      const fullName = ((p.name || "") + " " + (p.surname || "")).toLowerCase();
      return fullName.includes(value);
    });
  }

  result = applyFilter(result);

  renderPatients(result);
}

/* FILTER */
function applyFilter(list) {

  const filter = document.getElementById("filterSelect")?.value || "default";

  let sorted = [...list];

  if (filter === "riskHigh") {
    sorted = sorted.filter(p => p.risk === "high");
  }

  if (filter === "riskLow") {
    sorted = sorted.filter(p => p.risk === "normal");
  }

  if (filter === "newest") {
    sorted.reverse();
  }

  return sorted;
}

/*  HIGHLIGHT */
function highlight(text, value) {
  if (!value) return text;

  const regex = new RegExp(`(${value})`, "gi");
  return text.replace(regex, `<span class="highlight">$1</span>`);
}

/*  SAFE TEXT SET */
function setText(id, value) {
  const el = document.getElementById(id);
  if (el) el.innerText = value;
}