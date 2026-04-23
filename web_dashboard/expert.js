import {
  collection,
  getDocs,
  doc,
  getDoc,
  setDoc,
  query,
  where
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

let db;
let auth;

let allExperts = [];
let currentUser = null;
let currentUserData = null;

function waitForFirebase() {
  if (window.db && window.auth) {
    db = window.db;
    auth = window.auth;
    init();
  } else {
    setTimeout(waitForFirebase, 100);
  }
}

waitForFirebase();

function init() {

  onAuthStateChanged(auth, async (user) => {

    if (!user) return;

    currentUser = user;

    const userDoc = await getDoc(doc(db, "users", user.uid));
    currentUserData = userDoc.data();

    loadExperts();
  });
}

async function loadExperts() {

  console.log("Experts yükleniyor...");

  const snap = await getDocs(collection(db, "users"));

  allExperts = [];

  snap.forEach(docSnap => {

    const data = docSnap.data();

    console.log("USER DATA 👉", data);

    const role = data.role?.toLowerCase();

    if (role === "gynecologist" || role === "dietitian") {

      allExperts.push({
        id: docSnap.id,
        name: data.name || "Uzman",
        role: role,
        hospital: data.hospital || "Kurum bilgisi yok",
        clients: data.clients || []
      });
    }
  });

  console.log("BULUNAN EXPERT:", allExperts);

  window.filterExperts();
}

async function renderExperts(list) {

  const container = document.getElementById("expertList");
  container.innerHTML = "";

  for (const e of list) {

    const div = document.createElement("div");
    div.className = "expert-card";

    let btnText = "İstek Gönder";
    let disabled = false;

    if (
      (e.role === "gynecologist" && currentUserData?.assignedDoctor === e.id) ||
      (e.role === "dietitian" && currentUserData?.assignedDietitian === e.id)
    ) {
      btnText = "Danışanısınız";
      disabled = true;
    }

    if (!disabled) {

      const snap = await getDocs(query(
        collection(db, "expert_requests"),
        where("clientId", "==", currentUser.uid),
        where("expertId", "==", e.id),
        where("status", "==", "pending")
      ));

      if (!snap.empty) {
        btnText = "Beklemede";
        disabled = true;
      }
    }

    const roleText =
      e.role === "dietitian" ? "Diyetisyen" : "Jinekolog";

    div.innerHTML = `
      <div class="expert-left">
        <div class="avatar">🩺</div>

        <div>
          <div class="expert-name">${e.name}</div>
          <div class="expert-role">${roleText}</div>
          <div class="expert-hospital">${e.hospital}</div>
        </div>
      </div>

      <button class="expert-btn ${disabled ? "disabled" : ""}">
        ${btnText}
      </button>
    `;

    const btn = div.querySelector("button");

    if (!disabled) {
      btn.onclick = () => sendRequest(e.id);
    } else {
      btn.disabled = true;
    }

    container.appendChild(div);
  }
}

window.filterExperts = async function () {

  const text =
    document.getElementById("searchInput")?.value.toLowerCase() || "";

  const role =
    document.getElementById("roleFilter")?.value || "";

  let result = [...allExperts];

  if (text) {
    result = result.filter(e =>
      e.name.toLowerCase().includes(text)
    );
  }

  if (role) {
    result = result.filter(e =>
      e.role?.toLowerCase() === role.toLowerCase()
    );
  }

  await renderExperts(result);
};

/* EVENT */
document.getElementById("searchInput")
  ?.addEventListener("input", window.filterExperts);

document.getElementById("roleFilter")
  ?.addEventListener("change", window.filterExperts);

async function sendRequest(expertId) {

  const uid = currentUser.uid;

  const requestId = `${uid}_${expertId}`;
  const ref = doc(db, "expert_requests", requestId);

  const existing = await getDoc(ref);

  if (existing.exists()) {

    const status = existing.data().status;

    if (status === "pending") {
      alert("Zaten istek gönderdiniz ⏳");
      return;
    }

    if (status === "approved") {
      alert("Zaten danışansınız ✅");
      return;
    }
  }

  await setDoc(ref, {
    clientId: uid,
    expertId: expertId,
    status: "pending",
    createdAt: new Date()
  });

  alert("İstek gönderildi ✅");
}