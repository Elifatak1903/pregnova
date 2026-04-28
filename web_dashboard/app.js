import { initializeApp } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-app.js";
import { getAuth, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";
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
export{ db };

/* NAV */
window.go = function(page) {
  window.location.href = page;
};

window.logout = function() {
  window.location.href = "login.html";
};

window.db = db;
window.auth = auth;

/* AUTH CONTROL */
onAuthStateChanged(auth, async (user) => {
  if (!user) return;

  loadNotifications(user.uid);

  const userRef = doc(db, "users", user.uid);
  const userDoc = await getDoc(userRef);

  if (!userDoc.exists()) return;

  const role = userDoc.data().role;

  document.body.className = role;
  document.body.classList.add("ready");
});

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