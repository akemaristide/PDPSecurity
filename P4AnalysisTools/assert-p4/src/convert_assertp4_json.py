#!/usr/bin/env python3
import argparse, json, os, subprocess, sys, tempfile

def index_nodes(x, idx):
    if isinstance(x, dict):
        nid=x.get("Node_ID")
        if isinstance(nid,int):
            old=idx.get(nid)
            if old is None or len(x)>len(old):
                idx[nid]=x
        for v in x.values(): index_nodes(v,idx)
    elif isinstance(x,list):
        for v in x: index_nodes(v,idx)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("--base-converter", default=os.path.join(os.path.dirname(__file__),"convert_assertp4_json.py"))
    a=ap.parse_args()
    with open(a.input,encoding="utf-8") as f: root=json.load(f)
    idx={}; index_nodes(root,idx)
    next_id=[max(idx.keys())+1 if idx else 1]
    wrappers={}
    def alloc():
        n=next_id[0]; next_id[0]+=1; return n
    def resolve(v):
        if isinstance(v,dict) and set(v)=={"Node_ID"}:
            return idx.get(v["Node_ID"],v)
        return v
    def walk(x):
        if isinstance(x,list):
            return [walk(v) for v in x]
        if not isinstance(x,dict):
            return x
        out={}
        for k,v in x.items():
            if k=="annotations":
                r=resolve(v)
                if isinstance(r,dict) and r.get("Node_Type")=="Vector<Annotation>":
                    vid=r.get("Node_ID")
                    wid=wrappers.setdefault(vid,alloc())
                    out[k]={"Node_ID":wid,"Node_Type":"Annotations","annotations":walk(r)}
                elif isinstance(r,dict) and r.get("Node_Type")=="Annotations":
                    out[k]=walk(r)
                else:
                    out[k]=walk(v)
            elif x.get("Node_Type")=="Annotation" and k=="body":
                # handled below
                continue
            else:
                out[k]=walk(v)
        if x.get("Node_Type")=="Annotation" and "expr" not in out:
            body=x.get("body",{})
            val=body.get("value") if isinstance(body,dict) else None
            if isinstance(val,dict) and val.get("Node_Type")=="Vector<Expression>":
                out["expr"]=walk(val)
            else:
                out["expr"]={"Node_ID":alloc(),"Node_Type":"Vector<Expression>","vec":[]}
        return out
    normalized=walk(root)
    with tempfile.NamedTemporaryFile("w",suffix=".json",delete=False,encoding="utf-8") as t:
        json.dump(normalized,t); tmp=t.name
    try:
        p=subprocess.run([sys.executable,a.base_converter,tmp,a.output])
        return p.returncode
    finally:
        os.unlink(tmp)
if __name__=="__main__":
    sys.exit(main())
