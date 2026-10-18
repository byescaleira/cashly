export const FLAGS = [
  { name: 'mcpServer', title: 'Servidor MCP', defaultValue: true },
  { name: 'mcpLocalNetwork', title: 'MCP na rede local', defaultValue: true },
  { name: 'spreadsheetImport', title: 'Importar planilha', defaultValue: true },
  { name: 'guides', title: 'Guias', defaultValue: true },
  { name: 'analytics', title: 'Motor de análise', defaultValue: true },
  { name: 'journey', title: 'Jornada', defaultValue: true },
  { name: 'pro', title: 'Paywall do Cashly Pro', defaultValue: true },
  { name: 'intelligence', title: 'Inteligência no aparelho', defaultValue: false },
  { name: 'summary', title: 'Resumo do Cashly', defaultValue: true },
  { name: 'web', title: 'Cashly na Web', defaultValue: true },
];

export const FLAG_NAMES = FLAGS.map((flag) => flag.name);

export function parseFlagForm(form) {
  const name = form.get('name') ?? '';
  if (!FLAG_NAMES.includes(name)) return { error: 'unknown_flag' };
  const rollout = Number(form.get('rollout') ?? 100);
  if (!Number.isInteger(rollout) || rollout < 0 || rollout > 100) return { error: 'invalid_rollout' };
  return { value: { name, isOn: form.get('isOn') === 'on', rollout } };
}
