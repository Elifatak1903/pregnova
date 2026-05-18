import { t } from "./i18n.js";
import { doc, getDoc } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;
const content = document.getElementById("content");

function infoItem(title, value, icon) {
  return `
    <div class="info-item">
      <div class="info-icon">${icon}</div>
      <div>
        <div class="info-title">${title}</div>
        <div class="info-value">${value}</div>
      </div>
    </div>
  `;
}

function riskItem(title, value, icon) {
  const active = value === true;

  return `
    <div class="risk-item ${active ? "active" : ""}">
      <div class="risk-icon">${icon}</div>
      <div>
        <div class="risk-title">${title}</div>
        <div class="risk-value">${active ? t("exists") : t("none")}</div>
      </div>
    </div>
  `;
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

    const name = `${d.name || ""} ${d.surname || ""}`.trim() || "PregNova";
    const initials = name
      .split(" ")
      .filter(Boolean)
      .slice(0, 2)
      .map(part => part[0]?.toUpperCase())
      .join("") || "PN";

    content.innerHTML = `
      <div class="profile-hero">
        <div class="profile-avatar">${initials}</div>

        <div>
          <h2>${name}</h2>
          <p>${d.email || t("pregnantUser")}</p>
          <span>${t("pregnant")}</span>
        </div>
      </div>

      <div class="profile-section">
        <div class="section-head">
          <h3>${t("personalInfo")}</h3>
          <button onclick="editProfile()">${t("editInfo")}</button>
        </div>

        <div class="info-grid">
          ${infoItem(t("age"), d.yas ?? "-", "Y")}
          ${infoItem(t("currentWeight"), d.kilo ? `${d.kilo} kg` : "-", "K")}
          ${infoItem(t("height"), d.boy ? `${d.boy} cm` : "-", "B")}
          ${infoItem(t("bmi"), d.bmi ? Number(d.bmi).toFixed(1) : "-", "BMI")}
          ${infoItem(t("pregnancyWeek"), d.hafta ? t("weekValue", { week: d.hafta }) : "-", "H")}
          ${infoItem(t("allergies"), d.alerjiler || t("none"), "!")}
        </div>
      </div>

      <div class="profile-section">
        <div class="section-head">
          <h3>${t("riskFactors")}</h3>
        </div>

        <div class="risk-grid">
          ${riskItem(t("chronicHypertension"), d.chronicHypertension, "HT")}
          ${riskItem(t("diabetes"), d.diabetes, "DM")}
          ${riskItem(t("thyroidDisease"), d.thyroidDisease, "T")}
          ${riskItem(t("previousPreterm"), d.previousPreterm, "PT")}
          ${riskItem(t("multiplePregnancy"), d.multiplePregnancy, "MP")}
          ${riskItem(t("smokingUse"), d.smoker, "S")}
        </div>
      </div>
    `;
  } catch (err) {
    console.error(err);
    content.innerHTML = t("genericError");
  }
});

window.editProfile = function () {
  window.location.href = "profile_edit.html";
};
