const ALPHABET = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
const PREFIX = 'cashly-web:v1:';
const ITERATIONS = 310000;

export function normalizeCode(input) {
  const code = String(input ?? '').toUpperCase().replace(/[^0-9A-Z]/g, '');
  if (code.length !== 8 || [...code].some((character) => !ALPHABET.includes(character))) return null;
  return code;
}

const encoder = new TextEncoder();

function fromBase64(text) {
  const binary = atob(text);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) bytes[index] = binary.charCodeAt(index);
  return bytes;
}

function toHex(buffer) {
  return [...new Uint8Array(buffer)].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

export async function snapshotID(code) {
  return toHex(await crypto.subtle.digest('SHA-256', encoder.encode(PREFIX + code)));
}

export async function deriveKey(code, salt) {
  const material = await crypto.subtle.importKey('raw', encoder.encode(code), 'PBKDF2', false, ['deriveKey']);
  return crypto.subtle.deriveKey(
    { name: 'PBKDF2', hash: 'SHA-256', salt, iterations: ITERATIONS },
    material,
    { name: 'AES-GCM', length: 256 },
    true,
    ['decrypt']
  );
}

export async function openPackage(code, id, pack, key) {
  if (!pack || pack.v !== 1) throw new Error('unsupported');
  const cryptoKey = key ?? (await deriveKey(code, fromBase64(pack.salt)));
  const plain = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: fromBase64(pack.nonce), additionalData: encoder.encode(id), tagLength: 128 },
    cryptoKey,
    fromBase64(pack.ciphertext)
  );
  return { snapshot: JSON.parse(new TextDecoder().decode(plain)), key: cryptoKey };
}

export async function fetchPackage(id, etag, base = '/bridge') {
  const response = await fetch(`${base}/v1/snapshots/${id}`, {
    headers: etag ? { 'If-None-Match': etag } : {},
    cache: 'no-store'
  });
  if (response.status === 304) return { status: 'unchanged' };
  if (response.status === 404) return { status: 'missing' };
  if (response.status === 429) return { status: 'limited' };
  if (!response.ok) return { status: 'error' };
  return { status: 'ok', etag: response.headers.get('ETag'), pack: await response.json() };
}
