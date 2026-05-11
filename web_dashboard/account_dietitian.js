import { t } from "./i18n.js";

import {
  doc,
  getDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;

auth.onAuthStateChanged(async (user) => {
  if (!user) {
    window.location.href = "login.html";
    return;
  }

  loadUser(user.uid);
});

async function loadUser(uid) {
  const snap = await getDoc(doc(db, "users", uid));
  if (!snap.exists()) return;

  const data = snap.data();

  document.getElementById("userName").innerText =
    `${data.name || ""} ${data.surname || ""}`;
  document.getElementById("userEmail").innerText = auth.currentUser.email || "";
  document.getElementById("expertise").innerText = data.expertise || "-";
  document.getElementById("experience").innerText = data.experience || "-";
  document.getElementById("institution").innerText = data.institution || "-";

  const diplomaUrl = data.diplomaUrl || data.diploma || null;

  if (diplomaUrl) {
    document.getElementById("diplomaStatus").classList.remove("hidden");
    window.diplomaUrl = diplomaUrl;
  }
}

window.openDiploma = () => {
  if (!window.diplomaUrl) {
    alert(t("noDiploma"));
    return;
  }

  window.open(window.diplomaUrl, "_blank");
};
