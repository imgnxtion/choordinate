#!/usr/bin/env node
/*
  Chordinate minimal API server for React devs (no Swift required)
  - Stores chord bindings at: ~/Library/Application Support/Chordinate/bindings.json
  - Endpoints:
      GET  /api/bindings   -> JSON array of bindings
      PUT  /api/bindings   -> Replace with JSON array
      GET  /health         -> ok
*/
const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');
const url = require('url');

const PORT = process.env.PORT ? Number(process.env.PORT) : 6789;
const storageDir = path.join(os.homedir(), 'Library', 'Application Support', 'Chordinate');
const filePath = path.join(storageDir, 'bindings.json');

function ensureStorage() {
  fs.mkdirSync(storageDir, { recursive: true });
  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(filePath, '[]', 'utf8');
  }
}

function readBindings() {
  try {
    const txt = fs.readFileSync(filePath, 'utf8');
    const data = JSON.parse(txt);
    if (Array.isArray(data)) return data;
    return [];
  } catch (e) {
    return [];
  }
}

function writeBindings(arr) {
  fs.writeFileSync(filePath, JSON.stringify(arr, null, 2), 'utf8');
}

function send(res, code, body, headers = {}) {
  const h = Object.assign({ 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, headers);
  res.writeHead(code, h);
  if (body === null || body === undefined) return res.end();
  if (typeof body === 'string') return res.end(body);
  res.end(JSON.stringify(body));
}

function parseBody(req, limit = 1_000_000) {
  return new Promise((resolve, reject) => {
    let buf = Buffer.alloc(0);
    req.on('data', (chunk) => {
      buf = Buffer.concat([buf, chunk]);
      if (buf.length > limit) {
        reject(new Error('body too large'));
        req.destroy();
      }
    });
    req.on('end', () => {
      try {
        const txt = buf.toString('utf8').trim();
        resolve(txt ? JSON.parse(txt) : null);
      } catch (e) {
        reject(e);
      }
    });
  });
}

ensureStorage();

const server = http.createServer(async (req, res) => {
  const { pathname } = url.parse(req.url);

  // CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,PUT,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    });
    return res.end();
  }

  if (req.method === 'GET' && pathname === '/health') {
    return send(res, 200, { ok: true });
  }

  if (req.method === 'GET' && pathname === '/api/bindings') {
    return send(res, 200, readBindings());
  }

  if (req.method === 'PUT' && pathname === '/api/bindings') {
    try {
      const body = await parseBody(req);
      if (!Array.isArray(body)) return send(res, 400, { error: 'Expected array' });
      writeBindings(body);
      return send(res, 200, { ok: true });
    } catch (e) {
      return send(res, 400, { error: e.message });
    }
  }

  if (req.method === 'GET' && pathname === '/') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    return res.end('Chordinate API: GET/PUT /api/bindings');
  }

  send(res, 404, { error: 'not found' });
});

server.listen(PORT, () => {
  console.log(`Chordinate API listening on http://localhost:${PORT}`);
  console.log(`Bindings file: ${filePath}`);
});

