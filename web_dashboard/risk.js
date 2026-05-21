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
  getDocs,
  query,
  where,
  setDoc,
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

async function createNotification(targetUid, type, message, meta = {}) {

  const notificationType = type === "risk" ? "risk_alert" : type || "general";
  let title = t("notification");

  if (type === "risk") title = t("riskWarning");
  if (type === "chat") title = t("newMessage");

  if (notificationType === "risk_alert") title = t("riskWarning");
  if (notificationType === "message") title = t("newMessage");

  if (notificationType === "risk_alert") {
    const patientId = meta.patientId || meta.clientId || "";
    const recent = await getDocs(query(
      collection(db, "notification"),
      where("uid", "==", targetUid),
      where("type", "==", "risk_alert")
    ));

    const hasRecentDuplicate = recent.docs.some(docSnap => {
      const data = docSnap.data();
      const sameRisk = data.riskType === (meta.riskType || "");
      const samePatient = (data.patientId || data.clientId || "") === patientId;
      if (!sameRisk || !samePatient) return false;

      const lastCreatedAt = data.createdAt;
      const lastDate = lastCreatedAt?.toDate ? lastCreatedAt.toDate() : null;

      return Boolean(lastDate && Date.now() - lastDate.getTime() < 30 * 60 * 1000);
    });

    if (hasRecentDuplicate) return;
  }

  await addDoc(collection(db, "notification"), {
    uid: targetUid,
    type: notificationType,
    title,
    message: message || "",
    ...meta,
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

  const kilo = readOptionalNumber("kilo");
  const sistolik = readRequiredNumber("sistolik", t("systolic"));
  if (sistolik === null) return;

  const diastolik = readRequiredNumber("diastolik", t("diastolic"));
  if (diastolik === null) return;

  const aclik = readOptionalNumber("aclik", t("fastingSugar"));
  const tokluk = readOptionalNumber("tokluk", t("postMeal"));

  if (kilo !== null && !isInRange(kilo, 30, 250)) {
    alert(t("weightRangeError"));
    return;
  }

  if (sistolik === null || !isInRange(sistolik, 80, 250)) {
    alert(t("systolicRangeError"));
    return;
  }

  if (diastolik === null || !isInRange(diastolik, 50, 150)) {
    alert(t("diastolicRangeError"));
    return;
  }

  if (diastolik >= sistolik) {
    alert(t("diastolicMustBeLower"));
    return;
  }

  if (aclik === null && tokluk === null) {
    alert(t("bloodSugarRequired"));
    return;
  }

  if (aclik !== null && !isInRange(aclik, 40, 500)) {
    alert(t("fastingSugarRangeError"));
    return;
  }

  if (tokluk !== null && !isInRange(tokluk, 40, 600)) {
    alert(t("postMealSugarRangeError"));
    return;
  }

  const basAgrisi = document.getElementById("basAgrisi").checked;
  const gorme = document.getElementById("gorme").checked;
  const gormeBozuklugu = gorme;
  const sislik = document.getElementById("sislik").checked;

  const susama = document.getElementById("susama").checked;
  const asiriSusama = susama;
  const idrar = document.getElementById("idrar").checked;
  const sikIdrar = idrar;

  const kasilma = document.getElementById("kasilma").checked;
  const karinKasilma = kasilma;
  const akinti = document.getElementById("akinti").checked;
  const bel = document.getElementById("bel").checked;
  const belAgrisi = bel;

  const stres = +document.getElementById("stres").value;
  const stresSeviyesi = stres;

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

  const userUpdate = {
    riskLevel: resolveOverallRisk(pre, diyabet, preterm)
  };

  if (kilo && kilo > 0) {
    userUpdate.kilo = kilo;
  }

  await setDoc(doc(db, "users", user.uid), userUpdate, { merge: true });

  const measurementRef = await addDoc(collection(db, "risk_olcumleri"), {
    uid: user.uid,
    kilo,
    sistolik,
    diastolik,
    aclikSeker: aclik,
    toklukSeker: tokluk,
    basAgrisi,
    gormeBozuklugu,
    sislik,
    asiriSusama,
    sikIdrar,
    karinKasilma,
    akinti,
    belAgrisi,
    stresSeviyesi,
    preeklampsiRisk: pre,
    diyabetRisk: diyabet,
    pretermRisk: preterm,
    tarih: serverTimestamp(),
    createdAt: serverTimestamp()
  });

  const patientAction = {
    patientId: user.uid,
    measurementId: measurementRef.id,
    actionPage: "measurement_history.html"
  };

  const doctorAction = {
    patientId: user.uid,
    measurementId: measurementRef.id,
    actionPage: `patient_detail.html?uid=${encodeURIComponent(user.uid)}`
  };

  const dietitianAction = {
    clientId: user.uid,
    actionPage: `son_analizler.html?uid=${encodeURIComponent(user.uid)}`
  };

  if (pre === "HIGH") {
    await createNotification(user.uid, "risk", t("preeclampsiaHighMessage"), {
      ...patientAction,
      riskType: "preeklampsi"
    });

    if (assignedDoctor) {
      await createNotification(
        assignedDoctor,
        "risk",
        t("patientPreeclampsiaHighMessage"),
        {
          ...doctorAction,
          riskType: "preeklampsi"
        }
      );
    }
  }

  if (diyabet === "HIGH") {
    await createNotification(user.uid, "risk", t("diabetesHighMessage"), {
      ...patientAction,
      riskType: "diabetes"
    });

    if (assignedDoctor) {
      await createNotification(
        assignedDoctor,
        "risk",
        t("patientDiabetesHighMessage"),
        {
          ...doctorAction,
          riskType: "diabetes"
        }
      );
    }

    if (assignedDietitian) {
      await createNotification(
        assignedDietitian,
        "risk",
        t("clientNutritionRiskMessage"),
        {
          ...dietitianAction,
          riskType: "diabetes"
        }
      );
    }
  }

  if (preterm === "HIGH") {
    await createNotification(user.uid, "risk", t("pretermHighMessage"), {
      ...patientAction,
      riskType: "preterm"
    });

    if (assignedDoctor) {
      await createNotification(
        assignedDoctor,
        "risk",
        t("pretermBirthRiskMessage"),
        {
          ...doctorAction,
          riskType: "preterm"
        }
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

function resolveOverallRisk(...risks) {
  if (risks.includes("HIGH")) return "high";
  if (risks.includes("MEDIUM")) return "medium";
  return "low";
}

function readRequiredNumber(id, label) {
  const raw = document.getElementById(id)?.value?.trim();
  if (!raw) {
    alert(t("requiredNumberField", { field: label }));
    return null;
  }

  const value = Number(raw);
  return Number.isFinite(value) ? value : Number.NaN;
}

function readOptionalNumber(id, label = "") {
  const raw = document.getElementById(id)?.value?.trim();
  if (!raw) return null;

  const value = Number(raw);
  return Number.isFinite(value) ? value : Number.NaN;
}

function isInRange(value, min, max) {
  return Number.isFinite(value) && value >= min && value <= max;
}
