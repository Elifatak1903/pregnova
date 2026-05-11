import {
  collection,
  query,
  where,
  getDocs,
  orderBy,
  limit,
  doc,
  getDoc,
  Timestamp
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";
import { t } from "./i18n.js";

const db = window.db;
const auth = window.auth;

/* AUTH */
auth.onAuthStateChanged(async (user) => {
  if (!user) {
    window.location.href = "login.html";
    return;
  }

  const uid = user.uid;

  await loadStats(uid);
  await loadRecentActivity(uid);
});

/*  STAT CARDS */
async function loadStats(uid) {

  try {

    /* DANIŞAN SAYISI */
    const clientsSnap = await getDocs(
      query(
        collection(db, "users"),
        where("assignedDietitian", "==", uid)
      )
    );

    const clientIds = clientsSnap.docs.map(d => d.id);

    document.getElementById("approvedCount").innerText =
      clientIds.length;

    /* BEKLEYEN İSTEK */
    const pendingSnap = await getDocs(
      query(
        collection(db, "expert_requests"),
        where("expertId", "==", uid),
        where("status", "==", "pending")
      )
    );

    document.getElementById("pendingCount").innerText =
      pendingSnap.size;

    /*  SON 7 GÜN AKTİF ANALİZ */
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const sevenDaysAgoTimestamp = Timestamp.fromDate(sevenDaysAgo);

    let total = 0;

    for (const id of clientIds) {

      const snap = await getDocs(
        query(
          collection(db, "besin_analizleri"),
          where("uid", "==", id),
          where("createdAt", ">", sevenDaysAgoTimestamp)
        )
      );

      total += snap.size;
    }

    document.getElementById("activeCount").innerText = total;

  } catch (err) {
    console.error("STAT ERROR:", err);
  }
}

/* SON AKTİVİTELER */
async function loadRecentActivity(uid) {

  const container = document.getElementById("activityList");

  try {

    const q = query(
      collection(db, "besin_analizleri"),
      where("dietitianId", "==", uid),
      orderBy("createdAt", "desc"),
      limit(5)
    );

    const snapshot = await getDocs(q);

    if (snapshot.empty) {
      container.innerHTML = t("noActivity");
      return;
    }

    container.innerHTML = "";

    for (const docSnap of snapshot.docs) {

      const data = docSnap.data();
      const patientId = data.uid;

      /* USER ÇEK */
      const userSnap = await getDoc(doc(db, "users", patientId));

      let name = t("user");
      let surname = "";

      if (userSnap.exists()) {
        const u = userSnap.data();
        name = u.name || t("user");
        surname = u.surname || "";
      }

      const div = document.createElement("div");
      div.className = "activity-item";

      div.innerHTML = `
        <b>${name} ${surname}</b> ${t("sentNewAnalysis")}<br>
        <small>${formatTime(data.createdAt)}</small>
      `;

      div.onclick = () => {
        window.location.href = `client_detail.html?id=${patientId}`;
      };

      container.appendChild(div);
    }

  } catch (err) {
    console.error("ACTIVITY ERROR:", err);
    container.innerHTML = t("genericError");
  }
}

/* TIME FORMAT */
function formatTime(timestamp) {

  if (!timestamp) return "-";

  try {
    const date = timestamp.toDate
      ? timestamp.toDate()
      : new Date(timestamp);

    return date.toLocaleString();
  } catch {
    return "-";
  }
}
