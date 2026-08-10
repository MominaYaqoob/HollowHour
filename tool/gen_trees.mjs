import fs from 'fs';
import zlib from 'zlib';
import path from 'path';

const outDir = path.resolve('assets/game/environment');

function crc32(buf) {
  let c = ~0;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & -(c & 1));
  }
  return ~c >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const typeBuf = Buffer.from(type);
  const crcBuf = Buffer.alloc(4);
  crcBuf.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])));
  return Buffer.concat([len, typeBuf, data, crcBuf]);
}

function writePng(file, w, h, rgba) {
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) {
    raw[y * (w * 4 + 1)] = 0;
    rgba.copy(raw, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  const png = Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
  fs.writeFileSync(file, png);
}

function px(buf, w, x, y, r, g, b, a = 255) {
  if (x < 0 || y < 0 || x >= w || y >= buf.length / (w * 4)) return;
  const i = (y * w + x) * 4;
  buf[i] = r;
  buf[i + 1] = g;
  buf[i + 2] = b;
  buf[i + 3] = a;
}

function fillCircle(buf, w, h, cx, cy, rad, r, g, b, a = 255) {
  const r2 = rad * rad;
  for (let y = Math.floor(cy - rad); y <= Math.ceil(cy + rad); y++) {
    for (let x = Math.floor(cx - rad); x <= Math.ceil(cx + rad); x++) {
      const dx = x - cx + 0.5;
      const dy = y - cy + 0.5;
      if (dx * dx + dy * dy <= r2) px(buf, w, x, y, r, g, b, a);
    }
  }
}

function drawTrunk(buf, w, h, baseX, baseY, height, twist = 0) {
  for (let i = 0; i < height; i++) {
    const t = i / height;
    const x = Math.round(baseX + Math.sin(t * Math.PI * 1.2 + twist) * (2 + twist));
    const y = baseY - i;
    const shade = 70 + Math.floor((1 - t) * 40);
    px(buf, w, x, y, shade, 48, 36);
    px(buf, w, x - 1, y, shade - 15, 36, 28);
    if (i % 3 === 0) px(buf, w, x + 1, y, shade + 10, 55, 40);
  }
}

function makeGothicA() {
  const w = 64;
  const h = 96;
  const buf = Buffer.alloc(w * h * 4);
  drawTrunk(buf, w, h, 32, 94, 62, 0.4);
  // Bright enough blue-grey canopy for dark arenas
  fillCircle(buf, w, h, 32, 28, 17, 130, 145, 165);
  fillCircle(buf, w, h, 24, 34, 13, 100, 115, 135);
  fillCircle(buf, w, h, 40, 34, 13, 110, 125, 145);
  fillCircle(buf, w, h, 32, 20, 10, 160, 175, 190);
  for (const [x, y] of [[18, 40], [46, 38], [28, 16], [38, 14]]) {
    px(buf, w, x, y, 140, 105, 80);
    px(buf, w, x, y - 1, 110, 80, 60);
  }
  writePng(path.join(outDir, 'tree_gothic_a.png'), w, h, buf);
}

function makeGothicB() {
  const w = 72;
  const h = 104;
  const buf = Buffer.alloc(w * h * 4);
  drawTrunk(buf, w, h, 36, 102, 70, 0.9);
  fillCircle(buf, w, h, 36, 30, 19, 125, 140, 160);
  fillCircle(buf, w, h, 26, 38, 14, 95, 110, 130);
  fillCircle(buf, w, h, 48, 36, 15, 105, 120, 140);
  fillCircle(buf, w, h, 36, 20, 11, 155, 168, 185);
  fillCircle(buf, w, h, 42, 42, 10, 90, 105, 125);
  writePng(path.join(outDir, 'tree_gothic_b.png'), w, h, buf);
}

function makeTree01() {
  // Autumn foliage tree — visible mustard/olive canopy + trunk
  const w = 56;
  const h = 88;
  const buf = Buffer.alloc(w * h * 4);
  drawTrunk(buf, w, h, 28, 86, 48, 0.2);
  fillCircle(buf, w, h, 28, 30, 18, 170, 130, 55);
  fillCircle(buf, w, h, 20, 36, 13, 130, 100, 40);
  fillCircle(buf, w, h, 36, 36, 13, 145, 110, 45);
  fillCircle(buf, w, h, 28, 20, 11, 200, 160, 70);
  fillCircle(buf, w, h, 24, 40, 9, 100, 120, 50);
  writePng(path.join(outDir, 'tree_01.png'), w, h, buf);
}

function makeTreeDead() {
  // Bare dead tree — readable branches, no solid blob
  const w = 56;
  const h = 88;
  const buf = Buffer.alloc(w * h * 4);
  drawTrunk(buf, w, h, 28, 86, 58, 0.6);
  const branches = [
    [28, 40, 12, -10],
    [28, 48, -14, -8],
    [28, 32, 10, -14],
    [28, 36, -9, -12],
    [28, 55, 8, -6],
    [28, 55, -7, -5],
  ];
  for (const [sx, sy, dx, dy] of branches) {
    const steps = Math.max(Math.abs(dx), Math.abs(dy));
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      const x = Math.round(sx + dx * t);
      const y = Math.round(sy + dy * t);
      px(buf, w, x, y, 110, 85, 70);
      if (i % 2 === 0) px(buf, w, x, y + 1, 80, 60, 50);
    }
  }
  // tiny crown stubs
  fillCircle(buf, w, h, 28, 28, 3, 95, 75, 60);
  writePng(path.join(outDir, 'tree_dead.png'), w, h, buf);
}

makeGothicA();
makeGothicB();
makeTree01();
makeTreeDead();
console.log('Wrote tree sprites to', outDir);
