document.addEventListener('DOMContentLoaded', () => {
    const buttons = document.querySelectorAll('.reaction-button');

    buttons.forEach(button => {
        button.addEventListener('click', () => {
            const reaction = button.getAttribute('data-reaction');
            
            // Hacer una solicitud al servidor
            fetch('/guardar-reaccion', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ reaction: reaction }),
            })
            .then(response => response.json())
            .then(data => {
                console.log('Reacción guardada:', data);
            })
            .catch((error) => {
                console.error('Error al guardar la reacción:', error);
            });
        });
    });
});