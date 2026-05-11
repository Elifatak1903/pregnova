import { t } from "./i18n.js";

import {
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
    alert(t("fillAllFields"));
    return;
  }

  if (newPassword.length < 6) {
    alert(t("passwordMinLength"));
    return;
  }

  if (newPassword !== confirmPassword) {
    alert(t("passwordsDoNotMatch"));
    return;
  }

  const user = auth.currentUser;

  if (!user || !user.email) {
    alert(t("userNotFound"));
    return;
  }

  try {
    const credential = EmailAuthProvider.credential(user.email, currentPassword);

    await reauthenticateWithCredential(user, credential);
    await updatePassword(user, newPassword);

    alert(t("passwordUpdated"));
    window.location.href = "account_pregnant.html";
  } catch (e) {
    console.error(e);

    if (e.code === "auth/wrong-password") {
      alert(t("wrongCurrentPassword"));
    } else if (e.code === "auth/weak-password") {
      alert(t("weakPassword"));
    } else if (e.code === "auth/requires-recent-login") {
      alert(t("recentLoginRequired"));
    } else {
      alert(t("genericError"));
    }
  }
};
