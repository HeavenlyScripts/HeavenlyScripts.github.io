const router = {
  currentPage: 'home',

  navigateTo(pageId) {
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));

    const targetPage = document.getElementById('page-' + pageId);
    if (targetPage) targetPage.classList.add('active');

    const targetLink = document.querySelector('[data-page="' + pageId + '"]');
    if (targetLink) targetLink.classList.add('active');

    this.currentPage = pageId;
    window.scrollTo({ top: 0, behavior: 'smooth' });

    if (pageId === 'docs') setTimeout(() => docObserver.observe(), 100);

    closeMobileNav();
    closeSearch();
  }
};

function closeMobileNav() {
  document.querySelector('.nav-links').classList.remove('mobile-open');
}

function closeSearch() {
  document.querySelector('.search-results').classList.remove('open');
  document.querySelector('.search-bar input').value = '';
}

const docObserver = {
  observer: null,

  observe() {
    if (this.observer) this.observer.disconnect();

    const sections = document.querySelectorAll('.doc-section');

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');

          const id = entry.target.getAttribute('id');
          document.querySelectorAll('.sidebar-link').forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('data-section') === id) link.classList.add('active');
          });
        }
      });
    }, { threshold: 0.1, rootMargin: '-60px 0px -40% 0px' });

    sections.forEach(section => this.observer.observe(section));
  }
};

const searchData = [
  { title: 'Getting Started',        type: 'Docs', page: 'docs', section: 'getting-started' },
  { title: 'Installation',           type: 'Docs', page: 'docs', section: 'installation' },
  { title: 'Theming',                type: 'Docs', page: 'docs', section: 'theming' },
  { title: 'Window',                 type: 'Docs', page: 'docs', section: 'window' },
  { title: 'Button',                 type: 'Docs', page: 'docs', section: 'button' },
  { title: 'Toggle',                 type: 'Docs', page: 'docs', section: 'toggle' },
  { title: 'Slider',                 type: 'Docs', page: 'docs', section: 'slider' },
  { title: 'Dropdown',               type: 'Docs', page: 'docs', section: 'dropdown' },
  { title: 'MultiDropdown',          type: 'Docs', page: 'docs', section: 'multi-dropdown' },
  { title: 'TextBox',                type: 'Docs', page: 'docs', section: 'textbox' },
  { title: 'Bind',                   type: 'Docs', page: 'docs', section: 'bind' },
  { title: 'Colorpicker',            type: 'Docs', page: 'docs', section: 'colorpicker' },
  { title: 'Stepper',                type: 'Docs', page: 'docs', section: 'stepper' },
  { title: 'Label',                  type: 'Docs', page: 'docs', section: 'label' },
  { title: 'Paragraph',              type: 'Docs', page: 'docs', section: 'paragraph' },
  { title: 'ProgressBar',            type: 'Docs', page: 'docs', section: 'progressbar' },
  { title: 'KeyValue',               type: 'Docs', page: 'docs', section: 'keyvalue' },
  { title: 'Section',                type: 'Docs', page: 'docs', section: 'section' },
  { title: 'Separator',              type: 'Docs', page: 'docs', section: 'separator' },
  { title: 'Grid',                   type: 'Docs', page: 'docs', section: 'grid' },
  { title: 'Notify',                 type: 'Docs', page: 'docs', section: 'notify' },
  { title: 'CNotify',                type: 'Docs', page: 'docs', section: 'cnotify' },
  { title: 'Modal',                  type: 'Docs', page: 'docs', section: 'modal' },
  { title: 'Toast',                  type: 'Docs', page: 'docs', section: 'toast' },
  { title: 'Topbar',                 type: 'Docs', page: 'docs', section: 'topbar' },
  { title: 'Radial Menu',            type: 'Docs', page: 'docs', section: 'radial' },
  { title: 'Keybind List',           type: 'Docs', page: 'docs', section: 'keybindlist' },
  { title: 'Flags & Config',         type: 'Docs', page: 'docs', section: 'flags' },
  { title: 'Startup Animations',     type: 'Docs', page: 'docs', section: 'startup' },
  { title: 'Tab Sections',           type: 'Docs', page: 'docs', section: 'tabsection' },
  { title: 'Collapsible Tab Sections', type: 'Docs', page: 'docs', section: 'tabsection' },
  { title: 'User Section',           type: 'Docs', page: 'docs', section: 'usersection' },
  { title: 'Owner Buttons',          type: 'Docs', page: 'docs', section: 'owner-buttons' },
  { title: 'Owner Button Dropdown',  type: 'Docs', page: 'docs', section: 'owner-buttons' },
  { title: 'Key System',             type: 'Docs', page: 'docs', section: 'keysystem' },
  { title: 'SetTitle',               type: 'Docs', page: 'docs', section: 'settitle' },
  { title: 'Lock / Unlock',          type: 'Docs', page: 'docs', section: 'lock' },
  { title: 'Flash',                  type: 'Docs', page: 'docs', section: 'flash' },
  { title: 'Toggle Confirm',         type: 'Docs', page: 'docs', section: 'confirm-toggle' },
  { title: 'Locked Toggle',          type: 'Docs', page: 'docs', section: 'locked-toggle' },
  { title: 'Window Controls',        type: 'Docs', page: 'docs', section: 'window-controls' },
  { title: 'Hover Maximize',         type: 'Docs', page: 'docs', section: 'hover-maximize' },
  { title: 'Watermark',              type: 'Docs', page: 'docs', section: 'watermark' },
  { title: 'Destroy',                type: 'Docs', page: 'docs', section: 'destroy' },
  { title: 'Heavenly UI Library',    type: 'Project', page: 'portfolio' },
  { title: 'Heavenly Toolkit',       type: 'Project', page: 'portfolio' },
  { title: 'Emergency Hamburg',      type: 'Project', page: 'portfolio' },
  { title: 'Arsenal Script',         type: 'Project', page: 'portfolio' },
  { title: 'Flick Script',           type: 'Project', page: 'portfolio' },
  { title: 'Frontlines Script',      type: 'Project', page: 'portfolio' },
];

