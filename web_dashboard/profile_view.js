import { t } from "./i18n.js";
import { doc, getDoc } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;
const content = document.getElementById("content");

function kart(title, value, icon) {
  return `
    <div class="card">
      <div class="icon">${icon}</div>
      <div class="info">
        <div class="title">${title}</div>
        <div class="value">${value}</div>
      </div>
    </div>
  `;
}

function boolText(value) {
  return value ? t("exists") : t("none");
}

auth.onAuthStateChanged(async (user) => {
  if (!user) {
    window.location.href = "login.html";
    return;
  }

  try {
    const snap = await getDoc(doc(db, "users", user.uid));

    if (!snap.exists()) {
      content.innerHTML = t("dataNotFound");
      return;
    }

    const d = snap.data();

    content.innerHTML = `
      ${kart(t("age"), d.yas ?? "-", "👤")}
      ${kart(t("currentWeight"), d.kilo ? `${d.kilo} kg` : "-", "⚖️")}
      ${kart(t("height"), d.boy ? `${d.boy} cm` : "-", "📏")}
      ${kart(t("bmi"), d.bmi ? Number(d.bmi).toFixed(1) : "-", "📊")}
      ${kart(t("pregnancyWeek"), d.hafta ? t("weekValue", { week: d.hafta }) : "-", "📅")}
      ${kart(t("allergies"), d.alerjiler || t("none"), "⚠️")}
      ${kart(t("chronicHypertension"), boolText(d.chronicHypertension), "❤️")}
      ${kart(t("diabetes"), boolText(d.diabetes), "🩸")}
      ${kart(t("thyroidDisease"), boolText(d.thyroidDisease), "🧬")}
      ${kart(t("previousPreterm"), boolText(d.previousPreterm), "⚠️")}
      ${kart(t("multiplePregnancy"), boolText(d.multiplePregnancy), "👶👶")}
      ${kart(t("smokingUse"), boolText(d.smoker), "🚬")}

      <button class="edit-btn" onclick="editProfile()">
        ✏️ ${t("editInfo")}
      </button>
    `;
  } catch (err) {
    console.error(err);
    content.innerHTML = t("genericError");
  }
});

window.editProfile = function () {
  window.location.href = "profile_edit.html";
};
