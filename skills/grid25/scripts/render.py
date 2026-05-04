#!/usr/bin/env python3
"""
用法:
  python render.py grid    <INDUSTRY> <R2W_JSON> <R3W_JSON>
  python render.py results <INDUSTRY> <W2> <W3> <RESULTS_JSON>

widget.min.js 已打包在 assets/，渲染时直接 inline 注入，无需任何网络请求。
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TPL_DIR = ROOT / "references"
ASSETS_DIR = ROOT / "assets"


def render_grid(industry: str, r2w_json: str, r3w_json: str) -> None:
    tpl = (TPL_DIR / "widget-template.html").read_text(encoding="utf-8")
    widget_js = (ASSETS_DIR / "widget.min.js").read_text(encoding="utf-8")
    out = (
        tpl.replace("{{INDUSTRY}}", industry)
        .replace("{{R2W_JSON}}", r2w_json)
        .replace("{{R3W_JSON}}", r3w_json)
        .replace("{{WIDGET_JS}}", widget_js)
    )
    print(out, end="")


def render_results(industry: str, w2: str, w3: str, results_json: str) -> None:
    tpl = (TPL_DIR / "results-template.html").read_text(encoding="utf-8")
    out = (
        tpl.replace("{{INDUSTRY}}", industry)
        .replace("{{W2}}", w2)
        .replace("{{W3}}", w3)
        .replace("{{RESULTS_JSON}}", results_json)
    )
    print(out, end="")


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == "grid":
        if len(sys.argv) != 5:
            print("用法: render.py grid <INDUSTRY> <R2W_JSON> <R3W_JSON>", file=sys.stderr)
            sys.exit(1)
        render_grid(sys.argv[2], sys.argv[3], sys.argv[4])
    elif cmd == "results":
        if len(sys.argv) != 6:
            print("用法: render.py results <INDUSTRY> <W2> <W3> <RESULTS_JSON>", file=sys.stderr)
            sys.exit(1)
        render_results(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
    else:
        print(f"未知命令: {cmd}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
