/**
 * Landing "Guardianes de las Luciérnagas".
 *
 * Este archivo contenía por error el JS de otro proyecto (un catálogo de
 * anime): buscaba ids como #grid-trending o #search-input que no existen
 * aquí, así que reventaba con un TypeError en la primera línea del
 * DOMContentLoaded y se llevaba por delante todo lo demás — incluido el
 * menú móvil, que dejaba la landing inusable por debajo de 768px.
 *
 * El CSS ya tenía definidas todas las clases que se usan abajo
 * (.firefly, .navbar.scrolled, .nav-links a.active, .fade-up.visible);
 * lo único que faltaba era quien las accionara.
 */

/** Respeta a quien haya pedido menos animación en su sistema. */
const prefersReducedMotion = window.matchMedia(
  '(prefers-reduced-motion: reduce)'
).matches;

document.addEventListener('DOMContentLoaded', () => {
  initFireflies();
  initNavbarScroll();
  initMobileMenu();
  initScrollSpy();
  initRevealOnScroll();
});

// ── Luciérnagas flotantes ──────────────────────────────────────────
// El keyframe `float-firefly` del CSS interpola hasta translate(var(--dx),
// var(--dy)); sin esas dos custom properties el transform es inválido y la
// partícula no se movería. Se fijan aquí junto con la posición y el ritmo,
// que se aleatorizan para que no parpadeen todas a la vez.
function initFireflies() {
  const container = document.getElementById('fireflies');
  if (!container || prefersReducedMotion) return;

  const count = window.innerWidth < 768 ? 15 : 30;
  const fragment = document.createDocumentFragment();

  for (let i = 0; i < count; i++) {
    const firefly = document.createElement('div');
    firefly.className = 'firefly';
    firefly.style.left = `${Math.random() * 100}%`;
    firefly.style.top = `${Math.random() * 100}%`;
    firefly.style.setProperty('--dx', `${(Math.random() - 0.5) * 200}px`);
    firefly.style.setProperty('--dy', `${(Math.random() - 0.5) * 200}px`);
    firefly.style.animationDelay = `${Math.random() * 8}s`;
    firefly.style.animationDuration = `${6 + Math.random() * 6}s`;
    fragment.appendChild(firefly);
  }

  container.appendChild(fragment);
}

// ── Navbar opaca al hacer scroll ───────────────────────────────────
function initNavbarScroll() {
  const navbar = document.querySelector('.navbar');
  if (!navbar) return;

  const update = () => navbar.classList.toggle('scrolled', window.scrollY > 50);
  update();
  window.addEventListener('scroll', update, { passive: true });
}

// ── Menú hamburguesa ───────────────────────────────────────────────
// Por debajo de 768px el CSS oculta .nav-links y muestra el botón; la
// clase .open (añadida al CSS junto a ese breakpoint) es la que lo
// despliega.
function initMobileMenu() {
  const button = document.getElementById('mobile-menu');
  const links = document.querySelector('.nav-links');
  if (!button || !links) return;

  const setOpen = (open) => {
    links.classList.toggle('open', open);
    button.setAttribute('aria-expanded', String(open));
    const icon = button.querySelector('i');
    if (icon) icon.className = open ? 'fa-solid fa-xmark' : 'fa-solid fa-bars';
  };

  button.setAttribute('aria-label', 'Abrir menú de navegación');
  setOpen(false);

  button.addEventListener('click', (e) => {
    e.stopPropagation();
    setOpen(!links.classList.contains('open'));
  });

  // Al tocar un enlace el menú debe cerrarse solo: si no, tapa la sección
  // a la que acabas de saltar.
  links.querySelectorAll('a').forEach((link) =>
    link.addEventListener('click', () => setOpen(false))
  );

  document.addEventListener('click', (e) => {
    if (!links.contains(e.target) && !button.contains(e.target)) setOpen(false);
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') setOpen(false);
  });
}

// ── Enlace activo según la sección visible ─────────────────────────
function initScrollSpy() {
  const links = Array.from(document.querySelectorAll('.nav-links a[href^="#"]'));
  if (!links.length) return;

  const sections = links
    .map((link) => {
      const id = link.getAttribute('href').slice(1);
      const section = id ? document.getElementById(id) : null;
      return section ? { link, section } : null;
    })
    .filter(Boolean);

  if (!sections.length) return;

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        const match = sections.find((s) => s.section === entry.target);
        if (!match) return;
        links.forEach((l) => l.classList.remove('active'));
        match.link.classList.add('active');
      });
    },
    // Banda estrecha a la altura del tercio superior: marca la sección
    // que el lector está mirando, no la que apenas asoma por abajo.
    { rootMargin: '-30% 0px -60% 0px', threshold: 0 }
  );

  sections.forEach(({ section }) => observer.observe(section));
}

// ── Aparición progresiva al hacer scroll ───────────────────────────
// El CSS ya define .fade-up / .fade-up.visible, pero el HTML no aplica la
// clase a ningún elemento. Se asigna aquí para no tener que tocar cada
// tarjeta en index.php.
function initRevealOnScroll() {
  const targets = document.querySelectorAll(
    '.feature-card, .step-card, .gallery-card, .download-card, .section-header'
  );
  if (!targets.length) return;

  // .fade-up parte de opacity:0, así que solo se aplica si de verdad hay
  // quien la revierta. Sin IntersectionObserver (o con animaciones
  // reducidas) se deja el contenido visible en vez de esconderlo para
  // siempre.
  if (prefersReducedMotion || !('IntersectionObserver' in window)) {
    targets.forEach((el) => el.classList.add('fade-up', 'visible'));
    return;
  }

  targets.forEach((el) => el.classList.add('fade-up'));

  const observer = new IntersectionObserver(
    (entries, obs) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('visible');
        obs.unobserve(entry.target); // una sola vez por elemento
      });
    },
    { threshold: 0.15 }
  );

  targets.forEach((el) => observer.observe(el));

  // Red de seguridad para lo que ya está en pantalla al cargar: el
  // observer no emite mientras la pestaña está oculta (por ejemplo si se
  // abre en segundo plano), y estos elementos parten de opacity:0. Se
  // revelan aquí sin esperarlo. El rAF deja que el navegador aplique
  // primero .fade-up, para que la transición se vea en lugar de saltar.
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      targets.forEach((el) => {
        const rect = el.getBoundingClientRect();
        if (rect.top < window.innerHeight && rect.bottom > 0) {
          el.classList.add('visible');
          observer.unobserve(el);
        }
      });
    });
  });
}
