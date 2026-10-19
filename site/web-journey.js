const SVG = 'http://www.w3.org/2000/svg';
const MAX_LEVEL = 50;
const TITLE_LEVELS = 5;
const MARKS = [7, 30, 100, 365];
const BLUE_SCORE = 895;
const TIERS = { bronze: 'var(--brown)', silver: 'var(--secondary)', gold: 'var(--mustard)' };
const XP_RULES = [
  ['xpTransaction', '+10'],
  ['xpDay', '+5'],
  ['xpBudget', '+30'],
  ['xpMission', '+25'],
  ['xpChallenge', '75–300'],
  ['xpAchievement', '50–500'],
  ['xpMonth', '+200']
];
const DAY_ICONS = {
  tracked: 'M12 3c1 3.2 5 5.6 5 10a5 5 0 0 1-10 0c0-2 1-3.4 2.2-4.4.2 1.6.9 2.6 1.8 3 0-3.3.3-6 1-8.6z',
  frozen: 'M12 3v18M4.2 7.5l15.6 9M4.2 16.5l15.6-9M9.5 4.5 12 7l2.5-2.5M9.5 19.5 12 17l2.5 2.5',
  missed: 'M12 5.5a6.5 6.5 0 1 1 0 13 6.5 6.5 0 0 1 0-13z',
  pending: 'M12 5.5a6.5 6.5 0 1 1 0 13 6.5 6.5 0 0 1 0-13z'
};

function slot(name) {
  return document.querySelector(`[data-slot="${name}"]`);
}

function block(name, visible) {
  const node = document.querySelector(`[data-block="${name}"]`);
  if (node) node.hidden = !visible;
  return visible;
}

function clamp(value) {
  return Math.min(Math.max(Number(value) || 0, 0), 1);
}

function parseDay(value) {
  const [year, month, date] = value.split('-').map(Number);
  return new Date(year, month - 1, date);
}

function daysBetween(from, to) {
  return Math.round((parseDay(to) - parseDay(from)) / 86400000);
}

function number(kit, value) {
  return new Intl.NumberFormat(kit.locale).format(value);
}

function dayCount(kit, count) {
  return new Intl.NumberFormat(kit.locale, { style: 'unit', unit: 'day', unitDisplay: 'long' }).format(count);
}

function xpChip(kit, xp, done) {
  const chip = kit.element('span', 'chip', kit.t('xpChip', { xp }));
  chip.style.setProperty('--chip', done ? 'var(--positive)' : 'var(--secondary)');
  return chip;
}

function pair(kit, left, right, className = 'dash-pair') {
  const row = kit.element('div', className);
  row.append(kit.element('span', '', left), kit.element('span', '', right));
  return row;
}

function icon(path, state) {
  const node = document.createElementNS(SVG, 'svg');
  node.setAttribute('viewBox', '0 0 24 24');
  node.setAttribute('aria-hidden', 'true');
  node.classList.add('dash-day-icon', state);
  const shape = document.createElementNS(SVG, 'path');
  shape.setAttribute('d', path);
  node.append(shape);
  return node;
}

export function renderJourney(snapshot, kit) {
  const journey = snapshot.journey;
  if (!block('journey', Boolean(journey))) return;
  renderLevel(journey, kit);
  renderStreak(journey, snapshot.month?.today, kit);
  renderChallenge(journey.challenge, snapshot.month?.today, kit);
  renderMissions(journey.missions, snapshot.month?.today, kit);
  renderAchievements(journey.achievements, kit);
  renderBlue(snapshot.score, kit);
  renderRules(kit);
}

function renderLevel(journey, kit) {
  const { element, t } = kit;
  const level = Math.min(Math.max(Math.round(journey.level ?? 1), 1), MAX_LEVEL);
  const last = level >= MAX_LEVEL;
  const progress = last ? 1 : clamp(journey.progress);
  const head = element('div', 'dash-level-head');
  const title = element('div', 'dash-level-title');
  if (journey.levelTitle) {
    const chip = element('span', 'chip capsule', journey.levelTitle);
    chip.style.setProperty('--chip', 'var(--mustard)');
    title.append(chip);
  }
  title.append(element('strong', '', t('level', { level: number(kit, level) })));
  head.append(title);
  const hasXP = Number.isFinite(journey.xp);
  if (hasXP) head.append(element('span', 'footnote', t('xpTotal', { xp: number(kit, journey.xp) })));

  const track = element('div', 'dash-level-track');
  track.append(element('span', 'chip', t('level', { level: number(kit, level) })), kit.bar('var(--mustard)', progress));
  if (!last) track.append(element('span', 'chip', t('level', { level: number(kit, level + 1) })));

  const nodes = [head, track];
  if (!last) {
    if (hasXP) {
      const start = 50 * (level - 1) * level;
      const goal = 50 * level * (level + 1) - start;
      const done = Math.min(Math.max(journey.xp - start, 0), goal);
      const caption = pair(kit, t('levelXP', { xp: number(kit, done), goal: number(kit, goal) }), t('xpLeft', { xp: number(kit, goal - done) }));
      caption.firstChild.classList.add('accent');
      nodes.push(caption);
    } else {
      nodes.push(element('p', 'footnote dash-caption', t('levelTo', { percent: new Intl.NumberFormat(kit.locale, { style: 'percent' }).format(progress), level: number(kit, level + 1) })));
    }
  }

  const titleLevel = Math.floor((level - 1) / TITLE_LEVELS) * TITLE_LEVELS + TITLE_LEVELS + 1;
  if (titleLevel <= MAX_LEVEL) {
    const next = element('div', 'dash-level-next');
    const text = journey.nextTitle
      ? t('nextTitle', { title: journey.nextTitle, level: number(kit, titleLevel) })
      : t('titleAt', { level: number(kit, titleLevel) });
    const segments = element('div', 'dash-segments');
    const reached = (level - 1) % TITLE_LEVELS + 1;
    for (let index = 1; index <= TITLE_LEVELS; index += 1) segments.append(element('i', index <= reached ? 'on' : ''));
    next.append(element('span', 'footnote', text), segments);
    nodes.push(next);
  }
  slot('journey-level').replaceChildren(...nodes);
}

