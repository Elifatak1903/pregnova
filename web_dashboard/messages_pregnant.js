import { initializeApp } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-app.js";

import {
  getFirestore,
  collection,
  query,
  where,
  onSnapshot,
  doc,
  getDoc,
  addDoc,
  orderBy,
  updateDoc,
  serverTimestamp
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  getAuth,
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

const app = initializeApp({
  apiKey: "AIzaSyBHVmFtmXLe6BcN620XCmjv9vMOkcjeFdM",
  authDomain: "pregnova-38391.firebaseapp.com",
  projectId: "pregnova-38391"
});

const db = getFirestore(app);
const auth = getAuth(app);

let currentChatId = null;
let currentUserId = null;

onAuthStateChanged(auth, (user) => {

  if (!user) return;

  currentUserId = user.uid;

  loadChats(user.uid);
});

function loadChats(uid) {

  const q = query(
    collection(db, "chats"),
    where("users", "array-contains", uid)
  );

  onSnapshot(q, async (snapshot) => {

    const container = document.getElementById("chatList");
    if (!container) return;

    container.innerHTML = "";

    for (const docSnap of snapshot.docs) {

      const data = docSnap.data();
      const users = data.users || [];

      const otherUserId = users.find(u => u !== uid);

      if (!otherUserId) continue;

      const userSnap = await getDoc(doc(db, "users", otherUserId));
      const u = userSnap.data();

      const role = u?.role;
      let name = u?.name || "Kullanıcı";

      if (role === "gynecologist") {
        name = "Dr. " + name;
      } else if (role === "dietitian") {
        name = "Diyetisyen " + name;
      }

      const div = document.createElement("div");
      div.className = "chat-item";

      div.innerHTML = `
        <b>${name}</b><br>
        <small>${data.lastMessage || ""}</small>
      `;

      div.onclick = () => openChat(docSnap.id, name);

      container.appendChild(div);
    }
  });
}

function openChat(chatId, name) {

  currentChatId = chatId;

  document.getElementById("chatHeader").innerText = name;

  const q = query(
    collection(db, "messages"),
    where("chatId", "==", chatId),
    orderBy("createdAt", "asc")
  );

  onSnapshot(q, (snapshot) => {

    const container = document.getElementById("messages");
    if (!container) return;

    container.innerHTML = "";

    snapshot.forEach(docSnap => {

      const data = docSnap.data();

      const div = document.createElement("div");

      div.className =
        data.senderId === currentUserId ? "msg me" : "msg other";

      div.innerText = data.text;

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