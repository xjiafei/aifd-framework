#!/usr/bin/env bash
# post-stage-check.sh
#
# 阶段完成后检查：验证当前阶段的关键产出物是否存在。
# 借鉴自 enbrands-media2 项目实战经验：确保每个阶段"做完了"不等于"文档也完整了"。
#
# 用法：
#   由 new-feature skill 或 close-loop skill 在每个阶段完成时显式调用：
#     bash .claude/hooks/post-stage-check.sh [stage] [feature-name]
#   stage 可选值：requirement | product | tech | implementation | testing | gc
#
# 退出码：
#   0 = 阶段产出物完整
#   1 = 部分产出物缺失（WARNING，不阻塞，但应记录到 errors 数组）

STAGE="$1"
FEATURE="$2"
FAILED=0
ERRORS=()
WARNINGS=()

# 若未指定，从 stage-status.json 中读取
if [ -z "$STAGE" ] || [ -z "$FEATURE" ]; then
  STATUS_FILE="workspace/stage-status.json"
  if [ ! -f "$STATUS_FILE" ]; then
    echo "SKIP: workspace/stage-status.json 不存在，跳过阶段产出检查。" >&2
    exit 0
  fi
  read -r STAGE FEATURE <<< "$(python3 - "$STATUS_FILE" 2>/dev/null << 'PYEOF'
import json, sys
try:
    with open(sys.argv[1]) as f:
        d = json.load(f)
    features = d.get("features", {})
    active = [(n, v) for n, v in features.items()
              if isinstance(v, dict) and v.get("status") == "running"]
    if active:
        name, info = active[0]
        print(info.get("stage", ""), name)
    else:
        print("", "")
except Exception:
    print("", "")
PYEOF
)"
fi

if [ -z "$STAGE" ] || [ -z "$FEATURE" ]; then
  echo "SKIP: 无法确定当前阶段或功能，跳过阶段产出检查。" >&2
  exit 0
fi

SPEC_DIR="docs/specs/$FEATURE"

check_file() {
  local label="$1"
  local filepath="$2"
  if [ -z "$filepath" ] || [ ! -f "$filepath" ]; then
    WARNINGS+=("⚠️  $label — 文件不存在: $filepath")
    FAILED=1
  else
    echo "  ✅ $label"
  fi
}

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║   阶段产出检查 — stage: $STAGE | feature: $FEATURE"
echo "╚════════════════════════════════════════════════════╝"
echo ""

case "$STAGE" in
  requirement)
    echo "检查 P1 需求分析产出物..."
    check_file "需求文档 requirement.md" "$SPEC_DIR/requirement.md"
    ;;

  product)
    echo "检查 P2 产品设计产出物..."
    check_file "产品设计 product.md"     "$SPEC_DIR/product.md"
    ;;

  tech)
    echo "检查 P3 技术设计产出物..."
    check_file "技术设计 tech.md"        "$SPEC_DIR/tech.md"
    check_file "测试计划 test-plan.md"   "$SPEC_DIR/test-plan.md"
    check_file "测试用例 test-cases.md"  "$SPEC_DIR/test-cases.md"
    EXEC_PLAN=$(ls docs/plans/active/*.md 2>/dev/null | head -1)
    if [ -z "$EXEC_PLAN" ]; then
      WARNINGS+=("⚠️  执行计划 exec-plan.md — docs/plans/active/ 下无 .md 文件")
      FAILED=1
    else
      echo "  ✅ 执行计划 ($EXEC_PLAN)"
    fi
    ;;

  implementation)
    echo "检查 P4 实现阶段产出物..."
    check_file "CR 日志 review-log.md"          "$SPEC_DIR/review-log.md"
    check_file "测试报告 test-report.md"         "$SPEC_DIR/test-report.md"
    check_file "测试结果 test-result.json"       "$SPEC_DIR/test-result.json"
    ;;

  testing)
    echo "检查测试阶段产出物..."
    check_file "测试结果 test-result.json"       "$SPEC_DIR/test-result.json"
    check_file "测试报告 test-report.md"         "$SPEC_DIR/test-report.md"
    ;;

  gc)
    echo "检查 P5 收尾产出物..."
    check_file "功能索引 docs/specs/index.md" "docs/specs/index.md"
    check_file "架构文档 docs/architecture.md" "docs/architecture.md"
    check_file "CR 索引 workspace/cr-index.md" "workspace/cr-index.md"

    # 验证功能已登记到 specs/index.md（不仅仅文件存在）
    if ! grep -q "$FEATURE" docs/specs/index.md 2>/dev/null; then
      WARNINGS+=("⚠️  功能 '$FEATURE' 未登记到 docs/specs/index.md")
      FAILED=1
    else
      echo "  ✅ 功能已登记到 specs/index.md"
    fi

    # 验证 cr-index.md 包含本功能条目（非示例数据）
    if ! grep -q "$FEATURE" workspace/cr-index.md 2>/dev/null; then
      WARNINGS+=("⚠️  功能 '$FEATURE' 未登记到 workspace/cr-index.md")
      FAILED=1
    else
      echo "  ✅ 功能已登记到 cr-index.md"
    fi

    # 验证执行计划已移至 completed/
    if [ -f "docs/plans/active/$FEATURE.md" ]; then
      WARNINGS+=("⚠️  执行计划仍在 active/: docs/plans/active/$FEATURE.md（应已移至 completed/）")
      FAILED=1
    fi
    if [ ! -f "docs/plans/completed/$FEATURE.md" ]; then
      WARNINGS+=("⚠️  执行计划未找到: docs/plans/completed/$FEATURE.md")
      FAILED=1
    else
      echo "  ✅ 执行计划已归档到 completed/"
      # 验证执行计划 status 不是 active
      if grep -q "| status | active |" "docs/plans/completed/$FEATURE.md" 2>/dev/null; then
        WARNINGS+=("⚠️  执行计划 status 仍为 'active'（应改为 'completed'）")
        FAILED=1
      else
        echo "  ✅ 执行计划 status 已更新"
      fi
    fi
    ;;

  *)
    echo "SKIP: 未知阶段 '$STAGE'，跳过检查。" >&2
    exit 0
    ;;
esac

echo ""

if [ $FAILED -ne 0 ]; then
  echo "════════════════════════════════════════════════════" >&2
  echo "WARNING: 以下阶段产出物缺失（请在推进至下一阶段前补充）：" >&2
  for warn in "${WARNINGS[@]}"; do
    echo "  $warn" >&2
  done
  echo "" >&2
  echo "提示：此检查结果应记录到 workspace/stage-status.json 的 errors 数组。" >&2
  echo "════════════════════════════════════════════════════" >&2
  exit 1
fi

echo "════════════════════════════════════════════════════"
echo "✅ 阶段产出物检查通过：$STAGE 阶段产出完整。"
echo "════════════════════════════════════════════════════"
echo ""
exit 0
