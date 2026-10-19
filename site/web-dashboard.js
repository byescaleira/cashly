import { renderSections } from './web-sections.js';

const ROUTES = ['overview', 'transactions', 'budgets', 'journey'];
const STATUS = {
  toPay: ['toPay', 'var(--warning)'],
  toReceive: ['toReceive', 'var(--teal)'],
  canceled: ['canceled', 'var(--secondary)']
};

const view = { kind: 'all', category: '', query: '', sort: 'date', descending: true, snapshot: null, kit: null };

function slot(name) {
  return document.querySelector(`[data-slot="${name}"]`);
}

function clamp(value) {
  return Math.min(Math.max(Number(value) || 0, 0), 1);
}

export function currentRoute() {
  const route = location.hash.replace('#', '');
  const journeyVisible = !document.querySelector('[data-nav="journey"]')?.hidden;
  if (route === 'journey' && !journeyVisible) return 'overview';
  return ROUTES.includes(route) ? route : 'overview';
}

export function applyRoute(kit) {
  const route = currentRoute();
  document.querySelectorAll('[data-route-view]').forEach((section) => { section.hidden = section.dataset.routeView !== route; });
  document.querySelectorAll('[data-route]').forEach((link) => {
    if (link.dataset.route === route) link.setAttribute('aria-current', 'page');
    else link.removeAttribute('aria-current');
  });
  const titles = { overview: 'navOverview', transactions: 'navTransactions', budgets: 'navBudgets', journey: 'journeyTitle' };
  slot('route-title').textContent = kit.t(titles[route]);
}

export function renderDashboard(snapshot, kit) {
  view.snapshot = snapshot;
  view.kit = kit;
  const { t, money, locale, day } = kit;
  const month = snapshot.month;
  const paceColor = { onTrack: 'var(--positive)', ahead: 'var(--warning)', over: 'var(--negative)' }[month.pace] ?? 'var(--positive)';
  const monthName = day(month.start, { month: 'long', year: 'numeric' });

  const profile = snapshot.profile ?? {};
  const avatar = slot('avatar');
  avatar.textContent = profile.initials || (profile.name || 'C').charAt(0).toLocaleUpperCase(locale);
  avatar.style.setProperty('--badge', kit.palette(profile.color));
  slot('profile-name').textContent = profile.name || 'Cashly';
  slot('side-month').textContent = monthName;
  slot('head-month').textContent = monthName;
  slot('tx-count').textContent = new Intl.NumberFormat(locale).format(snapshot.transactions?.length ?? 0);
  document.querySelector('[data-nav="journey"]').hidden = !snapshot.journey;

  const pace = slot('pace');
  pace.textContent = t(month.pace in { onTrack: 1, ahead: 1, over: 1 } ? month.pace : 'onTrack');
  pace.style.setProperty('--chip', paceColor);

  slot('available').textContent = money.format(month.available);
  slot('available').style.color = month.available < 0 ? 'var(--negative)' : '';
  slot('per-day').textContent = month.perDay > 0 ? t('perDay', { amount: money.format(month.perDay) }) : '';
  slot('spent').textContent = money.format(month.spent);
  slot('income').textContent = money.format(month.income);
  slot('planned').textContent = money.format(month.planned);
  slot('used').textContent = t('used', { percent: new Intl.NumberFormat(locale, { style: 'percent' }).format(month.usedRatio) });
  const paceBar = slot('pace-bar');
  paceBar.style.setProperty('--bar', paceColor);
  paceBar.style.setProperty('--value', `${clamp(month.usedRatio) * 100}%`);
  paceBar.style.setProperty('--elapsed', `${clamp(month.elapsedRatio) * 100}%`);

  renderBudgets(snapshot, kit);
  renderUpcoming(snapshot, kit);
  renderSections(snapshot, kit);
  renderRecent(snapshot, kit);
  renderCategoryFilter(snapshot, kit);
  renderTable();
  applyRoute(kit);
}

