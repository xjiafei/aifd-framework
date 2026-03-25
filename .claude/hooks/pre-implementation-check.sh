#!/usr/bin/env bash
# pre-implementation-check.sh
#
# 实现阶段前置检查：进入 /close-loop 前，验证所有设计文档是否存在且非空。
# 借鉴自 enbrands-media2 项目实战经验：防止"没有测试用例就开始编码"的问题。
#
# 用法：
#   由 close-loop skill 在 4.0 Coding 开始前显式调用：
#     bash .claude/hooks/pre-implementation-check.sh [feature-name]
#   或手动验证：
#     bash .claude/hooks/pre-implementation-check.sh my-feature
#
# 退出码：
#   0 = 所有文档就绪，可以开始实现
#   1 = 部分文档缺失（WARNING，建议修复）
#   2 = 关键文档缺失（BLOCKED，必须修复后才能继续）

FEATURE="$1"
FAILED=0
ERRORS=()

# 若未指定 feature，从 stage-status.json 中读取当前活跃功能
if [ -z "$FEATURE" ]; then
  STATUS_FILE="workspace/stage-status.json"
  if [ -f "$STATUS_FILE" ]; then
    FEATURE=$(python3 - "$STATUS_FILE" 2>/dev/null << 'PYEOF'
import json, sys
try:
    with open(sys.argv[1]) as f:
        d = json.load(f)
    features = d.get("features", {})
    active = [n for n, v in features.items()
              if isinstance(v, dict) and v.get("status") == "running"]
    print(active[0] if active else "")
except Exception:
    print("")
PYEOF
)
  fi
fi

if [ -z "$FEATURE" ]; then
  echo "SKIP: 无法确定当前功能（stage-status 中无 running 状态的功能），跳过前置检查。" >&2
  exit 0
fi

SPEC_DIR="docs/specs/$FEATURE"

check_required() {
  local label="$1"
  local filepath="$2"
  if [ ! -f "$filepath" ]; then
    ERRORS+=("❌ [REQUIRED] $label — 文件不存在: $filepath")
    FAILED=2
  elif [ ! -s "$filepath" ]; then
    ERRORS+=("❌ [REQUIRED] $label — 文件为空: $filepath")
    FAILED=2
  else
    echo "  ✅ $label"
  fi
}

check_warn() {
  local label="$1"
  local filepath="$2"
  if [ ! -f "$filepath" ]; then
    ERRORS+=("⚠️  [WARN]     $label — 文件不存在: $filepath")
    [ $FAILED -lt 1 ] && FAILED=1
  else
    echo "  ✅ $label"
  fi
}

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║   实现阶段前置检查 — feature: $FEATURE"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "检查 P1-P3 阶段产出物..."
echo ""

# 必须存在（缺失则 BLOCKED）
check_required "需求文档 requirement.md"  "$SPEC_DIR/requirement.md"
check_required "产品设计 product.md"      "$SPEC_DIR/product.md"
check_required "技术设计 tech.md"         "$SPEC_DIR/tech.md"
check_required "测试计划 test-plan.md"    "$SPEC_DIR/test-plan.md"
check_required "测试用例 test-cases.md"   "$SPEC_DIR/test-cases.md"

# 建议存在（缺失为 WARNING）
EXEC_PLAN=$(ls docs/plans/active/*.md 2>/dev/null | head -1)
if [ -z "$EXEC_PLAN" ]; then
  ERRORS+=("⚠️  [WARN]     执行计划 exec-plan — docs/plans/active/ 下无 .md 文件")
  [ $FAILED -lt 1 ] && FAILED=1
else
  echo "  ✅ 执行计划 ($EXEC_PLAN)"
fi

echo ""

if [ $FAILED -eq 2 ]; then
  echo "════════════════════════════════════════════════════" >&2
  echo "BLOCKED: 进入实现阶段前，以下关键文档缺失或为空：" >&2
  echo "" >&2
  for err in "${ERRORS[@]}"; do
    echo "  $err" >&2
  done
  echo "" >&2
  echo "请先完成 P1(需求分析) → P2(产品设计) → P3(技术设计+测试计划)，" >&2
  echo "通过 Gate 评审并获得人工审批后，再运行 /close-loop 进入实现阶段。" >&2
  echo "════════════════════════════════════════════════════" >&2
  exit 2
elif [ $FAILED -eq 1 ]; then
  echo "════════════════════════════════════════════════════" >&2
  echo "WARNING: 以下文档缺失（建议补充，当前允许继续）：" >&2
  for err in "${ERRORS[@]}"; do
    echo "  $err" >&2
  done
  echo "════════════════════════════════════════════════════" >&2
  exit 1
fi

echo "════════════════════════════════════════════════════"
echo "✅ 前置检查通过：所有设计文档就绪，可以开始实现。"
echo "════════════════════════════════════════════════════"
echo ""
exit 0
