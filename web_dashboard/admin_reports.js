import { db } from "./app.js";
import { collection, getDocs } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

async function loadReports() {

    let totalUsers = 0;
    let pregnant = 0;
    let doctors = 0;
    let dietitians = 0;

    let high = 0, medium = 0, low = 0;

    const usersSnap = await getDocs(collection(db, "users"));

    totalUsers = usersSnap.size;

    usersSnap.forEach(doc => {
        const u = doc.data();

        if (u.role === "pregnant") pregnant++;
        if (u.role === "gynecologist") doctors++;
        if (u.role === "dietitian") dietitians++;
    });

    const risksSnap = await getDocs(collection(db, "risk_olcumleri"));

    risksSnap.forEach(doc => {
        const r = doc.data();

        const list = [
            r.preeklampsiRisk || "LOW",
            r.diyabetRisk || "LOW",
            r.pretermRisk || "LOW"
        ];

        list.forEach(val => {
            if (val === "HIGH") high++;
            if (val === "MEDIUM") medium++;
            if (val === "LOW") low++;
        });
    });

    const total = high + medium + low;

    const highP = percent(high, total);
    const medP = percent(medium, total);
    const lowP = percent(low, total);

    document.getElementById("totalUsers").innerText = totalUsers;
    document.getElementById("pregnantUsers").innerText = pregnant;
    document.getElementById("doctorUsers").innerText = doctors;
    document.getElementById("dietitianUsers").innerText = dietitians;

    renderChart(high, medium, low);
    renderBars(high, medium, low, highP, medP, lowP);
    renderInsight(highP);
}

function percent(val, total) {
    return total ? ((val / total) * 100).toFixed(0) : 0;
}

function renderChart(high, medium, low) {

    const ctx = document.getElementById("riskChart");

    new Chart(ctx, {
        type: "doughnut",
        data: {
            labels: ["High", "Medium", "Low"],
            datasets: [{
                data: [high, medium, low],
                backgroundColor: ["#EF5350", "#FFA000", "#00B894"],
                borderWidth: 0
            }]
        },
        options: {
            cutout: "70%",
            plugins: {
                legend: {
                    position: "bottom"
                }
            }
        }
    });
}

function renderBars(high, medium, low, hp, mp, lp) {

    document.getElementById("riskBars").innerHTML = `
        ${bar("HIGH Risk", high, hp, "#EF5350")}
        ${bar("MEDIUM Risk", medium, mp, "#FFA000")}
        ${bar("LOW Risk", low, lp, "#00B894")}
    `;
}

function bar(title, value, percent, color) {
    return `
        <div class="risk-box">
            <div class="risk-header">
                <span>${title}</span>
                <strong>${value} (${percent}%)</strong>
            </div>
            <div class="progress">
                <div class="bar" style="width:${percent}%; background:${color}"></div>
            </div>
        </div>
    `;
}

function renderInsight(highPercent) {

    let text = "✅ Sistem stabil";
    let color = "rgba(0,184,148,0.15)";

    if (highPercent > 30) {
        text = "⚠️ Sistem yüksek risk!";
        color = "rgba(239,83,80,0.15)";
    } else if (highPercent > 15) {
        text = "⚠️ Risk artıyor";
        color = "rgba(255,160,0,0.15)";
    }

    const card = document.getElementById("insightCard");
    card.style.background = color;
    card.innerText = text;

    document.getElementById("highPercentText").innerText =
        `High risk oranı: ${highPercent}%`;

    document.getElementById("systemComment").innerText = text;
}

loadReports();