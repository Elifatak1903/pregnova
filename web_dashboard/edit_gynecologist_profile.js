import {
  doc,
  getDoc,
  updateDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;

let diplomaUrl = null;

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

  diplomaUrl = data?.diplomaUrl || data?.diploma || null;

  if (diplomaUrl) {
    document.getElementById("uploadStatus").innerText =
      "Diploma yüklendi ✅";
  }
});

/* UPLOAD */
document.getElementById("uploadBtn").onclick = async () => {

  const input = document.createElement("input");
  input.type = "file";
  input.accept = "image/*,.pdf";

  input.onchange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();

    reader.onload = () => {
      diplomaUrl = reader.result;

      document.getElementById("uploadStatus").innerText =
        "Diploma yüklendi ✅";
    };

    reader.readAsDataURL(file);
  };

  input.click();
};

/* SAVE */
window.saveData = async () => {

  const user = auth.currentUser;

  await updateDoc(doc(db, "users", user.uid), {

    name: document.getElementById("name").value,
    licenseNumber: document.getElementById("license").value,
    experience: document.getElementById("experience").value,
    hospital: document.getElementById("hospital").value,
    diploma: diplomaUrl,
    diplomaUrl: diplomaUrl,

  });

  alert("Güncellendi ✅");

  window.location.href = "account_gynecologist.html";
};
