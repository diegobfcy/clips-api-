const express = require('express');
const clips = require('clips');
const fs = require('fs');
const app = express();
const port = 3000;

const hechosCLP = fs.readFileSync('HechosTrabajoFaseUno.clp', 'utf-8');
const reglasCLP = fs.readFileSync('TrabajoFaseUno.clp', 'utf-8');

app.use(express.json());

app.get('/recommendations/:userId', (req, res) => {
    const userId = req.params.userId;
    const env = new clips.Environment();

    try {
        env.load(hechosCLP);
        env.load(reglasCLP);
        
        env.reset();
        env.run();

        const facts = env.facts();
        const recommendations = [];
        const titulos = new Map();
        const generos = new Map();
        const plataformas = new Map();

        facts.forEach(fact => {
            if (fact.name === 'Titulo_Juego') {
                titulos.set(fact.slots.juego, fact.slots.titulo);
            }
            
            if (fact.name === 'Tiene_Genero') {
                if (!generos.has(fact.slots.juego)) {
                    generos.set(fact.slots.juego, []);
                }
                generos.get(fact.slots.juego).push(fact.slots.genero);
            }
            
            // Mapear plataformas de juegos
            if (fact.name === 'Disponible_En') {
                if (!plataformas.has(fact.slots.juego)) {
                    plataformas.set(fact.slots.juego, []);
                }
                plataformas.get(fact.slots.juego).push(fact.slots.plataforma);
            }

            // Recomendaciones finales
            if (fact.name === 'Recomendacion_Final' && fact.slots.usuario === userId) {
                recommendations.push({
                    juegoId: fact.slots.juego,
                    razon: fact.slots.razon
                });
            }
        });


        const resultado = recommendations.map(rec => ({
            ...rec,
            titulo: titulos.get(rec.juegoId) || 'Desconocido',
            generos: generos.get(rec.juegoId) || [],
            plataformas: plataformas.get(rec.juegoId) || []
        }));

        res.json({
            userId,
            recommendations: resultado.slice(0, 3)
        });

    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

app.listen(port, () => {
    console.log(`API escuchando en http://localhost:${port}`);
});