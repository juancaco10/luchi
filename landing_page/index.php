<?php
// Cache-busting automático: usa la fecha de modificación del archivo.
// Cada vez que subas un CSS o JS nuevo, el navegador lo descarga fresco.
$cssVersion = file_exists('style.css') ? filemtime('style.css') : time();
$jsVersion  = file_exists('app.js')    ? filemtime('app.js')    : time();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Guardianes de las Luciérnagas — Protege la Luz del Bosque</title>
    <meta name="description" content="Una aventura educativa para niños donde aprenderás a proteger las luciérnagas y el ecosistema nocturno. Disponible en Android y Web.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="style.css?v=<?php echo $cssVersion; ?>">
</head>
<body>

    <!-- Partículas de luciérnagas flotantes -->
    <div class="fireflies" id="fireflies"></div>

    <!-- Navbar -->
    <nav class="navbar glass">
        <div class="nav-left">
            <a href="#" class="logo">
                <span class="logo-icon">🪲</span> GUARDIANES <span class="accent">DE LAS LUCIÉRNAGAS</span>
            </a>
        </div>
        <div class="nav-right">
            <ul class="nav-links">
                <li><a href="#inicio" class="active">Inicio</a></li>
                <li><a href="#mision">Misión</a></li>
                <li><a href="#aventura">Aventura</a></li>
                <li><a href="#descargar">Descargar</a></li>
            </ul>
            <a href="/app/" class="btn btn-sm btn-primary">
                <i class="fa-solid fa-play"></i> Jugar Ahora
            </a>
        </div>
        <button class="mobile-menu" id="mobile-menu">
            <i class="fa-solid fa-bars"></i>
        </button>
    </nav>

    <!-- Hero -->
    <header class="hero" id="inicio">
        <div class="hero-bg">
            <img src="https://images.unsplash.com/photo-1505322022379-7c3353ee6291?auto=format&fit=crop&w=1920&q=80" alt="Bosque nocturno">
            <div class="hero-vignette"></div>
        </div>
        <div class="hero-content">
            <div class="hero-text">
                <div class="hero-badge glass-pill-sm">
                    <i class="fa-solid fa-sparkles"></i> Proyecto Educativo Ambiental
                </div>
                <h1 class="hero-title">
                    PROTEGE LA <span class="glow-text">LUZ</span> DEL BOSQUE
                </h1>
                <p class="hero-subtitle">
                    Una aventura interactiva para niños de 6 a 12 años donde descubrirás el mundo secreto de las luciérnagas, completarás misiones científicas reales y te convertirás en un verdadero Guardián de la Naturaleza.
                </p>
                <div class="hero-stats">
                    <div class="stat glass">
                        <span class="stat-num">🌿</span>
                        <span class="stat-label">Misiones Ecológicas</span>
                    </div>
                    <div class="stat glass">
                        <span class="stat-num">🗺️</span>
                        <span class="stat-label">Mapa de Avistamientos</span>
                    </div>
                    <div class="stat glass">
                        <span class="stat-num">🏆</span>
                        <span class="stat-label">Sistema de Rangos</span>
                    </div>
                </div>
                <div class="hero-actions">
                    <a href="#descargar" class="btn btn-primary btn-lg">
                        <i class="fa-brands fa-google-play"></i> Descargar en Android
                    </a>
                    <a href="/app/" class="btn btn-secondary glass btn-lg">
                        <i class="fa-solid fa-globe"></i> Jugar en la Web
                    </a>
                </div>
            </div>
            <div class="hero-visual">
                <div class="phone-mockup">
                    <div class="phone-frame glass">
                        <div class="phone-screen">
                            <img src="https://images.unsplash.com/photo-1518495973542-4542c06a5843?auto=format&fit=crop&w=400&q=80" alt="App Screenshot">
                            <div class="phone-overlay">
                                <span class="phone-badge">Vista previa</span>
                            </div>
                        </div>
                    </div>
                    <div class="phone-glow"></div>
                </div>
            </div>
        </div>
        <div class="scroll-indicator">
            <i class="fa-solid fa-chevron-down"></i>
        </div>
    </header>

    <!-- Sección: ¿Qué es? -->
    <section class="section-what" id="mision">
        <div class="section-container">
            <div class="section-header">
                <span class="section-tag glass-pill-sm">🪲 Nuestra Misión</span>
                <h2 class="section-title">¿POR QUÉ LAS LUCIÉRNAGAS <span class="glow-text">NECESITAN HÉROES</span>?</h2>
                <p class="section-desc">La contaminación lumínica está apagando su luz. Cada noche, millones de luciérnagas pierden su camino. Este juego te enseña a protegerlas mientras te diviertes.</p>
            </div>
            <div class="features-grid">
                <div class="feature-card glass" data-delay="0">
                    <div class="feature-icon">
                        <i class="fa-solid fa-book-open"></i>
                    </div>
                    <h3>Capítulos Educativos</h3>
                    <p>Aprende sobre la bioluminiscencia, los hábitats nocturnos y la importancia de la oscuridad para el ecosistema.</p>
                </div>
                <div class="feature-card glass" data-delay="100">
                    <div class="feature-icon icon-cyan">
                        <i class="fa-solid fa-map-location-dot"></i>
                    </div>
                    <h3>Mapa de Avistamientos</h3>
                    <p>Registra dónde has visto luciérnagas reales y contribuye a un mapa comunitario de conservación.</p>
                </div>
                <div class="feature-card glass" data-delay="200">
                    <div class="feature-icon icon-gold">
                        <i class="fa-solid fa-trophy"></i>
                    </div>
                    <h3>Misiones y Rangos</h3>
                    <p>Completa misiones diarias, gana puntos y sube de rango: de Observador a Maestro Guardián.</p>
                </div>
                <div class="feature-card glass" data-delay="300">
                    <div class="feature-icon icon-pink">
                        <i class="fa-solid fa-shield-halved"></i>
                    </div>
                    <h3>100% Seguro para Niños</h3>
                    <p>Sin anuncios, sin compras dentro de la app, GPS difuminado y datos protegidos por diseño.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Sección: Cómo funciona -->
    <section class="section-how" id="aventura">
        <div class="section-container">
            <div class="section-header">
                <span class="section-tag glass-pill-sm">⚡ La Aventura</span>
                <h2 class="section-title">TU CAMINO COMO <span class="glow-text">GUARDIÁN</span></h2>
            </div>
            <div class="steps-grid">
                <div class="step-card glass">
                    <div class="step-number">01</div>
                    <div class="step-content">
                        <h3>Explora los Capítulos</h3>
                        <p>Descubre los secretos de las luciérnagas con lecciones interactivas llenas de datos fascinantes.</p>
                    </div>
                </div>
                <div class="step-card glass">
                    <div class="step-number">02</div>
                    <div class="step-content">
                        <h3>Completa Misiones</h3>
                        <p>Acepta desafíos diarios y semanales: observar el cielo, reducir la luz artificial, investigar especies.</p>
                    </div>
                </div>
                <div class="step-card glass">
                    <div class="step-number">03</div>
                    <div class="step-content">
                        <h3>Registra Avistamientos</h3>
                        <p>¿Viste luciérnagas? Marca el lugar en el mapa y describe lo que encontraste.</p>
                    </div>
                </div>
                <div class="step-card glass">
                    <div class="step-number">04</div>
                    <div class="step-content">
                        <h3>Sube de Rango</h3>
                        <p>Acumula puntos y evoluciona de Observador → Explorador → Guardián → Maestro Guardián.</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Sección: Galería / Screenshots -->
    <section class="section-gallery">
        <div class="section-container">
            <div class="section-header">
                <span class="section-tag glass-pill-sm">📸 Vista Previa</span>
                <h2 class="section-title">CONOCE EL <span class="glow-text">MUNDO</span> DEL JUEGO</h2>
            </div>
            <div class="gallery-grid">
                <div class="gallery-card glass">
                    <img src="https://images.unsplash.com/photo-1507400492013-162706c8c05e?auto=format&fit=crop&w=600&q=80" alt="Bosque de noche">
                    <div class="gallery-overlay">
                        <span>Bosques Nocturnos</span>
                    </div>
                </div>
                <div class="gallery-card glass">
                    <img src="https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?auto=format&fit=crop&w=600&q=80" alt="Atardecer campo">
                    <div class="gallery-overlay">
                        <span>Hábitats Naturales</span>
                    </div>
                </div>
                <div class="gallery-card glass">
                    <img src="https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=600&q=80" alt="Sendero bosque">
                    <div class="gallery-overlay">
                        <span>Explora y Aprende</span>
                    </div>
                </div>
                <div class="gallery-card glass">
                    <img src="https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?auto=format&fit=crop&w=600&q=80" alt="Árboles noche">
                    <div class="gallery-overlay">
                        <span>Protege la Oscuridad</span>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Sección: Descargar (CTA) -->
    <section class="section-download" id="descargar">
        <div class="download-bg"></div>
        <div class="section-container download-content">
            <div class="section-header">
                <span class="section-tag glass-pill-sm">🚀 ¡Únete!</span>
                <h2 class="section-title">COMIENZA TU AVENTURA <span class="glow-text">HOY</span></h2>
                <p class="section-desc">Descarga la app en tu celular o juega directamente desde el navegador. ¡El bosque te espera!</p>
            </div>
            <div class="download-buttons">
                <!-- Sin destino real todavía: no hay APK publicado ni ficha
                     en Google Play. Se deja como aviso en vez de un enlace
                     roto; cuando exista la ficha, sustituir por su URL. -->
                <span class="download-card glass download-card-soon" aria-disabled="true">
                    <i class="fa-brands fa-google-play"></i>
                    <div>
                        <span class="dl-small">Muy pronto en</span>
                        <span class="dl-big">Google Play</span>
                    </div>
                </span>
                <a href="/app/" class="download-card glass">
                    <i class="fa-solid fa-globe"></i>
                    <div>
                        <span class="dl-small">Jugar ahora en</span>
                        <span class="dl-big">Navegador Web</span>
                    </div>
                </a>
            </div>
            <div class="trust-badges">
                <span><i class="fa-solid fa-child"></i> Apto para niños</span>
                <span><i class="fa-solid fa-lock"></i> 100% Privado</span>
                <span><i class="fa-solid fa-ban"></i> Sin anuncios</span>
                <span><i class="fa-solid fa-leaf"></i> Educación ambiental</span>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="footer glass">
        <div class="footer-content">
            <div class="footer-brand">
                <div class="footer-logo">🪲 GUARDIANES DE LAS LUCIÉRNAGAS</div>
                <p class="footer-tagline">Protegiendo la luz del bosque, una misión a la vez.</p>
            </div>
            <div class="footer-cols">
                <div class="footer-col">
                    <h4>Proyecto</h4>
                    <a href="#">Sobre Nosotros</a>
                    <a href="#">La Ciencia</a>
                    <a href="#">Preguntas Frecuentes</a>
                </div>
                <div class="footer-col">
                    <h4>Legal</h4>
                    <a href="api/privacidad.html">Política de Privacidad</a>
                    <a href="#">Términos de Uso</a>
                    <a href="#">Contacto</a>
                </div>
                <div class="footer-col">
                    <h4>Comunidad</h4>
                    <div class="footer-social">
                        <a href="#"><i class="fa-brands fa-instagram"></i></a>
                        <a href="#"><i class="fa-brands fa-youtube"></i></a>
                        <a href="#"><i class="fa-brands fa-tiktok"></i></a>
                        <a href="#"><i class="fa-brands fa-discord"></i></a>
                    </div>
                </div>
            </div>
        </div>
        <div class="footer-copy">
            &copy; 2026 Guardianes de las Luciérnagas. Todos los derechos reservados. Desarrollado con ❤️ para un futuro más luminoso.
        </div>
    </footer>

    <script src="app.js?v=<?php echo $jsVersion; ?>"></script>
</body>
</html>
