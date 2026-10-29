// Runs inside LibreSprite, never inside Godot. BUILD is embedded by build_unit_sprites.py.
// Actual native pose frames + editable pixel equipment; no runtime body slicing.
var SIZE = 64;
var INK = [12, 20, 29, 255], DARK = [32, 45, 55, 255];
var STEEL = [83, 104, 115, 255], LIGHT = [153, 177, 178, 255];
var COPPER = [154, 94, 52, 255], GOLD = [235, 176, 76, 255];
var CYAN = [71, 218, 203, 255], RED = [202, 63, 63, 255];
var sourceCache = {};

function source(path) {
    if (!sourceCache[path]) {
        var doc = app.open(path);
        var image = doc.sprite.layer(0).cel(0).image;
        sourceCache[path] = {w: image.width, h: image.height, pixels: image.getImageData()};
    }
    return sourceCache[path];
}
function pixel(out, x, y, color) {
    x = Math.round(x); y = Math.round(y);
    if (x < 0 || y < 0 || x >= SIZE || y >= 56) return;
    var p = (y * SIZE + x) * 4;
    for (var c = 0; c < 4; c++) out[p + c] = color[c];
}
function rect(out, x, y, w, h, color) {
    for (var j = 0; j < h; j++) for (var i = 0; i < w; i++) pixel(out, x + i, y + j, color);
}
function line(out, ax, ay, bx, by, color, thickness) {
    var steps = Math.max(Math.abs(bx - ax), Math.abs(by - ay), 1);
    for (var t = 0; t <= steps; t++) rect(out, ax + (bx - ax) * t / steps,
        ay + (by - ay) * t / steps, thickness || 1, thickness || 1, color);
}
function panel(out, x, y, w, h, color) {
    rect(out, x + 1, y, w - 2, h, INK);
    rect(out, x, y + 1, w, h - 2, INK);
    rect(out, x + 1, y + 1, w - 2, h - 2, color);
    line(out, x + 2, y + 1, x + w - 3, y + 1, LIGHT);
    line(out, x + 1, y + h - 2, x + w - 2, y + h - 2, DARK);
}
function bounds(bytes) {
    var box = {l: SIZE, r: 0, t: SIZE, b: 0};
    for (var y = 0; y < SIZE; y++) for (var x = 0; x < SIZE; x++) {
        if (bytes[(y * SIZE + x) * 4 + 3] > 96) {
            box.l = Math.min(box.l, x); box.r = Math.max(box.r, x);
            box.t = Math.min(box.t, y); box.b = Math.max(box.b, y);
        }
    }
    return box;
}
function normalized(input) {
    var scale = 34 / 44, bottom = 0;
    for (var y = 0; y < input.h; y++) for (var x = 0; x < input.w; x++)
        if (input.pixels[(y * input.w + x) * 4 + 3] > 96) bottom = y + 1;
    var output = new Uint8Array(SIZE * SIZE * 4);
    for (var dy = 0; dy < SIZE; dy++) for (var dx = 0; dx < SIZE; dx++) {
        var sx = Math.floor((dx - 32) / scale + input.w / 2);
        var sy = Math.floor((dy - 56) / scale + bottom);
        if (sx < 0 || sy < 0 || sx >= input.w || sy >= input.h) continue;
        var a = (sy * input.w + sx) * 4, b = (dy * SIZE + dx) * 4;
        for (var c = 0; c < 4; c++) output[b + c] = input.pixels[a + c];
    }
    return output;
}
function head(bytes) {
    var box = bounds(bytes), sum = 0, count = 0;
    if (box.b - box.t < 18 && box.r - box.l > 24)
        return {x: box.l + 4, y: box.b - 6, fallen: true};
    for (var y = box.t; y < box.t + 6; y++) for (var x = box.l; x <= box.r; x++)
        if (bytes[(y * SIZE + x) * 4 + 3] > 96) {sum += x; count++;}
    return {x: Math.round(sum / Math.max(1, count)), y: box.t + 4, fallen: false};
}
function palette(role) {
    if (role === 'medic') return [[86, 106, 112], [167, 185, 183], [229, 233, 213]];
    if (role === 'technician' || role === 'builder') return [[74, 57, 35], [153, 113, 43], [224, 177, 68]];
    if (role === 'civilian') return [[48, 38, 33], [99, 76, 52], [153, 121, 78]];
    if (role === 'collector') return [[32, 51, 52], [67, 102, 96], [132, 160, 137]];
    if (role === 'guardian') return [[36, 46, 56], [96, 115, 125], [170, 185, 181]];
    if (role === 'artillero' || role === 'saboteador') return [[40, 26, 33], [83, 63, 66], [134, 107, 100]];
    return [[30, 42, 50], [67, 88, 97], [126, 147, 152]];
}
function outfit(body, role, h) {
    var pal = palette(role), hostile = role === 'artillero' || role === 'saboteador';
    for (var y = 0; y < SIZE; y++) for (var x = 0; x < SIZE; x++) {
        var p = (y * SIZE + x) * 4;
        if (!body[p + 3]) continue;
        var r = body[p], g = body[p + 1], b = body[p + 2];
        if (hostile && g > r * 1.3 && b > r * 1.2) {
            body[p] = 230; body[p + 1] = 57; body[p + 2] = 59;
        } else if (Math.max(r,g,b) - Math.min(r,g,b) < 48 && r > 25 && r < 215) {
            var c = pal[r < 65 ? 0 : (r < 135 ? 1 : 2)];
            body[p] = c[0]; body[p + 1] = c[1]; body[p + 2] = c[2];
        }
        // Remove the carried long gun from utility and unarmed outfits, in the source frames.
        if (!h.fallen && role !== 'ranger' && role !== 'artillero' && role !== 'saboteador' &&
            x > h.x + 5 && y >= h.y + 7 && y < h.y + 24) body[p + 3] = 0;
    }
}
function cloth(body, role, h, entry) {
    var out = new Uint8Array(SIZE * SIZE * 4), pal = palette(role);
    var shade = [pal[0][0], pal[0][1], pal[0][2], 255];
    var mid = [pal[1][0], pal[1][1], pal[1][2], 255];
    var high = [pal[2][0], pal[2][1], pal[2][2], 255];
    var sway = (entry.state === 'caminar' || entry.state === 'cargar') ? [0,1,2,1,0,-1,-2,-1][entry.index % 8] : 0;
    if (h.fallen) {
        panel(out, h.x + 1, 52, 16, 4, shade);
        line(out, h.x + 3, 53, h.x + 12, 53, mid);
    } else {
        // Layered hood and split coat: cloth follows the native shoulders and stride.
        rect(out, h.x - 4, h.y - 3, 6, 7, INK);
        line(out, h.x - 3, h.y - 3, h.x + 1, h.y - 3, high);
        line(out, h.x - 4, h.y - 1, h.x - 4, h.y + 3, mid);
        var hem = Math.min(25, 55 - h.y);
        for (var j = 6; j < hem; j++) {
            var left = h.x - 4 - Math.floor((j - 6) / 7) + (j > 16 ? sway : 0);
            line(out, left, h.y + j, h.x - 1, h.y + j, shade);
            pixel(out, left + 1, h.y + j, mid);
            if (j % 4 === 0) pixel(out, left + 2, h.y + j, high);
            if (j < hem - 3) line(out, h.x + 1, h.y + j, h.x + 4, h.y + j, shade);
        }
        panel(out, h.x - 5, h.y + 5, 5, 5, mid);
        pixel(out, h.x - 3, h.y + 6, high);
        pixel(out, h.x - 4, h.y + 8, COPPER);
        line(out, h.x - 3, h.y + 16, h.x + 3, h.y + 16, COPPER);
    }
    for (var p = 0; p < body.length; p += 4) if (body[p + 3])
        for (var c = 0; c < 4; c++) out[p + c] = body[p + c];
    return out;
}
function equipment(role, entry, body) {
    var out = new Uint8Array(SIZE * SIZE * 4), h = head(body), x = h.x, y = h.y;
    var hostile = role === 'artillero' || role === 'saboteador';
    var accent = hostile ? RED : CYAN;
    var working = entry.state === 'reparar' || entry.state === 'proteger';
    var swing = working ? [-2,-5,-7,-3,2,3,0,-2][entry.index % 8] : 0;
    if (h.fallen) {
        if (role === 'guardian') {panel(out, 25, 52, 17, 4, STEEL); line(out, 27, 53, 40, 53, GOLD);}
        if (role === 'medic') {panel(out, x + 9, 52, 6, 4, STEEL); pixel(out,x+12,53,RED);}
        return out;
    }
    // Backpacks with straps, seams, copper couplings, rivets and indicator lights.
    if (role !== 'civilian' && role !== 'ranger') {
        panel(out, x - 8, y + 7, 6, 13, role === 'medic' ? LIGHT : DARK);
        line(out, x - 6, y + 10, x - 6, y + 16, COPPER);
        pixel(out, x - 5, y + 9, accent); pixel(out, x - 3, y + 18, COPPER);
    }
    if (role === 'guardian' || role === 'builder' || role === 'artillero') {
        panel(out, x - 4, y - 4, 9, 7, role === 'builder' ? GOLD : STEEL);
        rect(out, x + 1, y, 4, 2, INK); line(out, x + 2, y, x + 4, y, accent);
        pixel(out, x - 3, y - 2, LIGHT);
        if (role === 'builder') line(out, x - 5, y + 1, x + 6, y + 1, GOLD);
    }
    if (role === 'ranger') {
        var kick = entry.state === 'disparar' ? [0,-1,-2,0,-1,-2,0,0][entry.index % 8] : 0;
        panel(out, x + kick, y + 9, 14, 4, DARK);
        line(out, x + 3 + kick, y + 9, x + 12 + kick, y + 9, STEEL);
        line(out, x + 12 + kick, y + 10, x + 20 + kick, y + 10, INK, 2);
        line(out, x + 13 + kick, y + 10, x + 19 + kick, y + 10, STEEL);
        panel(out, x + 5 + kick, y + 7, 5, 3, STEEL);
        pixel(out, x + 8 + kick, y + 8, CYAN);
        line(out, x + 4 + kick, y + 12, x + 5 + kick, y + 15, COPPER, 2);
        pixel(out, x + 11 + kick, y + 11, LIGHT);
    } else if (role === 'guardian') {
        panel(out, x - 4, y + 7, 8, 7, STEEL);
        line(out, x - 3, y + 10, x + 2, y + 10, COPPER);
        var push = entry.state === 'proteger' ? [0,1,3,4,4,2,1,0][entry.index % 8] : 0;
        panel(out, x + 5 + push, y + 9, 10, 24, STEEL);
        rect(out, x + 5 + push, y + 9, 2, 1, [0,0,0,0]);
        rect(out, x + 13 + push, y + 9, 2, 1, [0,0,0,0]);
        line(out, x + 7 + push, y + 12, x + 7 + push, y + 29, GOLD, 2);
        for (var j = 0; j < 3; j++) pixel(out, x + 12 + push, y + 14 + j * 6, LIGHT);
        for (var j = 0; j < 6; j++) pixel(out, x + 9 + push + j % 3, y + 14 + j * 2, j % 2 ? COPPER : DARK);
        line(out, x + 9 + push, y + 24, x + 12 + push, y + 26, COPPER);
    } else if (role === 'medic') {
        rect(out, x - 4, y + 9, 5, 5, [211, 223, 214, 255]);
        rect(out, x - 2, y + 9, 1, 5, RED); rect(out, x - 4, y + 11, 5, 1, RED);
        panel(out, x - 2, y + 22, 8, 7, STEEL);
        rect(out, x + 1, y + 23, 1, 4, RED); rect(out, x, y + 24, 3, 1, RED);
        panel(out, x + 6, y + 14 + swing / 2, 5, 5, DARK);
        line(out, x + 7, y + 16 + swing / 2, x + 9, y + 16 + swing / 2, CYAN);
        line(out, x + 1, y + 14, x + 6, y + 17 + swing / 2, LIGHT, 2);
    } else if (role === 'technician' || role === 'builder' || role === 'collector') {
        var hx = x + 6 + (working ? 1 : 0), hy = y + 17 + swing;
        line(out, x, y + 11, x + 3, y + 16 + Math.min(swing,0) / 2, DARK, 3);
        line(out, x + 3, y + 16 + Math.min(swing,0) / 2, hx, hy, LIGHT, 2);
        panel(out, hx - 1, hy, 3, 3, COPPER);
        if (role === 'technician') {
            line(out, hx + 1, hy + 1, hx + 3, hy - 6, STEEL, 2);
            line(out, hx + 2, hy - 6, hx + 5, hy - 6, LIGHT);
            pixel(out, hx + 2, hy - 8, LIGHT); pixel(out, hx + 5, hy - 8, LIGHT);
            pixel(out, x - 5, y + 12, CYAN);
        } else if (role === 'builder') {
            line(out, hx + 1, hy, hx + 2, hy - 6, COPPER, 2);
            panel(out, hx - 1, hy - 8, 8, 4, STEEL);
            panel(out, x - 3, y + 20, 6, 5, DARK);
            pixel(out, x - 1, y + 22, GOLD);
        } else {
            panel(out, hx, hy - 2, 6, 5, DARK);
            pixel(out, hx + 3, hy, CYAN);
            panel(out, x - 7, y + 18, 6, 8, COPPER);
        }
    } else if (role === 'civilian') {
        line(out, x - 3, y + 7, x + 3, y + 9, COPPER, 2);
        line(out, x + 1, y + 12, x + 3, y + 20, DARK, 2);
        panel(out, x - 7, y + 12, 5, 11, COPPER);
        pixel(out, x - 5, y + 15, LIGHT);
    } else if (role === 'artillero') {
        var recoil = entry.state === 'disparar' && entry.index % 3 === 1 ? -2 : 0;
        panel(out, x - 5 + recoil, y + 5, 22, 6, DARK);
        line(out, x - 2 + recoil, y + 6, x + 13 + recoil, y + 6, LIGHT);
        panel(out, x + 13 + recoil, y + 5, 5, 7, STEEL);
        rect(out, x + 15 + recoil, y + 7, 3, 3, INK);
        line(out, x + 3 + recoil, y + 6, x + 3 + recoil, y + 9, RED);
    } else if (role === 'saboteador') {
        for (var k = 0; k < 3; k++) {
            panel(out, x - 9 + k * 2, y + 9, 3, 9, COPPER);
            pixel(out, x - 8 + k * 2, y + 11, RED);
        }
        panel(out, x + 6, y + 16 + swing / 2, 5, 6, DARK);
        pixel(out, x + 8, y + 18 + swing / 2, RED);
        line(out, x + 9, y + 15 + swing / 2, x + 9, y + 11 + swing / 2, STEEL);
    }
    if (entry.state === 'cargar') {
        panel(out, x + 2, y + 19, 12, 8, STEEL);
        line(out, x + 5, y + 21, x + 12, y + 24, COPPER);
        pixel(out, x + 10, y + 20, CYAN);
        line(out, x, y + 17, x + 4, y + 23, DARK, 2);
    }
    return out;
}
function build() {
    var inputs = [];
    if (BUILD.canonical) {
        var reference = app.open(BUILD.output + '/sources/pose_reference.ase');
        for (var i = 0; i < BUILD.entries.length; i++)
            inputs.push(reference.sprite.layer(0).cel(i).image.getImageData());
    } else {
        for (var i = 0; i < BUILD.entries.length; i++) inputs.push(normalized(source(BUILD.entries[i].file)));
        var reference = app.open(BUILD.work + '/pose-reference-blank.ase');
        for (var i = 0; i < inputs.length; i++) reference.sprite.layer(0).cel(i).image.putImageData(inputs[i]);
        reference.sprite.saveAs(BUILD.output + '/sources/pose_reference.ase');
    }
    for (var r = 0; r < BUILD.roles.length; r++) {
        var role = BUILD.roles[r];
        var doc = app.open(BUILD.work + '/' + role + '-blank.ase');
        for (var f = 0; f < BUILD.entries.length; f++) {
            var body = new Uint8Array(inputs[f]);
            outfit(body, role, head(body));
            body = cloth(body, role, head(body), BUILD.entries[f]);
            var gear = equipment(role, BUILD.entries[f], body);
            doc.sprite.layer(0).cel(f).image.putImageData(body);
            doc.sprite.layer(1).cel(f).image.putImageData(gear);
        }
        doc.sprite.saveAs(BUILD.output + '/sources/' + role + '.ase');
        console.log('Completed outfit: ' + role);
    }
}
function onEvent(event) { if (event === 'init') build(); }
