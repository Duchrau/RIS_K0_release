#!/usr/bin/env python3
# ASCII only
import sys, json, argparse, re, os

SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")
ID_RE     = re.compile(r"^(EQ|VAR|CONST|OP|UNIT|DOM|REL):[A-Za-z0-9_]+@\d+\.\d+\.\d+$")
CANON_FORBIDDEN = re.compile(r"d\s*/\s*dt|\b[dD]\(.*\)/dt|_\w+")  # verbietet d/dt und Indexnotation x_i
PUNCT = set("()+-*/=<>\t ")
WHITELIST = {"transpose","diag","W","1"}

def die(code,msg):
    print(msg)
    sys.exit(code)

def load_json(path):
    with open(path,"rb") as f:
        b=f.read()
    # 7-bit ASCII erzwingen
    if any(c>127 for c in b):
        die(2,f"Non-ASCII in {path}")
    try:
        return json.loads(b.decode("ascii"))
    except Exception as e:
        die(2,f"JSON parse error in {path}: {e}")

def assert_ascii_lf(path):
    with open(path,"rb") as f:
        b=f.read()
    if b.find(b"\r\n")!=-1:
        die(2,f"CRLF in {path}")
    if any(c>127 for c in b):
        die(2,f"Non-ASCII in {path}")

def parse_args():
    ap=argparse.ArgumentParser()
    ap.add_argument("--objects",required=True)
    ap.add_argument("--schema",required=True)
    ap.add_argument("--domain_map",required=True)
    ap.add_argument("--strict",action="store_true")
    return ap.parse_args()

def semver_ok(v):
    m=SEMVER_RE.match(v); return bool(m)

def kind_for_prefix(p):
    return {
        "EQ":"EQUATION","VAR":"VARIABLE","CONST":"CONSTANT",
        "OP":"OPERATOR","UNIT":"UNIT","DOM":"DOMAIN","REL":"RELATION"
    }[p]

def basename(id_):
    return id_.split("@",1)[0]

def split_id(id_):
    # PREFIX:Name@x.y.z
    prefix = id_.split(":",1)[0]
    return prefix

def lex_sorted(xs):
    return xs==sorted(xs)

def token_split(s):
    # simple tokenizer: identifiers, numbers, and punctuation
    toks=[]; cur=""
    def flush():
        nonlocal cur
        if cur!="": toks.append(cur); cur=""
    for ch in s:
        if ch.isalnum() or ch=="_":
            cur+=ch
        elif ch in PUNCT or ch==",":
            flush(); 
            if ch.strip(): toks.append(ch)
        else:
            # everything non-ASCII should already be blocked; still forbid
            die(2,f"canonical contains illegal char: {repr(ch)}")
    flush()
    return toks

