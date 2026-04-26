import {
  doc,
  getDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;

/* AUTH */
auth.onAuthStateChanged(async (user) => {
  if (!user) {
    window.location.href = "login.html";
    return;
  }

  loadUser(user.uid);
});

/* LOAD USER */
async function loadUser(uid) {

  const snap = await getDoc(doc(db, "users", uid));
  if (!snap.exists()) return;

  const data = snap.data();

  document.getElementById("userName").innerText =
    `${data.name || ""} ${data.surname || ""}`;

  document.getElementById("userEmail").innerText =
    auth.currentUser.email || "";

  document.getElementById("expertise").innerText =
    data.expertise || "-";

  document.getElementById("experience").innerText =
    data.experience || "-";

  document.getElementById("institution").innerText =
    data.institution || "-";

  if (data.diplomaUrl) {
    document.getElementById("diplomaStatus").classList.remove("hidden");
    window.diplomaUrl = data.diplomaUrl;
  }
}

/* diploma aç */
window.openDiploma = () => {
  if (!window.diplomaUrl) {
    alert("Henüz diploma yok");
    return;
  }
  window.open(window.diplomaUrl, "_blank");
};