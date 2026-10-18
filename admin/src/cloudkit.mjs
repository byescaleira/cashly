import { createHash, createPrivateKey, sign } from 'node:crypto';

export const CONTAINER = 'iCloud.cashly';
export const ENVIRONMENTS = ['development', 'production'];
export const RECORD_TYPE = 'FeatureFlag';

export class CloudKitError extends Error {
  constructor(code, reason = '') {
    super(reason ? `${code}: ${reason}` : code);
    this.code = code;
    this.reason = reason;
  }
}

export const isoDate = (date) => date.toISOString().replace(/\.\d{3}Z$/, 'Z');

export function signRequest({ keyID, privateKey, subpath, body, date }) {
  const stamp = isoDate(date);
  const bodyHash = createHash('sha256').update(body).digest('base64');
  const message = `${stamp}:${bodyHash}:${subpath}`;
  const signature = sign('sha256', Buffer.from(message), privateKey).toString('base64');
  return {
    message,
    headers: {
      'X-Apple-CloudKit-Request-KeyID': keyID,
      'X-Apple-CloudKit-Request-ISO8601Date': stamp,
      'X-Apple-CloudKit-Request-SignatureV1': signature,
    },
  };
}

function flagFrom(record) {
  const fields = record.fields ?? {};
  const name = fields.name?.value ?? record.recordName;
  return {
    name,
    isOn: Number(fields.isOn?.value ?? 0) === 1,
    rollout: Number(fields.rollout?.value ?? 100),
    modifiedAt: record.modified?.timestamp ? new Date(record.modified.timestamp).toISOString() : null,
  };
}

export function createCloudKit({ keyID, keyIDs = {}, privateKeyPem, baseURL = 'https://api.apple-cloudkit.com', container = CONTAINER, fetch = globalThis.fetch, now = () => new Date() }) {
  const privateKey = privateKeyPem ? createPrivateKey(privateKeyPem) : null;
  const keyFor = (environment) => keyIDs[environment] || keyID;
  const configured = Boolean(privateKey && (keyID || Object.values(keyIDs).some(Boolean)));

  async function call(environment, operation, payload) {
    if (!configured) throw new CloudKitError('NOT_CONFIGURED');
    if (!ENVIRONMENTS.includes(environment)) throw new CloudKitError('BAD_ENVIRONMENT');
    if (!keyFor(environment)) throw new CloudKitError('NOT_CONFIGURED');
    const subpath = `/database/1/${container}/${environment}/public/${operation}`;
    const body = JSON.stringify(payload);
    const { headers } = signRequest({ keyID: keyFor(environment), privateKey, subpath, body, date: now() });
    let response;
    try {
      response = await fetch(`${baseURL}${subpath}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...headers },
        body,
        signal: AbortSignal.timeout(10_000),
      });
    } catch (error) {
      throw new CloudKitError('NETWORK', error.message);
    }
    const json = await response.json().catch(() => ({}));
    if (!response.ok) throw new CloudKitError(json.serverErrorCode ?? `HTTP_${response.status}`, json.reason ?? '');
    return json;
  }

  async function query(environment) {
    const result = await call(environment, 'records/query', { query: { recordType: RECORD_TYPE }, resultsLimit: 200 });
    return (result.records ?? []).filter((record) => !record.serverErrorCode).map(flagFrom);
  }

  async function lookup(environment, names) {
    const result = await call(environment, 'records/lookup', { records: names.map((recordName) => ({ recordName })) });
    return (result.records ?? []).filter((record) => !record.serverErrorCode && record.recordType === RECORD_TYPE).map(flagFrom);
  }

  async function listFlags(environment, names) {
    try {
      return await query(environment);
    } catch (error) {
      if (['NOT_CONFIGURED', 'BAD_ENVIRONMENT', 'AUTHENTICATION_FAILED', 'ACCESS_DENIED', 'NETWORK'].includes(error.code)) throw error;
      return lookup(environment, names);
    }
  }

  async function saveFlag(environment, { name, isOn, rollout }) {
    const record = {
      recordType: RECORD_TYPE,
      recordName: name,
      fields: {
        name: { value: name, type: 'STRING' },
        isOn: { value: isOn ? 1 : 0, type: 'INT64' },
        rollout: { value: rollout, type: 'INT64' },
      },
    };
    const result = await call(environment, 'records/modify', { operations: [{ operationType: 'forceReplace', record }], atomic: false });
    const saved = result.records?.[0];
    if (!saved || saved.serverErrorCode) throw new CloudKitError(saved?.serverErrorCode ?? 'UNKNOWN', saved?.reason ?? '');
    return flagFrom(saved);
  }

  async function deleteFlag(environment, name) {
    const result = await call(environment, 'records/modify', { operations: [{ operationType: 'forceDelete', record: { recordName: name } }], atomic: false });
    const deleted = result.records?.[0];
    if (deleted?.serverErrorCode && deleted.serverErrorCode !== 'NOT_FOUND') throw new CloudKitError(deleted.serverErrorCode, deleted.reason ?? '');
  }

  return { configured, listFlags, saveFlag, deleteFlag };
}
