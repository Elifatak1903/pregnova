import { db } from "./app.js";

import {
    collection,
    onSnapshot,
    updateDoc,
    doc,
    writeBatch,
    addDoc
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const list = document.getElementById("requestList");

let roleFilter = "all";
let statusFilter = "all";
let searchText = "";

window.setRoleFilter = (role) => {
    roleFilter = role;
    render();
};

window.setStatusFilter = (status) => {
    statusFilter = status;
    render();
};

document.getElementById("searchInput").addEventListener("input", (e) => {
    searchText = e.target.value.toLowerCase();
    render();
});

let allData = [];

onSnapshot(collection(db, "expert_applications"), (snapshot) => {
    allData = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    render();
});

function render() {

    list.innerHTML = "";

    const filtered = allData.filter(item => {

        if (roleFilter !== "all" && item.role !== roleFilter) return false;
        if (statusFilter !== "all" && item.status !== statusFilter) return false;

        if (searchText) {
            return (
                item.email?.toLowerCase().includes(searchText) ||
                item.hospital?.toLowerCase().includes(searchText) ||
                item.licenseNumber?.toLowerCase().includes(searchText)
            );
        }

        return true;
    });

    if (filtered.length === 0) {
        list.innerHTML = "<p>Kayıt bulunamadı</p>";
        return;
    }

    filtered.forEach(item => {

        const div = document.createElement("div");
        div.className = "request-card";

        const badgeClass = item.status || "pending";

        div.innerHTML = `
            <div class="request-left">
                <div class="request-email">
                    ${item.email}
                    <span class="badge ${badgeClass}">
                        ${item.status === "approved" ? "Onaylandı" :
                          item.status === "rejected" ? "Reddedildi" : "Bekliyor"}
                    </span>
                </div>

                <div class="request-info">
                    Rol: ${item.role} |
                    Lisans: ${item.licenseNumber} |
                    Deneyim: ${item.experience || "-"} |
                    ${item.hospital || ""}
                </div>
            </div>

            <div class="request-actions">
                <button class="action-btn btn-detail">Detay</button>
                ${item.status === "pending" ? `
                    <button class="action-btn btn-reject">✖</button>
                    <button class="action-btn btn-approve">✔</button>
                ` : ""}
            </div>
        `;

        // reject
        div.querySelector(".btn-reject")?.addEventListener("click", async () => {
            await updateDoc(doc(db, "expert_applications", item.id), {
                status: "rejected"
            });
        });

        // approve
        div.querySelector(".btn-approve")?.addEventListener("click", async () => {
            await approveExpert(item);
        });

        list.appendChild(div);
    });
}

async function approveExpert(data) {

    const batch = writeBatch(db);

    batch.update(doc(db, "users", data.uid), {
        role: data.role,
        diplomaUrl: data.documentUrl
    });

    batch.update(doc(db, "expert_applications", data.id), {
        status: "approved"
    });

    await addDoc(collection(db, "notification"), {
        uid: data.uid,
        title: "Başvurun Onaylandı 🎉",
        message: "Artık uzman olarak giriş yapabilirsin.",
        isRead: false,
        createdAt: new Date()
    });

    await batch.commit();
}