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
      container.innerHTML = "Son 7 günde analiz yok";
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
            <div class="analysis-icon">🍽</div>

            <div class="analysis-text">
                <b>${name} ${surname}</b>
                <span>${time}</span>
            </div>
        </div>

        <div class="analysis-arrow">›</div>
      `;

      div.onclick = () => {
        window.location.href = `client_detail.html?id=${patientId}`;
      };

      container.appendChild(div);
    }

  } catch (err) {
    console.error(err);
    container.innerHTML = "Hata oluştu";
  }
}

/* TIME AGO */
function timeAgo(timestamp) {

  if (!timestamp) return "";

  const now = new Date();
  const date = timestamp.toDate();

  const diff = (now - date) / 1000;

  if (diff < 60) return `${Math.floor(diff)} sn önce`;
  if (diff < 3600) return `${Math.floor(diff/60)} dk önce`;
  if (diff < 86400) return `${Math.floor(diff/3600)} saat önce`;

  return `${Math.floor(diff/86400)} gün önce`;
}

function formatDateTime(timestamp) {

  if (!timestamp) return "";

  const date = timestamp.toDate();

  return date.toLocaleString("tr-TR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit"
  });
}