function showDocsModal() {
  const overlay = document.createElement('div');
  overlay.className = 'lib-modal-overlay';
  overlay.innerHTML = `
    <div class="lib-modal">
      <div class="lib-modal-header">
        <span class="lib-modal-eyebrow">Documentation</span>
        <h2 class="lib-modal-title">Choose a Library</h2>
        <p class="lib-modal-sub">Select which Heavenly product you want to read docs for.</p>
      </div>
      <div class="lib-modal-options">
        <button class="lib-option active-option" data-lib="lib" onclick="selectLib('lib')">
          <span class="lib-option-name">Heavenly Lib</span>
          <span class="lib-option-sub">An Heavily Modified fork of the UI-Library "Orion", adapted for Performace, User Friendliness. </span>
          <span class="lib-option-badge">Available</span>
        </button>
        <button class="lib-option" data-lib="interface" onclick="selectLib('interface')">
          <span class="lib-option-name">Heavenly Interface</span>
          <span class="lib-option-sub">Custom UI</span>
          <span class="lib-option-badge coming">Coming Soon</span>
        </button>
        <button class="lib-option" data-lib="framework" onclick="selectLib('framework')">
          <span class="lib-option-name">Heavenly Framework</span>
          <span class="lib-option-sub">Custom UI</span>
          <span class="lib-option-badge coming">Coming Soon</span>
        </button>
      </div>
      <div class="lib-modal-footer">
        <button class="lib-modal-close" onclick="closeLibModal()">Cancel</button>
        <button class="lib-modal-confirm" onclick="confirmLib()">Open Docs →</button>
      </div>
    </div>
  `;
  document.body.appendChild(overlay);
  requestAnimationFrame(() => overlay.classList.add('visible'));

  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) closeLibModal();
  });
}

let selectedLib = 'lib';

function selectLib(lib) {
  selectedLib = lib;
  document.querySelectorAll('.lib-option').forEach(btn => {
    btn.classList.toggle('active-option', btn.getAttribute('data-lib') === lib);
  });
}

function confirmLib() {
  if (selectedLib === 'lib') {
    closeLibModal();
    router.navigateTo('docs');
  } else {
    const btn = document.querySelector(`.lib-option[data-lib="${selectedLib}"]`);
    if (btn) {
      btn.classList.add('shake');
      setTimeout(() => btn.classList.remove('shake'), 500);
    }
  }
}

function closeLibModal() {
  const overlay = document.querySelector('.lib-modal-overlay');
  if (!overlay) return;
  overlay.classList.remove('visible');
  setTimeout(() => overlay.remove(), 280);
  selectedLib = 'lib';
  document.querySelectorAll('.lib-option').forEach(btn => {
    btn.classList.toggle('active-option', btn.getAttribute('data-lib') === 'lib');
  });
}

