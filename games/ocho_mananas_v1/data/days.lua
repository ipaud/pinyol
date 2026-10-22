-- The mornings, as data. Distances are street units (about 11 cm: a runner is 16 tall, Estafeta 64 wide here).
-- The eight mornings of the plan (7 to 14 July) and the empty-street practice. A morning with `variants` lets the player
-- pick between known stretches before the run (days 4, 7 and 8): days.resolve(day, i) merges the chosen one in.
local days = {}

days.practice = {
  id = "practice", title = "Práctica", subtitle = "Estafeta vacía", seed = 7,
  length = 2200, herd = {}, runners = 0, lane = {{0, 0}},
  zones = {},  -- the tutorial places its own way out when the player gets there
  views = {{0, "rear"}},
}

days[1] = {
  id = 1, title = "Mañana 1", date = "7 de julio", subtitle = "La foto", seed = 701,
  street = "ESTAFETA", length = 2700,
  -- the herd's lane: {z, x} keys along the street; the group keeps to it, each animal at its own offset
  lane = {{0, 6}, {600, 4}, {840, 14}, {1100, 14}, {1250, 12}, {1500, -4}, {2400, 7}, {3200, 0}},
  -- Nico on a right-hand balcony: run in front of the group, in its line, with control, and get out in time
  photo = {z0 = 760, z1 = 980, side = 1, at = 870, need = 30, near = 16, far = 45},
  -- a runner who will go down by the left-hand wall: the wall is not a free hiding place
  falls = {{start = 330, x = -25, at = 975, lie = 420}},
  herd = {
    {start = -700, speed = 1.55, members = {
      {"cabestro", -7, 0}, {"toro", 5, -6}, {"toro", -2, -14}, {"toro", 8, -22}, {"toro", -6, -28}, {"cabestro", 1, -40}}},
    {start = -1320, speed = 1.42, members = {{"cabestro", -4, 0}, {"toro", 4, -12}, {"cabestro", -1, -26}}},
  },
  runners = 12,
  zones = {
    {id = "R1", side = -1, z0 = 560, z1 = 700, label = "Portal de la izquierda"},
    {id = "R2", side = 1, z0 = 1420, z1 = 1600, label = "Portal de la derecha"},
    {id = "R3", side = -1, z0 = 2420, z1 = 2620, label = "Salida de final de tramo"},
  },
  -- which camera each part of the street wants; a cut waits for a calm moment
  views = {{0, "rear"}, {1180, "side"}, {2240, "rear"}},
  objective = "Cierra la carrera por una retirada sin quedarte sin aire.",
  challenges = {
    {id = "clean", text = "Sin contactos."},
    {id = "stay", text = "Deja pasar a la manada antes de retirarte."},
    {id = "photo", text = "La foto de Nico: delante del grupo, con control."},
  },
}

-- --- the other seven mornings ----------------------------------------------------------------------------------------------
-- Challenge ids the judge in main.lua understands: clean (no contacts), stay (let the herd pass before leaving), photo,
-- air (never under a third of the air), early (left by the first way out), late (left by the last one), smooth (at most two
-- sharp changes of line), nopush (never held A to push).

local function herd(...) return {...} end
local function group(start, speed, members) return {start = start, speed = speed, members = members} end
local C, T, N = "cabestro", "toro", nil

days[2] = {
  id = 2, title = "Mañana 2", date = "8 de julio", subtitle = "Los demás", seed = 802,
  street = "ESTAFETA", length = 2300,
  lane = {{0, 4}, {700, 2}, {1200, -6}, {1800, 6}, {2500, 0}},
  falls = {{start = 400, x = 25, at = 1180, lie = 380}},
  herd = {group(-900, 1.42, {{C, -6, 0}, {T, 4, -9}, {T, -3, -18}, {C, 2, -30}})},
  runners = 16,
  zones = {
    {id = "R1", side = -1, z0 = 700, z1 = 860, label = "Portal de la izquierda"},
    {id = "R2", side = 1, z0 = 1500, z1 = 1680, label = "Portal de la derecha"},
    {id = "R3", side = -1, z0 = 2060, z1 = 2220, label = "Salida de final de tramo"},
  },
  views = {{0, "side"}, {1450, "rear"}, {1950, "side"}},
  objective = "Mantén tu línea y retírate por una salida.",
  challenges = {
    {id = "smooth", text = "Sin cambios bruscos de línea."},
    {id = "air", text = "Que el aire no baje de un tercio."},
  },
}