function renderBudgets(snapshot, kit) {
  const { t, money, element } = kit;
  const percent = new Intl.NumberFormat(kit.locale, { style: 'percent' });
  const budgets = snapshot.budgets ?? [];
  slot('budgets').replaceChildren(...(budgets.length ? budgets.map((budget) => {
    const ratio = budget.planned > 0 ? budget.spent / budget.planned : 0;
    const row = element('div', 'dash-budget');
    const name = element('div', 'dash-budget-name');
    name.append(kit.badge(budget.name, budget.color), element('span', '', budget.name));
    const figures = element('span', 'dash-budget-figures', t('budgetOf', { spent: money.format(budget.spent), planned: money.format(budget.planned) }));
    const share = element('span', 'dash-budget-share', percent.format(ratio));
    if (ratio > 1) share.style.color = 'var(--negative)';
    row.append(name, kit.bar(ratio > 1 ? 'var(--negative)' : kit.palette(budget.color), ratio), figures, share);
    return row;
  }) : [element('p', 'web-empty', t('noBudgets'))]));
}

function renderUpcoming(snapshot, kit) {
  const { t, money, element, day } = kit;
  const items = snapshot.upcoming ?? [];
  slot('upcoming').replaceChildren(...(items.length ? items.map((item) => {
    const row = element('div', 'dash-line');
    const body = element('div');
    body.append(element('div', 'web-item-title', item.description), element('div', 'footnote', t('due', { date: day(item.dueDate, { day: 'numeric', month: 'short' }) })));
    row.append(kit.badge(item.description, 'denim'), body, element('span', 'web-item-amount', money.format(item.amount)));
    return row;
  }) : [element('p', 'web-empty', t('noUpcoming'))]));
}

function sorted(transactions) {
  return [...transactions].sort((a, b) => {
    const order = view.sort === 'amount'
      ? Math.abs(a.amount) - Math.abs(b.amount)
      : a.date.localeCompare(b.date);
    return view.descending ? -order : order;
  });
}

function signed(transaction, money) {
  const income = transaction.kind === 'income';
  return (income ? '+' : '−') + money.format(Math.abs(transaction.amount));
}

function statusChip(transaction, kit) {
  const status = STATUS[transaction.status];
  const chip = kit.element('span', 'chip', kit.t(status ? status[0] : 'statusPaid'));
  chip.style.setProperty('--chip', status ? status[1] : 'var(--positive)');
  return chip;
}

function renderRecent(snapshot, kit) {
  const { element, money, day } = kit;
  const recent = [...(snapshot.transactions ?? [])].sort((a, b) => b.date.localeCompare(a.date)).slice(0, 8);
  slot('recent').replaceChildren(...(recent.length ? recent.map((transaction) => {
    const row = element('div', 'dash-line');
    const body = element('div');
    body.append(element('div', 'web-item-title', transaction.description), element('div', 'footnote', [day(transaction.date, { day: 'numeric', month: 'short' }), transaction.category?.name].filter(Boolean).join(' · ')));
    const amount = element('span', `web-item-amount${transaction.kind === 'income' ? ' positive' : ''}`, signed(transaction, money));
    if (transaction.status === 'canceled') row.classList.add('canceled');
    row.append(kit.badge(transaction.category?.name || transaction.description, transaction.category?.color), body, amount);
    return row;
  }) : [element('p', 'web-empty', kit.t('noHistory'))]));
}

function renderCategoryFilter(snapshot, kit) {
  const select = slot('category-filter');
  const names = [...new Set((snapshot.transactions ?? []).map((transaction) => transaction.category?.name).filter(Boolean))].sort((a, b) => a.localeCompare(b, kit.locale));
  const options = [kit.element('option', '', kit.t('allCategories'))];
  options[0].value = '';
  for (const name of names) {
    const option = kit.element('option', '', name);
    option.value = name;
    options.push(option);
  }
  select.replaceChildren(...options);
  select.value = names.includes(view.category) ? view.category : '';
  view.category = select.value;
}

function matches(transaction) {
  if (view.kind !== 'all' && transaction.kind !== view.kind) return false;
  if (view.category && transaction.category?.name !== view.category) return false;
  if (!view.query) return true;
  const haystack = [transaction.description, transaction.category?.name, ...(transaction.tags ?? [])].join(' ').toLocaleLowerCase(view.kit.locale);
  return haystack.includes(view.query.toLocaleLowerCase(view.kit.locale));
}

