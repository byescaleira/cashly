const SVG = 'http://www.w3.org/2000/svg';

function svg(tag, attributes = {}) {
  const node = document.createElementNS(SVG, tag);
  for (const [name, value] of Object.entries(attributes)) node.setAttribute(name, value);
  return node;
}

function block(name, visible) {
  const node = document.querySelector(`[data-block="${name}"]`);
  if (node) node.hidden = !visible;
  return visible;
}

function slot(name) {
  return document.querySelector(`[data-slot="${name}"]`);
}

function clamp(value) {
  return Math.min(Math.max(Number(value) || 0, 0), 1);
}

function parseDay(value) {
  const [year, month, date] = value.split('-').map(Number);
  return new Date(year, month - 1, date);
}

export function renderSections(snapshot, kit) {
  renderHighlights(snapshot, kit);
  renderDaily(snapshot, kit);
  renderCategories(snapshot, kit);
  renderTags(snapshot, kit);
  renderMonths(snapshot, kit);
  renderJourney(snapshot, kit);
}

function card(kit, title, value, detail, color) {
  const node = kit.element('div', 'stat web-card');
  node.append(kit.element('span', 'footnote', title));
  const strong = kit.element('strong', '', value);
  if (color) strong.style.color = color;
  node.append(strong);
  if (detail) node.append(kit.element('span', 'footnote', detail));
  return node;
}

function renderHighlights(snapshot, kit) {
  const cards = [];
  const forecast = snapshot.forecast;
  if (forecast) {
    const outcome = forecast.outcome in { under: 1, onPlan: 1, over: 1 } ? forecast.outcome : 'onPlan';
    const color = { under: 'var(--positive)', onPlan: 'var(--positive)', over: 'var(--negative)' }[outcome];
    const amount = kit.money.format(Math.abs(forecast.available ?? 0));
    const value = { under: kit.t('forecastUnder', { amount }), onPlan: kit.t('forecastOnPlan'), over: kit.t('forecastOver', { amount }) }[outcome];
    cards.push(card(kit, kit.t('forecastTitle'), value, kit.t('forecastSpent', { amount: kit.money.format(forecast.spent ?? 0) }), color));
  }
  const savings = snapshot.savings;
  if (savings) {
    const percent = new Intl.NumberFormat(kit.locale, { style: 'percent' });
    const detail = savings.averageRate === undefined
      ? kit.t('savingsRateOnly', { percent: percent.format(savings.rate ?? 0) })
      : kit.t('savingsRate', { percent: percent.format(savings.rate ?? 0), average: percent.format(savings.averageRate) });
    cards.push(card(kit, kit.t('savingsTitle'), kit.money.format(savings.saved ?? 0), detail, (savings.saved ?? 0) < 0 ? 'var(--negative)' : 'var(--positive)'));
  }
  const score = snapshot.score;
  if (score) {
    const value = Math.round(score.value ?? 0);
    const color = value >= 70 ? 'var(--positive)' : value >= 40 ? 'var(--warning)' : 'var(--negative)';
    const node = card(kit, kit.t('scoreTitle'), `${new Intl.NumberFormat(kit.locale).format(value)}${score.label ? ` · ${score.label}` : ''}`, score.detail, color);
    node.append(kit.bar(color, value / 100));
    cards.push(node);
  }
  slot('highlights').replaceChildren(...cards);
  slot('highlights').hidden = !cards.length;
}

