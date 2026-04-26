import {
  collection,
  query,
  where,
  getDocs,
  doc,
  updateDoc,
  getDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;

/* AUTH */
auth.onAuthStateChanged(async (user) => {
  if (!user) {
    window.location.href = "login.html";
    return;
  }

  loadRequests(user.uid);
});

/* LOAD REQUESTS */
async function loadRequests(uid) {

  const container = document.getElementById("requestList");

  try {

    const q = query(
      collection(db, "expert_requests"),
      where("expertId", "==", uid),
      where("status", "==", "pending")
    );

    const snapshot = await getDocs(q);

    if (snapshot.empty) {
      container.innerHTML = "İstek yok";
      return;
    }

    container.innerHTML = "";

    for (const docSnap of snapshot.docs) {

      const data = docSnap.data();
      const requestId = docSnap.id;
      const clientId = data.clientId;

      /* USER GET */
      const userSnap = await getDoc(doc(db, "users", clientId));
      const u = userSnap.data();

      const div = document.createElement("div");
      div.className = "request-card";

      div.innerHTML = `
        <div class="req-info">
          <div class="req-name">
            ${u.name || ""} ${u.surname || ""}
          </div>
          <div class="req-meta">
            Hafta: ${u.hafta || "-"}
          </div>
        </div>

        <div class="req-actions">
          <button class="btn btn-approve">Kabul</button>
          <button class="btn btn-reject">Reddet</button>
        </div>
      `;

      /* BUTTON EVENTS */
      const approveBtn = div.querySelector(".btn-approve");
      const rejectBtn = div.querySelector(".btn-reject");

      approveBtn.onclick = () => approveRequest(requestId, clientId, uid);
      rejectBtn.onclick = () => rejectRequest(requestId);

      container.appendChild(div);
    }

  } catch (err) {
    console.error(err);
    container.innerHTML = "Hata oluştu";
  }
}

/* APPROVE */
async function approveRequest(requestId, clientId, expertId) {

  try {

    // request update
    await updateDoc(doc(db, "expert_requests", requestId), {
      status: "approved"
    });

    // kullanıcıya diyetisyen ata
    await updateDoc(doc(db, "users", clientId), {
      assignedDietitian: expertId
    });

    alert("Kabul edildi");
    location.reload();

  } catch (err) {
    console.error(err);
  }
}

/* REJECT */
async function rejectRequest(requestId) {

  try {

    await updateDoc(doc(db, "expert_requests", requestId), {
      status: "rejected"
    });

    alert("Reddedildi");
    location.reload();

  } catch (err) {
    console.error(err);
  }
}