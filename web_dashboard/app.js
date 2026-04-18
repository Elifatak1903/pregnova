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