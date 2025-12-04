#!/usr/bin/env python3
# ASCII only
import sys, re, json, argparse, os

MARKER_EQ   = re.compile(r'^\[EQ_REF id="([^"]+)"\]\s*$')
MARKER_HIST = re.compile(r'^\[HISTORICAL id="([^"]+)"\]\s*$')

def die(code,msg):
    print(msg)
    sys.exit(code)

def assert_ascii_lf(path):
    with open(path,"rb") as f:
        b=f.read()
    if b.find(b"\r\n")!=-1:
        die(2,f"CRLF in {path}")
    if any(c>127 for c in b):
        die(2,f"Non-ASCII in {path}")

def load_json_ascii(path):
    assert_ascii_lf(path)
    with open(path,"rb") as f:
        b=f.read()
    try:
        return json.loads(b.decode("ascii"))
    except Exception as e:
        die(2,f"JSON parse error in {path}: {e}")

def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--views", required=True)
    ap.add_argument("--objects", required=True)
    ap.add_argument("--migration", required=True)
    ap.add_argument("--strict", action="store_true")
    return ap.parse_args()

def read_core_spec(core_path):
    assert_ascii_lf(core_path)
    eq_refs=set(); historical=set()
    with open(core_path,"r",encoding="ascii",newline="\n") as f:
        for i,line in enumerate(f,1):
            s=line.strip()
            if s=="":
                continue
            m1=MARKER_EQ.match(s)
            if m1:
                eq_refs.add(m1.group(1)); continue
            m2=MARKER_HIST.match(s)
            if m2:
                historical.add(m2.group(1)); continue
            die(2,f"core_spec_view_v0.md: invalid line {i}: {line.rstrip()}")
    return eq_refs, historical

def basename(id_):
    return id_.split("@",1)[0]

def main():
    args = parse_args()

    # Paths
    core_spec = os.path.join(args.views,"core_spec_view_v0.md")
    if not os.path.isfile(core_spec):
        die(2,"missing views/core_spec_view_v0.md")

    # migration_log.tsv header check (ASCII + exact header + final LF allowed)
    assert_ascii_lf(args.migration)
    with open(args.migration,"rb") as f:
        b=f.read()
    header = b"segment_id\tclassification\thandled\tkernel_ids\tnote\tpurge_ok\n"
    if len(b)<len(header) or b[:len(header)]!=header:
        die(2,"logs/migration_log.tsv: header mismatch")

    # core_spec markers only
    eq_refs, hist = read_core_spec(core_spec)

    # load objects
    objs = load_json_ascii(args.objects)
    if not isinstance(objs,list):
        die(2,"objects must be a JSON array")

    by_id={o["id"]:o for o in objs if isinstance(o,dict) and "id"in o}

    # ACTIVE equations
    active_eq = { o["id"] for o in objs if o.get("kind")=="EQUATION" and o.get("lifecycle_status")=="ACTIVE" }

    # Coverage: ACTIVE(EQ) ? EQ_REF(core_spec)
    missing = sorted(active_eq - eq_refs)
    if missing:
        die(3,"Coverage fail, missing in core_spec: " + ", ".join(missing))

    # Closed-World roots: ACTIVE EQ (plus historical ends of supersede chains; none required here)
    roots = set(active_eq)

    # Build closure over depends_on
    def deps(id_):
        o=by_id.get(id_)
        if not o: return []
        return o.get("depends_on",[]) if isinstance(o.get("depends_on",[]),list) else []

    reachable=set(roots)
    stack=list(roots)
    while stack:
        x=stack.pop()
        for y in deps(x):
            if y not in reachable:
                reachable.add(y); stack.append(y)

    # All VARIABLE, OPERATOR, EQUATION must be reachable; CONSTANT/UNIT/DOMAIN are exempt; RELATION ignored
    violations=[]
    for o in objs:
        k=o.get("kind")
        if k in ("VARIABLE","OPERATOR","EQUATION"):
            if o["id"] not in reachable:
                violations.append(o["id"])
    if violations:
        die(3,"Closed-World fail, unreachable: " + ", ".join(sorted(violations)))

    print("validate_views.py: OK")
    sys.exit(0)

if __name__=="__main__":
    main()