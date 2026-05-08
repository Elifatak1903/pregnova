import {
  doc,
  getDoc,
  setDoc,
  Timestamp
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;

auth.onAuthStateChanged(async (user) => {

  if (!user) {
    window.location.href = "login.html";
    return;
  }

  const snap = await getDoc(doc(db, "users", user.uid));

  if (!snap.exists()) return;

  const d = snap.data();

  document.getElementById("yas").value = d.yas || "";
  document.getElementById("kilo").value = d.kilo || "";
  document.getElementById("boy").value = d.boy || "";
  document.getElementById("hafta").value = d.hafta || "";
  document.getElementById("alerjiler").value = d.alerjiler || "";
  updateBmiPreview();

  document.getElementById("chronicHypertension").checked = d.chronicHypertension || false;
  document.getElementById("diabetes").checked = d.diabetes || false;
  document.getElementById("thyroidDisease").checked = d.thyroidDisease || false;
  document.getElementById("previousPreterm").checked = d.previousPreterm || false;
  document.getElementById("multiplePregnancy").checked = d.multiplePregnancy || false;
  document.getElementById("smoker").checked = d.smoker || false;

});

window.saveProfile = async function () {

  const user = auth.currentUser;
  if (!user) return;

  const yas = document.getElementById("yas").value.trim();
  const kilo = document.getElementById("kilo").value.trim();
  const boy = document.getElementById("boy").value.trim();
  const hafta = document.getElementById("hafta").value.trim();
  const alerjiler = document.getElementById("alerjiler").value.trim();

  if (!yas || !kilo || !boy || !hafta) {
    alert("Tüm alanları doldur kanka ⚠️");
    return;
  }

  const kiloNumber = Number(kilo);
  const boyNumber = Number(boy);
  const haftaNumber = Number(hafta);
  const boyMetre = boyNumber / 100;
  const bmi = boyMetre > 0 ? kiloNumber / (boyMetre * boyMetre) : 0;
  const gebelikBaslangicTarihi = new Date();
  gebelikBaslangicTarihi.setDate(gebelikBaslangicTarihi.getDate() - (haftaNumber * 7));

  const data = {
    yas: Number(yas),
    kilo: kiloNumber,
    boy: boyNumber,
    bmi,
    hafta: haftaNumber,
    gebelikBaslangicTarihi: Timestamp.fromDate(gebelikBaslangicTarihi),
    alerjiler,

    chronicHypertension: document.getElementById("chronicHypertension").checked,
    diabetes: document.getElementById("diabetes").checked,
    thyroidDisease: document.getElementById("thyroidDisease").checked,
    previousPreterm: document.getElementById("previousPreterm").checked,
    multiplePregnancy: document.getElementById("multiplePregnancy").checked,
    smoker: document.getElementById("smoker").checked,

    profilTamamlandi: true
  };

  try {
    await setDoc(doc(db, "users", user.uid), data, { merge: true });

    alert("Kaydedildi ✅");

    window.location.href = "profile_view.html";

  } catch (err) {
    console.error(err);
    alert("Hata oluştu ❌");
  }
};

function updateBmiPreview() {
  const kilo = Number(document.getElementById("kilo").value);
  const boy = Number(document.getElementById("boy").value);
  const boyMetre = boy / 100;
  const bmi = boyMetre > 0 ? kilo / (boyMetre * boyMetre) : 0;

  document.getElementById("bmiPreview").textContent =
    bmi > 0 ? bmi.toFixed(1) : "-";
}

document.getElementById("kilo").addEventListener("input", updateBmiPreview);
document.getElementById("boy").addEventListener("input", updateBmiPreview);
