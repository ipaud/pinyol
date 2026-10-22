-- The scenes around each of the eight mornings (plan, pp. 11-16): before(d) is the scene that opens the morning, after(d, how)
-- the one that closes it, written from how the run went. `how` is the judge's result (main.lua): how.clean, how.exhausted,
-- how.photo, how.early, how.late, how.contacts, how.ch (the challenges done). Lines are short and read by hand: a game, not a book.
-- Day 1 lives in story/day1.lua (it also has the prologue and the practice).
local day1 = require("story.day1")
local story = {}

local function scene(place, bg, lines) return {place = place, bg = bg, lines = lines} end

local before = {}
local after = {}

before[1] = function() return day1.before end

before[2] = function()
  return scene("8 de julio · Estafeta · 07:40", "SCENE_CALLE", {
    {"Leire", "Hoy no se trata de correr rápido. Se trata de mirar a los demás."},
    {"Leire", "Esos dos van siempre pegados a la pared. Fíjate en cuándo cambian."},
    {"Dani", "¿Y si me adelanto?"},
    {"Leire", "Entonces fíjate en a quién le cierras el paso."},
  })
end

before[3] = function()
  return scene("9 de julio · Mercaderes · 07:40", "PIC_MERCADERES", {
    {"Leire", "Esta es la curva. Entra por fuera y sal por dentro."},
    {"Dani", "Yo entro tarde. Así se ve más."},
    {"Leire", "Prueba. Verás lo que cuesta cada corrección."},
  })
end

before[4] = function()
  return scene("10 de julio · Estafeta · 07:40", "SCENE_CALLE", {
    {"Dani", "Hoy lo tengo. Las calles ya me las sé."},
    {"Leire", "Yo tengo lo mío hoy. No corro a tu lado todo el rato."},
    {"Leire", "Elige tú el tramo, el corto o el largo. Ninguno es el bueno."},
  })
end

before[5] = function()
  return scene("11 de julio · El taller · 07:20", "PIC_MESA", {
    {"Dani", "Hoy lo sé. Por la izquierda y listo."},
    {"Leire", "En el cuaderno he apuntado otra salida, más adelante."},
    {"Leire", "Las condiciones cambian. Mira las dos antes de empezar."},
  })
end

before[6] = function()
  return scene("12 de julio · El taller · 07:20", "PIC_TALLER", {
    {"Nico", "Pasado mañana te hago el encuadre, desde el sitio autorizado."},
    {"Dani", "¿Ya? ¡Vale!"},
    {"Ana", "¿Quieres guardar el archivo o solo la copia del abuelo?"},
    {"Dani", "...Luego te lo digo."},
  })
end

before[7] = function()
  return scene("13 de julio · El taller · 07:20", "PIC_MESA", {
    {"Julián", "Me pedían siempre esa copia.", pic = "PIC_TIRA"},
    {"Dani", "Parece que estés celebrándolo."},
    {"Julián", "En el siguiente ya no estoy."},
    {"", "Dani mueve el fotograma. Aparece otra figura."},
    {"Julián", "Él quería salir. Yo también tenía sitio."},
  })
end

before[8] = function()
  return scene("14 de julio · El desayuno · 07:10", "PIC_BAR", {
    {"Nico", "Estaré donde dijimos. No prometo que salgas."},
    {"Leire", "Dos tramos conocidos. Elige tu salida."},
    {"Dani", "Esta vez la elijo yo."},
  })
end

function story.before(d)
  return before[d]()
end

-- --- after -----------------------------------------------------------------------------------------------------------------

local function leire_line(how)
  if how.exhausted then return "Tenías hueco, pero ya no podías cambiar de ritmo." end
  if how.contacts == 0 then return "Hoy has podido esperar." end
  return "Has rozado a alguien. Mira antes de cambiar de línea."
end

after[1] = function(how) return day1.after(how) end

after[2] = function(how)
  local first
  if how.clean then first = {"Leire", "Has dejado espacio. Se nota."}
  else first = {"Leire", "Hoy has cerrado el paso a uno. Mira antes de adelantar."} end
  return scene("Después de la carrera · Estafeta", "SCENE_CALLE", {
    first,
    {"Dani", "Es difícil saber quién va a girar."},
    {"Leire", "Se nota en los hombros antes que en los pies."},
    {"", "Ana ha encontrado en el taller una funda con negativos numerados. Sin ordenar."},
  })
end

