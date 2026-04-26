import {
  collection,
  query,
  where,
  getDocs,
  doc,
  getDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;

auth.onAuthStateChanged(async (user) => {
  if (!user) return location.href = "login.html";

  loadClients(user.uid);
});

async function loadClients(uid) {

  const container = document.getElementById("clientList");

  const q = query(
    collection(db, "expert_requests"),
    where("expertId", "==", uid),
    where("status", "==", "approved")
  );

  const snap = await getDocs(q);

  if (snap.empty) {
    container.innerHTML = "Danışan yok";
    return;
  }

  container.innerHTML = "";

  for (const docSnap of snap.docs) {

    const clientId = docSnap.data().clientId;

    const userSnap = await getDoc(doc(db, "users", clientId));
    const u = userSnap.data();

    const div = document.createElement("div");
    div.className = "client-card";

    div.innerHTML = `
      <b>${u.name || ""} ${u.surname || ""}</b>
      <span>›</span>
    `;

    div.onclick = () => {
      window.location.href = `create_diet.html?id=${clientId}`;
    };

    container.appendChild(div);
  }
}