function handleSearch(query) {
  const resultsContainer = document.querySelector('.search-results');

  if (!query || query.trim().length < 1) {
    resultsContainer.classList.remove('open');
    return;
  }

  const filtered = searchData.filter(item =>
    item.title.toLowerCase().includes(query.toLowerCase()) ||
    item.type.toLowerCase().includes(query.toLowerCase())
  );

  if (filtered.length === 0) {
    resultsContainer.innerHTML = '<div class="search-empty">No results found</div>';
  } else {
    resultsContainer.innerHTML = filtered.slice(0, 8).map(item => `
      <div class="search-result-item" onclick="handleSearchSelect('${item.page}', '${item.section || ''}')">
        <span class="search-result-title">${item.title}</span>
        <span class="search-result-type">${item.type}</span>
      </div>
    `).join('');
  }

  resultsContainer.classList.add('open');
}

function handleSearchSelect(page, section) {
  router.navigateTo(page);
  closeSearch();

  if (section) {
    setTimeout(() => {
      const target = document.getElementById(section);
      if (target) target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 350);
  }
}

function scrollToSection(sectionId) {
  const target = document.getElementById(sectionId);
  if (target) {
    const offset = 80;
    const top = target.getBoundingClientRect().top + window.scrollY - offset;
    window.scrollTo({ top, behavior: 'smooth' });
  }
}

function copyCode(btn) {
  const pre = btn.closest('.code-block').querySelector('pre');
  navigator.clipboard.writeText(pre.textContent).then(() => {
    const original = btn.textContent;
    btn.textContent = 'Copied';
    setTimeout(() => btn.textContent = original, 1500);
  });
}

function toggleTheme() {
  const html = document.documentElement;
  const isDark = html.getAttribute('data-theme') !== 'light';
  html.setAttribute('data-theme', isDark ? 'light' : 'dark');
  const btn = document.querySelector('.theme-toggle');
  btn.textContent = isDark ? '☾' : '☀';
}

function toggleSidebar() {
  const sidebar = document.querySelector('.sidebar');
  const overlay = document.querySelector('.mobile-sidebar-overlay');
  sidebar.classList.toggle('open');
  overlay.classList.toggle('open');
}

function closeSidebar() {
  document.querySelector('.sidebar').classList.remove('open');
  document.querySelector('.mobile-sidebar-overlay').classList.remove('open');
}

function setupProjectFilter() {
  const filterBtns = document.querySelectorAll('.filter-btn');
  const projectCards = document.querySelectorAll('.project-card');

  filterBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      filterBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      const filter = btn.getAttribute('data-filter');

      projectCards.forEach(card => {
        const tags = card.getAttribute('data-tags') || '';
        card.style.display = (filter === 'all' || tags.includes(filter)) ? 'flex' : 'none';
      });
    });
  });
}

function init() {
  document.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', () => {
      const page = link.getAttribute('data-page');
      if (page === 'docs') {
        showDocsModal();
      } else {
        router.navigateTo(page);
      }
    });
  });

  document.querySelectorAll('[data-goto]').forEach(el => {
    el.addEventListener('click', () => {
      const goto = el.getAttribute('data-goto');
      if (goto === 'docs') {
        showDocsModal();
      } else {
        router.navigateTo(goto);
      }
    });
  });

  document.querySelectorAll('.sidebar-link').forEach(link => {
    link.addEventListener('click', () => {
      const section = link.getAttribute('data-section');
      closeSidebar();
      setTimeout(() => scrollToSection(section), 100);
    });
  });

  document.querySelectorAll('.inline-link[data-section]').forEach(link => {
    link.addEventListener('click', () => {
      const section = link.getAttribute('data-section');
      router.navigateTo('docs');
      setTimeout(() => scrollToSection(section), 350);
    });
  });

  const searchInput = document.querySelector('.search-bar input');
  searchInput.addEventListener('input', (e) => handleSearch(e.target.value));
  searchInput.addEventListener('focus', (e) => {
    if (e.target.value) handleSearch(e.target.value);
  });

  document.addEventListener('click', (e) => {
    if (!e.target.closest('.search-wrapper')) closeSearch();
    if (!e.target.closest('.nav-links') && !e.target.closest('.hamburger')) closeMobileNav();
  });

  document.querySelector('.hamburger').addEventListener('click', () => {
    if (router.currentPage === 'docs') {
      toggleSidebar();
    } else {
      document.querySelector('.nav-links').classList.toggle('mobile-open');
    }
  });

  document.querySelector('.mobile-sidebar-overlay').addEventListener('click', closeSidebar);
  document.querySelector('.theme-toggle').addEventListener('click', toggleTheme);

  setupProjectFilter();
  router.navigateTo('home');
}

document.addEventListener('DOMContentLoaded', init);
