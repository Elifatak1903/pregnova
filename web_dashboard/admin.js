import { db } from "./app.js";

import {
    collection,
    onSnapshot,
    query,
    where
} from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";


onSnapshot(collection(db, "users"), (snapshot) => {

    let totalUsers = 0;
    let activeExperts = 0;

    snapshot.forEach(docSnap => {
        const user = docSnap.data();
        console.log("USER:", user);

        totalUsers++;

        if (
            (user.role === "dietitian" || user.role === "gynecologist") &&
            user.isApproved === true
        ) {
            activeExperts++;
        }
    });

    document.getElementById("totalUsers").innerText = totalUsers;
    document.getElementById("activeExperts").innerText = activeExperts;

    console.log("✔ USERS:", { totalUsers, activeExperts });
});


onSnapshot(
    query(
        collection(db, "expert_applications"),
        where("status", "==", "pending")
    ),
    (snapshot) => {

        document.getElementById("pendingCount").innerText = snapshot.size;

        console.log("✔ PENDING:", snapshot.size);
    }
);