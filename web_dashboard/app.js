import { getAuth, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";
import { getFirestore, doc, getDoc } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

window.go = function(page) {
  window.location.href = page;
};

window.logout = function() {
  window.location.href = "login.html";
};

const auth = getAuth();
const db = getFirestore();

onAuthStateChanged(auth, async (user) => {
  if (!user) return;

  const userRef = doc(db, "users", user.uid);
  const userDoc = await getDoc(userRef);

  if (!userDoc.exists()) return;

  const role = userDoc.data().role;

  document.body.className = role;
  document.body.classList.add("ready");

});

window.toggleNotifications = function(e) {

  e.stopPropagation();

  const dropdown = e.currentTarget.querySelector(".notif-dropdown");

  dropdown.classList.toggle("hidden");
};

window.addEventListener("click", () => {
  const dropdown = document.getElementById("notifDropdown");
  if (dropdown) dropdown.classList.add("hidden");
});

function loadNotifications() {

  const list = document.getElementById("notifList");

  list.innerHTML = `
    <div class="notif-item">Yeni hasta isteği geldi</div>
    <div class="notif-item">Yeni mesaj aldınız</div>
    <div class="notif-item">Yüksek riskli hasta tespit edildi</div>
  `;
}