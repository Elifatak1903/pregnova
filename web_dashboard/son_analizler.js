import {
  collection,
  query,
  where,
  getDocs,
  doc,
  getDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";
import { t } from "./i18n.js";

const db = window.db;
const auth = window.auth;

auth.onAuthStateChanged(async (user) => {
  if (!user) return location.href = "login.html";

  loadAnalyses(user.uid);
});

async function loadAnalyses(uid) {

  const container = document.getElementById("analysisList");

  try {

    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const q = query(
      collection(db, "besin_analizleri"),
      where("createdAt", ">", sevenDaysAgo)
    );

    const snap = await getDocs(q);

    if (snap.empty) {
      container.innerHTML = t("noAnalysesLast7Days");
      return;
    }

    container.innerHTML = "";

    for (const docSnap of snap.docs) {

      const data = docSnap.data();
      const patientId = data.uid;

      const userSnap = await getDoc(doc(db, "users", patientId));
      const u = userSnap.data();

      const name = u?.name || "";
      const surname = u?.surname || "";

      const time = formatDateTime(data.createdAt);

      const div = document.createElement("div");
      div.className = "analysis-card";

      div.innerHTML = `
        <div class="analysis-left">
            <div class="analysis-icon">A</div>

            <div class="analysis-text">
                <b>${name} ${surname}</b>
                <span>${time}</span>
            </div>
        </div>

        <div class="analysis-arrow">&rsaquo;</div>
      `;

      div.onclick = () => {
        window.location.href = `client_detail.html?id=${patientId}`;
      };

      container.appendChild(div);
    }

  } catch (err) {
    console.error(err);
    container.innerHTML = t("genericError");
  }
}

/* TIME AGO */
function timeAgo(timestamp) {

  if (!timestamp) return "";

  const now = new Date();
  const date = timestamp.toDate();

  const diff = (now - date) / 1000;

  if (diff < 60) return t("secondsAgo", { count: Math.floor(diff) });
  if (diff < 3600) return t("minutesAgo", { count: Math.floor(diff / 60) });
  if (diff < 86400) return t("hoursAgo", { count: Math.floor(diff / 3600) });

  return t("daysAgo", { count: Math.floor(diff / 86400) });
}

function formatDateTime(timestamp) {

  if (!timestamp) return "";

  const date = timestamp.toDate();

  return date.toLocaleString(undefined, {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit"
  });
}
