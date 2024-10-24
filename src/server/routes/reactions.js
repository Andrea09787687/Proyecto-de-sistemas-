const express = require('express');
const router = express.Router();
const db = require('../db');

// Endpoint para guardar la reacción
router.post('/', (req, res) => {
  const { reaction } = req.body;

  if (!reaction) {
    return res.status(400).json({ success: false, message: 'Reacción no proporcionada' });
  }
  /*const query = 'INSERT INTO reactiones (tipo,cantidad) VALUES (?)';*/

  const query = 'UPDATE reacciones SET cantidad = cantidad + 1 WHERE tipo = ?';

  db.query(query, [reaction], (err, results) => {
    if (err) {
      console.error('Error al actualizar la reacción:', err);
      return res.status(500).json({ success: false, message: 'Error al actualizar la base de datos' });
    }

    res.json({ success: true, message: 'Reacción guardada con éxito'});
  });
});

module.exports = router;