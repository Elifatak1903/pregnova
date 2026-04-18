import { initializeApp } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-app.js";

import {
  getFirestore,
  collection,
  getDocs,
  query,
  where,
  doc,
  getDoc,
  updateDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  getAuth,
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

/* 🔥 FIREBASE INIT */
const app = initializeApp({
  apiKey: "AIzaSyBHVmFtmXLe6BcN620XCmjv9vMOkcjeFdM",
  authDomain: "pregnova-38391.firebaseapp.com",
  projectId: "pregnova-38391"
});

const db = getFirestore(app);
const auth = getAuth(app);

/* 🔥 AUTH */
onAuthStateChanged(auth, (user) => {
  if (!user) {
    window.location.href = "login.html";
    return;
  }

  loadRequests(user.uid);
});

/* ========================= */
/* 🔥 LOAD REQUESTS */
/* ========================= */
async function loadRequests(uid) {

  const container = document.getElementById("requestsList");
  container.className = "requests-container";

  const snap = await getDocs(query(
    collection(db, "expert_requests"),
    where("expertId", "==", uid),
    where("status", "==", "pending")
  ));

  container.innerHTML = "";

  if (snap.empty) {
    container.innerHTML = "Bekleyen istek yok.";
    return;
  }

  for (const item of snap.docs) {

    const clientId = item.data().clientId;

    const userDoc = await getDoc(doc(db, "users", clientId));
    const data = userDoc.data();

    const name = data?.name || "";
    const surname = data?.surname || "";
    const hafta = data?.hafta || "-";

    const div = document.createElement("div");
    div.className = "request-card";

    div.innerHTML = `
      <div class="request-info">
        <b>${name} ${surname}</b>
        <span>Gebelik Haftası: ${hafta}</span>
      </div>

      <div class="request-actions">
        <button class="accept">Kabul</button>
        <button class="reject">Reddet</button>
      </div>
    `;

    /* ✅ KABUL */
    div.querySelector(".accept").onclick = async () => {

      await updateDoc(doc(db, "expert_requests", item.id), {
        status: "approved"
      });

      await updateDoc(doc(db, "users", clientId), {
        assignedDoctor: uid
      });

      loadRequests(uid);
    };

    /* ❌ REDDET */
    div.querySelector(".reject").onclick = async () => {

      await updateDoc(doc(db, "expert_requests", item.id), {
        status: "rejected"
      });

      loadRequests(uid);
    };

    container.appendChild(div);
  }
}