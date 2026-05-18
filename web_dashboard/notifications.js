import { auth, db, getNotificationActionPage } from "./app.js";
import { t, getLanguage } from "./i18n.js";

import {
  collection,
  query,
  where,
  orderBy,
  onSnapshot,
  doc,
  getDoc,
  updateDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

function timeAgo(date) {
  const now = new Date();
  const diff = (now - date) / 1000;

  if (diff < 60) return t("justNow");
  if (diff < 3600) return t("minutesAgo", { count: Math.floor(diff / 60) });
  if (diff < 86400) return t("hoursAgo", { count: Math.floor(diff / 3600) });
  if (diff < 604800) return t("daysAgo", { count: Math.floor(diff / 86400) });

  const locale = getLanguage() === "tr" ? "tr-TR" : "en-US";

  return date.toLocaleDateString(locale, {
    day: "2-digit",
    month: "long",
    year: "numeric"
  });
}

function getIcon(type) {
  if (type === "risk_alert") return "!";
  if (type === "message") return "M";
  if (type === "expert_application") return "E";
  return "N";
}

function getIconClass(type) {
  if (type === "risk_alert") return "risk";
  if (type === "message") return "message";
  if (type === "expert_application") return "expert";
  return "general";
}

function normalizeNotificationText(data) {
  const title = data.title || "";
  const message = data.message || "";

  if (data.type === "risk_alert") {
    return {
      title: t("riskWarning"),
      message: translateKnownMessage(message)
    };
  }

  if (data.type === "expert_application") {
    return {
      title: t("expertApplicationReceivedTitle"),
      message: t("expertApplicationReceivedMessage")
    };
  }

  return {
    title: translateKnownTitle(title),
    message: translateKnownMessage(message)
  };
}

function translateKnownTitle(title) {
  const normalized = String(title).trim().toLowerCase();

  if (normalized.includes("hafta") && normalized.includes("bilgilendirmesi")) {
    const week = normalized.match(/\d+/)?.[0] || "";
    return t("weeklyInfoTitle", { week });
  }

  if (normalized === "risk uyarısı" || normalized === "risk warning") {
    return t("riskWarning");
  }

  if (normalized === "yeni mesaj" || normalized === "new message") {
    return t("newMessage");
  }

  return title || t("notification");
}

function translateKnownMessage(message) {
  const raw = String(message || "").trim();
  const normalized = raw.toLowerCase();

  if (normalized.includes("hafta") && normalized.includes("sağlık")) {
    const week = normalized.match(/\d+/)?.[0] || "";
    return t("weeklyInfoMessage", { week });
  }

  if (normalized.includes("diyabet riski yüksek")) {
    return t("diabetesHighMessage");
  }

  if (normalized.includes("preeklampsi riski yüksek")) {
    return t("preeclampsiaHighMessage");
  }

  if (normalized.includes("preterm riski yüksek")) {
    return t("pretermHighMessage");
  }

  return raw;
}

onAuthStateChanged(auth, async (user) => {
  if (!user) {
    location.href = "login.html";
    return;
  }

  const role = await getCurrentUserRole(user.uid);
  loadNotifications(user.uid, role);
});

async function getCurrentUserRole(uid) {
  const userDoc = await getDoc(doc(db, "users", uid));
  return userDoc.exists() ? userDoc.data().role : "";
}

function loadNotifications(uid, role) {
  const list = document.getElementById("notificationList");

  const q = query(
    collection(db, "notification"),
    where("uid", "==", uid),
    orderBy("createdAt", "desc")
  );

  onSnapshot(q, (snapshot) => {
    list.innerHTML = "";

    if (snapshot.empty) {
      list.innerHTML = `
        <div class="empty-state">
          <div><span class="notification-mark" aria-hidden="true"></span></div>
          <h3>${t("noNotifications")}</h3>
        </div>
      `;
      return;
    }

    snapshot.forEach(docSnap => {
      const data = docSnap.data();

      const isRead = data.isRead ?? false;
      const type = data.type ?? "general";
      const date = data.createdAt?.toDate();

      const text = normalizeNotificationText(data);
      const actionPage = getNotificationActionPage(data, role);

      const div = document.createElement("div");
      div.className = "notification-card " + (isRead ? "" : "unread");
      if (actionPage) div.classList.add("clickable");

      div.innerHTML = `
        <div class="icon ${getIconClass(type)}">
          ${getIcon(type)}
        </div>

        <div class="notification-content">
          <div class="notification-title">${text.title}</div>
          <div class="notification-message">${text.message}</div>
          <div class="notification-time">${date ? timeAgo(date) : ""}</div>
        </div>

        ${actionPage ? `<span class="notification-action">${t("open")}</span>` : ""}

        ${!isRead ? `<div class="dot"></div>` : ""}
      `;

      div.onclick = async () => {
        if (!isRead) {
          await updateDoc(docSnap.ref, {
            isRead: true
          });
        }

        if (actionPage) {
          window.location.href = actionPage;
        }
      };

      list.appendChild(div);
    });
  });
}
