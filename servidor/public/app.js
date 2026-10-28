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
  let miNombre = leer('charla.nombre', null);
  let misEstrellas = leer('charla.estrellas', 0);
  // Lo que esta persona ya mandó: el servidor lo devuelve al reconectar.
  let mias = leer('charla.mias', { excusas: [], preguntas: [] });

  let socket = null;
  let intentos = 0;
  let estado = null;
  let modoPintado = '';
  let toques = 0;
  // Lo que se está escribiendo y no se ha enviado: sobrevive a recargar.
  const borrador = leer('charla.borradores', {});
  // Cuándo se cierra la ronda de excusas, en la hora de este celular.
  let finExcusas = 0;
  // El concurso: cuándo se cierra la pregunta y cómo le va a esta persona.
  let finPregunta = 0;
  let miConcurso = null;

  // ---------- Conexión ----------

  function conectar() {
    const protocolo = location.protocol === 'https:' ? 'wss' : 'ws';
    socket = new WebSocket(`${protocolo}://${location.host}/ws`);
    socket.onopen = () => {
      intentos = 0;
      // El apodo guardado vuelve con la persona si el servidor se reinició.
      enviar({ t: 'hola', id: cliente, nombre: miNombre || undefined, widget: leer('charla.widget', null) || undefined });
      marcar(true);
    };
    socket.onmessage = (evento) => {
      const mensaje = JSON.parse(evento.data);
      if (mensaje.t === 'yo') pintarYo(mensaje);
      if (mensaje.t === 'yo' || mensaje.t === 'mios') recordarMias(mensaje);
      if (mensaje.t === 'nombre' && mensaje.ok === false) {
        $('notaNombre').textContent = 'Ese nombre no pasó el linter. Prueba con otro.';
        $('formNombre').querySelector('button').disabled = false;
      }
      if (mensaje.t === 'concurso-mio') {
        miConcurso = mensaje;
        if (estado) { modoPintado = ''; pintar(); }
      }
      if (mensaje.t === 'estado') {
        estado = mensaje;
        const ronda = estado.excuseRound || {};
        finExcusas = ronda.phase === 'abierta' ? Date.now() + ronda.remaining * 1000 : 0;
        const concurso = estado.quiz || {};
        finPregunta = concurso.phase === 'pregunta' ? Date.now() + concurso.remaining * 1000 : 0;
        // En la portada del concurso empieza un juego nuevo: lo de antes no cuenta.
        if (concurso.phase === 'intro') miConcurso = null;
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

  // ---------- El nombre ----------

  $('formNombre').addEventListener('submit', (evento) => {
    evento.preventDefault();
    const nombre = $('textoNombre').value.trim().replace(/\s+/g, ' ');
    if (nombre.length < 2) { $('notaNombre').textContent = 'Escribe tu nombre.'; return; }
    $('notaNombre').textContent = '';
    $('formNombre').querySelector('button').disabled = true;
    enviar({ t: 'nombre', nombre });
  });

  // ---------- Pintar ----------

  function pintarYo(yo) {
    Object.assign(misVotos, yo.votos || {});
    if (!yo.nombre) {
      // Primero el nombre: sin él no se entra.
      $('bienvenida').hidden = false;
      $('yo').hidden = true;
      $('preguntar').hidden = true;
      $('pantalla').replaceChildren();
      modoPintado = '';
      setTimeout(() => $('textoNombre').focus(), 50);
      return;
    }
    miNombre = yo.nombre;
    guardar('charla.nombre', miNombre);
    $('bienvenida').hidden = true;
    $('yo').hidden = false;
    $('preguntar').hidden = false;
    $('saludo').textContent = `Hola, ${miNombre}. Tu apodo de hoy`;
    // SizedBox(height: 182) ya trae sus paréntesis.
    const conParentesis = yo.widget.endsWith(')');
    $('widget').textContent = yo.widget;
    $('parentesis').hidden = conParentesis;
    $('burbujaTitulo').textContent = conParentesis ? yo.widget : `${yo.widget}()`;
    $('burbujaTexto').textContent = yo.que || '';
    $('info').hidden = !yo.que;
    $('frase').textContent = yo.frase;
    guardar('charla.widget', yo.widget);
    if (estado) pintar();
  }

  function el(etiqueta, clase, texto) {
    const nodo = document.createElement(etiqueta);
    if (clase) nodo.className = clase;
    if (texto != null) nodo.textContent = texto;
    return nodo;
  }

  function recordarMias(mensaje) {
    mias = { excusas: mensaje.excusas || [], preguntas: mensaje.preguntas || [] };
    guardar('charla.mias', mias);
    if (mensaje.estrellas) {
      misEstrellas = mensaje.estrellas;
      guardar('charla.estrellas', misEstrellas);
    }
    pintarMias();
  }

  function pintarMias() {
    const lista = (id, textos, titulo) => {
      const nodo = $(id);
      if (!nodo) return;
      nodo.replaceChildren();
      nodo.hidden = textos.length === 0;
      if (!textos.length) return;
      nodo.append(el('p', 'etiqueta-lista', titulo), ...textos.map((texto) => el('p', 'mio', texto)));
    };
    lista('misExcusasLista', mias.excusas, 'Lo que mandaste');
    lista('misPreguntasLista', mias.preguntas, 'Tus preguntas');
  }

  function pintar() {
    $('conectados').textContent = `${estado.connected} conectados`;
    if (!miNombre || $('yo').hidden) return;
    const cue = estado.cue || { mode: 'idle' };
    // La pantalla roja se vuelve a pintar cuando se «arregla».
    const concurso = estado.quiz || {};
    const clave = cue.mode + (cue.poll ? cue.poll.id : '') + (cue.mode === 'crash' ? String(cue.revealed) : '') +
      (cue.mode === 'quiz' ? `${concurso.phase}-${concurso.index}` : '');
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
      case 'credits': pintarCreditos(pantalla); break;
      case 'crash': pintarError(pantalla, cue); break;
      case 'quiz': pintarConcurso(pantalla, concurso); break;
      default: pintarEspera(pantalla);
    }
  }

  /// Devuelve true si pudo actualizar sin volver a construir la pantalla.
  function actualizar(cue) {
    if (cue.mode === 'poll') { pintarResultados(cue); return true; }
    if (cue.mode === 'counter') { $('total').textContent = estado.counter; return true; }
    if (cue.mode === 'excuse') { relojExcusas(); return true; }
    if (cue.mode === 'quiz') { relojConcurso(); return true; }
    return ['rating', 'questions', 'credits', 'idle', 'crash'].includes(cue.mode);
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
      boton.append(el('span', 'barrita'), el('span', 'marca'));
      if (opcion.icon && window.MARCAS) {
        const icono = el('span', 'marca-app');
        icono.dataset.icono = opcion.icon;
        pintarIcono(icono, cue.revealed);
        boton.append(icono);
      }
      boton.append(el('span', 'texto', opcion.label), el('span', 'porcentaje', ''));
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

  // El logo de la app, como en la charla. «Esta presentación» muestra el de
  // Flutter solo cuando se revela la respuesta.
  function pintarIcono(nodo, revelado) {
    const clave = nodo.dataset.icono === 'esta' && revelado ? 'flutter' : nodo.dataset.icono;
    const marca = window.MARCAS[clave];
    if (!marca || nodo.dataset.pintado === clave) return;
    nodo.dataset.pintado = clave;
    nodo.style.background = marca.fondo;
    nodo.style.setProperty('--escala', marca.escala);
    nodo.innerHTML = marca.svg; // marcado fijo de marcas.js, nunca texto del público
  }

  function pintarResultados(cue) {
    const opciones = $('opciones');
    if (!opciones) return;
    for (const icono of opciones.querySelectorAll('.marca-app')) pintarIcono(icono, cue.revealed);
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

  function formulario({ titulo, ayuda, maximo, marcador, boton, alEnviar, limite, enviada }) {
    const form = el('form', 'formulario');
    const texto = el('textarea');
    texto.maxLength = maximo;
    texto.rows = 3;
    texto.placeholder = marcador;
    texto.value = borrador[titulo] || '';
    texto.addEventListener('input', () => {
      borrador[titulo] = texto.value;
      guardar('charla.borradores', borrador);
    });
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
      guardar('charla.borradores', borrador);
      nota.textContent = enviada;
    });
    return [el('h2', null, titulo), el('p', 'ayuda', ayuda), form];
  }

  function pintarExcusa(pantalla) {
    const reloj = el('p', 'reloj', '');
    reloj.id = 'relojExcusas';
    const [titulo, ayuda, form] = formulario({
      titulo: 'Tu mejor excusa de dev',
      ayuda: 'La que más has usado. Al acabar el tiempo, una IA escoge las mejores para la pantalla.',
      maximo: 140,
      marcador: 'Ej: en mi máquina sí funciona',
      boton: 'Enviar excusa',
      limite: () => mias.excusas.length < 3,
      enviada: 'Enviada. Puedes mandar hasta tres.',
      alEnviar: (texto) => enviar({ t: 'excusa', texto }),
    });
    form.id = 'formExcusa';
    const lista = el('div', 'mios');
    lista.id = 'misExcusasLista';
    pantalla.append(titulo, reloj, ayuda, form, lista);
    pintarMias();
    relojExcusas();
  }

  // La cuenta regresiva de las excusas: la lleva el celular, a partir de lo
  // que falta según el servidor.
  function relojExcusas() {
    const reloj = $('relojExcusas');
    if (!reloj) return;
    const fase = (estado.excuseRound || {}).phase;
    const falta = Math.max(0, Math.ceil((finExcusas - Date.now()) / 1000));
    const abierta = fase === 'abierta' && falta > 0;
    reloj.classList.toggle('fin', !abierta);
    reloj.textContent = abierta
      ? `${Math.floor(falta / 60)}:${String(falta % 60).padStart(2, '0')}`
      : fase === 'cerrada' ? 'Espera la señal…' : 'Tiempo. Mira la pantalla.';
    const form = $('formExcusa');
    if (form) for (const campo of form.querySelectorAll('textarea, button')) campo.disabled = !abierta;
  }
  setInterval(relojExcusas, 250);

  function pintarPreguntas(pantalla) {
    pantalla.append(
      el('h2', null, 'Preguntas'),
      el('p', 'ayuda', 'Mira la pantalla: una IA junta las que se parecen y escoge cinco. ¿Te falta la tuya? Escríbela abajo.'),
    );
    $('preguntar').open = true;
  }

  // La broma del error de mil millones de dólares, también en el celular.
  function pintarError(pantalla, cue) {
    const caja = el('div', `pantalla-roja${cue.revealed ? ' arreglada' : ''}`);
    if (cue.revealed) {
      const codigo = el('code', null, "String? excusa;\nexcusa ?? 'Funciona en mi máquina'   // sin pantalla roja");
      caja.append(
        el('p', 'listo', '✓ Hot fix aplicado'),
        el('h2', null, `Tranquilo, ${miNombre}: era parte del show.`),
        el('p', null, 'Ese «!» le dijo al compilador «confía en mí». Null safety existe para no tener que decirlo.'),
        codigo,
        el('p', null, '«Mi error de mil millones de dólares: la referencia nula.» — Tony Hoare'),
      );
    } else {
      caja.append(
        el('p', 'error-titulo', 'Null check operator used on a null value'),
        el('pre', null,
          'The relevant error-causing widget was:\n' +
          '  TuCelular  lib/celular.dart:42:13\n\n' +
          'When the exception was thrown, this was the stack:\n' +
          '#0  _TuCelularState.build (package:charla/celular.dart:57:24)\n' +
          '#1  StatefulElement.build (package:flutter/src/widgets/framework.dart)\n' +
          '#2  ComponentElement.performRebuild (package:flutter/…)'),
      );
      if (navigator.vibrate) navigator.vibrate([70, 50, 70, 50, 160]);
    }
    pantalla.append(caja);
  }

  // ---------- El concurso (tipo Kahoot) ----------

  // Los cuatro colores y figuras de siempre: triángulo, rombo, círculo y cuadrado.
  const FIGURAS = [
    { color: '#e21b3c', svg: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3 22 20H2z"/></svg>' },
    { color: '#1368ce', svg: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2 22 12 12 22 2 12z"/></svg>' },
    { color: '#d89e00', svg: '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10"/></svg>' },
    { color: '#26890c', svg: '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="3" width="18" height="18" rx="2"/></svg>' },
  ];

  function figura(i) {
    const nodo = el('span', 'figura');
    nodo.innerHTML = FIGURAS[i].svg; // marcado fijo, no texto del público
    return nodo;
  }

  function puntos(n) { return Number(n || 0).toLocaleString('es-CO'); }

  function pintarConcurso(pantalla, concurso) {
    const caja = el('div', 'concurso');
    const mio = miConcurso && miConcurso.index === concurso.index ? miConcurso : null;
    if (concurso.phase === 'intro' || concurso.index < 0) {
      caja.append(
        el('p', 'etiqueta', 'Concurso final'),
        el('h2', null, '¿Quién estuvo pilas?'),
        el('p', 'ayuda', `${concurso.total || 10} preguntas sobre la charla, 30 segundos cada una. Si aciertas ganas hasta 1000 puntos: entre más rápido, más.`),
        el('p', 'nota', 'Espera: empieza en la pantalla.'),
      );
    } else if (concurso.phase === 'pregunta') {
      const reloj = el('p', 'reloj', '');
      reloj.id = 'relojConcurso';
      caja.append(
        el('p', 'etiqueta', `Pregunta ${concurso.index + 1} de ${concurso.total}`),
        reloj,
        el('h2', null, concurso.question || ''),
      );
      const opciones = el('div', 'opciones-concurso');
      const respondida = mio && mio.answer != null;
      (concurso.options || []).forEach((texto, i) => {
        const boton = el('button', 'opcion-concurso');
        boton.type = 'button';
        boton.style.background = FIGURAS[i].color;
        boton.append(figura(i), el('span', null, texto));
        boton.disabled = respondida;
        if (respondida && mio.answer === i) boton.classList.add('elegida');
        boton.addEventListener('click', () => {
          enviar({ t: 'respuesta', index: concurso.index, opcion: i });
          if (navigator.vibrate) navigator.vibrate(12);
          for (const otro of opciones.children) otro.disabled = true;
          boton.classList.add('elegida');
          nota.textContent = '¡Listo! Espera el resultado.';
        });
        opciones.append(boton);
      });
      const nota = el('p', 'nota', respondida ? '¡Listo! Espera el resultado.' : 'Toca tu respuesta. Más rápido, más puntos.');
      caja.append(opciones, nota);
    } else {
      const correcta = concurso.correct;
      const final = concurso.phase === 'podio';
      if (!final && correcta != null && concurso.options) {
        const linea = el('p', 'correcta-concurso');
        linea.style.background = FIGURAS[correcta].color;
        linea.append(figura(correcta), el('span', null, concurso.options[correcta]));
        caja.append(el('p', 'etiqueta', `Pregunta ${concurso.index + 1}: la respuesta era`), linea);
      }
      if (final) {
        const medallas = ['', '🥇', '🥈', '🥉'];
        caja.append(
          el('p', 'etiqueta', 'Fin del concurso'),
          el('h2', 'puesto-final', miConcurso && miConcurso.rank ? `Quedaste #${miConcurso.rank} ${medallas[miConcurso.rank] || ''}` : 'Mira la pantalla'),
        );
      } else if (mio) {
        const acerto = (mio.gained || 0) > 0;
        caja.append(el('h2', acerto ? 'bien' : 'mal',
          mio.answer == null ? 'No alcanzaste a responder' : acerto ? `¡Correcto! +${puntos(mio.gained)}` : 'Esta no era'));
      }
      if (miConcurso && miConcurso.rank) {
        caja.append(el('p', 'ayuda', `Vas #${miConcurso.rank} de ${miConcurso.players} · ${puntos(miConcurso.points)} puntos`));
      }
      caja.append(el('p', 'nota', final ? '¡Mira el podio en la pantalla!' : 'Mira la tabla en la pantalla.'));
    }
    pantalla.append(caja);
    relojConcurso();
  }

  function relojConcurso() {
    const reloj = $('relojConcurso');
    if (!reloj) return;
    const falta = Math.max(0, Math.ceil((finPregunta - Date.now()) / 1000));
    reloj.classList.toggle('fin', falta === 0);
    reloj.textContent = falta > 0 ? `0:${String(falta).padStart(2, '0')}` : 'Tiempo';
  }
  setInterval(relojConcurso, 250);

  function pintarCreditos(pantalla) {
    pantalla.append(
      el('p', 'grande', '🎬'),
      el('h2', null, 'Busca tu nombre en la pantalla'),
      el('p', 'ayuda', `${miNombre}, saliste en los créditos.`),
    );
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

  // ---------- Qué hace mi widget ----------

  // Un tooltip que se abre con el botón de información y se cierra al tocar
  // afuera, con Esc o con el mismo botón.
  let cerrarAyuda = 0;
  function mostrarAyuda(mostrar) {
    const info = $('info');
    const burbuja = $('burbuja');
    clearTimeout(cerrarAyuda);
    info.setAttribute('aria-expanded', String(mostrar));
    if (mostrar) {
      burbuja.hidden = false;
      const boton = info.getBoundingClientRect();
      const caja = burbuja.getBoundingClientRect();
      burbuja.style.setProperty('--flecha', `${boton.left + boton.width / 2 - caja.left}px`);
      requestAnimationFrame(() => requestAnimationFrame(() => burbuja.classList.add('abierta')));
      if (navigator.vibrate) navigator.vibrate(5);
    } else {
      burbuja.classList.remove('abierta');
      cerrarAyuda = setTimeout(() => { burbuja.hidden = true; }, 240);
    }
  }
  $('info').addEventListener('click', (evento) => {
    evento.stopPropagation();
    mostrarAyuda($('info').getAttribute('aria-expanded') !== 'true');
  });
  document.addEventListener('click', (evento) => {
    if ($('info').getAttribute('aria-expanded') === 'true' && !$('burbuja').contains(evento.target)) mostrarAyuda(false);
  });
  document.addEventListener('keydown', (evento) => {
    if (evento.key === 'Escape' && $('info').getAttribute('aria-expanded') === 'true') mostrarAyuda(false);
  });

  // ---------- Siempre disponibles ----------

  $('formPregunta').addEventListener('submit', (evento) => {
    evento.preventDefault();
    const texto = $('textoPregunta').value.trim();
    const nota = $('notaPregunta');
    if (texto.length < 3) { nota.textContent = 'Escribe un poquito más.'; return; }
    enviar({ t: 'pregunta', texto });
    $('textoPregunta').value = '';
    borrador.pregunta = '';
    guardar('charla.borradores', borrador);
    nota.textContent = 'Recibida. Al final, una IA escoge las que cubren más dudas.';
  });
  $('textoPregunta').value = borrador.pregunta || '';
  $('textoPregunta').addEventListener('input', () => {
    borrador.pregunta = $('textoPregunta').value;
    guardar('charla.borradores', borrador);
  });
  pintarMias();

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
