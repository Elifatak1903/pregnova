import { auth, db } from "./app.js";
import { t } from "./i18n.js";

import {
  collection,
  query,
  where,
  onSnapshot,
  doc,
  getDoc,
  getDocs,
  addDoc,
  orderBy,
  updateDoc,
  serverTimestamp
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

let currentChatId = null;
let currentUserId = null;
let unsubscribeMessages = null;
let requestedChatId = new URLSearchParams(window.location.search).get("chatId");

onAuthStateChanged(auth, (user) => {
  if (!user) {
    location.href = "login.html";
    return;
  }

  currentUserId = user.uid;
  loadChats(user.uid);
});

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

    const chatRows = [];

    for (const docSnap of snapshot.docs) {
      const data = docSnap.data();
      const users = data.users || [];
      const otherUserId = users.find(u => u !== uid);

      if (!otherUserId) continue;

      chatRows.push({
        chatId: docSnap.id,
        otherUserId,
        data
      });
    }

    const chatUserIds = new Set(chatRows.map(row => row.otherUserId));
    const assignedClients = await loadAssignedClients(uid);

    for (const client of assignedClients) {
      if (chatUserIds.has(client.id)) continue;

      const chatId = await getOrCreateChat(uid, client.id);
      chatRows.push({
        chatId,
        otherUserId: client.id,
        data: {
          lastMessage: "",
          lastMessageTime: null
        }
      });
    }

    if (chatRows.length === 0) {
      container.innerHTML = t("noMessages");
      return;
    }

    for (const row of chatRows) {
      const userSnap = await getDoc(doc(db, "users", row.otherUserId));
      const user = userSnap.data() || {};

      const name = `${user.name || t("user")} ${user.surname || ""}`.trim();
      const initials = getInitials(name);
      const lastMessage = row.data.lastMessage || "";
      const time = formatTime(row.data.lastMessageTime);

      const div = document.createElement("div");
      div.className = "chat-item";
      div.dataset.chatId = row.chatId;

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
        selectChatItem(div, row.chatId, name);
      };

      container.appendChild(div);

      if (requestedChatId === row.chatId) {
        selectChatItem(div, row.chatId, name);
        requestedChatId = null;
      }
    }
  });
}

async function loadAssignedClients(uid) {
  const snap = await getDocs(query(
    collection(db, "users"),
    where("assignedDietitian", "==", uid)
  ));

  return snap.docs.map(docSnap => ({ id: docSnap.id, data: docSnap.data() }));
}

async function getOrCreateChat(currentUserId, otherUserId) {
  const chatSnap = await getDocs(query(
    collection(db, "chats"),
    where("users", "array-contains", currentUserId)
  ));

  for (const chatDoc of chatSnap.docs) {
    const users = chatDoc.data().users || [];
    if (users.includes(otherUserId)) return chatDoc.id;
  }

  const newChat = await addDoc(collection(db, "chats"), {
    users: [currentUserId, otherUserId],
    lastMessage: "",
    lastMessageTime: serverTimestamp()
  });

  return newChat.id;
}

function selectChatItem(element, chatId, name) {
  document.querySelectorAll(".chat-item").forEach(item => {
    item.classList.remove("active");
  });

  element.classList.add("active");
  openChat(chatId, name);
}

function openChat(chatId, name) {
  document.getElementById("emptyChat")?.classList.add("hidden");
  document.getElementById("activeChat")?.classList.remove("hidden");

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
      div.className = data.senderId === currentUserId ? "msg me" : "msg other";

      div.innerHTML = `
        <div>${data.text || ""}</div>
        <div class="msg-time">${formatTime(data.createdAt)}</div>
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
    createdAt: serverTimestamp(),
    isRead: false
  });

  await updateDoc(doc(db, "chats", currentChatId), {
    lastMessage: text,
    lastMessageTime: serverTimestamp()
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
