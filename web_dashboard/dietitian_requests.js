import {
  collection,
  addDoc,
  query,
  where,
  getDocs,
  doc,
  updateDoc,
  getDoc,
  serverTimestamp
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";
import { t } from "./i18n.js";

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
      container.innerHTML = t("noRequests");
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
          <div class="req-id">${t("patientId")}: ${clientId}</div>
          <div class="req-id">${t("requestId")}: ${requestId}</div>

          <div class="req-grid">
            ${detail(t("email"), user.email)}
            ${detail(t("phone"), user.phone)}
            ${detail(t("pregnancyWeek"), user.hafta)}
            ${detail(t("height"), formatUnit(user.boy, "cm"))}
            ${detail(t("weight"), formatUnit(user.kilo, "kg"))}
            ${detail("BMI", user.bmi || user.BMI)}
            ${detail(t("risk"), riskText(user.riskLevel))}
            ${detail(t("allergy"), user.allergy || user.alerji)}
          </div>
        </div>

        <div class="req-actions">
          <button class="btn btn-approve">${t("accept")}</button>
          <button class="btn btn-reject">${t("reject")}</button>
        </div>
      `;

      div.querySelector(".btn-approve").onclick = () =>
        approveRequest(requestId, clientId, uid);
      div.querySelector(".btn-reject").onclick = () => rejectRequest(requestId);

      container.appendChild(div);
    }
  } catch (err) {
    console.error(err);
    container.innerHTML = t("genericError");
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

    await createNotification(
      clientId,
      t("dietitian"),
      t("doctorApprovalMessage"),
      requestId
    );

    alert(t("accepted"));
    location.reload();
  } catch (err) {
    console.error(err);
  }
}

async function rejectRequest(requestId) {
  try {
    const requestSnap = await getDoc(doc(db, "expert_requests", requestId));
    const clientId = requestSnap.exists() ? requestSnap.data().clientId : "";

    await updateDoc(doc(db, "expert_requests", requestId), {
      status: "rejected",
      rejectedAt: serverTimestamp()
    });

    if (clientId) {
      await createNotification(
        clientId,
        t("requestRejectedTitle"),
        t("requestRejectedMessage"),
        requestId
      );
    }

    alert(t("rejectedShort"));
    location.reload();
  } catch (err) {
    console.error(err);
  }
}

async function createNotification(targetUid, title, message, requestId) {
  await addDoc(collection(db, "notification"), {
    uid: targetUid,
    type: "expert_request",
    requestId,
    title: title || t("notification"),
    message: message || "",
    actionPage: "expert_search.html",
    isRead: false,
    createdAt: serverTimestamp()
  });
}

function fullName(user) {
  const name = `${user.name || ""} ${user.surname || ""}`.trim();
  return name || t("anonymousPatient");
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
  if (value === "high") return t("high");
  if (value === "medium") return t("medium");
  if (value === "normal") return t("normal");
  return value || "-";
}
