// 1. Base de datos simulada de Anime
const animeDB = [
    { id: 1, title: 'Neon Tokyo Drifter', genre: 'Cyberpunk', img: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=400&q=80', rating: 4.9, trend: 1 },
    { id: 2, title: 'Blade of the Kami', genre: 'Shōnen', img: 'https://images.unsplash.com/photo-1579619570959-71286e681c96?auto=format&fit=crop&w=400&q=80', rating: 4.8, trend: 2 },
    { id: 3, title: 'Re:Fantasy World', genre: 'Isekai', img: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=400&q=80', rating: 4.7, trend: 3 },
    { id: 4, title: 'Cyber Hearts', genre: 'Cyberpunk', img: 'https://images.unsplash.com/photo-1555680202-c86f0e12f086?auto=format&fit=crop&w=400&q=80', rating: 4.6, trend: 4 },
    { id: 5, title: 'Spirit Fox', genre: 'Fantasía', img: 'https://images.unsplash.com/photo-1620336655055-088d06e36bf0?auto=format&fit=crop&w=400&q=80', rating: 4.5, trend: 5 },
    { id: 6, title: 'Starfighter Zero', genre: 'Acción', img: 'https://images.unsplash.com/photo-1542831371-29b0f74f9713?auto=format&fit=crop&w=400&q=80', rating: 4.8, trend: 6 },
    { id: 7, title: 'Cherry Blossom Tears', genre: 'Romance', img: 'https://images.unsplash.com/photo-1522383225653-ed111181a951?auto=format&fit=crop&w=400&q=80', rating: 4.3, trend: null },
    { id: 8, title: 'Demon Hunter X', genre: 'Shōnen', img: 'https://images.unsplash.com/photo-1614027164847-1b28cfe1df60?auto=format&fit=crop&w=400&q=80', rating: 4.9, trend: null },
    { id: 9, title: 'Virtual Knight', genre: 'Isekai', img: 'https://images.unsplash.com/photo-1563089145-599997674d42?auto=format&fit=crop&w=400&q=80', rating: 4.4, trend: null }
];

let watchlist = JSON.parse(localStorage.getItem('aniflix_watchlist')) || [];

document.addEventListener('DOMContentLoaded', () => {
    renderGrids();
    updateWatchlistCount();
    setupFilters();
    setupSearch();
    setupModal();
    setupPlayer();
});

// Renderizado de Grillas
function renderGrids() {
    const trendingGrid = document.getElementById('grid-trending');
    const actionGrid = document.getElementById('grid-action');
    const isekaiGrid = document.getElementById('grid-isekai');

    const trending = animeDB.filter(a => a.trend).sort((a,b) => a.trend - b.trend);
    const shonen = animeDB.filter(a => a.genre === 'Shōnen' || a.genre === 'Acción');
    const isekai = animeDB.filter(a => a.genre === 'Isekai' || a.genre === 'Fantasía');

    trendingGrid.innerHTML = trending.map(a => createCard(a, true)).join('');
    actionGrid.innerHTML = shonen.map(a => createCard(a)).join('');
    isekaiGrid.innerHTML = isekai.map(a => createCard(a)).join('');
}

function createCard(anime, isTrending = false) {
    const rank = isTrending ? `<div class="rank-badge">${anime.trend}</div>` : '';
    return `
        <div class="poster-card" onclick="openModal(${anime.id})">
            ${rank}
            <img src="${anime.img}" loading="lazy" alt="${anime.title}">
            <div class="play-icon"><i class="fa-solid fa-play"></i></div>
            <div class="poster-overlay">
                <div class="poster-title">${anime.title}</div>
                <div class="poster-meta">
                    <span style="color:var(--gold)"><i class="fa-solid fa-star"></i> ${anime.rating}</span>
                    <span>${anime.genre}</span>
                </div>
            </div>
        </div>
    `;
}

// Watchlist Logic
function updateWatchlistCount() {
    document.getElementById('watchlist-count').innerText = watchlist.length;
}

window.addToWatchlist = (title) => {
    if(!watchlist.includes(title)){
        watchlist.push(title);
        localStorage.setItem('aniflix_watchlist', JSON.stringify(watchlist));
        updateWatchlistCount();
        showToast(`🎉 Añadido a tu lista: ${title}`);
    } else {
        showToast(`⚠️ ${title} ya está en tu lista`);
    }
}

// Toast Notifications
function showToast(msg) {
    const container = document.getElementById('toast-container');
    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.innerText = msg;
    container.appendChild(toast);
    setTimeout(() => {
        toast.style.animation = 'fadeOut 0.3s ease forwards';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// Filtros
function setupFilters() {
    const pills = document.querySelectorAll('.glass-pill');
    pills.forEach(pill => {
        pill.addEventListener('click', (e) => {
            pills.forEach(p => p.classList.remove('active'));
            e.target.classList.add('active');
            const filter = e.target.getAttribute('data-filter');
            
            // Simulación de filtrado global (para demostración, filtra la sección de acción)
            const grid = document.getElementById('grid-action');
            if(filter === 'all') {
                grid.innerHTML = animeDB.map(a => createCard(a)).join('');
            } else {
                const filtered = animeDB.filter(a => a.genre.toLowerCase().includes(filter.toLowerCase()));
                grid.innerHTML = filtered.map(a => createCard(a)).join('');
            }
        });
    });
}

// Búsqueda
function setupSearch() {
    const input = document.getElementById('search-input');
    input.addEventListener('input', (e) => {
        const term = e.target.value.toLowerCase();
        const grid = document.getElementById('grid-trending');
        const filtered = animeDB.filter(a => a.title.toLowerCase().includes(term));
        grid.innerHTML = filtered.length ? filtered.map(a => createCard(a)).join('') : '<p style="color:var(--text-sec)">No se encontraron resultados.</p>';
    });
}

// Modal Interactivo
function setupModal() {
    const modal = document.getElementById('detail-modal');
    const closeBtn = document.getElementById('close-modal');

    closeBtn.addEventListener('click', () => {
        modal.classList.remove('active');
    });

    // Close on click outside
    modal.addEventListener('click', (e) => {
        if(e.target === modal) modal.classList.remove('active');
    });
}

window.openModal = (id) => {
    const anime = animeDB.find(a => a.id === id);
    if(!anime) return;

    document.getElementById('modal-bg').src = anime.img;
    document.getElementById('modal-title').innerText = anime.title;
    document.getElementById('modal-rating').innerHTML = `<i class="fa-solid fa-star"></i> ${anime.rating}`;
    document.getElementById('modal-genre').innerText = anime.genre;
    document.getElementById('modal-synopsis').innerText = `En un mundo de ${anime.genre}, los protagonistas enfrentan su mayor desafío. Una historia épica llena de emoción y misterio que te atrapará desde el primer episodio.`;
    
    document.getElementById('modal-play-btn').onclick = () => playMovie(anime.title);
    document.getElementById('modal-add-btn').onclick = () => addToWatchlist(anime.title);

    // Generar Episodios Simulados
    let epsHTML = '';
    for(let i=1; i<=12; i++){
        epsHTML += `
            <div class="episode-card" onclick="playMovie('${anime.title} - Ep ${i}')">
                <div class="ep-num">${i}</div>
                <img src="${anime.img}" class="ep-img" alt="Ep ${i}">
                <div class="ep-info">
                    <h4>Episodio ${i}</h4>
                    <p>24 min</p>
                </div>
            </div>
        `;
    }
    document.getElementById('episodes-grid').innerHTML = epsHTML;

    document.getElementById('detail-modal').classList.add('active');
}

// Simulador de Reproductor
function setupPlayer() {
    document.getElementById('close-player').addEventListener('click', () => {
        const player = document.getElementById('player-overlay');
        player.style.display = 'none';
        document.querySelector('.progress-bar').style.width = '0%';
    });
}

window.playMovie = (title) => {
    showToast(`▶ Iniciando reproductor...`);
    const player = document.getElementById('player-overlay');
    const loader = document.getElementById('player-loader');
    const ui = document.getElementById('player-ui');
    
    document.getElementById('player-title').innerText = `Reproduciendo: ${title}`;
    
    player.style.display = 'flex';
    loader.style.display = 'block';
    ui.style.display = 'none';

    // Simular carga de 2 segundos
    setTimeout(() => {
        loader.style.display = 'none';
        ui.style.display = 'block';
        
        // Simular progreso
        const bar = document.querySelector('.progress-bar');
        let width = 0;
        const interval = setInterval(() => {
            if(player.style.display === 'none') {
                clearInterval(interval);
                return;
            }
            width += 0.5;
            bar.style.width = `${width}%`;
            if(width >= 100) clearInterval(interval);
        }, 100);
    }, 2000);
}
