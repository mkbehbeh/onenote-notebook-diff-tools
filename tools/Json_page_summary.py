import json
import re
import csv
import sys
from datetime import datetime


def extract_text(obj, result):
    if isinstance(obj, dict):
        if obj.get("type") == "paragraph":
            for c in obj.get("content", []):
                if "text" in c:
                    result.append(c["text"])
        if "CachedTitleStringFromPage" in obj:
            result.append(obj["CachedTitleStringFromPage"])
        for v in obj.values():
            extract_text(v, result)
    elif isinstance(obj, list):
        for item in obj:
            extract_text(item, result)


def page_size(page):
    parts = []
    extract_text(page, parts)
    return sum(len(t) for t in parts)


def find_title_date_nodes(obj, results, depth=0):
    if depth > 30:
        return
    if isinstance(obj, dict):
        if obj.get("IsTitleDate") is True:
            texts = []
            collect_texts(obj, texts)
            results.append(texts)
        for v in obj.values():
            find_title_date_nodes(v, results, depth + 1)
    elif isinstance(obj, list):
        for item in obj:
            find_title_date_nodes(item, results, depth + 1)


def collect_texts(obj, result):
    if isinstance(obj, dict):
        if "text" in obj:
            result.append(obj["text"])
        for v in obj.values():
            collect_texts(v, result)
    elif isinstance(obj, list):
        for item in obj:
            collect_texts(item, result)


def parse_datetime(texts):
    date_formats = ["%A, %B %d, %Y", "%B %d, %Y", "%m/%d/%Y", "%Y-%m-%d"]
    time_formats = ["%I:%M %p", "%H:%M", "%I:%M%p"]

    date_str = texts[0].strip() if len(texts) > 0 else ""
    time_str = texts[1].strip() if len(texts) > 1 else ""

    dt = None
    for fmt in date_formats:
        try:
            dt = datetime.strptime(date_str, fmt)
            break
        except ValueError:
            continue

    if dt is None:
        return f"{date_str} {time_str}".strip()

    if time_str:
        for fmt in time_formats:
            try:
                t = datetime.strptime(time_str, fmt)
                dt = dt.replace(hour=t.hour, minute=t.minute)
                break
            except ValueError:
                continue

    fmt_out = "%Y-%m-%d %I:%M %p" if time_str else "%Y-%m-%d"
    return dt.strftime(fmt_out)


def get_page_date(page):
    date_nodes = []
    find_title_date_nodes(page, date_nodes)
    if not date_nodes:
        return ""

    parsed = []
    for texts in date_nodes:
        dt_str = parse_datetime(texts)
        parsed.append(dt_str)

    # return the latest parseable date, or last raw string
    best_dt = None
    best_str = parsed[-1] if parsed else ""
    for s in parsed:
        try:
            dt = datetime.strptime(s, "%Y-%m-%d %I:%M %p")
            if best_dt is None or dt > best_dt:
                best_dt = dt
                best_str = s
        except ValueError:
            pass
    return best_str


def fmt_size(n):
    if n >= 1000:
        return f"{n / 1000:.1f}k"
    return str(n)


def main():
    if len(sys.argv) < 2:
        print("Usage: python Json_page_summary.py <file.json> [output.csv]", file=sys.stderr)
        sys.exit(1)

    json_file = sys.argv[1]
    csv_file = sys.argv[2] if len(sys.argv) > 2 else None

    with open(json_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    rows = []
    for page in data.get("pages", {}).values():
        title = page.get("CachedTitleString")
        if not title:
            for node in page.get("ContentChildNodes", []):
                title = node.get("CachedTitleStringFromPage")
                if title:
                    break
        if not title:
            title = "UNKNOWN"

        date_str = get_page_date(page)
        size = page_size(page)

        rows.append([title, date_str, size])

    out = open(csv_file, "w", newline="", encoding="utf-8") if csv_file else sys.stdout
    writer = csv.writer(out)
    writer.writerow(["Page Name", "Title Date/Time", "Size (chars)"])
    writer.writerows(rows)
    if csv_file:
        out.close()
        print(f"Written {len(rows)} rows to {csv_file}", file=sys.stderr)


if __name__ == "__main__":
    main()
