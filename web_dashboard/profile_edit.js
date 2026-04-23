import {
  doc,
  getDoc,
  setDoc
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
  document.getElementById("hafta").value = d.hafta || "";

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
  const hafta = document.getElementById("hafta").value.trim();

  if (!yas || !kilo || !hafta) {
    alert("Tüm alanları doldur kanka ⚠️");
    return;
  }

  const data = {
    yas: Number(yas),
    kilo: Number(kilo),
    hafta: Number(hafta),

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