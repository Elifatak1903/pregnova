import { initializeApp } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-app.js";

import {
  getFirestore,
  collection,
  getDocs,
  query,
  where,
  doc,
  getDoc,
  updateDoc,
  serverTimestamp,
  addDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  getAuth,
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

const app = initializeApp({
  apiKey: "AIzaSyBHVmFtmXLe6BcN620XCmjv9vMOkcjeFdM",
  authDomain: "pregnova-38391.firebaseapp.com",
  projectId: "pregnova-38391"
});

const db = getFirestore(app);
const auth = getAuth(app);

onAuthStateChanged(auth, (user) => {
  if (!user) {
    window.location.href = "login.html";
    return;
  }

  console.log("✅ Expert giriş yaptı:", user.uid);

  loadRequests(user.uid);
});

async function createNotification(targetUid, title, message) {

  await addDoc(collection(db, "notification"), {
    uid: targetUid,
    title: title,
    message: message,
    isRead: false,
    createdAt: serverTimestamp()
  });

}

async function loadRequests(uid) {

  const container = document.getElementById("requestsList");
  if (!container) return;

  container.innerHTML = "Yükleniyor... ⏳";
  container.className = "requests-container";

  try {

    const q = query(
      collection(db, "expert_requests"),
      where("expertId", "==", uid),
      where("status", "==", "pending")
    );

    const snap = await getDocs(q);

    container.innerHTML = "";

    if (snap.empty) {
      container.innerHTML = "Bekleyen istek yok 👍";
      return;
    }

    for (const item of snap.docs) {

      const req = item.data();
      const clientId = req.clientId;

      const userDoc = await getDoc(doc(db, "users", clientId));
      const data = userDoc.data() || {};

      const name = data.name || "İsimsiz";
      const surname = data.surname || "";
      const hafta = data.hafta || "-";

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

      div.querySelector(".accept").onclick = async () => {

        if (!confirm("Danışanı kabul etmek istiyor musunuz?")) return;

        try {

          console.log("✔️ Kabul ediliyor:", item.id);

          await updateDoc(doc(db, "expert_requests", item.id), {
            status: "approved",
            approvedAt: serverTimestamp()
          });

          await updateDoc(doc(db, "users", clientId), {
            assignedDoctor: uid
          });

          await createNotification(
            clientId,
            "👩‍⚕️ Doktor Onayı",
            "Doktorunuz sizi danışan olarak kabul etti 🎉"
          );

          alert("Danışan kabul edildi ✅");

          loadRequests(uid);

        } catch (e) {
          console.error("❌ Kabul hatası:", e);
          alert("Hata: " + e.message);
        }
      };

      div.querySelector(".reject").onclick = async () => {

        if (!confirm("İsteği reddetmek istiyor musunuz?")) return;

        try {

          console.log("❌ Reddediliyor:", item.id);

          await updateDoc(doc(db, "expert_requests", item.id), {
            status: "rejected",
            rejectedAt: serverTimestamp()
          });

          await createNotification(
            clientId,
            "❌ İstek Reddedildi",
            "Gönderdiğiniz danışan isteği reddedildi."
          );

          alert("İstek reddedildi ❌");

          loadRequests(uid);

        } catch (e) {
          console.error("❌ Red hatası:", e);
          alert("Hata: " + e.message);
        }
      };

      container.appendChild(div);
    }

  } catch (e) {

    console.error(" LOAD ERROR:", e);
    container.innerHTML = "Hata oluştu ❌";

  }
}