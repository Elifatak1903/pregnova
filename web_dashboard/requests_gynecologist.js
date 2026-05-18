import { auth, db } from "./app.js";
import { t } from "./i18n.js";

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
    title: title || t("notification"),
    message: message || "",
    actionPage: "expert_search.html",
    isRead: false,
    createdAt: serverTimestamp()
  });
}

async function loadRequests(uid) {
  const container = document.getElementById("requestsList");
  if (!container) return;

  container.innerHTML = t("loading");
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
      container.innerHTML = t("noPendingRequests");
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
          <span>${t("patientId")}: ${clientId}</span>
          <span>${t("requestId")}: ${item.id}</span>

          <div class="request-grid">
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

        <div class="request-actions">
          <button class="accept">${t("accept")}</button>
          <button class="reject">${t("reject")}</button>
        </div>
      `;

      div.querySelector(".accept").onclick = async () => {
        if (!confirm(t("confirmAcceptClient"))) return;

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
            t("doctorApprovalTitle"),
            t("doctorApprovalMessage")
          );

          alert(t("clientAccepted"));
          loadRequests(uid);
        } catch (e) {
          console.error("Accept error:", e);
          alert(t("errorWithMessage", { message: e.message }));
        }
      };

      div.querySelector(".reject").onclick = async () => {
        if (!confirm(t("confirmRejectRequest"))) return;

        try {
          await updateDoc(doc(db, "expert_requests", item.id), {
            status: "rejected",
            rejectedAt: serverTimestamp()
          });

          await createNotification(
            clientId,
            t("requestRejectedTitle"),
            t("requestRejectedMessage")
          );

          alert(t("requestRejected"));
          loadRequests(uid);
        } catch (e) {
          console.error("Reject error:", e);
          alert(t("errorWithMessage", { message: e.message }));
        }
      };

      container.appendChild(div);
    }
  } catch (e) {
    console.error("LOAD ERROR:", e);
    container.innerHTML = t("genericError");
  }
}

function fullName(user) {
  const name = `${user.name || ""} ${user.surname || ""}`.trim();
  return name || t("anonymousPatient");
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
  if (value === "high") return t("high");
  if (value === "medium") return t("medium");
  if (value === "normal") return t("normal");
  return value || "-";
}
