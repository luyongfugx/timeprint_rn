#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, re, sys, argparse
from pathlib import Path

# 可编辑的文件类型
CODE_EXTS = {".h",".m",".mm",".swift",".c",".cc",".cpp",".hpp",".hh",".pch"}
CONF_EXTS = {".pbxproj",".xcconfig",".plist",".podspec",".json",".yml",".yaml",".txt",".md",".sh",".rb",".py"}
TEXT_EXTS = CODE_EXTS | CONF_EXTS

SKIP_DIR_PARTS = {"/Pods/", "/DerivedData/", "/.git/", "/.svn/", "/.hg/",
                  "/.xcworkspace/", "/build/", "/Build/", "/__MACOSX/"}

def is_text_file(p: Path) -> bool:
    return p.suffix.lower() in TEXT_EXTS

def read_text(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return ""

def write_text_atomic(p: Path, content: str):
    tmp = p.with_suffix(p.suffix + ".tmp__ren")
    tmp.write_text(content, encoding="utf-8")
    tmp.replace(p)

def should_skip_dir(path: Path) -> bool:
    s = str(path)
    return any(tag in s for tag in SKIP_DIR_PARTS)

def walk_targets(project_root: Path, scopes):
    roots = [project_root] if not scopes else [ (project_root / s).resolve() for s in scopes ]
    for root in roots:
        if not root.exists():
            print(f"[WARN] scope not found: {root}", file=sys.stderr)
            continue
        for dp, dn, fn in os.walk(root):
            dp_path = Path(dp)
            if should_skip_dir(dp_path):
                continue
            yield dp_path, [dp_path/f for f in fn]

def build_filename_mapping(project_root: Path, scopes, old_prefix, new_prefix):
    """
    文件名映射：以 old_prefix 开头的代码/配置文件，改为 new_prefix + 其余部分 + 原扩展名
    处理 category：XHFoo+Bar.m -> CZDFoo+Bar.m
    """
    mapping = {}
    for dp, files in walk_targets(project_root, scopes):
        for p in files:
            p = Path(p)
            if not is_text_file(p):
                continue
            name = p.stem
            ext  = p.suffix
            if not name.startswith(old_prefix):
                continue
            rest = name[len(old_prefix):]
            # category 保持 +Cat 不变
            new_name = f"{new_prefix}{rest}{ext}"
            new_path = p.with_name(new_name)
            if new_path != p:
                if new_path.exists():
                    # 避免覆盖，极少见
                    base = f"{new_prefix}{rest}"
                    new_path = p.with_name(base + "__renamed" + ext)
                mapping[p] = new_path
    return mapping

def build_regexes(old_prefix, new_prefix):
    """
    代码/工程内的前缀替换（仅前缀，不加后缀）：
    - 标识符：XHClass / XHSomething
    - 类目声明：@interface XHClass (Cat)，@implementation/@class 同理
    - import/include：#import "XHFoo.h"，#import <Path/XHFoo(.h)>
    - @import XHModule;
    """
    # 仅匹配前缀 XH + 大写起始主体，避免误伤 xhxxx 等
    ident    = re.compile(rf"\b{re.escape(old_prefix)}([A-Z][A-Za-z0-9_]*)\b")
    cat_decl = re.compile(rf"(\b@interface|\b@implementation|\b@class)\s+{re.escape(old_prefix)}([A-Z][A-Za-z0-9_]*)(\s*\()")
    inc_q    = re.compile(rf"\"({re.escape(old_prefix)}([A-Za-z0-9_]+))(\.([A-Za-z0-9_]+))?\"")
    inc_a    = re.compile(rf"<([^>]*?/)??({re.escape(old_prefix)}([A-Za-z0-9_]+))(\.([A-Za-z0-9_]+))?>")
    atimport = re.compile(rf"\@import\s+{re.escape(old_prefix)}([A-Za-z0-9_]*)\s*;")

    def r_ident(m):    return f"{new_prefix}{m.group(1)}"
    def r_cat(m):      return f"{m.group(1)} {new_prefix}{m.group(2)}{m.group(3)}"
    def r_inc_q(m):
        rest   = m.group(2)
        dotext = m.group(3) or ""
        return f"\"{new_prefix}{rest}{dotext}\""
    def r_inc_a(m):
        pathp  = m.group(1) or ""
        rest   = m.group(3)
        dotext = m.group(4) or ""
        return f"<{pathp}{new_prefix}{rest}{dotext}>"
    def r_atimp(m):    return f"@import {new_prefix}{m.group(1)};"

    return [(cat_decl, r_cat), (inc_q, r_inc_q), (inc_a, r_inc_a), (atimport, r_atimp), (ident, r_ident)]

def apply_text_replacements(txt: str, regexes) -> str:
    for rx, fn in regexes:
        txt = rx.sub(fn, txt)
    return txt

def collect_all_text_files(project_root: Path, scopes):
    files = []
    for dp, fn in walk_targets(project_root, scopes):
        for p in fn:
            p = Path(p)
            if is_text_file(p):
                files.append(p)
    return files

def main():
    ap = argparse.ArgumentParser(description="Prefix-only renamer: XH* -> CZD* (files + symbols + imports + pbxproj).")
    ap.add_argument("--old-prefix", required=True)
    ap.add_argument("--new-prefix", required=True)
    ap.add_argument("--scope", nargs="*", help="限定修改的根目录（相对项目根），可多个；不传=全仓库（跳过 Pods/DerivedData/.git 等）")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    project_root = Path(".").resolve()
    oldp = args.old_prefix
    newp = args.new_prefix

    # 1) 生成文件名改名映射（先不落盘）
    file_map = build_filename_mapping(project_root, args.scope, oldp, newp)
    print(f"[INFO] 文件需改名：{len(file_map)}")

    # 2) 收集所有待处理文本文件
    all_files = collect_all_text_files(project_root, args.scope)
    print(f"[INFO] 扫描文本文件数：{len(all_files)}")

    # 3) 内容替换（先替换，再重命名）
    regexes = build_regexes(oldp, newp)
    changed = 0
    for p in all_files:
        txt = read_text(p)
        if not txt:
            continue
        new_txt = apply_text_replacements(txt, regexes)
        if new_txt != txt:
            changed += 1
            print(f"  UPDATE: {p}")
            if not args.dry_run:
                write_text_atomic(p, new_txt)

    print(f"[INFO] 已更新内容文件数：{changed}")

    # 4) 重命名文件（深路径优先）
    items = sorted(file_map.items(), key=lambda kv: len(str(kv[0])), reverse=True)
    for old_p, new_p in items:
        print(f"  RENAME: {old_p} -> {new_p}")
        if not args.dry_run:
            new_p.parent.mkdir(parents=True, exist_ok=True)
            old_p.rename(new_p)

    # 5) 刷新 .pbxproj 里的文件名（只按 basename 替换；不动 UUID）
    pbx_files = [p for p in all_files if p.suffix == ".pbxproj"]
    if pbx_files:
        # 构造 basename 替换表：XHFoo.m -> CZDFoo.m
        name_map = {}
        for o, n in items:
            if o.name != n.name:
                name_map[o.name] = n.name
            # 同时把对应的头/源的同名也兜一下（如果只改了 .m 被引用到 .h）
            ob = o.stem; nb = n.stem
            for ext in [".h",".hpp",".hh",".m",".mm",".c",".cc",".cpp",".pch",".swift"]:
                name_map[ob+ext] = nb+ext
        # 去重后按长到短替换
        seq = sorted(set(name_map.items()), key=lambda kv: len(kv[0]), reverse=True)
        for pbx in pbx_files:
            txt = read_text(pbx)
            new_txt = txt
            for oname, nname in seq:
                new_txt = new_txt.replace(oname, nname)
            if new_txt != txt:
                print(f"  PBX UPDATE: {pbx}")
                if not args.dry_run:
                    write_text_atomic(pbx, new_txt)

    print("[OK] 前缀改名完成。")
    print("建议后续：")
    print("  1) Xcode: Product -> Clean Build Folder")
    print("  2) 如用 CocoaPods：rm -rf Pods Podfile.lock && pod install")
    print("  3) 全量编译；若有个别动态反射 NSClassFromString(\"XH...\")，脚本已把字符串也替了，如需保留可回退指定文件。")

if __name__ == "__main__":
    main()
