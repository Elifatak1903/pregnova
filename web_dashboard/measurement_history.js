import {
  collection,
  query,
  where,
  orderBy,
  getDocs
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

const db = window.db;
const auth = window.auth;

async function loadHistory(user) {

  const q = query(
    collection(db, "risk_olcumleri"),
    where("uid", "==", user.uid),
    orderBy("tarih", "desc")
  );

  const snap = await getDocs(q);

  const container = document.getElementById("historyList");
  if (!container) return;

  container.innerHTML = "";

  if (snap.empty) {
    container.innerHTML = "<p>Henüz ölçüm yok 😔</p>";
    return;
  }

  snap.forEach(docSnap => {

    const d = docSnap.data();

    let date = "Bilinmiyor";

    if (d.tarih?.seconds) {
      date = new Date(d.tarih.seconds * 1000)
        .toLocaleString("tr-TR");
    }

    container.innerHTML += `
      <div class="history-card">

        <div class="date">📅 ${date}</div>

        <div class="risk-row">
          <span>Preeklampsi</span>
          <span class="badge ${d.preeklampsiRisk}">
            ${d.preeklampsiRisk}
          </span>
        </div>

        <div class="risk-row">
          <span>Diyabet</span>
          <span class="badge ${d.diyabetRisk}">
            ${d.diyabetRisk}
          </span>
        </div>

        <div class="risk-row">
          <span>Preterm</span>
          <span class="badge ${d.pretermRisk}">
            ${d.pretermRisk}
          </span>
        </div>

      </div>
    `;
  });
}

onAuthStateChanged(auth, (user) => {
  if (user) {
    loadHistory(user);
  }
});