export function renderTable() {
  const { snapshot, kit } = view;
  if (!snapshot || !kit) return;
  const { element, money, day, t, locale } = kit;
  const rows = sorted((snapshot.transactions ?? []).filter(matches));
  slot('tx-body').replaceChildren(...rows.map((transaction) => {
    const row = element('tr');
    if (transaction.status === 'canceled') row.classList.add('canceled');
    const date = element('td', 'dash-date', day(transaction.date, { day: '2-digit', month: 'short' }));
    date.dataset.label = t('colDate');
    const description = element('td', 'dash-description');
    const title = element('div', 'web-item-title', transaction.description);
    description.append(title);
    if (transaction.tags?.length) {
      const tags = element('div', 'dash-tags');
      for (const tag of transaction.tags) {
        const chip = element('span', 'chip', tag);
        chip.style.setProperty('--chip', 'var(--denim)');
        tags.append(chip);
      }
      description.append(tags);
    }
    const category = element('td', 'dash-category');
    category.dataset.label = t('colCategory');
    if (transaction.category?.name) {
      const dot = element('i', 'dash-dot');
      dot.style.background = kit.palette(transaction.category.color);
      category.append(dot, document.createTextNode(transaction.category.name));
    }
    const status = element('td', 'dash-status');
    status.dataset.label = t('colStatus');
    status.append(statusChip(transaction, kit));
    const amount = element('td', `num web-item-amount${transaction.kind === 'income' ? ' positive' : ''}`, signed(transaction, money));
    row.append(date, description, category, status, amount);
    return row;
  }));
  slot('tx-empty').hidden = rows.length > 0;
  const total = rows.reduce((sum, transaction) => sum + (transaction.status === 'canceled' ? 0 : (transaction.kind === 'income' ? 1 : -1) * Math.abs(transaction.amount)), 0);
  slot('tx-summary').textContent = t('txSummary', { count: new Intl.NumberFormat(locale).format(rows.length), total: (total >= 0 ? '+' : '−') + money.format(Math.abs(total)) });
  document.querySelectorAll('[data-sort]').forEach((button) => {
    const active = button.dataset.sort === view.sort;
    button.setAttribute('aria-sort', active ? (view.descending ? 'descending' : 'ascending') : 'none');
    button.closest('th').setAttribute('aria-sort', active ? (view.descending ? 'descending' : 'ascending') : 'none');
  });
}

const PACK_ROW = 2;
const packer = typeof ResizeObserver === 'function' ? new ResizeObserver(() => requestAnimationFrame(pack)) : null;

function gridItems(grid) {
  return [...grid.children].flatMap((child) => {
    if (getComputedStyle(child).display === 'contents') return [...child.children];
    for (const panel of child.classList.contains('dash-stack') ? child.children : []) panel.style.gridRowEnd = '';
    return [child];
  });
}

function pack() {
  document.querySelectorAll('.dash-grid').forEach((grid) => {
    const gap = parseFloat(getComputedStyle(grid).columnGap) || 0;
    for (const item of gridItems(grid)) {
      const height = item.getBoundingClientRect().height;
      if (height > 0) item.style.gridRowEnd = `span ${Math.ceil((height + gap) / PACK_ROW)}`;
    }
  });
}

function bindPacking() {
  if (!packer) return;
  document.querySelectorAll('.dash-grid').forEach((grid) => {
    grid.classList.add('packed');
    grid.querySelectorAll('.dash-panel, .dash-stack').forEach((item) => packer.observe(item));
  });
}

export function bindDashboard(kit) {
  bindPacking();
  window.addEventListener('hashchange', () => applyRoute(kit));
  slot('search').addEventListener('input', (event) => {
    view.query = event.target.value.trim();
    renderTable();
  });
  slot('category-filter').addEventListener('change', (event) => {
    view.category = event.target.value;
    renderTable();
  });
  slot('kind').addEventListener('click', (event) => {
    const button = event.target.closest('[data-kind]');
    if (!button) return;
    view.kind = button.dataset.kind;
    slot('kind').querySelectorAll('[data-kind]').forEach((item) => item.setAttribute('aria-pressed', String(item === button)));
    renderTable();
  });
  document.querySelectorAll('[data-sort]').forEach((button) => button.addEventListener('click', () => {
    if (view.sort === button.dataset.sort) view.descending = !view.descending;
    else {
      view.sort = button.dataset.sort;
      view.descending = true;
    }
    renderTable();
  }));
}