days[3] = {
  id = 3, title = "Mañana 3", date = "9 de julio", subtitle = "La curva", seed = 903,
  street = "MERCADERES", length = 2400,
  -- the herd's line swings across the street at the bend (z 900-1300): to be out of it, be on the right before the vertex
  lane = {{0, 6}, {600, 8}, {900, -12}, {1250, 16}, {1700, 10}, {2400, 0}},
  herd = {group(-930, 1.65, {{C, -5, 0}, {T, 5, -8}, {T, -3, -16}, {T, 7, -24}, {C, 0, -36}})},
  runners = 12,
  zones = {
    {id = "R1", side = -1, z0 = 940, z1 = 1100, label = "Portal antes de la curva"},
    {id = "R2", side = 1, z0 = 1860, z1 = 2040, label = "Portal después de la curva"},
  },
  views = {{0, "rear"}, {850, "side"}, {1700, "rear"}},
  objective = "Prepara el giro antes de su vértice y sal sin contacto.",
  challenges = {
    {id = "clean", text = "Sin contactos en la curva."},
    {id = "stay", text = "Deja pasar a la manada antes de salir."},
  },
}

days[4] = {
  id = 4, title = "Mañana 4", date = "10 de julio", subtitle = "Demasiado pronto", seed = 1004,
  street = "ESTAFETA", length = 2900, hints = true,
  lane = {{0, 6}, {700, 2}, {1300, -8}, {2100, 10}, {2900, 0}},
  herd = {group(-800, 1.5, {{C, -6, 0}, {T, 4, -9}, {T, -3, -17}, {T, 8, -26}, {C, 0, -38}}),
          group(-1500, 1.62, {{C, -4, 0}, {T, 5, -10}, {T, -5, -20}})},
  runners = 15,
  zones = {
    {id = "R1", side = -1, z0 = 800, z1 = 960, label = "Portal de la izquierda"},
    {id = "R2", side = 1, z0 = 1700, z1 = 1880, label = "Portal de la derecha"},
    {id = "R3", side = -1, z0 = 2560, z1 = 2760, label = "Salida del final"},
  },
  views = {{0, "rear"}, {1000, "side"}, {2000, "rear"}},
  objective = "Llega a una retirada con aire para corregir.",
  challenges = {
    {id = "air", text = "Que el aire no baje de un tercio."},
    {id = "late", text = "Salir por la última retirada."},
  },
  variants = {
    {name = "Tramo corto", note = "1.900 · dos salidas", length = 1900,
     lane = {{0, 6}, {600, 0}, {1200, -6}, {1900, 4}},
     herd = {group(-600, 1.6, {{C, -6, 0}, {T, 4, -9}, {T, -3, -17}, {T, 8, -26}, {C, 0, -38}})},
     zones = {{id = "R1", side = 1, z0 = 1150, z1 = 1310, label = "Portal de la derecha"},
              {id = "R2", side = -1, z0 = 1640, z1 = 1820, label = "Salida del final"}},
     views = {{0, "rear"}, {800, "side"}, {1500, "rear"}}},
    {name = "Tramo largo", note = "2.900 · tres salidas", length = 2900},
  },
}

days[5] = {
  id = 5, title = "Mañana 5", date = "11 de julio", subtitle = "Lo imprevisto", seed = 1105,
  street = "ESTAFETA", length = 2700,
  -- the herd leaves the left wall for the right one at z 1100-1250: the gap Dani knew is gone
  lane = {{0, -6}, {1100, -8}, {1250, 18}, {2700, 14}},
  falls = {{start = 300, x = -25, at = 960, lie = 600}},
  herd = {group(-800, 1.5, {{C, -6, 0}, {T, 4, -9}, {T, -3, -18}, {T, 7, -27}, {C, 0, -38}}),
          group(-1450, 1.55, {{C, -5, 0}, {T, 4, -10}, {T, -6, -22}})},
  runners = 15,
  zones = {
    {id = "R1", side = -1, z0 = 850, z1 = 1010, label = "Portal de la izquierda (cortado)"},
    {id = "R2", side = 1, z0 = 1380, z1 = 1560, label = "Portal alternativo"},
    {id = "R3", side = -1, z0 = 2450, z1 = 2640, label = "Salida del final"},
  },
  views = {{0, "rear"}, {1150, "side"}, {2150, "rear"}},
  objective = "Si el hueco se cierra, cambia y busca otra salida.",
  challenges = {
    {id = "clean", text = "Sin contactos al cambiar de plan."},
    {id = "stay", text = "Deja pasar a la manada antes de salir."},
  },
}

