import {
  getFirestore,
  doc,
  getDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  getAuth
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

const db = window.db;
const auth = window.auth;

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
    console.error("Profil kontrol hatası:", error);
    alert("Bir hata oluştu");
  }
};