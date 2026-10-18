import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';
import { handle, store, rateBuckets } from './server.mjs';

const ID = 'ABEiM0RVZneImaq7zN3u_w';
const OWNER = 'o'.repeat(43);
const PACKAGE = JSON.parse(readFileSync(new URL('../docs/web-test-vector-v2.json', import.meta.url), 'utf8')).package;

let clock = 1_000_000;

async function request(method, path, { body, headers = {} } = {}) {
  const server = createServer((req, res) => handle(req, res, clock));
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();
  const response = await fetch(`http://127.0.0.1:${port}${path}`, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  const text = await response.text();
  server.closeAllConnections();
  server.close();
  return { status: response.status, headers: response.headers, json: text ? JSON.parse(text) : null };
}

const auth = (token = OWNER) => ({ Authorization: `Bearer ${token}` });

beforeEach(() => {
  store.clear();
  rateBuckets.clear();
  clock = 1_000_000;
});

test('health', async () => {
  const response = await request('GET', '/bridge/health');
  assert.equal(response.status, 200);
  assert.deepEqual(response.json, { ok: true });
});

test('create, read with etag and not modified', async () => {
  const created = await request('PUT', `/bridge/v1/snapshots/${ID}`, { body: PACKAGE, headers: auth() });
  assert.equal(created.status, 201);
  const read = await request('GET', `/bridge/v1/snapshots/${ID}`);
  assert.equal(read.status, 200);
  assert.equal(read.json.ciphertext, PACKAGE.ciphertext);
  const etag = read.headers.get('etag');
  const again = await request('GET', `/bridge/v1/snapshots/${ID}`, { headers: { 'If-None-Match': etag } });
  assert.equal(again.status, 304);
});

test('update needs the same owner and keeps expiry', async () => {
  await request('PUT', `/bridge/v1/snapshots/${ID}`, { body: PACKAGE, headers: auth() });
  const expiresAt = store.get(ID).expiresAt;
  clock += 60_000;
  const stranger = await request('PUT', `/bridge/v1/snapshots/${ID}`, { body: PACKAGE, headers: auth('x'.repeat(43)) });
  assert.equal(stranger.status, 403);
  const updated = await request('PUT', `/bridge/v1/snapshots/${ID}`, { body: { ...PACKAGE, nonce: 'AAAAAAAAAAAAAAAA' }, headers: auth() });
  assert.equal(updated.status, 200);
  assert.equal(store.get(ID).expiresAt, expiresAt);
});

test('write without owner is rejected', async () => {
  const response = await request('PUT', `/bridge/v1/snapshots/${ID}`, { body: PACKAGE });
  assert.equal(response.status, 401);
});

test('invalid package and id', async () => {
  assert.equal((await request('PUT', `/bridge/v1/snapshots/${ID}`, { body: { v: 2 }, headers: auth() })).status, 400);
  assert.equal((await request('PUT', `/bridge/v1/snapshots/${ID}`, { body: { ...PACKAGE, v: 1 }, headers: auth() })).status, 400);
  assert.equal((await request('PUT', `/bridge/v1/snapshots/${ID}`, { body: { ...PACKAGE, appKey: 'AAAA' }, headers: auth() })).status, 400);
  assert.equal((await request('GET', '/bridge/v1/snapshots/not-an-id')).status, 404);
});

test('expires after 24 hours', async () => {
  await request('PUT', `/bridge/v1/snapshots/${ID}`, { body: PACKAGE, headers: auth() });
  clock += 24 * 60 * 60 * 1000 + 1;
  assert.equal((await request('GET', `/bridge/v1/snapshots/${ID}`)).status, 404);
});

test('delete by owner', async () => {
  await request('PUT', `/bridge/v1/snapshots/${ID}`, { body: PACKAGE, headers: auth() });
  assert.equal((await request('DELETE', `/bridge/v1/snapshots/${ID}`, { headers: auth('x'.repeat(43)) })).status, 403);
  assert.equal((await request('DELETE', `/bridge/v1/snapshots/${ID}`, { headers: auth() })).status, 204);
  assert.equal((await request('GET', `/bridge/v1/snapshots/${ID}`)).status, 404);
});

test('waiting for the scan stays under the read limit and floods are limited', async () => {
  const waiting = 'b'.repeat(22);
  for (let index = 0; index < 30; index += 1) assert.equal((await request('GET', `/bridge/v1/snapshots/${waiting}`)).status, 404);
  let last;
  for (let index = 0; index < 91; index += 1) last = await request('GET', `/bridge/v1/snapshots/${waiting}`);
  assert.equal(last.status, 429);
});

test('cors only for the site origin', async () => {
  await request('PUT', `/bridge/v1/snapshots/${ID}`, { body: PACKAGE, headers: auth() });
  const site = await request('GET', `/bridge/v1/snapshots/${ID}`, { headers: { Origin: 'https://cashly.byescaleira.com' } });
  assert.equal(site.headers.get('access-control-allow-origin'), 'https://cashly.byescaleira.com');
  const other = await request('GET', `/bridge/v1/snapshots/${ID}`, { headers: { Origin: 'https://evil.example' } });
  assert.equal(other.headers.get('access-control-allow-origin'), null);
});

test('body over the limit is rejected', async () => {
  const big = { ...PACKAGE, ciphertext: 'A'.repeat(1024 * 1024 + 10) };
  const response = await request('PUT', `/bridge/v1/snapshots/${ID}`, { body: big, headers: auth() });
  assert.ok(response.status === 413 || response.status === 400);
});
