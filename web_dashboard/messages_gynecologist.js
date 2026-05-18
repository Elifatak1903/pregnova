import { auth, db } from "./app.js";
import { t } from "./i18n.js";

import {
  collection,
  query,
  where,
  onSnapshot,
  doc,
  getDoc,
  addDoc,
  orderBy,
  updateDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

let currentChatId = null;
let currentUserId = null;
let unsubscribeMessages = null;

/* AUTH */
onAuthStateChanged(auth, (user) => {
  if (!user) {
    location.href = "login.html";
    return;
  }

  currentUserId = user.uid;
  loadChats(user.uid);
});

/* LOAD CHATS */
function loadChats(uid) {
  const q = query(
    collection(db, "chats"),
    where("users", "array-contains", uid),
    orderBy("lastMessageTime", "desc")
  );

  onSnapshot(q, async (snapshot) => {
    const container = document.getElementById("chatList");
    if (!container) return;

    container.innerHTML = "";

    if (snapshot.empty) {
      container.innerHTML = t("noMessages");
      return;
    }

    for (const docSnap of snapshot.docs) {
      const data = docSnap.data();
      const users = data.users || [];

      const otherUserId = users.find(u => u !== uid);
      if (!otherUserId) continue;

      const userSnap = await getDoc(doc(db, "users", otherUserId));
      const u = userSnap.data();

      const name = `${u?.name || t("user")} ${u?.surname || ""}`.trim();
      const initials = getInitials(name);
      const lastMessage = data.lastMessage || "";
      const time = formatTime(data.lastMessageTime);

      const div = document.createElement("div");
      div.className = "chat-item";

      div.innerHTML = `
        <div class="chat-avatar">${initials}</div>

        <div class="chat-info">
          <div class="chat-name">${name}</div>
          <div class="chat-role">${t("patientRole")}</div>
          <div class="chat-last">${lastMessage}</div>
        </div>

        <div class="chat-time">${time}</div>
      `;

      div.onclick = () => {
        document.querySelectorAll(".chat-item").forEach(item => {
          item.classList.remove("active");
        });

        div.classList.add("active");
        openChat(docSnap.id, name);
      };

      container.appendChild(div);
    }
  });
}

function openChat(chatId, name) {
  document.getElementById("emptyChat").classList.add("hidden");
  document.getElementById("activeChat").classList.remove("hidden");

  currentChatId = chatId;

  document.getElementById("chatHeader").innerText = name;

  if (unsubscribeMessages) {
    unsubscribeMessages();
  }

  const q = query(
    collection(db, "messages"),
    where("chatId", "==", chatId),
    orderBy("createdAt", "asc")
  );

  unsubscribeMessages = onSnapshot(q, (snapshot) => {
    const container = document.getElementById("messages");
    if (!container) return;

    container.innerHTML = "";

    snapshot.forEach(docSnap => {
      const data = docSnap.data();

      const div = document.createElement("div");
      div.className =
        data.senderId === currentUserId ? "msg me" : "msg other";

      const time = formatTime(data.createdAt);

      div.innerHTML = `
        <div>${data.text}</div>
        <div class="msg-time">${time}</div>
      `;

      container.appendChild(div);

      if (!data.isRead && data.senderId !== currentUserId) {
        updateDoc(docSnap.ref, { isRead: true });
      }
    });

    container.scrollTop = container.scrollHeight;
  });
}

window.sendMessage = async function () {
  const input = document.getElementById("messageInput");
  const text = input.value.trim();

  if (!text || !currentChatId) return;

  await addDoc(collection(db, "messages"), {
    chatId: currentChatId,
    senderId: currentUserId,
    text,
    createdAt: new Date(),
    isRead: false
  });

  await updateDoc(doc(db, "chats", currentChatId), {
    lastMessage: text,
    lastMessageTime: new Date()
  });

  input.value = "";
};

window.addEventListener("DOMContentLoaded", () => {
  const input = document.getElementById("messageInput");

  if (input) {
    input.addEventListener("keypress", (e) => {
      if (e.key === "Enter") {
        sendMessage();
      }
    });
  }
});

function getInitials(name) {
  return String(name)
    .trim()
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map(part => part[0]?.toUpperCase())
    .join("") || "?";
}

function formatTime(value) {
  if (!value) return "";

  let date;

  if (value.toDate) {
    date = value.toDate();
  } else if (value.seconds) {
    date = new Date(value.seconds * 1000);
  } else {
    date = new Date(value);
  }

  if (Number.isNaN(date.getTime())) return "";

  return date.toLocaleTimeString("tr-TR", {
    hour: "2-digit",
    minute: "2-digit"
  });
}