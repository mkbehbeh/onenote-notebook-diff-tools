import json
import hashlib
import re
import sys
import os

def normalize_text(text_list):
    text = " ".join(text_list)
    text = text.lower()
    text = re.sub(r"[^\w\s]", "", text)
    text = " ".join(text.split())
    return text

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

def fingerprint_page(page):
    text_parts = []
    extract_text(page, text_parts)
    normalized = normalize_text(text_parts)
    return hashlib.md5(normalized.encode()).hexdigest(), sum(len(t) for t in text_parts)

def extract_pages(data):
    pages = []

    for page in data.get("pages", {}).values():
        title = page.get("CachedTitleString")

        if not title:
            for node in page.get("ContentChildNodes", []):
                title = node.get("CachedTitleStringFromPage")
                if title:
                    break

        if not title:
            title = "UNKNOWN"

        fp, size = fingerprint_page(page)

        pages.append({
            "title": title,
            "fp": fp,
            "size": size,
        })

    return pages

def fmt_size(n):
    if n >= 1000:
        return f"{n/1000:.1f}k chars"
    return f"{n} chars"

def compare_sections(pages_a, pages_b, name_a, name_b):
    # FIXED: Prints clean, actual filenames instead of internal JSON types
    print(f"\n=== Comparing Files ===")
    print(f"  File A (Dir 1): {name_a}")
    print(f"  File B (Dir 2): {name_b}\n")

    set_a = {p["fp"]: p for p in pages_a}
    set_b = {p["fp"]: p for p in pages_b}

    all_fps = set(set_a.keys()).union(set_b.keys())

    missing_in_b = []
    missing_in_a = []

    for fp in all_fps:
        a = set_a.get(fp)
        b = set_b.get(fp)
        if a and not b:
            missing_in_b.append(a)
        elif b and not a:
            missing_in_a.append(b)

    # FIXED: Replaced "A" and "B" with "Dir 1" and "Dir 2" for fast reference
    if missing_in_b:
        print(f"--- Pages in Dir 1 only ({len(missing_in_b)}) ---")
        for p in sorted(missing_in_b, key=lambda x: x["title"]):
            print(f"  {p['title']}  ({fmt_size(p['size'])})")

    if missing_in_a:
        print(f"\n--- Pages in Dir 2 only ({len(missing_in_a)}) ---")
        for p in sorted(missing_in_a, key=lambda x: x["title"]):
            print(f"  {p['title']}  ({fmt_size(p['size'])})")

    titles_a = {}
    for p in pages_a:
        titles_a.setdefault(p["title"], []).append(p)

    titles_b = {}
    for p in pages_b:
        titles_b.setdefault(p["title"], []).append(p)

    common_titles = set(titles_a.keys()).intersection(set(titles_b.keys()))

    changed = []
    for t in common_titles:
        fps_a = sorted(p["fp"] for p in titles_a[t])
        fps_b = sorted(p["fp"] for p in titles_b[t])
        if fps_a != fps_b:
            size_a = max(p["size"] for p in titles_a[t])
            size_b = max(p["size"] for p in titles_b[t])
            changed.append((t, size_a, size_b))

    if changed:
        print(f"\n--- Same title, different content ({len(changed)}) ---")
        for title, size_a, size_b in sorted(changed):
            delta = size_b - size_a
            sign = "+" if delta >= 0 else ""
            
            # FIXED: Tells you explicitly which directory holds the larger file size
            recommendation = "-> Dir 2 is larger" if delta > 0 else "-> Dir 1 is larger" if delta < 0 else "-> Sizes equal (structure change)"
            print(f"  {title}  (Dir 1: {fmt_size(size_a)}, Dir 2: {fmt_size(size_b)}, delta: {sign}{fmt_size(delta)}) {recommendation}")

    total_a = sum(p["size"] for p in pages_a)
    total_b = sum(p["size"] for p in pages_b)
    print(f"\n--- Summary ---")
    print(f"  Dir 1: {len(pages_a)} pages, {fmt_size(total_a)} total")
    print(f"  Dir 2: {len(pages_b)} pages, {fmt_size(total_b)} total")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python Json_title_size_compare.py fileA.json fileB.json")
        sys.exit(1)

    with open(sys.argv[1], "r", encoding="utf-8") as f:
        dataA = json.load(f)

    with open(sys.argv[2], "r", encoding="utf-8") as f:
        dataB = json.load(f)

    # FIXED: Grabs actual file names from the execution paths instead of internal JSON tags
    file_name_a = os.path.basename(sys.argv[1])
    file_name_b = os.path.basename(sys.argv[2])

    pagesA = extract_pages(dataA)
    pagesB = extract_pages(dataB)

    compare_sections(pagesA, pagesB, file_name_a, file_name_b)
