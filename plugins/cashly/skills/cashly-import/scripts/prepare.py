import json
import re
import sys
import unicodedata
from collections import defaultdict
from datetime import date, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from read_xls import sheets

INSTALLMENT = re.compile(r"\s*(\d{1,2})/(\d{1,2})\s*$")
INVOICE_PAYMENT = re.compile(r"pagamento de fatura|cardbankslip|pagto\.? fatura|deb\.? ?cta\.? ?fatura|fatura cart", re.I)
INVESTMENT_MOVE = re.compile(
    r"\b(resgate|aplica[cç][aã]o|rdb|cdb|integralizacao de capital|tesouro|liq bolsa - vista bruto"
    r"|valor (recebido de|aplicado em) investimentos|caixinha)\b", re.I)
CARD_PAYMENT_CODE = re.compile(r"^[A-Z]{2,3}[-\d]{12,}")
INVESTMENT_INCOME = re.compile(r"rendimentos|dividendos|juros s/ capital|taxa remunera|restituicao de capital", re.I)
INVESTMENT_COST = re.compile(r"^ir - |liq bolsa|corretagem|cust[oó]dia", re.I)
BANK_SETTLEMENT = re.compile(r"^banco [\w ]+ s\.?a\.?$", re.I)
CREDIT_PIX_FUNDING = re.compile(r"valor adicionado para pix no cr[eé]dito", re.I)
TRANSFER_HINT = re.compile(r"\b(tef|ted|doc|transf|transferencia)\b")


def fold(text):
    return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()


def has_word(folded, word):
    return re.search(rf"\b{re.escape(word)}\b", folded) is not None


def looks_like_transfer(entry):
    folded = fold(entry["raw"])
    return entry["reason"] == "own_transfer" or (TRANSFER_HINT.search(folded) and "pix" not in folded)


def parse_date(text):
    day, month, year = (int(x) for x in re.split(r"[./-]", text.strip())[:3])
    return date(year, month, day)


def add_months(value, months):
    month = value.month - 1 + months
    year = value.year + month // 12
    month = month % 12 + 1
    for day in (value.day, 30, 29, 28):
        try:
            return date(year, month, day)
        except ValueError:
            continue


def rows(path):
    for account, table in sheets(path).items():
        header = [fold(str(h)) for h in table[0]]
        index = {name: header.index(name) for name in header}
        is_card = "fatura" in index
        for line, row in enumerate(table[1:], start=2):
            if not str(row[index["data"]]).strip():
                continue
            yield {
                "account": account,
                "is_card": is_card,
                "line": line,
                "date": parse_date(str(row[index["data"]])),
                "raw": " ".join(str(row[index["descricao"]]).split()),
                "bank_category": str(row[index["categoria"]]).strip(),
                "value": float(row[index["valor"]] or 0),
                "invoice": str(row[index["fatura"]]).strip() if is_card else "",
                "tags": [t.strip() for t in str(row[index["tags"]]).split(",") if t.strip()],
            }


def classify(entry, holder, issuers):
    raw, folded = entry["raw"], fold(entry["raw"])
    if round(entry["value"], 2) == 0:
        return "zero_value"
    if not entry["is_card"] and BANK_SETTLEMENT.search(raw.strip()):
        return "investment_move"
    if not entry["is_card"] and entry["value"] < 0 and any(has_word(folded, name) for name in issuers):
        return "invoice_payment"
    if entry["is_card"] and raw.lower().startswith("fatura ") and not entry["bank_category"]:
        return "invoice_total"
    if entry["is_card"] and entry["value"] > 0 and CARD_PAYMENT_CODE.match(raw):
        return "invoice_payment"
    if INVOICE_PAYMENT.search(raw):
        return "invoice_payment"
    if CREDIT_PIX_FUNDING.search(raw):
        return "credit_pix_funding"
    if holder and all(has_word(folded, part) for part in holder):
        return "own_transfer"
    if not entry["is_card"] and INVESTMENT_MOVE.search(folded):
        return "investment_move"
    if INVESTMENT_INCOME.search(folded):
        return "investment_income"
    if INVESTMENT_COST.search(folded):
        return "investment_cost"
    return None


def pair_transfers(entries):
    pending = defaultdict(list)
    for entry in entries:
        if entry["reason"] in (None, "own_transfer") and not entry["is_card"]:
            pending[round(abs(entry["value"]), 2)].append(entry)
    for group in pending.values():
        outs = [e for e in group if e["value"] < 0]
        ins = [e for e in group if e["value"] > 0]
        for out in outs:
            match = next(
                (i for i in ins if i["account"] != out["account"] and not i.get("paired")
                 and (i["reason"] is None or out["reason"] is None)
                 and ("own_transfer" in (i["reason"], out["reason"])
                      or (looks_like_transfer(i) and looks_like_transfer(out)))
                 and abs((i["date"] - out["date"]).days) <= 3), None)
            if match:
                out["paired"] = match["paired"] = True
                labeled = "Salário" in (out["bank_category"], match["bank_category"])
                out["reason"] = match["reason"] = (
                    "transfer_labeled_as_salary" if labeled else "own_transfer")