days[6] = {
  id = 6, title = "Mañana 6", date = "12 de julio", subtitle = "Hacerse a un lado", seed = 1206,
  street = "ESTAFETA", length = 2600,
  lane = {{0, 4}, {800, 14}, {1500, 8}, {2100, 14}, {2600, 6}},
  falls = {{start = 350, x = 25, at = 1700, lie = 420}},
  herd = {group(-750, 1.55, {{C, -6, 0}, {T, 4, -9}, {T, 9, -18}}),
          group(-1250, 1.5, {{C, -3, 0}, {T, 6, -11}, {T, -6, -22}}),
          group(-1700, 1.6, {{C, -5, 0}, {T, 3, -12}, {T, 8, -24}})},
  runners = 18,
  zones = {
    {id = "R1", side = 1, z0 = 1050, z1 = 1210, label = "Portal de la derecha"},
    {id = "R2", side = 1, z0 = 2040, z1 = 2200, label = "Segundo portal"},
    {id = "R3", side = -1, z0 = 2400, z1 = 2560, label = "Salida del final"},
  },
  views = {{0, "side"}, {1300, "rear"}, {2000, "side"}},
  objective = "Modula el ritmo y termina en una salida libre.",
  challenges = {
    {id = "early", text = "Salir por la primera salida."},
    {id = "nopush", text = "Sin empujar: sin mantener A."},
  },
}

local estafeta7 = {
  name = "Estafeta", note = "la calle de la primera mañana",
  length = 2700, lane = {{0, 6}, {600, 4}, {840, 14}, {1100, 14}, {1250, 12}, {1500, -4}, {2400, 7}, {3200, 0}},
  falls = {{start = 330, x = -25, at = 975, lie = 420}},
  herd = {group(-700, 1.6, {{C, -7, 0}, {T, 5, -6}, {T, -2, -14}, {T, 8, -22}, {T, -6, -28}, {C, 1, -40}}),
          group(-1320, 1.48, {{C, -4, 0}, {T, 4, -12}, {C, -1, -26}})},
  runners = 14,
  zones = {
    {id = "R1", side = -1, z0 = 560, z1 = 700, label = "Portal de la izquierda"},
    {id = "R2", side = 1, z0 = 1420, z1 = 1600, label = "Portal de la derecha"},
    {id = "R3", side = -1, z0 = 2420, z1 = 2620, label = "Salida de final de tramo"},
  },
  views = {{0, "rear"}, {1180, "side"}, {2240, "rear"}},
}
local mercaderes7 = {
  name = "Mercaderes", note = "la curva del tercer día",
  length = 2400, street = "MERCADERES",
  lane = {{0, 6}, {600, 8}, {900, -12}, {1250, 16}, {1700, 10}, {2400, 0}},
  herd = {group(-800, 1.58, {{C, -5, 0}, {T, 5, -8}, {T, -3, -16}, {T, 7, -24}, {C, 0, -36}}),
          group(-1400, 1.5, {{C, -4, 0}, {T, 5, -11}, {T, -6, -22}})},
  runners = 13, falls = {},
  zones = {
    {id = "R1", side = -1, z0 = 940, z1 = 1100, label = "Portal antes de la curva"},
    {id = "R2", side = 1, z0 = 1860, z1 = 2040, label = "Portal después de la curva"},
  },
  views = {{0, "rear"}, {850, "side"}, {1700, "rear"}},
}

