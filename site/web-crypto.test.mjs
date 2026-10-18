import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { normalizeCode, snapshotID, deriveKey, openPackage } from './web-crypto.js';

const vector = JSON.parse(readFileSync(new URL('../docs/web-test-vector.json', import.meta.url), 'utf8'));

test('normalizes typed codes', () => {
  assert.equal(normalizeCode('k7qf-2m9x'), 'K7QF2M9X');
  assert.equal(normalizeCode(' K7QF 2M9X '), 'K7QF2M9X');
  assert.equal(normalizeCode('K7QF-2M9'), null);
  assert.equal(normalizeCode('K7QF-2M90'), null);
  assert.equal(normalizeCode('K7QF-2M9I'), null);
});

test('matches the shared id', async () => {
  assert.equal(await snapshotID(vector.code), vector.id);
});

test('derives the shared key', async () => {
  const key = await deriveKey(vector.code, Buffer.from(vector.package.salt, 'base64'));
  const raw = Buffer.from(await crypto.subtle.exportKey('raw', key)).toString('hex');
  assert.equal(raw, vector.keyHex);
});

test('opens the shared package', async () => {
  const { snapshot } = await openPackage(vector.code, vector.id, vector.package);
  assert.deepEqual(snapshot, vector.snapshot);
});

test('rejects a wrong code', async () => {
  await assert.rejects(openPackage('K7QF2M9Y', vector.id, vector.package));
});

test('rejects a package moved to another id', async () => {
  await assert.rejects(openPackage(vector.code, 'f'.repeat(64), vector.package));
});