function renderDaily(snapshot, kit) {
  const daily = snapshot.daily ?? [];
  if (!block('daily', daily.length > 0)) return;
  const start = parseDay(snapshot.month.start);
  const end = parseDay(snapshot.month.end);
  const days = Math.round((end - start) / 86400000) + 1;
  const plan = (snapshot.month.planned ?? 0) / days;
  const spentByDay = new Map(daily.map((item) => [item.date, item.spent]));
  const values = [...Array(days)].map((_, index) => {
    const date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + index);
    const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
    return { key, date, spent: spentByDay.get(key) };
  });
  const max = Math.max(plan * 1.6, ...values.map((value) => value.spent ?? 0), 1);
  const width = 640;
  const height = 140;
  const gap = 2;
  const barWidth = width / days - gap;
  const chart = svg('svg', { viewBox: `0 0 ${width} ${height}`, role: 'img', 'aria-label': kit.t('dailyTitle'), class: 'web-svg' });
  values.forEach((value, index) => {
    if (value.spent === undefined) {
      chart.append(svg('rect', { x: index * (barWidth + gap), y: height - 2, width: barWidth, height: 2, rx: 1, class: 'web-future' }));
      return;
    }
    const barHeight = Math.max((value.spent / max) * height, value.spent > 0 ? 3 : 1);
    const rect = svg('rect', { x: index * (barWidth + gap), y: height - barHeight, width: barWidth, height: barHeight, rx: Math.min(barWidth / 2, 4) });
    rect.style.fill = value.spent > plan ? 'var(--negative)' : 'var(--tint)';
    const title = svg('title');
    title.textContent = `${kit.day(value.key, { day: 'numeric', month: 'short' })}: ${kit.money.format(value.spent)}`;
    rect.append(title);
    chart.append(rect);
  });
  const planY = height - (plan / max) * height;
  chart.append(svg('line', { x1: 0, x2: width, y1: planY, y2: planY, class: 'web-plan-line' }));
  const axis = kit.element('div', 'web-axis-row');
  [0, Math.floor(days / 2), days - 1].forEach((index) => axis.append(kit.element('span', '', kit.day(values[index].key, { day: 'numeric', month: 'short' }))));
  const legend = kit.element('div', 'web-legend');
  legend.append(legendItem(kit, 'var(--tint)', kit.t('spent')), legendItem(kit, 'var(--label)', kit.t('dailyPlan', { amount: kit.money.format(plan) }), true));
  slot('daily').replaceChildren(chart, axis, legend);
}

function legendItem(kit, color, text, line) {
  const item = kit.element('span', 'footnote');
  const mark = kit.element('i', line ? 'web-legend-line' : 'web-legend-dot');
  mark.style.background = color;
  item.append(mark, document.createTextNode(text));
  return item;
}

function renderCategories(snapshot, kit) {
  const categories = snapshot.categories ?? [];
  if (!block('categories', categories.length > 0)) return;
  const percent = new Intl.NumberFormat(kit.locale, { style: 'percent' });
  slot('categories').replaceChildren(...categories.map((category) => {
    const row = kit.element('div', 'row budget');
    const body = kit.element('div');
    const top = kit.element('div', 'budget-top');
    top.append(kit.element('span', '', category.name), kit.element('span', '', `${kit.money.format(category.spent)} · ${percent.format(category.share ?? 0)}`));
    body.append(top, kit.bar(kit.palette(category.color), clamp(category.share)));
    row.append(kit.badge(category.name, category.color), body);
    return row;
  }));
}

function renderTags(snapshot, kit) {
  const tags = snapshot.tags ?? [];
  if (!block('tags', tags.length > 0)) return;
  const top = Math.max(...tags.map((tag) => tag.spent ?? 0), 1);
  slot('tags').replaceChildren(...tags.map((tag) => {
    const row = kit.element('div', 'row');
    const head = kit.element('div', 'budget-top');
    const name = kit.element('span', 'chip', tag.name);
    name.style.setProperty('--chip', 'var(--denim)');
    head.append(name, kit.element('span', '', `${kit.money.format(tag.spent)} · ${new Intl.NumberFormat(kit.locale).format(tag.count ?? 0)}×`));
    row.append(head, kit.bar('var(--denim)', (tag.spent ?? 0) / top));
    return row;
  }));
}

