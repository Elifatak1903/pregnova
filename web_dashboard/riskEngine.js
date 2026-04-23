import {
  collection,
  query,
  where,
  orderBy,
  limit,
  getDocs,
  doc,
  getDoc,
  setDoc,
  addDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

function getDB() {
  return window.db;
}
export const RiskLevel = {
  LOW: "LOW",
  MEDIUM: "MEDIUM",
  HIGH: "HIGH"
};

export async function calculatePreeklampsi({
  uid,
  sistolik,
  diastolik,
  basAgrisi,
  gorme,
  sislik,
  chronic = false
}) {

  if (sistolik >= 160 || diastolik >= 110) {
    return RiskLevel.HIGH;
  }

  let score = 0;

  if (sistolik >= 140) score += 2;
  if (diastolik >= 90) score += 2;
  if (basAgrisi) score += 1;
  if (gorme) score += 1;
  if (sislik) score += 1;
  if (chronic) score += 2;

  let risk = RiskLevel.LOW;

  if (score <= 2) risk = RiskLevel.LOW;
  else if (score <= 5) risk = RiskLevel.MEDIUM;
  else risk = RiskLevel.HIGH;

  const q = query(
    collection(getDB(), "risk_olcumleri"),
    where("uid", "==", uid),
    orderBy("createdAt", "desc"),
    limit(3)
  );

  const snap = await getDocs(q);

  if (snap.docs.length === 3) {
    let abnormal = 0;

    snap.forEach(doc => {
      const d = doc.data();
      if (d.sistolik >= 140 || d.diastolik >= 90) {
        abnormal++;
      }
    });

    if (abnormal === 3) {
      if (risk === "LOW") risk = "MEDIUM";
      else if (risk === "MEDIUM") risk = "HIGH";
    }
  }

  await setDoc(doc(db, "users", uid), {
    riskLevel: risk.toLowerCase()
  }, { merge: true });

  return risk;
}

export function calculateDiyabet({
  aclik,
  tokluk,
  susama,
  idrar,
  diabetes = false
}) {

  if ((aclik >= 126) || (tokluk >= 200)) {
    return RiskLevel.HIGH;
  }

  let score = 0;

  if (aclik >= 100) score += 2;
  if (tokluk >= 140) score += 2;
  if (susama) score += 1;
  if (idrar) score += 1;
  if (diabetes) score += 2;

  if (score <= 2) return RiskLevel.LOW;
  if (score <= 5) return RiskLevel.MEDIUM;
  return RiskLevel.HIGH;
}

export function calculatePreterm({
  kasilma,
  akinti,
  bel,
  stres,
  prev = false,
  multi = false
}) {

  let score = 0;

  if (kasilma) score += 2;
  if (akinti) score += 1;
  if (bel) score += 1;

  if (stres === 5) score += 3;
  else if (stres >= 4) score += 2;

  if (prev) score += 2;
  if (multi) score += 2;

  if (score <= 2) return RiskLevel.LOW;
  if (score <= 5) return RiskLevel.MEDIUM;
  return RiskLevel.HIGH;
}