after[3] = function(how)
  return scene("Después de la carrera · El taller", "PIC_MESA", {
    {"Dani", "Mira. Otro negativo, justo al lado del de Estafeta.", pic = "PIC_NEG1"},
    {"Ana", "Julián mira hacia un lado."},
    {"Dani", "Mira a la cámara."},
    {"Ana", "A mí me parece que mira hacia allí."},
    {"Dani", "Eso es la cámara. Seguro."},
    {"", how.clean and "Dani sonríe. Ha entrado en la curva sin un solo roce."
        or "Dani se frota el hombro. La curva no perdona."},
  })
end

after[4] = function(how)
  local lines = {
    {"Leire", leire_line(how)},
    {"Julián", "En una secuencia de fotos, el orden importa más que la imagen más espectacular."},
    {"Dani", "¿Y la de Estafeta?"},
    {"Julián", "Esa es la que se quedó."},
    {"", "Ana pone sobre la mesa un sobre. Su numeración continúa la serie."},
  }
  return scene("Después de la carrera · El taller", "PIC_MESA", lines)
end

after[5] = function(how)
  local lines = {
    {"Leire", "¿Qué señal te hizo cambiar de salida?"},
  }
  if how.clean then lines[#lines + 1] = {"Dani", "Vi cerrarse el hueco a la izquierda."}
  else lines[#lines + 1] = {"Dani", "No lo vi hasta que lo tuve encima."} end
  lines[#lines + 1] = {"Leire", "Pues anótalo. Descríbelo con movimientos, no con segundos."}
  lines[#lines + 1] = {"", "Dani escribe en el cuaderno: «pared izquierda, cerrado; derecha, libre»."}
  return scene("Después de la carrera · Estafeta", "SCENE_CALLE", lines)
end

after[6] = function(how)
  local lines = {
    {"Dani", "Mira. Aquí sale claro el otro corredor, junto al abuelo.", pic = "PIC_NEG1"},
    {"Julián", "Mañana ordenamos la secuencia entera, si quieres."},
    {"Dani", "Quiero."},
  }
  if how.early then table.insert(lines, 1, {"Leire", "Has salido a tiempo. Ese día, eso era correr bien."}) end
  return scene("Después de la carrera · El taller", "PIC_MESA", lines)
end

after[7] = function(how)
  return scene("Después de la carrera · El desayuno", "PIC_BAR", {
    {"Nico", "He hecho unas cuantas. Pocas salen tan bien como te sientes."},
    {"Dani", "La foto final no debe mandar en mi carrera."},
    {"Nico", "Eso. Yo fotografío lo que pasa."},
    {"Dani", "Ya. Aunque me gustaría salir."},
    {"Nico", "Mañana, el encuadre. No prometo nada."},
  })
end

-- how the last morning ends: three endings from what the player did, none of them a punishment
function story.ending(how)
  if how.photo and (how.contacts > 0 or how.exhausted) then return "foto" end
  if how.early and not how.stay then return "otra" end
  return "secuencia"
end

after[8] = function(how)
  local end_ = story.ending(how)
  local lines
  if end_ == "foto" then
    lines = {
      {"Nico", "Mira. La tienes. El toro, tú, todo."},
      {"Dani", "...Soy yo. Se ve el roce."},
      {"Leire", "También sale lo que costó. Eso también es la foto."},
      {"Julián", "La tira lo enseña entera. No la escondas."},
      {"Dani", "No. Me quedo con esta, y con las otras."},
    }
  elseif end_ == "otra" then
    lines = {
      {"Dani", "No ha salido la que buscaba."},
      {"Leire", "Pero saliste a tiempo."},
      {"Nico", "Tengo una del desayuno, antes de correr. Estás riéndote."},
      {"Dani", "Esa también me la quedo."},
    }
  else
    lines = {
      {"Dani", how.photo and "Ha salido la foto. Y sin un roce." or "No ha salido la que buscaba."},
      {"Julián", "¿Y esta?"},
      {"Dani", "Esta sí me acuerdo de hacerla."},
      {"Ana", "Entonces va a la funda nueva, con las demás."},
    }
  end
  lines[#lines + 1] = {"", "Ana coloca la tira completa en la funda. Apaga la luz del taller."}
  return scene("Después de la carrera · El taller", "PIC_TALLER", lines)
end

function story.after(d, how)
  return after[d](how)
end

story.TITLES = {secuencia = "LA SECUENCIA COMPLETA", foto = "LA FOTO BUSCADA", otra = "OTRA MAÑANA"}
story.NOTES = {
  secuencia = "Saliste a tiempo y completaste el archivo.",
  foto = "Fuiste a por la foto. Y la tienes.",
  otra = "Te quedaste con una mañana tranquila.",
}

return story