function renderMonths(snapshot, kit) {
  const months = snapshot.history ?? [];
  if (!block('months', months.length > 1)) return;
  const max = Math.max(...months.flatMap((month) => [month.planned ?? 0, month.spent ?? 0, month.income ?? 0]), 1);
  const width = 320;
  const height = 110;
  const slotWidth = width / months.length;
  const barWidth = Math.min(slotWidth / 4.5, 14);
  const chart = svg('svg', { viewBox: `0 0 ${width} ${height}`, role: 'img', 'aria-label': kit.t('monthsTitle'), class: 'web-svg' });
  const axis = kit.element('div', 'web-axis-row months');
  axis.style.gridTemplateColumns = `repeat(${months.length}, minmax(0, 1fr))`;
  const formatter = new Intl.DateTimeFormat(kit.locale, { month: 'short' });
  months.forEach((month, index) => {
    const center = index * slotWidth + slotWidth / 2;
    const bars = [
      { value: month.planned, color: 'color-mix(in srgb, var(--tint) 30%, transparent)', label: kit.t('planned') },
      { value: month.spent, color: (month.spent ?? 0) > (month.planned ?? 0) && month.planned ? 'var(--negative)' : 'var(--tint)', label: kit.t('spent') },
      { value: month.income, color: 'var(--positive)', label: kit.t('income') }
    ];
    bars.forEach((bar, position) => {
      const barHeight = Math.max(((bar.value ?? 0) / max) * height, 1);
      const rect = svg('rect', { x: center + (position - 1.5) * barWidth + (position - 1) * 1.5, y: height - barHeight, width: barWidth, height: barHeight, rx: Math.min(barWidth / 2, 3) });
      rect.style.fill = bar.color;
      const title = svg('title');
      title.textContent = `${bar.label}: ${kit.money.format(bar.value ?? 0)}`;
      rect.append(title);
      chart.append(rect);
    });
    const [year, number] = month.month.split('-').map(Number);
    axis.append(kit.element('span', index === months.length - 1 ? 'current' : '', formatter.format(new Date(year, number - 1, 1))));
  });
  const legend = kit.element('div', 'web-legend');
  legend.append(
    legendItem(kit, 'color-mix(in srgb, var(--tint) 30%, transparent)', kit.t('planned')),
    legendItem(kit, 'var(--tint)', kit.t('spent')),
    legendItem(kit, 'var(--positive)', kit.t('income'))
  );
  slot('months').replaceChildren(chart, axis, legend);
}

function renderJourney(snapshot, kit) {
  const journey = snapshot.journey;
  if (!block('journey', Boolean(journey))) return;
  const rows = [];
  const level = kit.element('div', 'row');
  const head = kit.element('div', 'budget-top');
  head.append(kit.element('span', '', [kit.t('level', { level: journey.level ?? 1 }), journey.levelTitle].filter(Boolean).join(' · ')), kit.element('span', '', new Intl.NumberFormat(kit.locale, { style: 'percent' }).format(clamp(journey.progress))));
  level.append(head, kit.bar('var(--mustard)', clamp(journey.progress)));
  rows.push(level);
  if (journey.streak !== undefined) {
    const streak = kit.element('div', 'row web-pair-row');
    streak.append(kit.element('span', '', kit.t('streak')), kit.element('strong', '', new Intl.NumberFormat(kit.locale, { style: 'unit', unit: 'day', unitDisplay: 'long' }).format(journey.streak)));
    rows.push(streak);
  }
  if (journey.challenge) {
    const challenge = kit.element('div', 'row');
    const top = kit.element('div', 'budget-top');
    top.append(kit.element('span', '', journey.challenge.title), kit.element('span', '', journey.challenge.endsOn ? kit.t('challengeEnds', { date: kit.day(journey.challenge.endsOn, { day: 'numeric', month: 'short' }) }) : ''));
    challenge.append(top, kit.bar('var(--teal)', clamp(journey.challenge.progress)));
    rows.push(challenge);
  }
  slot('journey').replaceChildren(...rows);
}
