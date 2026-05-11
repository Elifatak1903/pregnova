import { getLanguage, setLanguage, t } from "./i18n.js";

const sidebarGroups = {
  pregnant: [
    {
      labelKey: "home",
      icon: "🏠",
      page: "pregnant.html",
      children: [
        { labelKey: "riskMeasurement", icon: "❤️", page: "risk.html" },
        { labelKey: "nutritionAnalysis", icon: "🍽️", page: "nutrition.html" },
        {
          labelKey: "measurementHistory",
          icon: "📊",
          page: "measurement_history.html"
        },
        {
          labelKey: "nutritionHistory",
          icon: "💊",
          page: "nutrition_history.html"
        }
      ]
    },
    { labelKey: "messages", icon: "💬", page: "messages_pregnant.html" },
    { labelKey: "searchExpert", icon: "🔍", page: "expert_search.html" },
    { labelKey: "myDietPlan", icon: "🥗", page: "pregnant_diet.html" },
    {
      labelKey: "account",
      icon: "👤",
      page: "account_pregnant.html",
      children: [
        { labelKey: "profileInfo", icon: "📝", page: "profile_view.html" },
        { labelKey: "profileEdit", icon: "✏️", page: "profile_edit.html" },
        { labelKey: "changePassword", icon: "🔒", page: "change_password.html" },
        {
          labelKey: "expertApplication",
          icon: "🩺",
          page: "expert_application.html"
        }
      ]
    }
  ],
  dietitian: [
    {
      labelKey: "home",
      icon: "🏠",
      page: "dietitian.html",
      children: [
        { labelKey: "recentAnalyses", icon: "📈", page: "son_analizler.html" },
        { labelKey: "writeDiet", icon: "🥗", page: "select_client_for_diet.html" }
      ]
    },
    { labelKey: "clients", icon: "👩‍⚕️", page: "dietitian_clients.html" },
    { labelKey: "requests", icon: "📥", page: "dietitian_requests.html" },
    { labelKey: "messages", icon: "💬", page: "messages_dietitian.html" },
    {
      labelKey: "account",
      icon: "👤",
      page: "account_dietitian.html",
      children: [
        { labelKey: "editProfile", icon: "✏️", page: "edit_profile.html" },
        { labelKey: "changePassword", icon: "🔒", page: "change_password.html" }
      ]
    }
  ],
  gynecologist: [
    {
      labelKey: "home",
      icon: "🏠",
      page: "gynecologist.html",
      children: [
        {
          labelKey: "recentMeasurements",
          icon: "📈",
          page: "son_olcumler.html"
        }
      ]
    },
    { labelKey: "clients", icon: "👩‍⚕️", page: "patients.html" },
    { labelKey: "requests", icon: "📥", page: "requests_gynecologist.html" },
    { labelKey: "messages", icon: "💬", page: "messages_gynecologist.html" },
    {
      labelKey: "account",
      icon: "👤",
      page: "account_gynecologist.html",
      children: [
        {
          labelKey: "editProfile",
          icon: "✏️",
          page: "edit_gynecologist_profile.html"
        },
        { labelKey: "changePassword", icon: "🔒", page: "change_password.html" }
      ]
    }
  ],
  admin: [
    {
      labelKey: "dashboard",
      icon: "📊",
      page: "admin.html",
      children: [
        {
          labelKey: "expertApplications",
          icon: "📩",
          page: "admin_requests.html"
        },
        { labelKey: "userManagement", icon: "👥", page: "admin_users.html" },
        { labelKey: "systemReports", icon: "📄", page: "admin_reports.html" }
      ]
    }
  ]
};

export function renderSidebar(role) {
  const sidebar = document.querySelector(".sidebar");
  if (!sidebar) return;

  const groups = sidebarGroups[role] || sidebarGroups.pregnant;
  const currentPage = getCurrentPage();

  sidebar.innerHTML = `
    <h2 class="sidebar-brand" onclick="go('${groups[0].page}')">
      <img src="assets/icon/app_icon.jpeg" alt="PregNova">
      <span>PregNova</span>
    </h2>
    <ul class="sidebar-menu">
      ${groups.map(group => renderGroup(group, currentPage)).join("")}
      <li class="sidebar-item sidebar-logout" onclick="logout()">
        <span>🚪</span>
        <span>${t("logout")}</span>
      </li>
    </ul>
    <div class="sidebar-language" aria-label="${t("language")}">
      <button type="button" data-sidebar-lang="tr" class="${getLanguage() === "tr" ? "active" : ""}">TR</button>
      <button type="button" data-sidebar-lang="en" class="${getLanguage() === "en" ? "active" : ""}">EN</button>
    </div>
  `;

  sidebar.querySelectorAll(".sidebar-caret").forEach(caret => {
    caret.addEventListener("click", event => {
      event.stopPropagation();
      const group = caret.closest(".sidebar-group");
      const key = group.dataset.group;
      const isOpen = group.classList.toggle("open");
      localStorage.setItem(`sidebar:${key}`, isOpen ? "open" : "closed");
    });
  });

  sidebar.querySelectorAll("[data-sidebar-lang]").forEach(button => {
    button.addEventListener("click", event => {
      event.stopPropagation();
      const lang = button.dataset.sidebarLang;
      if (lang === getLanguage()) return;
      setLanguage(lang);
      window.location.reload();
    });
  });
}

function renderGroup(group, currentPage) {
  const childPages = (group.children || []).map(child => child.page);
  const isActive = group.page === currentPage || childPages.includes(currentPage);
  const canExpand = childPages.length > 0;
  const storageKey = group.page;
  const stored = localStorage.getItem(`sidebar:${storageKey}`);
  const isOpen = canExpand && (stored === "open" || childPages.includes(currentPage));
  const label = t(group.labelKey);

  if (!canExpand) {
    return `
      <li class="sidebar-item ${isActive ? "active" : ""}" onclick="go('${group.page}')">
        <span>${group.icon}</span>
        <span>${label}</span>
      </li>
    `;
  }

  return `
    <li class="sidebar-group ${isOpen ? "open" : ""} ${isActive ? "active-group" : ""}" data-group="${storageKey}">
      <div class="sidebar-parent ${group.page === currentPage ? "active" : ""}">
        <span class="sidebar-caret" role="button" aria-label="${t("toggleSubmenu", { label })}">▸</span>
        <span class="sidebar-parent-label" onclick="go('${group.page}')">
          <span>${group.icon}</span>
          <span>${label}</span>
        </span>
      </div>
      <ul class="sidebar-submenu">
        ${group.children.map(child => renderChild(child, currentPage)).join("")}
      </ul>
    </li>
  `;
}

function renderChild(child, currentPage) {
  return `
    <li class="sidebar-subitem ${child.page === currentPage ? "active" : ""}" onclick="go('${child.page}')">
      <span>${child.icon}</span>
      <span>${t(child.labelKey)}</span>
    </li>
  `;
}

function getCurrentPage() {
  const page = window.location.pathname.split("/").pop();
  return page || "pregnant.html";
}
