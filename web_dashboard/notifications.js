import { auth, db } from "./app.js";

import {
  collection,
  query,
  where,
  orderBy,
  onSnapshot,
  doc,
  updateDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

/* TIME AGO */
function timeAgo(date) {

  const now = new Date();
  const diff = (now - date) / 1000;

  if (diff < 60) return "Az önce";
  if (diff < 3600) return Math.floor(diff / 60) + " dk önce";
  if (diff < 86400) return Math.floor(diff / 3600) + " saat önce";
  if (diff < 604800) return Math.floor(diff / 86400) + " gün önce";

  return date.toLocaleDateString();
}

/* ICON */
function getIcon(type) {
  if (type === "risk_alert") return "⚠️";
  if (type === "message") return "💬";
  return "🔔";
}

function getIconClass(type) {
  if (type === "risk_alert") return "risk";
  if (type === "message") return "message";
  return "general";
}

/* AUTH */
onAuthStateChanged(auth, (user) => {

  if (!user) {
    location.href = "login.html";
    return;
  }

  loadNotifications(user.uid);
});

/* LOAD */
function loadNotifications(uid) {

  const list = document.getElementById("notificationList");

  const q = query(
    collection(db, "notification"),
    where("uid", "==", uid),
    orderBy("createdAt", "desc")
  );

  onSnapshot(q, (snapshot) => {

    list.innerHTML = "";

    if (snapshot.empty) {
      list.innerHTML = "<p>Bildirim yok</p>";
      return;
    }

    snapshot.forEach(docSnap => {

      const data = docSnap.data();

      const isRead = data.isRead ?? false;
      const type = data.type ?? "general";
      const title = data.title ?? "";
      const message = data.message ?? "";
      const date = data.createdAt?.toDate();

      const div = document.createElement("div");

      div.className = "notification-card " + (isRead ? "" : "unread");

      div.innerHTML = `
        <div class="icon ${getIconClass(type)}">
          ${getIcon(type)}
        </div>

        <div class="content">
          <div class="title">${title}</div>
          <div class="message">${message}</div>
          <div class="time">${date ? timeAgo(date) : ""}</div>
        </div>

        ${!isRead ? `<div class="dot"></div>` : ""}
      `;

      /* CLICK */
      div.onclick = async () => {

        if (!isRead) {
          await updateDoc(docSnap.ref, {
            isRead: true
          });
        }
      };

      list.appendChild(div);
    });

  });
}
