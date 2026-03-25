#!/usr/bin/env bash
# check-coding-gate.sh
# 检查是否有处于 implementation/running 状态的功能，才允许编写代码
#
# 检查路径：src/ lib/ app/ backend/ frontend/ cmd/ internal/ pkg/ api/ routers/
# 支持 stage-status.json 的单功能格式和多功能格式
#
# 豁免机制：在 workspace/stage-status.json 中配置 "legacyPaths" 数组，
# 列出存量项目的遗留代码路径，这些路径下的修改不受门禁约束。
# 示例：{ ..., "legacyPaths": ["legacy/", "vendor/", "migrations/"] }

FILE="$1"

# 判断文件路径是否属于代码路径
is_code_path() {
  case "$1" in
    src/*|lib/*|app/*|backend/*|frontend/*|cmd/*|internal/*|pkg/*|api/*|routers/*)
      return 0 ;;
    *)
      return 1 ;;
  esac
}

# 判断文件路径是否在豁免路径中（存量项目遗留代码）
is_legacy_exempt() {
  STATUS_FILE="workspace/stage-status.json"
  if [ ! -f "$STATUS_FILE" ]; then
    return 1
  fi
  # 从 stage-status.json 读取 legacyPaths 并检查当前文件是否匹配
  EXEMPT=$(python3 - "$STATUS_FILE" "$1" 2>/dev/null << 'PYEOF'
import json, sys
try:
    with open(sys.argv[1]) as f:
        d = json.load(f)
    legacy_paths = d.get("legacyPaths", [])
    file_path = sys.argv[2]
    for pattern in legacy_paths:
        if file_path.startswith(pattern.rstrip("/")):
            print("exempt")
            sys.exit(0)
    print("not-exempt")
except Exception:
    print("not-exempt")
PYEOF
)
  [ "$EXEMPT" = "exempt" ]
}

if ! is_code_path "$FILE"; then
  exit 0
fi

# 检查是否在豁免路径（存量项目遗留代码）
if is_legacy_exempt "$FILE"; then
  exit 0
fi

STATUS_FILE="workspace/stage-status.json"

if [ ! -f "$STATUS_FILE" ]; then
  echo "BLOCKED: workspace/stage-status.json 不存在。请先运行 /init-project 初始化框架。" >&2
  exit 2
fi

# 用 Python 解析 JSON，支持单功能和多功能两种格式
RESULT=$(python3 - "$STATUS_FILE" 2>/dev/null << 'PYEOF'
import json, sys

try:
    with open(sys.argv[1]) as f:
        d = json.load(f)
except Exception as e:
    print(f"error: {e}")
    sys.exit(1)

# 支持多功能格式: { "features": { "name": {...} } }
# 和单功能格式: { "feature": "name", "stage": "...", "status": "..." }
if "features" in d and isinstance(d["features"], dict):
    features = d["features"]
else:
    feature_name = d.get("feature", "unknown")
    features = {feature_name: d}

active = [
    name for name, v in features.items()
    if isinstance(v, dict)
    and v.get("stage") == "implementation"
    and v.get("status") == "running"
]

if active:
    print("ok:" + ",".join(active))
else:
    # 找出最近活跃的功能状态，给出更好的错误提示
    all_stages = [(name, v.get("stage"), v.get("status")) for name, v in features.items() if isinstance(v, dict)]
    if all_stages:
        name, stage, status = all_stages[-1]
        print(f"blocked:feature={name},stage={stage},status={status}")
    else:
        print("blocked:no-features")
PYEOF
)

if [[ "$RESULT" == ok:* ]]; then
  exit 0
elif [[ "$RESULT" == blocked:* ]]; then
  INFO="${RESULT#blocked:}"
  echo "BLOCKED: 不允许在当前状态下编写代码。" >&2
  echo "当前状态: $INFO" >&2
  echo "需要状态: stage=implementation, status=running" >&2
  echo "请先完成 P1(需求分析) → P2(产品设计) → P3(技术设计) 并获得人工审批，然后运行 /close-loop 进入编码阶段。" >&2
  exit 2
else
  # Python 解析失败时降级为宽松检查（避免误拦截）
  echo "WARNING: 无法解析 workspace/stage-status.json，跳过门禁检查。" >&2
  exit 0
fi
