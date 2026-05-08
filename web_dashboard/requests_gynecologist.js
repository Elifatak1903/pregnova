import { auth, db } from "./app.js";

import {
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
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

onAuthStateChanged(auth, (user) => {
  if (!user) {
    window.location.href = "login.html";
    return;
  }

  loadRequests(user.uid);
});

async function createNotification(targetUid, title, message) {
  await addDoc(collection(db, "notification"), {
    uid: targetUid,
    type: "expert_request",
    title: title || "Bildirim",
    message: message || "",
    isRead: false,
    createdAt: serverTimestamp()
  });
}

async function loadRequests(uid) {
  const container = document.getElementById("requestsList");
  if (!container) return;

  container.innerHTML = "Yükleniyor...";
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
      container.innerHTML = "Bekleyen istek yok";
      return;
    }

    for (const item of snap.docs) {
      const request = item.data();
      const clientId = request.clientId;

      const userDoc = await getDoc(doc(db, "users", clientId));
      const user = userDoc.data() || {};

      const div = document.createElement("div");
      div.className = "request-card";

      div.innerHTML = `
        <div class="request-info">
          <b>${fullName(user)}</b>
          <span>Hasta ID: ${clientId}</span>
          <span>İstek ID: ${item.id}</span>

          <div class="request-grid">
            ${detail("E-posta", user.email)}
            ${detail("Telefon", user.phone)}
            ${detail("Gebelik haftası", user.hafta)}
            ${detail("Boy", formatUnit(user.boy, "cm"))}
            ${detail("Kilo", formatUnit(user.kilo, "kg"))}
            ${detail("BMI", user.bmi || user.BMI)}
            ${detail("Risk", riskText(user.riskLevel))}
            ${detail("Alerji", user.allergy || user.alerji)}
          </div>
        </div>

        <div class="request-actions">
          <button class="accept">Kabul</button>
          <button class="reject">Reddet</button>
        </div>
      `;

      div.querySelector(".accept").onclick = async () => {
        if (!confirm("Danışanı kabul etmek istiyor musunuz?")) return;

        try {
          await updateDoc(doc(db, "expert_requests", item.id), {
            status: "approved",
            approvedAt: serverTimestamp()
          });

          await updateDoc(doc(db, "users", clientId), {
            assignedDoctor: uid
          });

          await createNotification(
            clientId,
            "Doktor Onayı",
            "Doktorunuz sizi danışan olarak kabul etti."
          );

          alert("Danışan kabul edildi");
          loadRequests(uid);
        } catch (e) {
          console.error("Kabul hatası:", e);
          alert("Hata: " + e.message);
        }
      };

      div.querySelector(".reject").onclick = async () => {
        if (!confirm("İsteği reddetmek istiyor musunuz?")) return;

        try {
          await updateDoc(doc(db, "expert_requests", item.id), {
            status: "rejected",
            rejectedAt: serverTimestamp()
          });

          await createNotification(
            clientId,
            "İstek Reddedildi",
            "Gönderdiğiniz danışan isteği reddedildi."
          );

          alert("İstek reddedildi");
          loadRequests(uid);
        } catch (e) {
          console.error("Red hatası:", e);
          alert("Hata: " + e.message);
        }
      };

      container.appendChild(div);
    }
  } catch (e) {
    console.error("LOAD ERROR:", e);
    container.innerHTML = "Hata oluştu";
  }
}

function fullName(user) {
  const name = `${user.name || ""} ${user.surname || ""}`.trim();
  return name || "İsimsiz hasta";
}

function detail(label, value) {
  return `
    <div class="request-detail">
      <span>${label}</span>
      <strong>${value || "-"}</strong>
    </div>
  `;
}

function formatUnit(value, unit) {
  return value ? `${value} ${unit}` : "-";
}

function riskText(value) {
  if (value === "high") return "Yüksek";
  if (value === "medium") return "Orta";
  if (value === "normal") return "Normal";
  return value || "-";
}
