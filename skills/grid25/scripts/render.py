#!/usr/bin/env python3
"""
用法:
  python render.py grid  <INDUSTRY> <R2W_JSON> <R3W_JSON> [CDN_URL]
  python render.py results <INDUSTRY> <W2> <W3> <RESULTS_JSON>

CDN_URL 默认值在 SKILL.md 安装后由用户配置，或直接传入。
"""
import sys, json
from pathlib import Path

BASE = Path(__file__).parent.parent / "references"
DEFAULT_CDN = "https://storage.5km.host/grid25/widget.min.js"

def render_grid(industry, r2w_json, r3w_json, cdn_url=None):
    tpl = (BASE / "widget-template.html").read_text(encoding="utf-8")
    out = tpl.replace("{{INDUSTRY}}", industry)
    out = out.replace("{{R2W_JSON}}", r2w_json)
    out = out.replace("{{R3W_JSON}}", r3w_json)
    out = out.replace("{{CDN_URL}}", cdn_url or DEFAULT_CDN)
    print(out, end="")

def render_results(industry, w2, w3, results_json):
    tpl = (BASE / "results-template.html").read_text(encoding="utf-8")
    out = tpl.replace("{{INDUSTRY}}", industry)
    out = out.replace("{{W2}}", w2)
    out = out.replace("{{W3}}", w3)
    out = out.replace("{{RESULTS_JSON}}", results_json)
    print(out, end="")

cmd = sys.argv[1]
if cmd == "grid":
    cdn = sys.argv[5] if len(sys.argv) > 5 else None
    render_grid(sys.argv[2], sys.argv[3], sys.argv[4], cdn)
elif cmd == "results":
    render_results(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
