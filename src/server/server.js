const express = require('express');
const app = express();
const path = require('path');
const reactionRoutes = require('./routes/reactions');
const dotenv = require('dotenv');

// Cargar variables de entorno desde .env
dotenv.config();

// Middleware para manejar JSON
app.use(express.json());

// Ruta para servir archivos estáticos
app.use(express.static(path.join(__dirname, '../public')));

// Usar rutas
app.use('/guardar-reaccion', reactionRoutes);

// Iniciar el servidor
const PORT = process.env.DB_PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor escuchando en http://localhost:${PORT}`);
});