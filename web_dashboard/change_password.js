import {
  getAuth,
  EmailAuthProvider,
  reauthenticateWithCredential,
  updatePassword
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

const auth = window.auth;

window.changePassword = async function () {

  const currentPassword = document.getElementById("currentPassword").value;
  const newPassword = document.getElementById("newPassword").value;
  const confirmPassword = document.getElementById("confirmPassword").value;

  if (!currentPassword || !newPassword || !confirmPassword) {
    alert("Tüm alanları doldur ⚠️");
    return;
  }

  if (newPassword.length < 6) {
    alert("Şifre en az 6 karakter olmalı");
    return;
  }

  if (newPassword !== confirmPassword) {
    alert("Şifreler eşleşmiyor");
    return;
  }

  const user = auth.currentUser;

  if (!user || !user.email) {
    alert("Kullanıcı bulunamadı");
    return;
  }

  try {
    const credential = EmailAuthProvider.credential(
      user.email,
      currentPassword
    );

    await reauthenticateWithCredential(user, credential);

    await updatePassword(user, newPassword);

    alert("Şifre başarıyla değiştirildi ✅");

    window.location.href = "account_pregnant.html";

  } catch (e) {
    console.error(e);

    if (e.code === "auth/wrong-password") {
      alert("Mevcut şifre yanlış ❌");
    } else if (e.code === "auth/weak-password") {
      alert("Şifre çok zayıf ❌");
    } else if (e.code === "auth/requires-recent-login") {
      alert("Tekrar giriş yapman gerekiyor ⚠️");
    } else {
      alert("Hata oluştu ❌");
    }
  }
};