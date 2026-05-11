import { auth, db } from "./app.js";
import { t } from "./i18n.js";

import {
  onAuthStateChanged,
  signOut
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

import {
  doc,
  getDoc,
  getDocs,
  addDoc,
  collection,
  query,
  where,
  orderBy,
  onSnapshot,
  updateDoc,
  serverTimestamp
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

/* NAVIGATION */
window.go = function(page) {
  window.location.href = page;
};

window.logout = async function() {
  await signOut(auth);
  window.location.href = "login.html";
};

/* AUTH CONTROL */
onAuthStateChanged(auth, async (user) => {

  if (!user) {
    window.location.href = "login.html";
    return;
  }

  const uid = user.uid;

  document.body.classList.add("pregnant");
  document.body.classList.add("ready");

  await loadUserData(uid);
  loadRisk(uid);
  loadNotifications(uid);
});

/* HAFTA */
async function loadUserData(uid) {

  const userRef = doc(db, "users", uid);
  const snap = await getDoc(userRef);

  if (!snap.exists()) return;

  const data = snap.data();
  const hafta = calculatePregnancyWeek(data);

  if (data.profilTamamlandi !== true) {
    showProfileModal();
  }

  if (hafta !== data.hafta) {
    await updateDoc(userRef, { hafta });
  }

  await createWeeklyNotification(uid, hafta);

  const weekEl = document.getElementById("weekText");

  if (weekEl) {
    weekEl.innerText = t("weekValue", { week: hafta });
  }
}

function calculatePregnancyWeek(data) {
  const start = data.gebelikBaslangicTarihi;

  if (!start) {
    return data.hafta || 1;
  }

  const startDate = start.toDate ? start.toDate() : new Date(start);
  const diffMs = Date.now() - startDate.getTime();
  const week = Math.floor(diffMs / (1000 * 60 * 60 * 24 * 7));

  return Math.min(Math.max(week, 1), 42);
}

async function createWeeklyNotification(uid, week) {
  if (!week) return;

  const existing = await getDocs(query(
    collection(db, "notification"),
    where("uid", "==", uid),
    where("type", "==", "weekly_info"),
    where("week", "==", week)
  ));

  if (!existing.empty) return;

  await addDoc(collection(db, "notification"), {
    uid,
    week,
    type: "weekly_info",
    title: t("weeklyInfoTitle", { week }),
    message: t("weeklyInfoMessage", { week }),
    isRead: false,
    createdAt: serverTimestamp()
  });
}

function showProfileModal() {
  const modal = document.getElementById("profileModal");
  if (modal) modal.classList.remove("hidden");
}

window.closeProfileModal = function() {
  const modal = document.getElementById("profileModal");
  if (modal) modal.classList.add("hidden");
};

/* RISK DASHBOARD */
function loadRisk(uid) {

  const q = query(
    collection(db, "risk_olcumleri"),
    where("uid", "==", uid),
    orderBy("tarih", "desc")
  );

  onSnapshot(q, (snapshot) => {

    if (snapshot.empty) return;

    const data = snapshot.docs[0].data();
    const box = document.getElementById("riskBox");

    if (!box) return;

    box.innerHTML = `
      <div>${t("preeclampsia")}: ${colorRisk(data.preeklampsiRisk)}</div>
      <div>${t("diabetes")}: ${colorRisk(data.diyabetRisk)}</div>
      <div>${t("preterm")}: ${colorRisk(data.pretermRisk)}</div>
    `;
  });
}

/* RISK RENK */
function colorRisk(risk) {
  if (!risk) return "-";

  if (risk === "HIGH")
    return `<span style="color:#EF5350">${t("high")}</span>`;

  if (risk === "MEDIUM")
    return `<span style="color:#FFA000">${t("medium")}</span>`;

  return `<span style="color:#00BFA5">${t("low")}</span>`;
}

/* NOTIFICATIONS */
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

  onSnapshot(q, (snapshot) => {

    list.innerHTML = "";

    let unread = 0;

    snapshot.forEach(docSnap => {
      if (!docSnap.data().isRead) unread++;
    });

    snapshot.docs.slice(0, 7).forEach(docSnap => {

      const data = docSnap.data();

      const div = document.createElement("div");
      div.className = "notif-item";

      div.innerHTML = `
        <b>${data.title || t("notification")}</b><br>
        <small>${data.message || ""}</small>
      `;

      div.onclick = async () => {

        if (!data.isRead) {
          await updateDoc(docSnap.ref, {
            isRead: true
          });
        }
      };

      list.appendChild(div);
    });

    /* BADGE */
    if (unread === 0) {
      badge.style.display = "none";
    } else {
      badge.style.display = "flex";
      badge.innerText = unread > 99 ? "99+" : unread;
    }
  });
}