function renderStreak(journey, today, kit) {
  const { element, t } = kit;
  const streak = Math.max(Math.round(journey.streak ?? 0), 0);
  const nodes = [];
  const count = element('div', 'dash-streak-count');
  count.append(icon(DAY_ICONS.tracked, streak > 0 ? 'tracked' : 'pending'), element('strong', '', dayCount(kit, streak)));
  nodes.push(count);
  if (typeof journey.trackedToday === 'boolean') nodes.push(element('p', 'footnote dash-caption', t(journey.trackedToday ? 'todayDone' : 'todayPending')));
  if (streak === 0) nodes.push(element('p', 'footnote dash-caption', t('streakNone')));

  const days = (journey.days ?? []).filter((day) => day?.date && DAY_ICONS[day.state]).slice(-7);
  if (days.length) {
    const strip = element('div', 'dash-days');
    for (const day of days) {
      const cell = element('span', 'dash-day');
      cell.title = `${kit.day(day.date, { weekday: 'long', day: 'numeric', month: 'short' })} · ${t({ tracked: 'dayTracked', frozen: 'dayFrozen', missed: 'dayMissed', pending: 'dayPending' }[day.state])}`;
      cell.append(icon(DAY_ICONS[day.state], day.state), element('span', '', kit.day(day.date, { weekday: 'narrow' })));
      strip.append(cell);
    }
    nodes.push(strip);
  }

  const facts = [];
  if (Number.isFinite(journey.best)) facts.push([t('best'), dayCount(kit, journey.best)]);
  if (Number.isFinite(journey.freezes)) facts.push([t('freezes'), number(kit, journey.freezes)]);
  if (facts.length) {
    const grid = element('div', 'dash-facts');
    for (const [label, value] of facts) {
      const fact = element('div');
      fact.append(element('span', 'footnote', label), element('strong', '', value));
      grid.append(fact);
    }
    nodes.push(grid);
  }

  const mark = MARKS.find((value) => value > streak);
  if (mark) {
    const next = element('div', 'dash-mark');
    next.append(pair(kit, t('nextMark', { count: dayCount(kit, mark) }), t('daysLeft', { count: dayCount(kit, mark - streak) })), kit.bar('var(--tint)', streak / mark));
    nodes.push(next);
  }
  slot('journey-streak').replaceChildren(...nodes);
}

function endsText(kit, endsOn, today) {
  const date = kit.day(endsOn, { day: 'numeric', month: 'short' });
  if (!today) return kit.t('challengeEnds', { date });
  const left = daysBetween(today, endsOn);
  if (left <= 0) return kit.t('endsToday');
  return `${kit.t('challengeEnds', { date })} · ${kit.t('daysLeft', { count: dayCount(kit, left) })}`;
}

function renderChallenge(challenge, today, kit) {
  const { element, t } = kit;
  if (!challenge?.title) {
    slot('journey-challenge').replaceChildren(element('p', 'web-empty', t('noChallenge')));
    return;
  }
  const head = element('div', 'dash-pair');
  head.append(element('strong', '', challenge.title));
  if (Number.isFinite(challenge.xp)) head.append(xpChip(kit, `+${number(kit, challenge.xp)}`, false));
  const nodes = [head, kit.bar('var(--teal)', clamp(challenge.progress))];
  if (challenge.detail) nodes.push(element('p', 'footnote dash-caption', challenge.detail));
  if (challenge.endsOn) nodes.push(element('p', 'footnote dash-caption', endsText(kit, challenge.endsOn, today)));
  slot('journey-challenge').replaceChildren(...nodes);
}

