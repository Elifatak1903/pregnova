import { db } from "./app.js";
import { t } from "./i18n.js";

import {
    collection,
    onSnapshot,
    updateDoc,
    doc,
    writeBatch,
    serverTimestamp
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

const list = document.getElementById("requestList");
const detailModal = document.getElementById("detailModal");
const detailContent = document.getElementById("detailContent");
const closeDetailModal = document.getElementById("closeDetailModal");

let roleFilter = "all";
let statusFilter = "all";
let searchText = "";
let allData = [];

window.setRoleFilter = (role) => {
    roleFilter = role;
    render();
};

window.setStatusFilter = (status) => {
    statusFilter = status;
    render();
};

document.getElementById("searchInput").addEventListener("input", (event) => {
    searchText = event.target.value.toLowerCase();
    render();
});

closeDetailModal.addEventListener("click", closeDetail);
detailModal.addEventListener("click", (event) => {
    if (event.target === detailModal) closeDetail();
});

onSnapshot(collection(db, "expert_applications"), (snapshot) => {
    allData = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    render();
});

function render() {
    list.innerHTML = "";

    const filtered = allData.filter(item => {
        const status = item.status || "pending";

        if (roleFilter !== "all" && item.role !== roleFilter) return false;
        if (statusFilter !== "all" && status !== statusFilter) return false;

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
        list.innerHTML = `<p>${t("noRecordsFound")}</p>`;
        return;
    }

    filtered.forEach(item => {
        const status = item.status || "pending";
        const div = document.createElement("div");
        div.className = "request-card";

        div.innerHTML = `
            <div class="request-left">
                <div class="request-email">
                    ${item.email || "-"}
                    <span class="badge ${status}">
                        ${getStatusText(status)}
                    </span>
                </div>

                <div class="request-info">
                    ${t("role")}: ${getRoleText(item.role)} |
                    ${t("licenseNo")}: ${item.licenseNumber || "-"} |
                    ${t("experience")}: ${item.experience || "-"} |
                    ${item.hospital || "-"}
                </div>
            </div>

            <div class="request-actions">
                <button class="action-btn btn-detail">${t("detail")}</button>
                ${status === "pending" ? `
                    <button class="action-btn btn-reject" aria-label="${t("rejected")}">X</button>
                    <button class="action-btn btn-approve" aria-label="${t("approved")}">OK</button>
                ` : ""}
            </div>
        `;

        div.querySelector(".btn-detail").addEventListener("click", () => {
            showDetail(item);
        });

        div.querySelector(".btn-reject")?.addEventListener("click", async () => {
            await rejectExpert(item);
        });

        div.querySelector(".btn-approve")?.addEventListener("click", async () => {
            await approveExpert(item);
        });

        list.appendChild(div);
    });
}

function showDetail(item) {
    const diplomaUrl = item.documentUrl || item.diplomaUrl || "";
    const status = item.status || "pending";

    detailContent.innerHTML = `
        <div class="detail-row"><span>${t("email")}</span><strong>${item.email || "-"}</strong></div>
        <div class="detail-row"><span>${t("role")}</span><strong>${getRoleText(item.role)}</strong></div>
        <div class="detail-row"><span>${t("status")}</span><strong>${getStatusText(status)}</strong></div>
        <div class="detail-row"><span>${t("licenseNo")}</span><strong>${item.licenseNumber || "-"}</strong></div>
        <div class="detail-row"><span>${t("experience")}</span><strong>${item.experience || "-"}</strong></div>
        <div class="detail-row"><span>${t("phone")}</span><strong>${item.phone || "-"}</strong></div>
        <div class="detail-row"><span>${t("institution")}</span><strong>${item.hospital || "-"}</strong></div>
        <div class="detail-row"><span>${t("city")}</span><strong>${item.city || "-"}</strong></div>
        <div class="detail-actions">
            ${diplomaUrl
                ? `<a class="action-btn btn-open-document" href="${diplomaUrl}" target="_blank" rel="noopener">${t("viewDiploma")}</a>`
                : `<span class="empty-document">${t("noDocumentFound")}</span>`}
        </div>
    `;

    detailModal.classList.remove("hidden");
}

function closeDetail() {
    detailModal.classList.add("hidden");
    detailContent.innerHTML = "";
}

async function approveExpert(data) {
    const diplomaUrl = data.documentUrl || data.diplomaUrl || "";
    const uid = String(data.uid || "");
    const role = String(data.role || "");

    if (!uid) {
        alert("Başvuruda kullanıcı ID bilgisi yok.");
        return;
    }

    if (role !== "gynecologist" && role !== "dietitian") {
        alert("Başvuruda geçerli uzman rolü yok.");
        return;
    }

    const batch = writeBatch(db);

    batch.set(doc(db, "users", uid), {
        role,
        diplomaUrl,
        isApproved: true,
        expertApplicationStatus: "approved",
        approvedAt: serverTimestamp()
    }, { merge: true });

    batch.update(doc(db, "expert_applications", data.id), {
        status: "approved",
        diplomaUrl,
        approvedAt: serverTimestamp()
    });

    batch.set(doc(collection(db, "notification")), {
        uid,
        type: "expert_application",
        title: t("applicationApprovedTitle"),
        message: t("applicationApprovedMessage"),
        actionPage: "expert_application.html",
        isRead: false,
        createdAt: serverTimestamp()
    });

    try {
        await batch.commit();
    } catch (error) {
        console.error("Approve expert error:", error);
        alert(t("errorWithMessage", { message: error.message || error }));
    }
}

async function rejectExpert(data) {
    const uid = String(data.uid || "");
    const batch = writeBatch(db);

    batch.update(doc(db, "expert_applications", data.id), {
        status: "rejected",
        rejectedAt: serverTimestamp()
    });

    if (uid) {
        batch.set(doc(db, "users", uid), {
            expertApplicationStatus: "rejected"
        }, { merge: true });
    }

    try {
        await batch.commit();
    } catch (error) {
        console.error("Reject expert error:", error);
        alert(t("errorWithMessage", { message: error.message || error }));
    }
}

function getRoleText(role) {
    if (role === "gynecologist") return t("gynecologist");
    if (role === "dietitian") return t("dietitian");
    if (role === "pregnant") return t("pregnant");
    return role || "-";
}

function getStatusText(status) {
    if (status === "approved") return t("approvedShort");
    if (status === "rejected") return t("rejectedShort");
    return t("waiting");
}
