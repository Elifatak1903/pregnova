import { t } from "./i18n.js";

import {
  doc,
  getDoc,
  updateDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";
import {
  getStorage,
  ref,
  uploadBytes,
  getDownloadURL
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-storage.js";

const db = window.db;
const auth = window.auth;
const storage = getStorage();

let diplomaUrl = null;

auth.onAuthStateChanged(async (user) => {
  if (!user) {
    location.href = "login.html";
    return;
  }

  const snap = await getDoc(doc(db, "users", user.uid));
  const data = snap.data() || {};

  document.getElementById("name").value = data.name || "";
  document.getElementById("email").value = user.email || "";
  document.getElementById("expertise").value = data.expertise || "";
  document.getElementById("experience").value = data.experience || "";
  document.getElementById("institution").value = data.institution || "";

  diplomaUrl = data.diplomaUrl || data.diploma || null;

  if (diplomaUrl) {
    document.getElementById("uploadStatus").innerText = t("diplomaUploaded");
  }
});

document.getElementById("uploadBtn").onclick = async () => {
  const input = document.createElement("input");
  input.type = "file";
  input.accept = "image/*,.pdf";

  input.onchange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    try {
      const user = auth.currentUser;
      if (!user) return;

      document.getElementById("uploadStatus").innerText = t("loading");

      const path = `diplomas/${user.uid}/${Date.now()}_${sanitizeFileName(file.name)}`;
      const storageRef = ref(storage, path);

      await uploadBytes(storageRef, file);
      diplomaUrl = await getDownloadURL(storageRef);
      document.getElementById("uploadStatus").innerText = t("diplomaUploaded");
    } catch (error) {
      console.error("Diploma upload error:", error);
      document.getElementById("uploadStatus").innerText = t("uploadError");
    }
  };

  input.click();
};

function sanitizeFileName(name) {
  return name.replace(/[^a-zA-Z0-9._-]/g, "_");
}

window.saveData = async () => {
  const user = auth.currentUser;
  if (!user) return;

  await updateDoc(doc(db, "users", user.uid), {
    name: document.getElementById("name").value,
    expertise: document.getElementById("expertise").value,
    experience: document.getElementById("experience").value,
    institution: document.getElementById("institution").value,
    diploma: diplomaUrl,
    diplomaUrl
  });

  alert(t("updated"));
  window.location.href = "account_dietitian.html";
};