days[7] = {
  id = 7, title = "Mañana 7", date = "13 de julio", subtitle = "Fuera de campo", seed = 1307,
  street = "ESTAFETA", hints = false,
  length = estafeta7.length, lane = estafeta7.lane, falls = estafeta7.falls, herd = estafeta7.herd, runners = estafeta7.runners,
  zones = estafeta7.zones, views = estafeta7.views, seed_alt = 1308,
  objective = "Elige entrada y retirada; completa el plan o adáptalo.",
  challenges = {
    {id = "air", text = "Que el aire no baje de un tercio."},
    {id = "smooth", text = "Sin cambios bruscos: una línea limpia."},
  },
  variants = {estafeta7, mercaderes7},
}

local estafeta8 = {
  name = "Estafeta", note = "tres salidas: elige una",
  length = 3000, street = "ESTAFETA",
  lane = {{0, 6}, {600, 4}, {1100, 12}, {1500, -4}, {1900, 14}, {2400, -8}, {3200, 0}},
  falls = {{start = 350, x = -25, at = 1000, lie = 420}, {start = 900, x = 25, at = 2150, lie = 420}},
  herd = {group(-700, 1.6, {{C, -7, 0}, {T, 5, -6}, {T, -2, -14}, {T, 8, -22}, {T, -6, -28}, {C, 1, -40}}),
          group(-1250, 1.55, {{C, -4, 0}, {T, 4, -12}, {T, -5, -22}, {C, 0, -34}}),
          group(-1900, 1.5, {{C, -3, 0}, {T, 5, -10}, {T, -4, -20}})},
  runners = 16,
  photo = {z0 = 700, z1 = 950, side = 1, at = 820, need = 30, near = 16, far = 45},
  zones = {
    {id = "R1", side = -1, z0 = 1250, z1 = 1420, label = "Retirada temprana"},
    {id = "R2", side = 1, z0 = 1980, z1 = 2150, label = "Retirada a mitad"},
    {id = "R3", side = -1, z0 = 2780, z1 = 2960, label = "Retirada exigente"},
  },
  views = {{0, "rear"}, {1000, "side"}, {1900, "rear"}, {2400, "side"}},
}
local mercaderes8 = {
  name = "Mercaderes", note = "la curva, manada larga",
  length = 2800, street = "MERCADERES",
  lane = {{0, 6}, {600, 8}, {900, -12}, {1250, 16}, {1700, 10}, {2100, -10}, {2800, 0}},
  falls = {{start = 500, x = 25, at = 1500, lie = 420}},
  herd = {group(-800, 1.6, {{C, -5, 0}, {T, 5, -8}, {T, -3, -16}, {T, 7, -24}, {C, 0, -36}}),
          group(-1450, 1.55, {{C, -4, 0}, {T, 5, -11}, {T, -6, -22}, {C, 0, -32}})},
  runners = 15,
  photo = {z0 = 800, z1 = 1050, side = 1, at = 930, need = 30, near = 16, far = 45},
  zones = {
    {id = "R1", side = -1, z0 = 940, z1 = 1100, label = "Retirada temprana"},
    {id = "R2", side = 1, z0 = 1900, z1 = 2060, label = "Retirada a mitad"},
    {id = "R3", side = -1, z0 = 2560, z1 = 2760, label = "Retirada exigente"},
  },
  views = {{0, "rear"}, {850, "side"}, {1700, "rear"}, {2200, "side"}},
}

days[8] = {
  id = 8, title = "Mañana 8", date = "14 de julio", subtitle = "Tu carrera", seed = 1408,
  street = "ESTAFETA", hints = false,
  length = estafeta8.length, lane = estafeta8.lane, falls = estafeta8.falls, herd = estafeta8.herd, runners = estafeta8.runners,
  photo = estafeta8.photo, zones = estafeta8.zones, views = estafeta8.views,
  objective = "Cierra una carrera controlada: tú eliges la salida.",
  challenges = {
    {id = "air", text = "Que el aire no baje de un tercio."},
    {id = "clean", text = "Sin contactos."},
    {id = "photo", text = "El encuadre de Nico, si te sale."},
  },
  variants = {estafeta8, mercaderes8},
}

-- The day as it is played: the picked variant laid over it (nothing to merge for a morning without variants).
function days.resolve(day, i)
  if not day.variants then return day end
  local v = day.variants[i or 1]
  local out = {}
  for k, x in pairs(day) do out[k] = x end
  for k, x in pairs(v) do
    if k ~= "name" and k ~= "note" then out[k] = x end
  end
  out.variant, out.variant_name = i or 1, v.name
  return out
end

return days
