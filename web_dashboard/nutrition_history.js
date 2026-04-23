import {
  collection,
  query,
  where,
  orderBy,
  onSnapshot,
  deleteDoc,
  doc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

const db = window.db;
const auth = window.auth;

function loadHistory(user) {

  const q = query(
    collection(db, "besin_analizleri"),
    where("uid", "==", user.uid),
    orderBy("tarih", "desc")
  );

  onSnapshot(q, (snap) => {

    const container = document.getElementById("historyList");
    container.innerHTML = "";

    if (snap.empty) {
      container.innerHTML = "<p>Henüz analiz yok 😔</p>";
      return;
    }

    snap.forEach(docSnap => {

      const d = docSnap.data();
      const id = docSnap.id;

      let date = "Bilinmiyor";
      if (d.tarih?.seconds) {
        date = new Date(d.tarih.seconds * 1000)
          .toLocaleString("tr-TR");
      }

      const foods = (d.besinler || []).map(f =>
        `<div class="tag">🍎 ${f.ad} (${f.miktar} ${f.format})</div>`
      ).join("");

      const sups = (d.takviyeler || []).map(s =>
        `<div class="tag">💊 ${s.ad} (${s.miktar})</div>`
      ).join("");

      const consumed = (d.consumedNutrients || [])
        .map(n => `<div class="good">✔ ${n}</div>`).join("");

      const missing = (d.missingNutrients || [])
        .map(n => `<div class="warn">⚠ ${n}</div>`).join("");

      const excess = (d.excessNutrients || [])
        .map(n => `<div class="bad">⬆ ${n}</div>`).join("");

      container.innerHTML += `
        <div class="history-card">

          <div class="card-header">
            <span>📅 ${date}</span>
            <button onclick="deleteItem('${id}')">🗑️</button>
          </div>

          <div class="section">
            <h4>🍎 Besinler</h4>
            <div class="tag-container">${foods || "Yok"}</div>
          </div>

          <div class="section">
            <h4>💊 Takviyeler</h4>
            <div class="tag-container">${sups || "Yok"}</div>
          </div>

          <div class="section">
            <h4>✔ Alınanlar</h4>
            ${consumed || "Yok"}
          </div>

          <div class="section">
            <h4>⚠ Eksikler</h4>
            ${missing || "Yok"}
          </div>

          <div class="section">
            <h4>⬆ Fazlalar</h4>
            ${excess || "Yok"}
          </div>

        </div>
      `;
    });
  });
}

window.deleteItem = async function(id){
  if (!confirm("Silmek istediğine emin misin?")) return;

  await deleteDoc(doc(db, "besin_analizleri", id));
};

onAuthStateChanged(auth, (user) => {
  if (user) loadHistory(user);
});