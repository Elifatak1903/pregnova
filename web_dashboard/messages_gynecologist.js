import { initializeApp } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-app.js";

import {
  getFirestore,
  collection,
  query,
  where,
  orderBy,
  onSnapshot,
  doc,
  getDoc,
  getDocs,
  addDoc,
  serverTimestamp,
  updateDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

import {
  getAuth,
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-auth.js";

/* FIREBASE */
const app = initializeApp({
  apiKey: "AIzaSyBHVmFtmXLe6BcN620XCmjv9vMOkcjeFdM",
  authDomain: "pregnova-38391.firebaseapp.com",
  projectId: "pregnova-38391"
});

let currentChatId = null;
let currentUserId = null;
let unsubscribeMessages = null;

const db = getFirestore(app);
const auth = getAuth(app);

/* AUTH */
onAuthStateChanged(auth, (user) => {
  if (!user) return location.href = "login.html";

  loadChats(user.uid);
});

/* LOAD CHATS */
function loadChats(uid) {

  const container = document.getElementById("chatList");

  const q = query(
    collection(db, "chats"),
    where("users", "array-contains", uid),
    orderBy("lastMessageTime", "desc")
  );

  onSnapshot(q, async (snapshot) => {

    container.innerHTML = "";

    if (snapshot.empty) {
      container.innerHTML = "Henüz mesaj yok";
      return;
    }

    for (const chat of snapshot.docs) {

      const data = chat.data();

      const otherUserId = data.users.find(u => u !== uid);

      const userDoc = await getDoc(doc(db, "users", otherUserId));
      const user = userDoc.data();

      const name = user?.name || "";
      const surname = user?.surname || "";

      const lastMessage = data.lastMessage || "";

      let timeText = "";
      if (data.lastMessageTime && data.lastMessageTime.toDate) {
        const d = data.lastMessageTime.toDate();
        timeText =
          d.getHours().toString().padStart(2, "0") + ":" +
          d.getMinutes().toString().padStart(2, "0");
      }

      const div = document.createElement("div");
      div.className = "chat-card";

      div.innerHTML = `
        <div class="chat-left">
          <div class="avatar">👤</div>

          <div class="chat-info">
            <b>${name} ${surname}</b><br>
            <span>${lastMessage}</span>
          </div>
        </div>

        <div class="chat-right">
          <div>${timeText}</div>
        </div>
      `;
      div.onclick = () => {

        currentChatId = chat.id;
        currentUserId = otherUserId;

        document.getElementById("chatHeader").innerText =
          name + " " + surname;

        document.querySelectorAll(".chat-card")
          .forEach(c => c.classList.remove("active"));

        div.classList.add("active");

        loadMessages();
      };

      container.appendChild(div);
    }

  });
}
window.sendMessage = async function () {

  const input = document.getElementById("messageInput");
  const text = input.value;

  if (!text.trim() || !currentChatId) return;

  await addDoc(collection(db, "messages"), {
    text,
    senderId: auth.currentUser.uid,
    chatId: currentChatId,
    createdAt: serverTimestamp(),
    isRead: false
  });

  await updateDoc(doc(db, "chats", currentChatId), {
    lastMessage: text,
    lastMessageTime: serverTimestamp()
  });

  input.value = "";
};

function loadMessages() {

  const messagesDiv = document.getElementById("messages");

  if (unsubscribeMessages) {
    unsubscribeMessages();
  }

  const q = query(
    collection(db, "messages"),
    where("chatId", "==", currentChatId),
    orderBy("createdAt", "asc")
  );

  unsubscribeMessages = onSnapshot(q, (snapshot) => {

    messagesDiv.innerHTML = "";

    snapshot.forEach(doc => {
      const data = doc.data();

      console.log("MESAJ:", data);

      const div = document.createElement("div");
      div.className =
        "message " +
        (data.senderId === auth.currentUser.uid ? "me" : "other");

      let time = "";

      if (data.createdAt && data.createdAt.toDate) {
        const d = data.createdAt.toDate();
        time =
          d.getHours().toString().padStart(2, "0") + ":" +
          d.getMinutes().toString().padStart(2, "0");
      }

      div.innerHTML = `
        <span>${data.text}</span>
        <div class="msg-time">${time}</div>
      `;

      messagesDiv.appendChild(div);
    });

    messagesDiv.scrollTop = messagesDiv.scrollHeight;
  });
}
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