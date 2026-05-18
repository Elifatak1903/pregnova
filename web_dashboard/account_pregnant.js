import { t } from "./i18n.js";

import {
  doc,
  getDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;

/* ACCOUNT HEADER BİLGİLERİ */
auth.onAuthStateChanged(async (user) => {
  if (!user) return;

  try {
    const snap = await getDoc(doc(db, "users", user.uid));

    if (!snap.exists()) return;

    const data = snap.data();

    const name = data.name || "";
    const surname = data.surname || "";

    const fullName = `${name} ${surname}`.trim();

    const accountName = document.getElementById("accountName");
    const profileAvatar = document.getElementById("profileAvatar");
    const accountEmail = document.getElementById("accountEmail");

    if (accountName) {
      accountName.textContent = fullName || "PregNova";
    }

    if (profileAvatar) {
      const initials =
        `${name.charAt(0)}${surname.charAt(0)}`.toUpperCase();

      profileAvatar.textContent = initials || "PN";
    }

    if (accountEmail) {
      accountEmail.textContent = user.email || t("pregnantUser");
      accountEmail.removeAttribute("data-i18n");
    }

  } catch (error) {
    console.error(error);
  }
});

/* KİŞİSEL BİLGİ KONTROL */
window.kisiselBilgiKontrol = async function () {
  const user = auth.currentUser;
  if (!user) return;

  try {
    const ref = doc(db, "users", user.uid);
    const snap = await getDoc(ref);

    if (!snap.exists()) {
      window.location.href = "profile_edit.html";
      return;
    }

    const data = snap.data();

    if (data.profilTamamlandi === true) {
      window.location.href = "profile_view.html";
    } else {
      window.location.href = "profile_edit.html";
    }
  } catch (error) {
    console.error(error);
    alert(t("genericError"));
  }
};
