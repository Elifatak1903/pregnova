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
import { t } from "./i18n.js";

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

  const notificationType = type === "risk" ? "risk_alert" : type || "general";
  let title = t("notification");

  if (type === "risk") title = t("riskWarning");
  if (type === "chat") title = t("newMessage");

  if (notificationType === "risk_alert") title = t("riskWarning");
  if (notificationType === "message") title = t("newMessage");

  await addDoc(collection(db, "notification"), {
    uid: targetUid,
    type: notificationType,
    title,
    message: message || "",
    isRead: false,
    createdAt: serverTimestamp()
  });
}

window.calculateRisk = async function () {

  const user = auth.currentUser;
  if (!user) return alert(t("userNotFound"));

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
    await createNotification(user.uid, "risk", t("preeclampsiaHighMessage"));

    if (assignedDoctor) {
      await createNotification(
        assignedDoctor,
        "risk",
        t("patientPreeclampsiaHighMessage")
      );
    }
  }

  if (diyabet === "HIGH") {
    await createNotification(user.uid, "risk", t("diabetesHighMessage"));

    if (assignedDoctor) {
      await createNotification(
        assignedDoctor,
        "risk",
        t("patientDiabetesHighMessage")
      );
    }

    if (assignedDietitian) {
      await createNotification(
        assignedDietitian,
        "risk",
        t("clientNutritionRiskMessage")
      );
    }
  }

  if (preterm === "HIGH") {
    await createNotification(user.uid, "risk", t("pretermHighMessage"));

    if (assignedDoctor) {
      await createNotification(
        assignedDoctor,
        "risk",
        t("pretermBirthRiskMessage")
      );
    }
  }

  showModal(`
${t("preeclampsia")}: ${riskText(pre)}
${t("diabetes")}: ${riskText(diyabet)}
${t("preterm")}: ${riskText(preterm)}
  `);
};

function riskText(value) {
  if (value === "HIGH") return t("high");
  if (value === "MEDIUM") return t("medium");
  if (value === "LOW") return t("low");
  return value || "-";
}
