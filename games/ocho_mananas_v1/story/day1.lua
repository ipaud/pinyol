-- The first morning's words (plan, pp. 11 and 15). Draft lines: short, read by hand, no long tutorials.
local story = {}

story.prologue = {
  place = "Taller de fotografía · 6 de julio, noche", bg = "PIC_TALLER",
  lines = {
    {"Dani", "¿Esta es la de Estafeta?", pic = "PIC_FOTO"},
    {"Ana", "La copia sí. El resto debe de estar en esas cajas.", pic = "PIC_FOTO"},
    {"Dani", "Este año quiero una así."},
    {"Ana", "Primero ayúdame a encontrar de dónde salió."},
    {"", "Leire, la amiga de siempre, se asoma a la puerta del taller."},
    {"Leire", "¿Vas a correr? Mañana temprano vemos el tramo. Sin toros."},
  },
}

story.practice = {
  place = "Estafeta · antes de que la abran", bg = "SCENE_CALLE",
  lines = {
    {"Leire", "Aquí no hay prisa. Aprende a moverte y a salir."},
    {"Leire", "Lo importante no es aguantar: es saber cuándo terminar."},
  },
}

story.before = {
  place = "Mañana 1 · 7 de julio · 07:55", bg = "SCENE_CALLE",
  lines = {
    {"Leire", "Hoy corro a tu lado un rato. Luego cada uno a lo suyo."},
    {"Leire", "Elige tu salida antes de empezar. Y mira el radar, no la espalda."},
  },
}

-- after the first race; `leire` is the line chosen from how it went
function story.after(how)
  local first
  if how.photo then
    first = {
      {"Nico", "Mira. Te he sacado. Con el toro detrás.", pic = "PIC_NICO_OK"},
      {"Dani", "...¿Ese soy yo?"},
      {"Leire", "Ese eres tú, un segundo. Luego te has apartado."},
      {"Dani", "Eso no sale."},
      {"Leire", "Pero ha pasado. Y es lo que ha estado bien."},
    }
  else
    first = {
      {"Nico", "Mira. Te he sacado. Bueno... casi.", pic = "PIC_NICO"},
      {"Dani", "En la foto ni se me ve."},
      {"Leire", "Yo te he visto salir."},
      {"Dani", "Eso no sale."},
      {"Leire", "Pero ha pasado."},
    }
  end
  local lines = first
  for _, l in ipairs({
      {"Leire", how.leire},
      {"Leire", "¿Te acuerdas de por dónde saliste?"},
      {"", "Dani abre un cuaderno: entrada, salida y una sola observación."},
      {"", "En el taller, la copia del abuelo se queda sobre la mesa. Esperando."},
    }) do lines[#lines + 1] = l end
  return {
    place = "Primer desayuno", bg = "PIC_BAR",
    lines = lines,
  }
end

return story
