import { initializeApp } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-app.js";

import {
  getAuth,
  onAuthStateChanged,
  signOut
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

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

/* FIREBASE INIT */
const app = initializeApp({
  apiKey: "AIzaSyBHVmFtmXLe6BcN620XCmjv9vMOkcjeFdM",
  authDomain: "pregnova-38391.firebaseapp.com",
  projectId: "pregnova-38391"
});

const auth = getAuth(app);
const db = getFirestore(app);

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
  const hafta = data.hafta || 1;

  const weekEl = document.getElementById("weekText");

  if (weekEl) {
    weekEl.innerText = hafta + ". Hafta";
  }
}

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
      <div>Preeklampsi: ${colorRisk(data.preeklampsiRisk)}</div>
      <div>Diyabet: ${colorRisk(data.diyabetRisk)}</div>
      <div>Preterm: ${colorRisk(data.pretermRisk)}</div>
    `;
  });
}

/* RISK RENK */
function colorRisk(risk) {
  if (!risk) return "-";

  if (risk === "HIGH")
    return `<span style="color:#EF5350">Yüksek</span>`;

  if (risk === "MEDIUM")
    return `<span style="color:#FFA000">Orta</span>`;

  return `<span style="color:#00BFA5">Düşük</span>`;
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

      const data = docSnap.data();

      if (!data.isRead) unread++;

      const div = document.createElement("div");
      div.className = "notif-item";

      div.innerHTML = `
        <b>${data.title}</b><br>
        <small>${data.message}</small>
      `;

      div.onclick = async () => {

        if (!data.isRead) {
          await updateDoc(docSnap.ref, {
            isRead: true
          });
        }

        // 👉 İstersen yönlendirme buraya eklenir
        // window.location.href = "somepage.html";
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