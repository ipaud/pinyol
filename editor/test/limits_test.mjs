// What a project from a file cannot make the editor do: write Lua that does not load (a drawing called "end", a title
// with a line break, a control character), or keep more than the console takes (drawings, sounds, videos, a level's
// objects). The same caps are in the tabs, so what is kept is what was made.
//   node editor/test/limits_test.mjs
import assert from 'node:assert/strict';
import { check, DRAWING, blankFrame, MAX_DRAWINGS, MAX_SOUNDS, MAX_VIDEOS, MAX_OBJECTS } from '../js/project.js';
import { lua, buildFiles } from '../js/build.js';

assert.equal(lua({ end: 1, ok: 2, 'a b': 3 }), '{\n  ["end"] = 1,\n  ok = 2,\n  ["a b"] = 3\n}');
assert.equal(lua('a\r\nb\x01'), '"a\\r\\nb\\001"');

const one = name => ({ ...DRAWING, name, w: 1, h: 1, frames: [blankFrame(1, 1)] });
const p = check({ format: 3, title: 'Uno\ndos', drawings: [one('end'), ...Array.from({ length: MAX_DRAWINGS + 5 }, (_, i) => one('d' + i))],
  sounds: Array.from({ length: MAX_SOUNDS + 3 }, (_, i) => ({ name: 's' + i, recipe: 'blip' })),
  videos: Array.from({ length: MAX_VIDEOS + 3 }, (_, i) => ({ name: 'v' + i, npv: 'eA==' })),
  levels: [{ id: 'n1', name: 'Uno\r\ndos', objects: Array.from({ length: MAX_OBJECTS + 7 }, () => ({ kind: 'end', x: 1, y: 1 })) }] });
assert.equal(p.title, 'Uno dos');
assert.equal(p.levels[0].name, 'Uno dos');
assert.equal(p.drawings.length, MAX_DRAWINGS);
assert.equal(p.drawings[0].name, 'end');
assert.equal(p.sounds.length, MAX_SOUNDS);
assert.equal(p.videos.length, MAX_VIDEOS);
assert.equal(p.levels[0].objects.length, MAX_OBJECTS);
const files = buildFiles(p, '', []);
const texts = [...files.values()].map(v => typeof v === 'string' ? v : new TextDecoder().decode(v));
assert.ok(texts.some(v => v.includes('["end"] = {')), 'a drawing called "end" is written as a Lua key in brackets');
assert.ok(!texts.some(v => /\n\s*end = \{/.test(v)), 'never bare');
console.log('limits: ok');
