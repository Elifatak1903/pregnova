import { db } from "./app.js";

import {
    collection,
    onSnapshot,
    deleteDoc,
    doc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const list = document.getElementById("userList");
const searchInput = document.getElementById("searchInput");

let allUsers = [];
let searchText = "";
let roleFilter = "all";

window.setRoleFilter = (role) => {
    roleFilter = role;
    render();
};

searchInput.addEventListener("input", (event) => {
    searchText = event.target.value.toLowerCase();
    render();
});

onSnapshot(collection(db, "users"), (snapshot) => {
    allUsers = snapshot.docs.map(d => ({
        id: d.id,
        ...d.data()
    }));
    render();
});

function render() {
    list.innerHTML = "";

    const filtered = allUsers.filter(user => {
        if (roleFilter !== "all" && user.role !== roleFilter) return false;

        const email = (user.email || "").toLowerCase();
        const name = (user.name || "").toLowerCase();

        return email.includes(searchText) || name.includes(searchText);
    });

    if (filtered.length === 0) {
        list.innerHTML = "<p>Kullanıcı bulunamadı</p>";
        return;
    }

    filtered.forEach(user => {
        const initials = getInitials(user.name, user.email);
        const div = document.createElement("div");
        div.className = "user-card";

        div.innerHTML = `
            <div class="user-header">
                <div class="avatar">${initials}</div>
                <span class="badge ${user.role || "unknown"}">
                    ${getRoleText(user.role)}
                </span>
            </div>

            <div class="user-name">${user.name || "Kullanıcı"}</div>

            <div class="user-info">
                📧 ${user.email || "-"}
                <span>📅 Katılma: ${formatDate(user.createdAt)}</span>
            </div>

            <div class="user-actions">
                <button class="btn-delete">Sil</button>
            </div>
        `;

        div.querySelector(".btn-delete").addEventListener("click", async () => {
            if (!confirm("Silmek istediğine emin misin?")) return;
            await deleteDoc(doc(db, "users", user.id));
        });

        list.appendChild(div);
    });
}

function getRoleText(role) {
    if (role === "pregnant") return "Hamile";
    if (role === "dietitian") return "Diyetisyen";
    if (role === "gynecologist") return "Jinekolog";
    if (role === "admin") return "Admin";
    return role || "-";
}

function formatDate(timestamp) {
    if (!timestamp) return "-";
    const date = timestamp.seconds ? new Date(timestamp.seconds * 1000) : new Date(timestamp);
    return date.toLocaleDateString("tr-TR");
}

function getInitials(name, email) {
    if (name) {
        const parts = name.trim().split(" ");

        if (parts.length === 1) {
            return parts[0].charAt(0).toUpperCase();
        }

        return (
            parts[0].charAt(0) +
            parts[parts.length - 1].charAt(0)
        ).toUpperCase();
    }

    return email ? email.substring(0, 2).toUpperCase() : "U";
}