function renderMissions(missions, today, kit) {
  const items = (missions?.items ?? []).filter((item) => item?.title);
  if (!block('journey-missions', items.length > 0)) return;
  const { element, t } = kit;
  const finished = items.filter((item) => (item.done ?? 0) >= (item.target ?? 1)).length;
  slot('missions-count').textContent = `${number(kit, finished)}/${number(kit, items.length)}`;
  const rows = items.map((item) => {
    const target = Math.max(item.target ?? 1, 1);
    const done = Math.min(Math.max(item.done ?? 0, 0), target);
    const row = element('div', 'dash-mission');
    const head = element('div', 'dash-pair');
    head.append(element('span', '', item.title), xpChip(kit, `+${number(kit, item.xp ?? 25)}`, done >= target));
    row.append(head, kit.bar(done >= target ? 'var(--positive)' : 'var(--tint)', done / target), element('span', 'footnote', t('progressOf', { done: number(kit, done), target: number(kit, target) })));
    return row;
  });
  if (missions.renewsOn && today) {
    const left = Math.max(daysBetween(today, missions.renewsOn), 1);
    rows.push(element('p', 'footnote dash-caption', t('missionsRenew', { count: dayCount(kit, left) })));
  }
  slot('journey-missions').replaceChildren(...rows);
}

function renderAchievements(achievements, kit) {
  const total = achievements?.total ?? 0;
  if (!block('journey-achievements', total > 0)) return;
  const { element, t } = kit;
  const unlocked = Math.min(Math.max(achievements.unlocked ?? 0, 0), total);
  const overall = element('div', 'dash-mark');
  overall.append(pair(kit, t('achievementsUnlocked', { count: number(kit, unlocked), total: number(kit, total) }), new Intl.NumberFormat(kit.locale, { style: 'percent' }).format(unlocked / total)), kit.bar('var(--mustard)', unlocked / total));

  const columns = element('div', 'dash-achievements');
  const next = (achievements.next ?? []).filter((item) => item?.title).slice(0, 3);
  if (next.length) {
    const list = element('div');
    list.append(element('h3', 'dash-subhead', t('achievementsNext')));
    for (const item of next) {
      const row = element('div', 'dash-mission');
      const head = element('div', 'dash-pair');
      head.append(element('span', '', item.title));
      if (Number.isFinite(item.xp)) head.append(xpChip(kit, `+${number(kit, item.xp)}`, false));
      row.append(head);
      if (item.detail) row.append(element('span', 'footnote', item.detail));
      row.append(kit.bar('var(--mustard)', clamp(item.progress)));
      if (Number.isFinite(item.done) && Number.isFinite(item.target)) row.append(element('span', 'footnote', t('progressOf', { done: number(kit, item.done), target: number(kit, item.target) })));
      list.append(row);
    }
    columns.append(list);
  }
  const recent = (achievements.recent ?? []).filter((item) => item?.title).slice(0, 3);
  if (recent.length) {
    const list = element('div');
    list.append(element('h3', 'dash-subhead', t('achievementsRecent')));
    for (const item of recent) {
      const row = element('div', 'dash-line');
      const medal = element('span', 'badge', '★');
      medal.style.setProperty('--badge', TIERS[item.tier] ?? 'var(--mustard)');
      const body = element('div');
      body.append(element('div', 'web-item-title', item.title));
      if (item.unlockedOn) body.append(element('div', 'footnote', kit.day(item.unlockedOn, { day: 'numeric', month: 'short', year: 'numeric' })));
      row.append(medal, body, Number.isFinite(item.xp) ? xpChip(kit, `+${number(kit, item.xp)}`, true) : element('span'));
      list.append(row);
    }
    columns.append(list);
  }
  slot('journey-achievements').replaceChildren(overall, columns);
}

function renderBlue(score, kit) {
  const visible = Boolean(score) && score.max === 1000 && Number.isFinite(score.value);
  if (!block('journey-blue', visible)) return;
  const { element, t } = kit;
  const value = Math.round(score.value);
  const ratio = clamp((value - 200) / (BLUE_SCORE - 200));
  const healthy = value >= BLUE_SCORE;
  const color = healthy ? 'var(--positive)' : ratio >= 0.6 ? 'var(--warning)' : 'var(--negative)';
  const head = element('div', 'dash-pair');
  const figure = element('strong', '', t('blueScore', { value: number(kit, value), target: number(kit, BLUE_SCORE) }));
  figure.style.color = color;
  head.append(figure, xpChip(kit, '+200', healthy));
  slot('journey-blue').replaceChildren(
    head,
    kit.bar(color, ratio),
    element('p', 'footnote dash-caption', t(healthy ? 'blueOn' : 'blueGoal')),
    element('p', 'footnote dash-caption', t('bluePerfect'))
  );
}

function renderRules(kit) {
  slot('journey-xp').replaceChildren(...XP_RULES.map(([key, xp]) => {
    const row = kit.element('div', 'dash-pair dash-rule');
    row.append(kit.element('span', '', kit.t(key)), xpChip(kit, xp, true));
    return row;
  }));
}