def collapse_installments(entries):
    series = defaultdict(list)
    for entry in entries:
        found = INSTALLMENT.search(entry["raw"])
        if entry["reason"] is None and entry["is_card"] and found:
            current, total = int(found.group(1)), int(found.group(2))
            if 1 <= current <= total and total > 1:
                base = INSTALLMENT.sub("", entry["raw"]).strip()
                series[(entry["account"], base, total)].append((current, entry))
    for (account, base, total), items in series.items():
        chains = []
        for number, entry in sorted(items, key=lambda pair: (pair[1]["date"], pair[0])):
            chain = next(
                (c for c in chains if c[-1][0] == number - 1 and c[-1][1]["date"] < entry["date"]
                 and abs(c[-1][1]["value"] - entry["value"]) <= 0.011),
                None)
            if chain is None:
                chains.append([(number, entry)])
            else:
                chain.append((number, entry))
        for chain in chains:
            first_number, first = chain[0]
            values = [entry["value"] for _, entry in chain]
            amount = sum(values) + values[-1] * (total - len(chain))
            start = first["date"] if first_number == 1 else add_months(first["date"], -(first_number - 1))
            first.update(
                raw=base, date=start, value=round(amount, 2), installments=total,
                seen=[n for n, _ in chain], estimated_start=first_number != 1)
            for _, other in chain[1:]:
                other["reason"] = "installment_duplicate"


TICKER = re.compile(r"\b([A-Z]{4}\d{1,2})\b")
INVESTMENT_NAMES = [
    (re.compile(r"^rendimentos", re.I), "Rendimentos"),
    (re.compile(r"^dividendos", re.I), "Dividendos"),
    (re.compile(r"^juros s/ capital", re.I), "JCP"),
    (re.compile(r"^taxa remunera", re.I), "Aluguel de ações"),
    (re.compile(r"^restituicao de capital", re.I), "Restituição de capital"),
    (re.compile(r"^leil[aã]o de fra", re.I), "Leilão de frações"),
    (re.compile(r"^ir - ", re.I), "IR sobre aluguel"),
    (re.compile(r"corretagem", re.I), "Corretagem"),
    (re.compile(r"liq bolsa - vista tx", re.I), "Taxas da B3"),
    (re.compile(r"cust[oó]dia.*estor", re.I), "Estorno da taxa de custódia"),
    (re.compile(r"cust[oó]dia", re.I), "Taxa de custódia"),
]


def investment_name(raw):
    label = next((name for pattern, name in INVESTMENT_NAMES if pattern.search(fold(raw))), None)
    if not label:
        return None
    tickers = TICKER.findall(raw)
    return f"{label} {tickers[-1]}" if tickers and label not in ("Corretagem", "Taxas da B3") else label


def grouped_investments(entries):
    buckets = defaultdict(float)
    for entry in entries:
        if entry["reason"] in ("investment_income", "investment_cost"):
            key = (entry["account"], entry["date"].year, entry["date"].month)
            buckets[key] += entry["value"]
            entry["reason"] = "investment_grouped"
    result = []
    for (account, year, month), total in sorted(buckets.items()):
        if round(total, 2) == 0:
            continue
        last = add_months(date(year, month, 1), 1) - timedelta(days=1)
        result.append({
            "date": last.isoformat(), "raw": f"Proventos e taxas · {account}",
            "description": "Proventos de investimentos" if total > 0 else "Taxas de investimentos",
            "amount": round(abs(total), 2), "kind": "income" if total > 0 else "expense",
            "bank_category": "Investimentos", "account": account, "installments": 1,
        })
    return result


def main():
    path = sys.argv[1]
    group_investments = "--itemize-investments" not in sys.argv
    salary_is_income = "--salary-transfers-are-income" in sys.argv
    holder_arg = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--holder=")), "")
    if not holder_arg:
        found = re.search(r"movimentacoes_([a-z-]+)_\d{8}", Path(path).name)
        holder_arg = found.group(1).replace("-", " ") if found else ""
    holder = fold(holder_arg).split()
    entries = list(rows(path))
    issuers = {fold(e["account"]).split()[-1] for e in entries if e["is_card"]}
    for entry in entries:
        entry["reason"] = classify(entry, holder, issuers)
        entry.setdefault("installments", 1)
    pair_transfers(entries)
    if salary_is_income:
        for entry in entries:
            if entry["reason"] == "transfer_labeled_as_salary" and entry["value"] > 0:
                entry["reason"] = None
    collapse_installments(entries)
    extra = grouped_investments(entries) if group_investments else []
    ready, skipped = [], defaultdict(lambda: {"count": 0, "total": 0.0})
    for entry in entries:
        reason = entry["reason"]
        if reason in ("investment_income", "investment_cost"):
            reason = None
        if reason:
            skipped[reason]["count"] += 1
            skipped[reason]["total"] += entry["value"]
            continue
        item = {
            "date": entry["date"].isoformat(), "raw": entry["raw"],
            "amount": round(abs(entry["value"]), 2),
            "kind": "income" if entry["value"] > 0 else "expense",
            "bank_category": entry["bank_category"], "account": entry["account"],
            "installments": entry["installments"],
        }
        if entry["reason"] in ("investment_income", "investment_cost"):
            item["description"] = investment_name(entry["raw"]) or entry["raw"]
            item["investment"] = True
        if entry["tags"]:
            item["tags"] = entry["tags"]
        if entry.get("estimated_start"):
            item["note"] = f"parcelas vistas {entry['seen']}; início calculado"
        ready.append(item)
    ready += extra
    ready.sort(key=lambda item: item["date"])
    json.dump({
        "ready": ready,
        "skipped": {k: {"count": v["count"], "total": round(v["total"], 2)} for k, v in skipped.items()},
    }, sys.stdout, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
