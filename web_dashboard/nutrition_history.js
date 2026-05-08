import {
  collection,
  query,
  where,
  onSnapshot,
  deleteDoc,
  doc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

import { FoodUnits } from "./foodUnits.js";
import { NutritionEngine } from "./nutritionEngine.js";
import { SupplementUnits } from "./supplementUnits.js";

const db = window.db;
const auth = window.auth;

function loadHistory(user) {
  const q = query(
    collection(db, "besin_analizleri"),
    where("uid", "==", user.uid)
  );

  onSnapshot(q, (snap) => {
    const container = document.getElementById("historyList");
    container.innerHTML = "";

    if (snap.empty) {
      container.innerHTML = "<p>Henüz analiz yok</p>";
      return;
    }

    const groups = new Map();

    snap.forEach(docSnap => {
      const data = docSnap.data();
      const date = getAnalysisDate(data);
      if (!date) return;

      const key = date.toLocaleDateString("tr-TR");
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key).push({ id: docSnap.id, data, date });
    });

    Array.from(groups.entries())
      .sort((a, b) => b[1][0].date - a[1][0].date)
      .forEach(([day, items]) => {
      items.sort((a, b) => a.date - b.date);
      const total = summarizeDay(items);

      container.innerHTML += `
        <div class="history-card">
          <div class="card-header">
            <span>📅 ${day}</span>
            <b>${total.calorie.toFixed(0)} kcal</b>
          </div>

          ${items.map((item, index) => renderAnalysis(item, index)).join("")}

          <div class="section">
            <h4>Günlük Toplam Analiz Sonucu</h4>
            <h4>✔ Alınanlar</h4>
            ${total.consumed.map(n => `<div class="good">✔ ${n}</div>`).join("") || "Yok"}
            <h4>⚠ Eksikler</h4>
            ${total.missing.map(n => `<div class="warn">⚠ ${n}</div>`).join("") || "Yok"}
            <h4>⬆ Fazlalar</h4>
            ${total.excess.map(n => `<div class="bad">⬆ ${n}</div>`).join("") || "Yok"}
          </div>
        </div>
      `;
    });
  });
}

function renderAnalysis(item, index) {
  const data = item.data;
  const time = item.date.toLocaleTimeString("tr-TR", {
    hour: "2-digit",
    minute: "2-digit"
  });

  const foods = (data.besinler || [])
    .map(f => `<div class="tag">🍎 ${f.ad} (${f.miktar} ${f.format})</div>`)
    .join("");

  const sups = (data.takviyeler || [])
    .map(s => `<div class="tag">💊 ${s.ad} (${s.miktar} ${s.format || s.birim || ""})</div>`)
    .join("");

  return `
    <div class="section">
      <div class="card-header">
        <span>${index + 1}. Analiz - ${time}</span>
        <button onclick="deleteItem('${item.id}')">🗑️</button>
      </div>
      <h4>Besinler</h4>
      <div class="tag-container">${foods || "Yok"}</div>
      <h4>Takviyeler</h4>
      <div class="tag-container">${sups || "Yok"}</div>
      <div>Kalori: ${Number(data.kalori || 0).toFixed(0)} kcal</div>
    </div>
  `;
}

function getAnalysisDate(data) {
  const raw = data.createdAt || data.tarih;
  if (raw?.toDate) return raw.toDate();
  if (raw?.seconds) return new Date(raw.seconds * 1000);
  return raw ? new Date(raw) : null;
}

function summarizeDay(items) {
  const foods = [];
  const supplements = [];

  items.forEach(({ data }) => {
    (data.besinler || []).forEach(item => {
      const gram = (FoodUnits.units[item.format] || 1) * Number(item.miktar || 0);

      foods.push({
        name: String(item.ad || "").toLowerCase(),
        amount: gram
      });
    });

    (data.takviyeler || []).forEach(item => {
      const info = SupplementUnits[item.ad];

      supplements.push({
        name: item.ad,
        amount: info ? Number(item.miktar || 0) * info.value : Number(item.miktar || 0),
        unit: info ? info.unit : ""
      });
    });
  });

  const result = NutritionEngine.analyzeFoods(foods, supplements);

  return {
    calorie: result.totalCalories || 0,
    consumed: result.consumedNutrients || [],
    missing: result.missingNutrients || [],
    excess: result.excessNutrients || []
  };
}

window.deleteItem = async function(id) {
  if (!confirm("Silmek istediğine emin misin?")) return;
  await deleteDoc(doc(db, "besin_analizleri", id));
};

onAuthStateChanged(auth, (user) => {
  if (user) loadHistory(user);
});
