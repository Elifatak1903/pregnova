import {
  collection,
  addDoc,
  serverTimestamp
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;

const params = new URLSearchParams(window.location.search);
const clientId = params.get("id");

window.saveDiet = async () => {

  const uid = auth.currentUser.uid;

  await addDoc(collection(db, "diet_plans"), {
    clientId,
    dietitianId: uid,
    kahvalti: val("kahvalti"),
    ara1: val("ara1"),
    ogle: val("ogle"),
    ara2: val("ara2"),
    aksam: val("aksam"),
    gece: val("gece"),
    notlar: val("notlar"),
    createdAt: serverTimestamp()
  });

  alert("Kaydedildi ✅");

  window.location.href = "dietitian.html";
};

function val(id) {
  return document.getElementById(id).value;
}