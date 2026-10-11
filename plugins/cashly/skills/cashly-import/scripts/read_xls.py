import struct
import sys

def ole_stream(data, wanted=("Workbook", "Book")):
    sector = 1 << struct.unpack_from("<H", data, 30)[0]
    mini = 1 << struct.unpack_from("<H", data, 32)[0]
    nfat, dir_start = struct.unpack_from("<II", data, 44)
    mini_cutoff, minifat_start, nminifat, difat_start, ndifat = struct.unpack_from("<IIIII", data, 56)
    def sec(i): return data[512 + i * sector: 512 + (i + 1) * sector]
    difat = list(struct.unpack_from("<109I", data, 76))
    d = difat_start
    for _ in range(ndifat):
        s = sec(d); vals = struct.unpack_from("<%dI" % (sector // 4), s)
        difat += vals[:-1]; d = vals[-1]
    fat = []
    for f in difat[:nfat]:
        fat += struct.unpack_from("<%dI" % (sector // 4), sec(f))
    def chain(start):
        out = []; i = start
        while i < 0xFFFFFFFA and len(out) < len(fat):
            out.append(i); i = fat[i]
        return out
    dirdata = b"".join(sec(i) for i in chain(dir_start))
    entries = []
    for k in range(len(dirdata) // 128):
        e = dirdata[k * 128:(k + 1) * 128]
        nl = struct.unpack_from("<H", e, 64)[0]
        name = e[:max(nl - 2, 0)].decode("utf-16-le", "ignore")
        start, size = struct.unpack_from("<II", e, 116)
        entries.append((name, e[66], start, size))
    root = entries[0]
    for name, typ, start, size in entries:
        if name in wanted:
            if size < mini_cutoff:
                ministream = b"".join(sec(i) for i in chain(root[2]))
                minifat = []
                for f in chain(minifat_start):
                    minifat += struct.unpack_from("<%dI" % (sector // 4), sec(f))
                out = []; i = start
                while i < 0xFFFFFFFA: out.append(ministream[i * mini:(i + 1) * mini]); i = minifat[i]
                return b"".join(out)[:size]
            return b"".join(sec(i) for i in chain(start))[:size]
    raise SystemExit("workbook not found")

def rk(v):
    num = v >> 2
    if v & 2:
        num = num - (1 << 30) if num & (1 << 29) else num
        val = float(num)
    else:
        val = struct.unpack("<d", struct.pack("<Q", (v & 0xFFFFFFFC) << 32))[0]
    return val / 100 if v & 1 else val

def read_string(buf, pos, conts, lenbytes=2):
    n = struct.unpack_from("<H" if lenbytes == 2 else "<B", buf, pos)[0]; pos += lenbytes
    flags = buf[pos]; pos += 1
    rich = ext = 0
    if flags & 8: rich = struct.unpack_from("<H", buf, pos)[0]; pos += 2
    if flags & 4: ext = struct.unpack_from("<I", buf, pos)[0]; pos += 4
    chars = []; wide = flags & 1
    while n > 0:
        if pos >= len(buf):
            buf = conts.pop(0); wide = buf[0] & 1; pos = 1
        take = min(n, (len(buf) - pos) // (2 if wide else 1))
        raw = buf[pos:pos + take * (2 if wide else 1)]
        chars.append(raw.decode("utf-16-le") if wide else raw.decode("latin-1"))
        pos += len(raw); n -= take
    skip = rich * 4 + ext
    while skip > 0:
        if pos >= len(buf): buf = conts.pop(0); pos = 0
        step = min(skip, len(buf) - pos); pos += step; skip -= step
    return "".join(chars), buf, pos

def parse(path):
    data = open(path, "rb").read()
    wb = ole_stream(data)
    records = []; p = 0
    while p + 4 <= len(wb):
        rid, ln = struct.unpack_from("<HH", wb, p); records.append((rid, wb[p + 4:p + 4 + ln])); p += 4 + ln
    sst = []; sheets = []; cells = {}; sheet = -1
    i = 0
    while i < len(records):
        rid, body = records[i]
        if rid == 0x00FC:
            conts = []; j = i + 1
            while j < len(records) and records[j][0] == 0x003C: conts.append(records[j][1]); j += 1
            total = struct.unpack_from("<I", body, 4)[0]; pos = 8; buf = body
            for _ in range(total):
                if pos >= len(buf) and conts: buf = conts.pop(0); pos = 0
                s, buf, pos = read_string(buf, pos, conts); sst.append(s)
            i = j; continue
        if rid == 0x0085:
            sheets.append(body[8:].decode("latin-1", "ignore"))
        if rid == 0x0809 and struct.unpack_from("<H", body, 2)[0] == 0x10:
            sheet += 1
        if rid == 0x00FD:
            r, c, _, idx = struct.unpack_from("<HHHI", body); cells[(sheet, r, c)] = sst[idx]
        elif rid == 0x0203:
            r, c, _ = struct.unpack_from("<HHH", body); cells[(sheet, r, c)] = struct.unpack_from("<d", body, 6)[0]
        elif rid == 0x027E:
            r, c, _, v = struct.unpack_from("<HHHI", body); cells[(sheet, r, c)] = rk(v)
        elif rid == 0x00BD:
            r, c = struct.unpack_from("<HH", body); n = (len(body) - 6) // 6
            for k in range(n):
                v = struct.unpack_from("<I", body, 4 + k * 6 + 2)[0]; cells[(sheet, r, c + k)] = rk(v)
        elif rid == 0x0204:
            r, c, _ = struct.unpack_from("<HHH", body); s, _, _ = read_string(body, 6, [], 2); cells[(sheet, r, c)] = s
        elif rid == 0x0006:
            r, c, _ = struct.unpack_from("<HHH", body)
            if body[12:14] != b"\xff\xff": cells[(sheet, r, c)] = struct.unpack_from("<d", body, 6)[0]
        elif rid == 0x0207 and i > 0 and records[i - 1][0] == 0x0006:
            pr = records[i - 1][1]; r, c = struct.unpack_from("<HH", pr)
            try: s, _, _ = read_string(body, 0, [], 2); cells[(sheet, r, c)] = s
            except Exception: pass
        i += 1
    return sheets, cells

def sheets(path):
    names, cells = parse(path)
    result = {}
    for s in range(len(names)):
        keys = [k for k in cells if k[0] == s]
        if not keys:
            continue
        rows = max(k[1] for k in keys) + 1
        cols = max(k[2] for k in keys) + 1
        table = [[cells.get((s, r, c), "") for c in range(cols)] for r in range(rows)]
        result[names[s]] = table
    return result


if __name__ == "__main__":
    import json
    json.dump(sheets(sys.argv[1]), sys.stdout, ensure_ascii=False)
