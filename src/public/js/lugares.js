const lugares = [
    { lat: 4.5851, lng: -74.1832, mapId: "map1", nombre: "Parque Principal de Soacha" },
    { lat: 4.5921, lng: -74.1620, mapId: "map2", nombre: "Cerro de Las Cuchillas" },
    { lat: 4.5731, lng: -74.1586, mapId: "map3", nombre: "Catedral de Soacha" },
    { lat: 4.5825, lng: -74.1673, mapId: "map4", nombre: "Parque de los Eucaliptos" },
    { lat: 4.5778, lng: -74.1901, mapId: "map5", nombre: "Centro Comercial Soacha Plaza" },
    { lat: 4.5801, lng: -74.1835, mapId: "map6", nombre: "Plaza de la Cultura" },
    { lat: 4.5751, lng: -74.1768, mapId: "map7", nombre: "Parque de La Paz" },
    { lat: 4.5889, lng: -74.1801, mapId: "map8", nombre: "Monumento a los Héroes" },
    { lat: 4.5862, lng: -74.1863, mapId: "map9", nombre: "Parque El Chicó" },
];

lugares.forEach(lugar => {
    const map = L.map(lugar.mapId).setView([lugar.lat, lugar.lng], 15);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
    }).addTo(map);

    L.marker([lugar.lat, lugar.lng]).addTo(map)
        .bindPopup(lugar.nombre)
        .openPopup();
});

function initializeMap() {
    const map = L.map('generalMap').setView([4.6097, -74.0817], 10);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
    }).addTo(map);

    lugares.forEach(lugar => {
        L.marker([lugar.lat, lugar.lng]).addTo(map)
            .bindPopup(`<b>${lugar.nombre}</b>`)
            .openPopup();
    });
}

function toggleMap() {
    const mapDiv = document.getElementById('generalMap');
    if (mapDiv.style.display === 'none') {
        mapDiv.style.display = 'block';
        initializeMap();
    } else {
        mapDiv.style.display = 'none';
    }
}


function enviarComentario() {
    const nombre = document.getElementById('nombre').value;
    const comentario = document.getElementById('comentario').value;
    if (nombre && comentario) {
        alert(`Comentario de ${nombre} enviado: "${comentario}"`);
        document.getElementById('nombre').value = '';
        document.getElementById('comentario').value = '';
    } else {
        alert('Por favor, completa todos los campos.');
    }
}

function toggleCronograma() {
    const cronograma = document.getElementById('cronograma');
    if (cronograma.style.display === 'none') {
        cronograma.style.display = 'block';
    } else {
        cronograma.style.display = 'none';
    }
}
function toggleConsejos() {
    const consejos = document.getElementById('consejos');
    consejos.style.display = consejos.style.display === 'none' ? 'block' : 'none';
}


function searchPlace() {
    const input = document.getElementById('searchInput').value.toLowerCase();
    const lugaresElement = document.querySelectorAll('.lugar');

    lugaresElement.forEach(lugar => {
        const lugarName = lugar.getAttribute('data-name').toLowerCase();
        if (lugarName.includes(input)) {
            lugar.style.display = '';
        } else {
            lugar.style.display = 'none';
        }
    });
}
function agregarComentario(comentariosId, nombreId, comentarioId) {
    const nombre = document.getElementById(nombreId).value;
    const comentario = document.getElementById(comentarioId).value;
    if (nombre && comentario) {
        const comentarioDiv = document.createElement('div');
        comentarioDiv.textContent = `${nombre}: ${comentario}`;
        document.getElementById(comentariosId).appendChild(comentarioDiv);
        document.getElementById(nombreId).value = '';
        document.getElementById(comentarioId).value = '';
    }
}