import {
  collection,
  query,
  where,
  orderBy,
  onSnapshot,
  doc,
  getDoc,
  addDoc,
  serverTimestamp,
  updateDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const db = window.db;
const auth = window.auth;

let currentChatId = null;
let unsubscribeMessages = null;

/* AUTH */
auth.onAuthStateChanged((user) => {
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

      const div = document.createElement("div");
      div.className = "chat-card";

      div.innerHTML = `
        <div class="chat-left">
          <div class="avatar">👤</div>

          <div class="chat-info">
            <b>${name} ${surname}</b><br>
            <span>${data.lastMessage || ""}</span>
          </div>
        </div>
      `;

      div.onclick = () => {

        currentChatId = chat.id;

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

/* SEND */
window.sendMessage = async function () {

  const input = document.getElementById("messageInput");
  const text = input.value;

  if (!text.trim() || !currentChatId) return;

  await addDoc(collection(db, "messages"), {
    text,
    senderId: auth.currentUser.uid,
    chatId: currentChatId,
    createdAt: serverTimestamp()
  });

  await updateDoc(doc(db, "chats", currentChatId), {
    lastMessage: text,
    lastMessageTime: serverTimestamp()
  });

  input.value = "";
};

/* LOAD MESSAGES */
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

      const div = document.createElement("div");
      div.className =
        "message " +
        (data.senderId === auth.currentUser.uid ? "me" : "other");

      div.innerHTML = `
        <span>${data.text}</span>
      `;

      messagesDiv.appendChild(div);
    });

    messagesDiv.scrollTop = messagesDiv.scrollHeight;
  });
}

/* ENTER SEND */
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