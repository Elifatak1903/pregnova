import {
  collection,
  query,
  where,
  getDocs
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";
import { t } from "./i18n.js";

const db = window.db;
const auth = window.auth;

auth.onAuthStateChanged(async (user) => {
  if (!user) {
    window.location.href = "login.html";
    return;
  }

  loadClients(user.uid);
});

async function loadClients(uid) {

  const container = document.getElementById("clientsList");

  try {

    const q = query(
      collection(db, "users"),
      where("assignedDietitian", "==", uid)
    );

    const snapshot = await getDocs(q);

    if (snapshot.empty) {
      container.innerHTML = t("clientNotFound");
      return;
    }

    container.innerHTML = "";

    snapshot.forEach(docSnap => {

      const data = docSnap.data();
      const id = docSnap.id;

      const div = document.createElement("div");
      div.className = "client-card";

      div.innerHTML = `
        <div class="client-info">
          <div class="client-name">
            ${data.name || ""} ${data.surname || ""}
          </div>
          <div class="client-meta">
            ${t("age")}: ${data.yas || "-"} | ${t("week")}: ${data.hafta || "-"}
          </div>
        </div>

        <button class="view-btn">${t("detail")}</button>
      `;

      div.onclick = () => {
        window.location.href = `client_detail.html?id=${id}`;
      };

      container.appendChild(div);
    });

  } catch (err) {
    console.error(err);
    container.innerHTML = t("genericError");
  }
}
