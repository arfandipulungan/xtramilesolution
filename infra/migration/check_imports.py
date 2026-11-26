#!/usr/bin/env python3
"""Fail fast if an import block points at a resource address that does not exist in the
configuration (e.g. a typo, or a module refactor). `terraform validate` does not catch this;
`plan` would, but only with cloud credentials. Usage: check_imports.py <live-root-dir>"""
import re,os,sys,glob
def load(d): return "\n".join(open(f).read() for f in glob.glob(os.path.join(d,"*.tf")))
def resolve(root,addr):
    parts=addr.split('.'); d=root
    while parts[0]=='module':
        name=re.sub(r'\[.*\]','',parts[1]); src=re.search(r'module\s+"%s"\s*{.{0,3000}?source\s*=\s*"([^"]+)"'%name,load(d),re.S)
        if not src: return f"module {name} not found in {d}"
        d=os.path.normpath(os.path.join(d,src.group(1))); parts=parts[2:]
    rtype,rname=parts[0],re.sub(r'\[.*\]','',parts[1])
    return None if re.search(r'resource\s+"%s"\s+"%s"'%(rtype,rname),load(d)) else f"resource {rtype}.{rname} not in {d}"
root=sys.argv[1]; bad=0
for m in re.finditer(r'import\s*{\s*to\s*=\s*([^\s]+)',open(os.path.join(root,"imports.tf")).read()):
    err=resolve(root,m.group(1)); print(("OK  " if not err else "ERR ")+m.group(1)+("" if not err else "  -> "+err)); bad+=bool(err)
sys.exit(bad)
