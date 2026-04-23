import { doc, getDoc } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;

const content = document.getElementById("content");

function kart(title, value, icon) {
    return `
        <div class="card">
            <div class="icon">${icon}</div>
            <div class="info">
                <div class="title">${title}</div>
                <div class="value">${value}</div>
            </div>
        </div>
    `;
}

auth.onAuthStateChanged(async (user) => {

    if (!user) {
        window.location.href = "login.html";
        return;
    }

    try {
        const snap = await getDoc(doc(db, "users", user.uid));

        if (!snap.exists()) {
            content.innerHTML = "Veri bulunamadı";
            return;
        }

        const d = snap.data();

        content.innerHTML = `
            ${kart("Kronik Hipertansiyon", d.chronicHypertension ? "Var" : "Yok", "❤️")}
            ${kart("Diyabet", d.diabetes ? "Var" : "Yok", "🩸")}
            ${kart("Tiroid Hastalığı", d.thyroidDisease ? "Var" : "Yok", "🧬")}
            ${kart("Önceki Preterm", d.previousPreterm ? "Var" : "Yok", "⚠️")}
            ${kart("Çoğul Gebelik", d.multiplePregnancy ? "Var" : "Yok", "👶👶")}
            ${kart("Sigara Kullanımı", d.smoker ? "Var" : "Yok", "🚬")}

            <button class="edit-btn" onclick="editProfile()">
                ✏️ Bilgileri Düzenle
            </button>
        `;

    } catch (err) {
        console.error(err);
        content.innerHTML = "Hata oluştu";
    }

});

window.editProfile = function () {
    window.location.href = "profile_edit.html";
};