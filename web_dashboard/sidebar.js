const sidebarGroups = {
  pregnant: [
    {
      label: "Ana Sayfa",
      icon: "🏠",
      page: "pregnant.html",
      children: [
        { label: "Risk Ölçüm", icon: "❤️", page: "risk.html" },
        { label: "Besin Analizi", icon: "🍽️", page: "nutrition.html" },
        { label: "Ölçüm Geçmişi", icon: "📊", page: "measurement_history.html" },
        { label: "Besin Geçmişi", icon: "💊", page: "nutrition_history.html" }
      ]
    },
    { label: "Mesajlar", icon: "💬", page: "messages_pregnant.html" },
    { label: "Uzman Ara", icon: "🔍", page: "expert_search.html" },
    { label: "Diyet Planım", icon: "🥗", page: "pregnant_diet.html" },
    {
      label: "Hesabım",
      icon: "👤",
      page: "account_pregnant.html",
      children: [
        { label: "Profil Bilgileri", icon: "📝", page: "profile_view.html" },
        { label: "Profili Düzenle", icon: "✏️", page: "profile_edit.html" },
        { label: "Şifre Değiştir", icon: "🔒", page: "change_password.html" },
        { label: "Uzman Olarak Başvur", icon: "🩺", page: "expert_application.html" }
      ]
    }
  ],
  dietitian: [
    {
      label: "Ana Sayfa",
      icon: "🏠",
      page: "dietitian.html",
      children: [
        { label: "Son Analizler", icon: "📈", page: "son_analizler.html" },
        { label: "Diyet Yaz", icon: "🥗", page: "select_client_for_diet.html" }
      ]
    },
    { label: "Danışanlar", icon: "👩‍⚕️", page: "dietitian_clients.html" },
    { label: "İstekler", icon: "📥", page: "dietitian_requests.html" },
    { label: "Mesajlar", icon: "💬", page: "messages_dietitian.html" },
    {
      label: "Hesabım",
      icon: "👤",
      page: "account_dietitian.html",
      children: [
        { label: "Profil Düzenle", icon: "✏️", page: "edit_profile.html" },
        { label: "Şifre Değiştir", icon: "🔒", page: "change_password.html" }
      ]
    }
  ],
  gynecologist: [
    {
      label: "Ana Sayfa",
      icon: "🏠",
      page: "gynecologist.html",
      children: [
        { label: "Son Ölçümler", icon: "📈", page: "son_olcumler.html" }
      ]
    },
    { label: "Danışanlar", icon: "👩‍⚕️", page: "patients.html" },
    { label: "İstekler", icon: "📥", page: "requests_gynecologist.html" },
    { label: "Mesajlar", icon: "💬", page: "messages_gynecologist.html" },
    {
      label: "Hesabım",
      icon: "👤",
      page: "account_gynecologist.html",
      children: [
        { label: "Profil Düzenle", icon: "✏️", page: "edit_gynecologist_profile.html" },
        { label: "Şifre Değiştir", icon: "🔒", page: "change_password.html" }
      ]
    }
  ],
  admin: [
    {
      label: "Dashboard",
      icon: "📊",
      page: "admin.html",
      children: [
        { label: "Uzman Başvuruları", icon: "📩", page: "admin_requests.html" },
        { label: "Kullanıcı Yönetimi", icon: "👥", page: "admin_users.html" },
        { label: "Sistem Raporları", icon: "📄", page: "admin_reports.html" }
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
        <span>Çıkış</span>
      </li>
    </ul>
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
}

function renderGroup(group, currentPage) {
  const childPages = (group.children || []).map(child => child.page);
  const isActive = group.page === currentPage || childPages.includes(currentPage);
  const canExpand = childPages.length > 0;
  const storageKey = group.page;
  const stored = localStorage.getItem(`sidebar:${storageKey}`);
  const isOpen = canExpand && (stored === "open" || childPages.includes(currentPage));

  if (!canExpand) {
    return `
      <li class="sidebar-item ${isActive ? "active" : ""}" onclick="go('${group.page}')">
        <span>${group.icon}</span>
        <span>${group.label}</span>
      </li>
    `;
  }

  return `
    <li class="sidebar-group ${isOpen ? "open" : ""} ${isActive ? "active-group" : ""}" data-group="${storageKey}">
      <div class="sidebar-parent ${group.page === currentPage ? "active" : ""}">
        <span class="sidebar-caret" role="button" aria-label="${group.label} alt menüsünü aç/kapat">▸</span>
        <span class="sidebar-parent-label" onclick="go('${group.page}')">
          <span>${group.icon}</span>
          <span>${group.label}</span>
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
      <span>${child.label}</span>
    </li>
  `;
}

function getCurrentPage() {
  const page = window.location.pathname.split("/").pop();
  return page || "pregnant.html";
}
