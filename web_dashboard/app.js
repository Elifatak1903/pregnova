import { initializeApp } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-app.js";
import { getAuth, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";
import { renderSidebar } from "./sidebar.js";
import { applyTranslations, getLanguage, setLanguage, t } from "./i18n.js";
import {
  getFirestore,
  doc,
  getDoc,
  collection,
  query,
  where,
  orderBy,
  onSnapshot,
  updateDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const app = initializeApp({
  apiKey: "AIzaSyBHVmFtmXLe6BcN620XCmjv9vMOkcjeFdM",
  authDomain: "pregnova-38391.firebaseapp.com",
  projectId: "pregnova-38391"
});

const auth = getAuth(app);
const db = getFirestore(app);
export { app, auth, db };

const MAX_DROPDOWN_NOTIFICATIONS = 7;

ensureSidebarCssLast();

/* NAV */
window.go = function(page) {
  window.location.href = page;
};

window.logout = function() {
  window.location.href = "login.html";
};

window.db = db;
window.auth = auth;
window.pregnovaT = t;
window.setPregnovaLanguage = setLanguage;
window.getPregnovaLanguage = getLanguage;

/* AUTH CONTROL */
onAuthStateChanged(auth, async (user) => {
  if (!user) return;

  loadNotifications(user.uid);

  const userRef = doc(db, "users", user.uid);
  const userDoc = await getDoc(userRef);

  if (!userDoc.exists()) return;

  const role = userDoc.data().role;

  document.body.classList.remove("pregnant", "dietitian", "gynecologist", "admin");
  document.body.classList.add(role || "pregnant");
  document.body.classList.add("ready");
  renderSidebar(role);
  applyTranslations();
});

document.addEventListener("DOMContentLoaded", () => applyTranslations());
window.addEventListener("pregnova:languageChanged", () => applyTranslations());

/* NOTIFICATION */
window.toggleNotifications = function(e) {
  e.stopPropagation();
  const dropdown = e.currentTarget.querySelector(".notif-dropdown");
  dropdown.classList.toggle("hidden");
};

window.addEventListener("click", () => {
  const dropdown = document.getElementById("notifDropdown");
  if (dropdown) dropdown.classList.add("hidden");
});

function loadNotifications(uid) {

  const list = document.getElementById("notifList");
  const badge = document.querySelector(".badge");

  if (!list || !badge) return;

  const q = query(
    collection(db, "notification"),
    where("uid", "==", uid),
    orderBy("createdAt", "desc")
  );

  onSnapshot(q, async (snapshot) => {

    list.innerHTML = "";
    const role = await getCurrentUserRole(uid);

    let unread = 0;

    snapshot.forEach(docSnap => {
      if (!docSnap.data().isRead) unread++;
    });

    const dropdownDocs = snapshot.docs.slice(0, MAX_DROPDOWN_NOTIFICATIONS);

    dropdownDocs.forEach(docSnap => {

      const data = docSnap.data();
      const actionPage = getNotificationActionPage(data, role);

      const div = document.createElement("div");
      div.className = "notif-item";
      if (actionPage) div.classList.add("clickable");

      div.innerHTML = `
        <b>${data.title || t("notification")}</b><br>
        <small>${data.message || ""}</small>
      `;

      div.addEventListener("click", async (event) => {
        event.stopPropagation();

        if (data.isRead !== true) {
          await updateDoc(docSnap.ref, { isRead: true });
        }

        if (actionPage) {
          window.location.href = actionPage;
        }
      });

      list.appendChild(div);
    });

    if (unread === 0) {
      badge.style.display = "none";
    } else {
      badge.style.display = "flex";
      badge.innerText = unread > 99 ? "99+" : unread;
    }

  });
}

async function getCurrentUserRole(uid) {
  const userDoc = await getDoc(doc(db, "users", uid));
  return userDoc.exists() ? userDoc.data().role : "";
}

export function getNotificationActionPage(data, role = "") {
  if (data.actionPage) return data.actionPage;

  const type = data.type || "general";
  const patientId = data.patientId || data.clientId;

  if (type === "weekly_info") return "pregnant.html";

  if (type === "risk_alert") {
    if (role === "gynecologist") {
      return patientId
        ? `patient_detail.html?uid=${encodeURIComponent(patientId)}`
        : "son_olcumler.html";
    }

    if (role === "dietitian") {
      return patientId
        ? `client_detail.html?id=${encodeURIComponent(patientId)}`
        : "son_analizler.html";
    }

    return "measurement_history.html";
  }

  if (type === "expert_application") {
    return role === "admin" ? "admin_requests.html" : "expert_application.html";
  }

  if (type === "expert_request") {
    if (role === "gynecologist") return "requests_gynecologist.html";
    if (role === "dietitian") return "dietitian_requests.html";
    return "expert_search.html";
  }

  if (type === "message") {
    if (role === "gynecologist") return "messages_gynecologist.html";
    if (role === "dietitian") return "messages_dietitian.html";
    return "messages_pregnant.html";
  }

  return "";
}

function ensureSidebarCssLast() {
  const href = "css/sidebar.css";
  const existing = [...document.querySelectorAll("link[rel='stylesheet']")]
    .find(link => link.getAttribute("href") === href);

  if (!existing) return;

  existing.remove();
  document.head.appendChild(existing);
}
