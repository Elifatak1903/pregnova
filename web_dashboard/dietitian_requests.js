import {
  collection,
  query,
  where,
  getDocs,
  doc,
  updateDoc,
  getDoc,
  serverTimestamp
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;

auth.onAuthStateChanged(async (user) => {
  if (!user) {
    window.location.href = "login.html";
    return;
  }

  loadRequests(user.uid);
});

async function loadRequests(uid) {
  const container = document.getElementById("requestList");

  try {
    const q = query(
      collection(db, "expert_requests"),
      where("expertId", "==", uid),
      where("status", "==", "pending")
    );

    const snapshot = await getDocs(q);

    if (snapshot.empty) {
      container.innerHTML = "İstek yok";
      return;
    }

    container.innerHTML = "";

    for (const docSnap of snapshot.docs) {
      const request = docSnap.data();
      const requestId = docSnap.id;
      const clientId = request.clientId;

      const userSnap = await getDoc(doc(db, "users", clientId));
      const user = userSnap.data() || {};

      const div = document.createElement("div");
      div.className = "request-card";

      div.innerHTML = `
        <div class="req-info">
          <div class="req-name">${fullName(user)}</div>
          <div class="req-id">Hasta ID: ${clientId}</div>
          <div class="req-id">İstek ID: ${requestId}</div>

          <div class="req-grid">
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

        <div class="req-actions">
          <button class="btn btn-approve">Kabul</button>
          <button class="btn btn-reject">Reddet</button>
        </div>
      `;

      div.querySelector(".btn-approve").onclick = () =>
        approveRequest(requestId, clientId, uid);
      div.querySelector(".btn-reject").onclick = () => rejectRequest(requestId);

      container.appendChild(div);
    }
  } catch (err) {
    console.error(err);
    container.innerHTML = "Hata oluştu";
  }
}

async function approveRequest(requestId, clientId, expertId) {
  try {
    await updateDoc(doc(db, "expert_requests", requestId), {
      status: "approved",
      approvedAt: serverTimestamp()
    });

    await updateDoc(doc(db, "users", clientId), {
      assignedDietitian: expertId
    });

    alert("Kabul edildi");
    location.reload();
  } catch (err) {
    console.error(err);
  }
}

async function rejectRequest(requestId) {
  try {
    await updateDoc(doc(db, "expert_requests", requestId), {
      status: "rejected",
      rejectedAt: serverTimestamp()
    });

    alert("Reddedildi");
    location.reload();
  } catch (err) {
    console.error(err);
  }
}

function fullName(user) {
  const name = `${user.name || ""} ${user.surname || ""}`.trim();
  return name || "İsimsiz hasta";
}

function detail(label, value) {
  return `
    <div class="req-detail">
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
