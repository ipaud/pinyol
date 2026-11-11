"""tools/library.py on what people may send: a good game, a path that climbs out, a file that is no zip, a form.

    python3 tests/library_test.py build/pinyol_headless
"""
import json
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import library  # noqa: E402
import pack_game  # noqa: E402

headless = Path(sys.argv[1])
with tempfile.TemporaryDirectory() as t:
    t = Path(t)
    taken = pack_game.pack(ROOT / "examples" / "pozo", t / "zips", False)  # an example's own id: refused
    r = library.check(taken, t / "taken", headless)
    assert not r["ok"] and "ya es el de un ejemplo" in r["errors"][0], r
    mine = t / "mine"
    shutil.copytree(ROOT / "examples" / "pozo", mine, ignore=shutil.ignore_patterns("saves"))
    meta = json.loads((mine / "game.json").read_text(encoding="utf-8"))
    (mine / "game.json").write_text(json.dumps({**meta, "id": "mi_bolsillo"}), encoding="utf-8")
    good = pack_game.pack(mine, t / "zips", False)
    r = library.check(good, t / "good", headless)
    assert r["ok"] and r["id"] == "mi_bolsillo", r
    bad_art = t / "bad_art_game"
    shutil.copytree(mine, bad_art)
    meta = json.loads((bad_art / "game.json").read_text(encoding="utf-8"))
    (bad_art / "game.json").write_text(json.dumps({**meta, "id": "sin_dibujo"}), encoding="utf-8")
    with (bad_art / "main.lua").open("a") as lua:
        lua.write("\nfunction _draw() img('MISSING_ART', 10, 10) end\n")
    missing = pack_game.pack(bad_art, t / "zips", False)
    r = library.check(missing, t / "bad_art", headless)
    assert not r["ok"] and any("MISSING_ART" in e for e in r["errors"]), r
    shared = t / "para-compartir.zip"  # as people share it: the game's folder, with notes and the editor's project beside
    with zipfile.ZipFile(good) as src, zipfile.ZipFile(shared, "w") as z:
        for n in src.namelist():
            z.writestr(n, src.read(n))
        z.writestr("LEEME.txt", "léeme")
        z.writestr("mi_bolsillo.pinyol.json", "{}")
    r = library.check(shared, t / "shared", headless)
    assert r["ok"] and r["id"] == "mi_bolsillo" and not (t / "shared" / "game" / "LEEME.txt").exists(), r
    assert (t / "good" / "cover.png").exists() and (t / "good" / "game" / "game.json").exists()

    evil = t / "evil.zip"
    with zipfile.ZipFile(evil, "w") as z:
        z.writestr("juego/game.json", "{}")
        z.writestr("../../escape.lua", "print('out')")
    r = library.check(evil, t / "evil", headless)
    assert not r["ok"] and "Ruta no permitida" in r["errors"][0], r
    assert not (t / "escape.lua").exists() and not (t.parent / "escape.lua").exists()

    junk = t / "junk.zip"
    junk.write_text("not a zip")
    r = library.check(junk, t / "junk", headless)
    assert not r["ok"] and "no es un .zip" in r["errors"][0], r

    body = ("### Título\n\nMi juego\n\n### Descripción\n\nUn juego.\n\n### El juego (.zip)\n\n"
            "[j.zip](https://github.com/user-attachments/files/123/j.zip)\n\n### Licencia\n\nCC0\n\n"
            "### Permisos\n\n- [X] Es mío\n- [X] Acepto\n- [X] Tengo 14 años\n")
    f = library.form_fields(body)
    assert f["Título"] == "Mi juego" and f["Licencia"] == "CC0", f
    assert library.ATTACHMENT.findall(f["El juego (.zip)"]) == ["https://github.com/user-attachments/files/123/j.zip"]
    assert not library.ATTACHMENT.findall("https://evil.example/files/1/x.zip")
    rel = "https://github.com/ana/mi-juego/releases/download/v1.0/juego.zip"  # past the 25 MB GitHub attaches
    assert library.ATTACHMENT.findall(f"[descarga]({rel})") == [rel]
    assert not library.ATTACHMENT.findall("https://github.com/ana/mi-juego/blob/main/juego.zip")
    assert library.said("Un juego.\n\n[j.zip](https://github.com/user-attachments/files/123/j.zip)") == "Un juego."
    r = library.check(good, t / "form", headless, f)
    assert r["ok"] and r["license"] == "CC0" and r["form_title"] == "Mi juego", r
    f["Permisos"] = "- [X] Es mío\n- [X] Acepto\n- [ ] Tengo 14 años"  # the age box left empty
    r = library.check(good, t / "form2", headless, f)
    assert not r["ok"] and any("tres casillas" in e for e in r["errors"]), r

    # the sender's words and the engine's output reach the issue as code: no mention, link or formatting comes out of them
    assert library.code("@ana `x`") == "`` @ana `x` ``" and library.code("`a") == "`` `a ``" and library.code(" a \n b ") == "`a b`"
    assert library.fenced("x\n```\ny") == "````\nx\n```\ny\n````"
    note = library.comment(t / "bad_art")
    assert "  ```" in note and "MISSING_ART" in note, note
    r = library.check(good, t / "form3", headless, {**f, "Permisos": "[X] [X] [X]", "Título": "Hola @ana [x](https://evil.example)"})
    note = library.comment(t / "form3")
    assert "`Hola @ana [x](https://evil.example)`" in note and f"sha256: `{r['sha256']}`" in note, note
    # a zip the robot cannot take apart (a bad CRC, a file where a folder goes): an answer, not a crash
    crc = t / "crc.zip"
    with zipfile.ZipFile(crc, "w") as z:
        z.writestr(zipfile.ZipInfo("game.json"), b'{"id": "x"}')  # stored as it is
    crc.write_bytes(crc.read_bytes().replace(b'"x"', b'"y"', 1))
    r = library.check(crc, t / "crc", headless)
    assert not r["ok"] and "No puedo sacar" in r["errors"][0] and "CRC" in r["errors"][0], r
    clash = t / "clash.zip"
    with zipfile.ZipFile(clash, "w") as z:
        z.writestr("game.json", "{}")
        z.writestr("lib.lua", "x")
        z.writestr("lib.lua/y.lua", "y")
    r = library.check(clash, t / "clash", headless)
    assert not r["ok"] and "No puedo sacar" in r["errors"][0], r

    # a new version of a game already in the Library: same author, title and licence; a game that is not there is refused
    library.LIBRARY = t / "lib"
    (t / "lib").mkdir()
    library.publish(t / "good", 7, "ana")
    # approved: only the zip the robot's last comment found fine (the one the maintainer looked at) is published
    bot = {"login": "github-actions[bot]", "type": "Bot"}
    sha = json.loads((t / "good" / "result.json").read_text())["sha256"]
    said_ok = {"user": bot, "body": library.comment(t / "good")}
    assert library.approved_sha([{"user": {"login": "ana", "type": "User"}, "body": f"sha256: `{'0' * 64}`"}]) is None
    assert library.approved_sha([said_ok, {"user": bot, "body": "Publicado"}]) == sha
    for comments in ([], [{"user": bot, "body": f"sha256: `{'0' * 64}`"}]):
        try:
            library.publish(t / "good", 7, "ana", comments)
            raise AssertionError("published a zip the robot had not found fine")
        except SystemExit as err:
            assert "not the one" in str(err), err
    assert library.publish(t / "good", 7, "ana", [said_ok]) == "mi_bolsillo"
    # what the check wrote is looked at again by the job that can write
    odd = t / "odd"
    shutil.copytree(t / "good", odd)
    r = json.loads((odd / "result.json").read_text())
    (odd / "result.json").write_text(json.dumps({**r, "id": "../../etc"}))
    try:
        library.publish(odd, 7, "ana")
        raise AssertionError("published an odd id")
    except SystemExit as err:
        assert "odd game id" in str(err), err
    (odd / "result.json").write_text(json.dumps({**r, "form_title": " Mi\njuego\x01 ", "form_description": "a\n\nb"}))
    assert library.publish(odd, 7, "ana") == "mi_bolsillo"
    assert (library.index()[0]["title"], library.index()[0]["description"]) == ("Mi juego", "a b"), library.index()[0]
    (t / "lib" / "library.json").write_text(json.dumps([{**library.index()[0], "title": "Mi juego", "license": "CC0"}]))
    note = library.comment(t / "good")
    assert "sustituirá" in note, note
    assert library.update(good, headless) == "mi_bolsillo"
    e = library.index()[0]
    assert (e["author"], e["issue"], e["title"], e["license"]) == ("ana", 7, "Mi juego", "CC0"), e
    other = t / "other"
    shutil.copytree(mine, other)
    (other / "game.json").write_text(json.dumps({**meta, "id": "otro_bolsillo"}), encoding="utf-8")
    try:
        library.update(pack_game.pack(other, t / "zips2", False), headless)
        raise AssertionError("a game that is not in the Library was updated")
    except SystemExit as err:
        assert "not in the Library" in str(err), err
    print(json.dumps({"library": "ok"}))
