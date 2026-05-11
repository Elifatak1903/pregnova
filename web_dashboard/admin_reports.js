import { db } from "./app.js";
import { t } from "./i18n.js";
import { collection, getDocs } from "https://www.gstatic.com/firebasejs/12.12.0/firebase-firestore.js";

async function loadReports() {
    let totalUsers = 0;
    let pregnant = 0;
    let doctors = 0;
    let dietitians = 0;
    let riskMeasurements = 0;
    let nutritionAnalyses = 0;
    let pendingApplications = 0;
    let approvedApplications = 0;
    let rejectedApplications = 0;
    let high = 0;
    let medium = 0;
    let low = 0;

    const usersSnap = await getDocs(collection(db, "users"));
    const risksSnap = await getDocs(collection(db, "risk_olcumleri"));
    const nutritionSnap = await getDocs(collection(db, "besin_analizleri"));
    const applicationsSnap = await getDocs(collection(db, "expert_applications"));

    totalUsers = usersSnap.size;
    riskMeasurements = risksSnap.size;
    nutritionAnalyses = nutritionSnap.size;

    usersSnap.forEach(docSnap => {
        const user = docSnap.data();

        if (user.role === "pregnant") pregnant++;
        if (user.role === "gynecologist") doctors++;
        if (user.role === "dietitian") dietitians++;
    });

    applicationsSnap.forEach(docSnap => {
        const status = docSnap.data().status || "pending";

        if (status === "approved") {
            approvedApplications++;
        } else if (status === "rejected") {
            rejectedApplications++;
        } else {
            pendingApplications++;
        }
    });

    risksSnap.forEach(docSnap => {
        const risk = docSnap.data();

        [
            risk.preeklampsiRisk,
            risk.diyabetRisk,
            risk.pretermRisk
        ].forEach(value => {
            const normalized = String(value || "LOW").trim().toUpperCase();

            if (normalized === "HIGH") high++;
            else if (normalized === "MEDIUM") medium++;
            else low++;
        });
    });

    const totalRisk = high + medium + low;
    const highP = percent(high, totalRisk);
    const medP = percent(medium, totalRisk);
    const lowP = percent(low, totalRisk);

    setText("totalUsers", totalUsers);
    setText("pregnantUsers", pregnant);
    setText("doctorUsers", doctors);
    setText("dietitianUsers", dietitians);
    setText("riskMeasurements", riskMeasurements);
    setText("nutritionAnalyses", nutritionAnalyses);
    setText("pendingApplications", pendingApplications);
    setText("approvedApplications", approvedApplications);
    setText("rejectedApplications", rejectedApplications);

    renderChart(high, medium, low);
    renderBars(high, medium, low, highP, medP, lowP);
    renderInsight(highP);
}

function setText(id, value) {
    const element = document.getElementById(id);
    if (element) element.innerText = value;
}

function percent(value, total) {
    return total ? ((value / total) * 100).toFixed(0) : 0;
}

function renderChart(high, medium, low) {
    const ctx = document.getElementById("riskChart");
    if (!ctx) return;

    new Chart(ctx, {
        type: "doughnut",
        data: {
            labels: [t("high"), t("medium"), t("low")],
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
    const riskBars = document.getElementById("riskBars");
    if (!riskBars) return;

    riskBars.innerHTML = `
        ${bar(t("highRisk"), high, hp, "#EF5350")}
        ${bar(t("mediumRisk"), medium, mp, "#FFA000")}
        ${bar(t("lowRisk"), low, lp, "#00B894")}
    `;
}

function bar(title, value, percentValue, color) {
    return `
        <div class="risk-box">
            <div class="risk-header">
                <span>${title}</span>
                <strong>${value} (${percentValue}%)</strong>
            </div>
            <div class="progress">
                <div class="bar" style="width:${percentValue}%; background:${color}"></div>
            </div>
        </div>
    `;
}

function renderInsight(highPercent) {
    let text = t("systemStable");
    let color = "rgba(0,184,148,0.15)";

    if (highPercent > 30) {
        text = t("highRiskNeedsAttention");
        color = "rgba(239,83,80,0.15)";
    } else if (highPercent > 15) {
        text = t("riskRateIncreasing");
        color = "rgba(255,160,0,0.15)";
    }

    const card = document.getElementById("insightCard");
    if (card) {
        card.style.background = color;
        card.innerText = text;
    }

    setText("highPercentText", t("highRiskRate", { percent: highPercent }));
    setText("systemComment", text);
}

loadReports().catch(error => {
    console.error("Admin reports could not be loaded:", error);
    setText("insightCard", t("reportsLoadError"));
});