def main():
    args=parse_args()

    # Normative ASCII/LF Guard auf drei Pflichtdateien
    for p in (args.objects,args.schema,args.domain_map):
        assert_ascii_lf(p)

    objs=load_json(args.objects)
    if not isinstance(objs,list):
        die(2,"objects file must be a JSON array")

    # Indexe
    by_id={}
    for o in objs:
        if not isinstance(o,dict) or "id" not in o or "kind" not in o:
            die(2,"object without id/kind")
        id_=o["id"]; kind=o["kind"]
        if not ID_RE.match(id_): die(2,f"bad id format: {id_}")
        prefix=id_.split(":",1)[0]
        if kind!=kind_for_prefix(prefix): die(2,f"kind/prefix mismatch: {id_} kind={kind}")
        if "@" not in id_: die(2,f"missing semver: {id_}")
        ver=id_.split("@",1)[1]
        if not semver_ok(ver): die(2,f"bad semver: {id_}")
        if id_ in by_id: die(2,f"duplicate id: {id_}")
        by_id[id_]=o

    # Collect active by basename
    active_by_base={}
    for id_,o in by_id.items():
        if o.get("kind")=="RELATION": continue
        if o.get("lifecycle_status")=="ACTIVE":
            b=basename(id_)
            if b in active_by_base:
                die(2,f"ACTIVE_UNIQUE violated: {b}")
            active_by_base[b]=id_

    # Domain map
    dm=load_json(args.domain_map)
    pairs = dm.get("subdomain_of",[])
    edges={}
    for sub, sup in pairs:
        edges.setdefault(sub,set()).add(sup)
    # compute transitive closure
    def supers_of(d):
        seen=set(); stack=[d]
        while stack:
            x=stack.pop()
            for y in edges.get(x,()):
                if y not in seen:
                    seen.add(y); stack.append(y)
        return seen

    # Build symbol sets for canonical checks
    var_sym=set(); const_sym=set(); op_tokens=set()
    for o in objs:
        k=o["kind"]
        sp=o.get("semantic_payload",{})
        if k=="VARIABLE": var_sym.add(sp.get("symbol",""))
        if k=="CONSTANT": const_sym.add(sp.get("symbol",""))
        if k=="OPERATOR":
            ct=sp.get("canonical_token",None)
            if not ct or not re.match(r"^[A-Za-z][A-Za-z0-9_]*$",ct):
                die(2,f"OPERATOR without valid canonical_token: {o['id']}")
            op_tokens.add(ct)

    # Per-equation checks
    for id_,o in by_id.items():
        if o["kind"]!="EQUATION": continue
        dep=o.get("depends_on",[])
        if not isinstance(dep,list) or not lex_sorted(dep): die(2,f"{id_}: depends_on must be ASCII-lex sorted")
        # refs present
        sp=o.get("semantic_payload",{})
        refs=sp.get("refs",{})
        rvars=refs.get("variables",[])
        rcons=refs.get("constants",[])
        rops =refs.get("operators",[])
        for arr,name in ((rvars,"refs.variables"),(rcons,"refs.constants"),(rops,"refs.operators")):
            if not isinstance(arr,list) or not lex_sorted(arr): die(2,f"{id_}: {name} must be ASCII-lex sorted")
        # Ref?Dep identity
        dep_set=set(dep)
        if set(rvars)!=set(x for x in dep if x.startswith("VAR:")): die(2,f"{id_}: refs.variables != depends_on?VAR")
        if set(rcons)!=set(x for x in dep if x.startswith("CONST:")): die(2,f"{id_}: refs.constants != depends_on?CONST")
        if set(rops)!=set(x for x in dep if x.startswith("OP:")): die(2,f"{id_}: refs.operators != depends_on?OP")

        # domain_ref/unit_ref in depends_on as required
        dref=o.get("domain_ref",None)
        uref=o.get("unit_ref",None)
        if dref and dref not in dep_set: die(2,f"{id_}: domain_ref must be in depends_on")
        if uref is not None and uref not in dep_set and uref!="": 
            die(2,f"{id_}: unit_ref must be in depends_on when not null")

        # variable domains compatible
        def obj(x): 
            if x not in by_id: die(2,f"{id_}: unknown id in depends_on: {x}")
            return by_id[x]
        for v in rvars:
            vo = obj(v)
            vdom = vo.get("semantic_payload",{}).get("domain_ref",None)
            if vdom is None: die(2,f"{id_}: variable {v} missing domain_ref")
            if vdom!=dref and dref not in supers_of(vdom):
                die(2,f"{id_}: domain mismatch for {v}: {vdom} not <= {dref}")

        # canonical IFF rule and token policy
        canon = sp.get("canonical",None)
        uses_dot = any(basename(x)=="OP:dot" for x in rops)
        if uses_dot and not isinstance(canon,str):
            die(2,f"{id_}: canonical must exist when OP:dot is referenced")
        if (not uses_dot) and canon not in (None,):
            die(2,f"{id_}: canonical must be null when OP:dot not referenced")
        if isinstance(canon,str):
            # forbid d/dt, index notation, non-ASCII already guarded
            if CANON_FORBIDDEN.search(canon):
                die(2,f"{id_}: canonical contains forbidden pattern (d/dt or index notation)")
            # token check
            toks = token_split(canon)
            for t in toks:
                if t in PUNCT: 
                    continue
                # numbers allowed
                if t.replace(".","",1).isdigit():
                    continue
                # allowed identifiers
                if t in var_sym or t in const_sym or t in op_tokens or t in WHITELIST:
                    continue
                die(2,f"{id_}: unknown identifier in canonical: {t}")

    print("check_kernel.py: OK")
    sys.exit(0)

if __name__=="__main__":
    main()