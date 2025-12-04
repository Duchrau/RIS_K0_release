#!/usr/bin/env python3
# ASCII only
import sys, json, os, argparse

def die(code,msg):
    print(msg); sys.exit(code)

def assert_dir(p):
    if not os.path.isdir(p):
        os.makedirs(p, exist_ok=True)

def load_ascii_json(path):
    with open(path,"rb") as f:
        b=f.read()
    if b.find(b"\r\n")!=-1: die(2,f"CRLF in {path}")
    if any(c>127 for c in b): die(2,f"Non-ASCII in {path}")
    try:
        return json.loads(b.decode("ascii"))
    except Exception as e:
        die(2,f"JSON parse error in {path}: {e}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--objects", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    objs = load_ascii_json(args.objects)
    if not isinstance(objs,list):
        die(2,"objects must be a JSON array")

    # simple counts
    counts = {}
    active = {}
    for o in objs:
        k = o.get("kind","?")
        counts[k] = counts.get(k,0)+1
        if o.get("lifecycle_status")=="ACTIVE":
            active[k] = active.get(k,0)+1

    # ensure reports/
    outp = os.path.abspath(args.out)
    assert_dir(os.path.dirname(outp))

    # TSV header + rows (ASCII + LF)
    lines = []
    lines.append("metric\tvalue\n")
    for k in sorted(counts):
        lines.append(f"count_{k}\t{counts[k]}\n")
    for k in sorted(active):
        lines.append(f"active_{k}\t{active[k]}\n")

    with open(outp,"wb") as f:
        f.write("".join(lines).encode("ascii"))

    print("dump_stats.py: OK ->", outp)

if __name__=="__main__":
    main()