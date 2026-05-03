import {
  doc,
  getDoc,
  updateDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;

/* LOAD */
auth.onAuthStateChanged(async (user) => {
  if (!user) {
    window.location.href = "login.html";
    return;
  }

  const snap = await getDoc(doc(db, "users", user.uid));
  const data = snap.data();

  document.getElementById("name").value =
    data?.name || "";

  document.getElementById("email").value =
    user.email || "";

  document.getElementById("license").value =
    data?.licenseNumber || "";

  document.getElementById("experience").value =
    data?.experience || "";

  document.getElementById("hospital").value =
    data?.hospital || "";
});

/* SAVE */
window.saveData = async () => {

  const user = auth.currentUser;

  await updateDoc(doc(db, "users", user.uid), {

    name: document.getElementById("name").value,
    licenseNumber: document.getElementById("license").value,
    experience: document.getElementById("experience").value,
    hospital: document.getElementById("hospital").value,

  });

  alert("Güncellendi ✅");

  window.location.href = "account_gynecologist.html";
};