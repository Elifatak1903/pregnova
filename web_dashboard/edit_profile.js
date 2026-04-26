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
  if (!user) return location.href = "login.html";

  const snap = await getDoc(doc(db, "users", user.uid));
  const data = snap.data();

  document.getElementById("name").value = data.name || "";
  document.getElementById("email").value = user.email || "";
  document.getElementById("expertise").value = data.expertise || "";
  document.getElementById("experience").value = data.experience || "";
  document.getElementById("institution").value = data.institution || "";

  diplomaUrl = data.diploma || null;

  if (diplomaUrl) {
    document.getElementById("uploadStatus").innerText =
      "Diploma yüklendi ✅";
  }
});

/* UPLOAD */
document.getElementById("uploadBtn").onclick = async () => {

  const input = document.createElement("input");
  input.type = "file";

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
    expertise: document.getElementById("expertise").value,
    experience: document.getElementById("experience").value,
    institution: document.getElementById("institution").value,
    diploma: diplomaUrl
  });

  alert("Güncellendi ✅");

  window.location.href = "account_dietitian.html";
};