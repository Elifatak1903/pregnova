import {
  getFirestore,
  doc,
  getDoc,
  setDoc,
  collection,
  addDoc,
  serverTimestamp
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  getAuth
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

import {
  getStorage,
  ref,
  uploadBytes,
  getDownloadURL
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-storage.js";

const db = window.db;
const auth = window.auth;
const storage = getStorage();

const form = document.getElementById("applicationForm");
const statusView = document.getElementById("statusView");
const fileInput = document.getElementById("fileInput");
const fileName = document.getElementById("fileName");
const submitBtn = document.getElementById("submitBtn");

let selectedFile = null;

fileInput.addEventListener("change", () => {
  selectedFile = fileInput.files[0];
  fileName.textContent = selectedFile ? selectedFile.name : "";
});

auth.onAuthStateChanged(async (user) => {
  if (!user) return;

  try {
    const refDoc = doc(db, "expert_applications", user.uid);
    const snap = await getDoc(refDoc);

    if (!snap.exists()) {
      form.classList.remove("hidden");
      return;
    }

    const status = snap.data()?.status;

    if (status === "pending") {
      statusView.textContent = "⏳ Başvurunuz inceleniyor...";
    } else if (status === "approved") {
      statusView.textContent = "✅ Zaten uzmansınız!";
    } else if (status === "rejected") {
      statusView.textContent = "❌ Başvurunuz reddedildi. Tekrar deneyebilirsiniz.";
      form.classList.remove("hidden");
    }

  } catch (err) {
    console.error("Status kontrol hatası:", err);
  }
});

form.addEventListener("submit", async (e) => {
  e.preventDefault();

  const user = auth.currentUser;
  if (!user) return;

  if (!selectedFile) {
    alert("Lütfen belge yükleyin");
    return;
  }

  submitBtn.disabled = true;
  submitBtn.textContent = "Gönderiliyor...";

  try {
    const path = `expert_documents/${Date.now()}_${selectedFile.name}`;
    const storageRef = ref(storage, path);

    await uploadBytes(storageRef, selectedFile);
    const url = await getDownloadURL(storageRef);

    const data = {
      uid: user.uid,
      email: user.email,
      role: document.getElementById("role").value,
      licenseNumber: document.getElementById("licenseNo").value,
      experience: document.getElementById("experience").value,
      phone: document.getElementById("phone").value,
      hospital: document.getElementById("hospital").value,
      city: document.getElementById("city").value,
      documentUrl: url,
      status: "pending",
      createdAt: serverTimestamp()
    };

    await setDoc(
      doc(db, "expert_applications", user.uid),
      data,
      { merge: true }
    );

    await addDoc(collection(db, "notification"), {
      uid: user.uid,
      title: "Uzman Başvurusu Alındı",
      message: "Başvurunuz alındı. Onay bekleniyor.",
      isRead: false,
      createdAt: serverTimestamp()
    });

    alert("Başvurunuz alındı");
    location.reload();

  } catch (err) {
    console.error(err);
    alert(err.message);
  } finally {
    submitBtn.disabled = false;
    submitBtn.textContent = "Başvuruyu Gönder";
  }
});