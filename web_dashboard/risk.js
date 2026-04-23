import {
  calculatePreeklampsi,
  calculateDiyabet,
  calculatePreterm
} from "./riskEngine.js";

import {
  collection,
  addDoc,
  doc,
  getDoc,
  serverTimestamp
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;

function showModal(text) {
  document.getElementById("resultText").innerText = text;
  document.getElementById("resultModal").classList.remove("hidden");
}

window.closeModal = function () {
  document.getElementById("resultModal").classList.add("hidden");
};

async function createNotification(targetUid, type, message) {

  let title = "Bildirim";

  if (type === "risk") title = "⚠️ Risk Uyarısı";
  if (type === "chat") title = "💬 Yeni Mesaj";

  await addDoc(collection(db, "notification"), {
    uid: targetUid,
    type,
    title,
    message,
    isRead: false,
    createdAt: serverTimestamp()
  });
}

window.calculateRisk = async function () {

  const user = auth.currentUser;
  if (!user) return alert("Kullanıcı bulunamadı ❌");

  const userDoc = await getDoc(doc(db, "users", user.uid));
  const userData = userDoc.data() || {};

  const assignedDoctor = userData.assignedDoctor;
  const assignedDietitian = userData.assignedDietitian;

  const sistolik = +document.getElementById("sistolik").value || 0;
  const diastolik = +document.getElementById("diastolik").value || 0;

  const aclik = +document.getElementById("aclik").value || 0;
  const tokluk = +document.getElementById("tokluk").value || 0;

  const basAgrisi = document.getElementById("basAgrisi").checked;
  const gorme = document.getElementById("gorme").checked;
  const sislik = document.getElementById("sislik").checked;

  const susama = document.getElementById("susama").checked;
  const idrar = document.getElementById("idrar").checked;

  const kasilma = document.getElementById("kasilma").checked;
  const akinti = document.getElementById("akinti").checked;
  const bel = document.getElementById("bel").checked;

  const stres = +document.getElementById("stres").value;

  const pre = await calculatePreeklampsi({
    uid: user.uid,
    sistolik,
    diastolik,
    basAgrisi,
    gorme,
    sislik
  });

  const diyabet = calculateDiyabet({
    aclik,
    tokluk,
    susama,
    idrar
  });

  const preterm = calculatePreterm({
    kasilma,
    akinti,
    bel,
    stres
  });

  await addDoc(collection(db, "risk_olcumleri"), {
    uid: user.uid,
    sistolik,
    diastolik,
    aclikSeker: aclik,
    toklukSeker: tokluk,
    preeklampsiRisk: pre,
    diyabetRisk: diyabet,
    pretermRisk: preterm,
    tarih: serverTimestamp()
  });

  if (pre === "HIGH") {
    await createNotification(user.uid, "risk", "⚠️ Preeklampsi riski yüksek!");

    if (assignedDoctor) {
      await createNotification(
        assignedDoctor,
        "risk",
        "🚨 Hastanızda yüksek preeklampsi riski!"
      );
    }
  }

  if (diyabet === "HIGH") {
    await createNotification(user.uid, "risk", "⚠️ Diyabet riski yüksek!");

    if (assignedDoctor) {
      await createNotification(
        assignedDoctor,
        "risk",
        "🚨 Hastada diyabet riski!"
      );
    }

    if (assignedDietitian) {
      await createNotification(
        assignedDietitian,
        "risk",
        "🥗 Danışanda beslenme riski!"
      );
    }
  }

  if (preterm === "HIGH") {
    await createNotification(user.uid, "risk", "⚠️ Preterm riski yüksek!");

    if (assignedDoctor) {
      await createNotification(
        assignedDoctor,
        "risk",
        "🚨 Preterm doğum riski!"
      );
    }
  }

  showModal(`
Preeklampsi: ${pre}
Diyabet: ${diyabet}
Preterm: ${preterm}
  `);
};