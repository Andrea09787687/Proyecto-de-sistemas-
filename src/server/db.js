const mysql = require('mysql');
const conexion = mysql.createConnection({
    host: 'localhost',
    database: 'geocalizacion_soacha',
    user: 'root',
    password: '',
});

conexion.connect(function (err) {
    if (err) {
        console.error('Error de conexion: ' + err.stack);
        return;
    }
    console.log('Conectado con el identificador ' + conexion.threadId);
    /*conexion.end();*/
});

/*conexion.end((err) => {
    if (err) return console.error(err.message);
    console.log('Cerrando la conexión con la base de datos');
});
*/

module.exports = conexion;
