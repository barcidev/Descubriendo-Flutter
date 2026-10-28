// La página del público: un WebSocket y una pantalla que cambia según lo
// que la charla tenga en ese momento. Todo lo que escribe la gente se pinta
// con textContent, nunca como HTML.
(() => {
  'use strict';

  const $ = (id) => document.getElementById(id);
  const leer = (clave, defecto) => {
    try { return JSON.parse(localStorage.getItem(clave)) ?? defecto; } catch { return defecto; }
  };
  const guardar = (clave, valor) => {
    try { localStorage.setItem(clave, JSON.stringify(valor)); } catch { /* sin almacenamiento */ }
  };

  let cliente = leer('charla.cliente', null);
  if (!cliente) {
    cliente = (crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${Math.random()}`.replace('.', ''))
      .replace(/[^A-Za-z0-9_-]/g, '');
    guardar('charla.cliente', cliente);
  }

  const misVotos = leer('charla.votos', {});
  const misApoyos = new Set(leer('charla.apoyos', []));
  let misExcusas = leer('charla.excusas', 0);
  let misEstrellas = leer('charla.estrellas', 0);

  let socket = null;
  let intentos = 0;
  let estado = null;
  let modoPintado = '';
  let toques = 0;
  let borrador = {};

  // ---------- Conexión ----------

  function conectar() {
    const protocolo = location.protocol === 'https:' ? 'wss' : 'ws';
    socket = new WebSocket(`${protocolo}://${location.host}/ws`);
    socket.onopen = () => {
      intentos = 0;
      enviar({ t: 'hola', id: cliente });
      marcar(true);
    };
    socket.onmessage = (evento) => {
      const mensaje = JSON.parse(evento.data);
      if (mensaje.t === 'yo') pintarYo(mensaje);
      if (mensaje.t === 'estado') {
        estado = mensaje;
        pintar();
      }
    };
    socket.onclose = () => {
      marcar(false);
      setTimeout(conectar, Math.min(1000 * 2 ** intentos++, 8000));
    };
  }

  function enviar(mensaje) {
    if (socket && socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(mensaje));
  }

  function marcar(vivo) {
    $('punto').classList.toggle('vivo', vivo);
    $('estado').textContent = vivo ? 'en vivo' : 'reconectando…';
  }

  // Los toques del contador se juntan y salen en tandas.
  setInterval(() => {
    if (toques > 0) {
      const tanda = Math.min(toques, 25);
      toques -= tanda;
      enviar({ t: 'toque', n: tanda });
    }
  }, 220);

  // ---------- Pintar ----------

  function pintarYo(yo) {
    $('yo').hidden = false;
    $('widget').textContent = yo.widget;
    $('frase').textContent = yo.frase;
    Object.assign(misVotos, yo.votos || {});
  }

  function el(etiqueta, clase, texto) {
    const nodo = document.createElement(etiqueta);
    if (clase) nodo.className = clase;
    if (texto != null) nodo.textContent = texto;
    return nodo;
  }

  function pintar() {
    $('conectados').textContent = `${estado.connected} conectados`;
    const cue = estado.cue || { mode: 'idle' };
    const clave = cue.mode + (cue.poll ? cue.poll.id : '');
    // Si la pantalla es la misma, solo se actualizan los números: así no se
    // pierde lo que la persona está escribiendo.
    if (clave === modoPintado && actualizar(cue)) return;
    modoPintado = clave;
    const pantalla = $('pantalla');
    pantalla.replaceChildren();
    switch (cue.mode) {
      case 'poll': pintarEncuesta(pantalla, cue); break;
      case 'counter': pintarContador(pantalla); break;
      case 'excuse': pintarExcusa(pantalla); break;
      case 'questions': pintarPreguntas(pantalla); break;
      case 'rating': pintarEstrellas(pantalla); break;
      default: pintarEspera(pantalla);
    }
  }

  /// Devuelve true si pudo actualizar sin volver a construir la pantalla.
  function actualizar(cue) {
    if (cue.mode === 'poll') { pintarResultados(cue); return true; }
    if (cue.mode === 'counter') { $('total').textContent = estado.counter; return true; }
    if (cue.mode === 'questions') { pintarListaPreguntas(); return true; }
    if (cue.mode === 'rating' || cue.mode === 'excuse' || cue.mode === 'idle') return true;
    return false;
  }

  function pintarEspera(pantalla) {
    pantalla.append(
      el('h2', null, 'Descubriendo Flutter'),
      el('p', 'ayuda', 'Deja esta pestaña abierta: aquí aparecen las votaciones y los juegos de la charla.'),
    );
  }

  function pintarEncuesta(pantalla, cue) {
    const poll = cue.poll;
    pantalla.append(
      el('h2', null, poll.question),
      el('p', 'ayuda', poll.multiple ? 'Marca todas las que creas.' : 'Elige una.'),
    );
    const opciones = el('div', 'opciones');
    opciones.id = 'opciones';
    const elegidas = new Set(misVotos[poll.id] || []);
    for (const opcion of poll.options) {
      const boton = el('button', 'opcion');
      boton.type = 'button';
      boton.dataset.id = opcion.id;
      boton.append(el('span', 'barrita'), el('span', 'marca'), el('span', 'texto', opcion.label), el('span', 'porcentaje', ''));
      boton.classList.toggle('elegida', elegidas.has(opcion.id));
      boton.addEventListener('click', () => {
        if (!estado.cue.open) return;
        if (poll.multiple) {
          elegidas.has(opcion.id) ? elegidas.delete(opcion.id) : elegidas.add(opcion.id);
        } else {
          elegidas.clear();
          elegidas.add(opcion.id);
        }
        misVotos[poll.id] = [...elegidas];
        guardar('charla.votos', misVotos);
        enviar({ t: 'voto', poll: poll.id, opciones: [...elegidas] });
        if (navigator.vibrate) navigator.vibrate(8);
        for (const nodo of opciones.children) nodo.classList.toggle('elegida', elegidas.has(nodo.dataset.id));
        pintarResultados(estado.cue);
      });
      opciones.append(boton);
    }
    pantalla.append(opciones, el('p', 'nota', ''));
    pintarResultados(cue);
  }

  function pintarResultados(cue) {
    const opciones = $('opciones');
    if (!opciones) return;
    const resultados = estado.results || { counts: {}, voters: 0 };
    const yaVote = (misVotos[cue.poll.id] || []).length > 0;
    const correctas = new Set(cue.correct || []);
    for (const nodo of opciones.children) {
      const votos = resultados.counts[nodo.dataset.id] || 0;
      const parte = resultados.voters ? votos / resultados.voters : 0;
      const mostrar = yaVote || cue.revealed || !cue.open;
      nodo.querySelector('.barrita').style.width = mostrar ? `${Math.round(parte * 100)}%` : '0';
      nodo.querySelector('.porcentaje').textContent = mostrar ? `${Math.round(parte * 100)} %` : '';
      nodo.classList.toggle('correcta', cue.revealed && correctas.has(nodo.dataset.id));
      nodo.classList.toggle('incorrecta', cue.revealed && correctas.size > 0 && !correctas.has(nodo.dataset.id));
    }
    const nota = opciones.nextElementSibling;
    nota.textContent = cue.revealed
      ? 'Respuesta en pantalla.'
      : !cue.open ? 'Votación cerrada.' : yaVote ? `Voto registrado · ${resultados.voters} personas votaron` : '';
  }

  function pintarContador(pantalla) {
    const caja = el('div', 'contador');
    const total = el('div', 'total', String(estado.counter));
    total.id = 'total';
    const mas = el('button', 'mas', '+');
    mas.type = 'button';
    mas.setAttribute('aria-label', 'Sumar uno');
    mas.addEventListener('pointerdown', (evento) => {
      evento.preventDefault();
      toques++;
      total.textContent = String(Number(total.textContent) + 1);
      if (navigator.vibrate) navigator.vibrate(6);
    });
    caja.append(
      el('h2', null, 'El contador más grande del mundo'),
      el('p', 'ayuda', 'Aprieta el botón. Todo lo que puedas.'),
      mas,
      total,
    );
    pantalla.append(caja);
  }

  function formulario({ titulo, ayuda, maximo, marcador, boton, alEnviar, limite }) {
    const form = el('form', 'formulario');
    const texto = el('textarea');
    texto.maxLength = maximo;
    texto.rows = 3;
    texto.placeholder = marcador;
    texto.value = borrador[titulo] || '';
    texto.addEventListener('input', () => { borrador[titulo] = texto.value; });
    const enviarBoton = el('button', 'boton', boton);
    enviarBoton.type = 'submit';
    const nota = el('p', 'nota', '');
    form.append(texto, enviarBoton, nota);
    form.addEventListener('submit', (evento) => {
      evento.preventDefault();
      const valor = texto.value.trim();
      if (valor.length < 3) { nota.textContent = 'Escribe un poquito más.'; return; }
      if (limite && !limite()) { nota.textContent = 'Ya mandaste suficientes. ¡Gracias!'; return; }
      alEnviar(valor);
      texto.value = '';
      borrador[titulo] = '';
      nota.textContent = 'Enviada. Si pasa el code review, sale en pantalla.';
    });
    return [el('h2', null, titulo), el('p', 'ayuda', ayuda), form];
  }

  function pintarExcusa(pantalla) {
    pantalla.append(...formulario({
      titulo: 'Tu mejor excusa de dev',
      ayuda: 'La que más has usado. Las aprobadas salen en la tarjeta en vivo.',
      maximo: 140,
      marcador: 'Ej: en mi máquina sí funciona',
      boton: 'Enviar excusa',
      limite: () => misExcusas < 3,
      alEnviar: (texto) => {
        enviar({ t: 'excusa', texto });
        guardar('charla.excusas', ++misExcusas);
      },
    }));
  }

  function pintarPreguntas(pantalla) {
    pantalla.append(
      el('h2', null, 'Preguntas'),
      el('p', 'ayuda', 'Apoya las que también quieres escuchar. Escribe la tuya abajo.'),
    );
    const lista = el('ul', 'lista');
    lista.id = 'listaPreguntas';
    pantalla.append(lista);
    pintarListaPreguntas();
    $('preguntar').open = true;
  }

  function pintarListaPreguntas() {
    const lista = $('listaPreguntas');
    if (!lista) return;
    lista.replaceChildren();
    for (const pregunta of estado.questions || []) {
      const item = el('li', pregunta.done ? 'respondida' : '');
      const cuerpo = el('div', 'cuerpo');
      cuerpo.append(el('span', null, pregunta.text), el('span', 'autor', `${pregunta.author}()`));
      const apoyo = el('button', `apoyo${misApoyos.has(pregunta.id) ? ' hecho' : ''}`, `+${pregunta.votes}`);
      apoyo.type = 'button';
      apoyo.disabled = misApoyos.has(pregunta.id);
      apoyo.addEventListener('click', () => {
        misApoyos.add(pregunta.id);
        guardar('charla.apoyos', [...misApoyos]);
        enviar({ t: 'apoyo', id: pregunta.id });
        apoyo.classList.add('hecho');
        apoyo.disabled = true;
      });
      item.append(cuerpo, apoyo);
      lista.append(item);
    }
    if (!lista.children.length) lista.append(el('li', null, 'Todavía no hay preguntas aprobadas.'));
  }

  const leyendas = [
    '',
    'Segmentation fault',
    'Compila con warnings',
    'Funciona en mi máquina',
    'Pasa los tests',
    'Deploy un viernes y nada se rompió',
  ];

  function pintarEstrellas(pantalla) {
    pantalla.append(el('h2', null, 'La cuenta, por favor'), el('p', 'ayuda', '¿Cómo estuvo la charla?'));
    const fila = el('div', 'estrellas');
    const leyenda = el('p', 'leyenda', leyendas[misEstrellas] || '');
    for (let n = 1; n <= 5; n++) {
      const estrella = el('button', 'estrella', '★');
      estrella.type = 'button';
      estrella.setAttribute('aria-label', `${n} de 5`);
      estrella.addEventListener('click', () => {
        misEstrellas = n;
        guardar('charla.estrellas', n);
        enviar({ t: 'estrellas', n });
        encender();
      });
      fila.append(estrella);
    }
    const encender = () => {
      [...fila.children].forEach((estrella, i) => estrella.classList.toggle('encendida', i < misEstrellas));
      leyenda.textContent = leyendas[misEstrellas] || '';
    };
    encender();
    pantalla.append(fila, leyenda);
  }

  // ---------- Siempre disponibles ----------

  $('formPregunta').addEventListener('submit', (evento) => {
    evento.preventDefault();
    const texto = $('textoPregunta').value.trim();
    const nota = $('notaPregunta');
    if (texto.length < 3) { nota.textContent = 'Escribe un poquito más.'; return; }
    enviar({ t: 'pregunta', texto });
    $('textoPregunta').value = '';
    nota.textContent = 'Recibida. Si pasa la moderación, sale en pantalla.';
  });

  let ultimaReaccion = 0;
  for (const boton of document.querySelectorAll('.reacciones button')) {
    boton.addEventListener('click', () => {
      const ahora = Date.now();
      if (ahora - ultimaReaccion < 300) return;
      ultimaReaccion = ahora;
      enviar({ t: 'reaccion', r: boton.dataset.r });
      if (navigator.vibrate) navigator.vibrate(5);
    });
  }

  conectar();
})();
