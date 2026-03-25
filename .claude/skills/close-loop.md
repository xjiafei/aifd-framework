---
name: close-loop
description: "当技术设计审批通过、需要进入代码实现阶段时使用。"
disable-model-invocation: true
---

# /close-loop — P4 自动闭环

> 代码实现阶段的自动循环：coding → code-review → testing → acceptance
> 最多 3 轮，每轮结果持久化到 workspace/。超出 3 轮暂停请人类介入。

## 前置条件

- `docs/plans/active/` 中有活跃的执行计划
- 执行计划的 status 为 active，且技术设计已通过审查
- 如果前置条件不满足，提示用户先完成前序阶段

**启动时强制执行前置检查**：

```bash
bash .claude/hooks/pre-implementation-check.sh
```

- 退出码 0 → 继续执行
- 退出码 1 → 记录 WARNING，继续执行（建议先补充缺失文档）
- 退出码 2 → BLOCKED：关键设计文档缺失，必须停止，提示用户先完成 P1-P3

## 执行流程

读取 `workflows/full-lifecycle.md` 中 P4 章节作为参考。

```
当前轮次 = 1

LOOP:
  if 当前轮次 > 3:
    更新 stage-status.json: status=failed, summary="超出 3 轮循环，请人类介入"
    通知用户：列出 code-review-log.md 中所有 OPEN 问题 + stage-status.json 的 errors 数组
    STOP

  ── 轮次交接读取（loopRound > 1 时强制执行）──
  if 当前轮次 > 1:
    0.1 读取 workspace/code-review-log.md，列出本功能所有 OPEN 问题
    0.2 读取 exec-plan 里程碑完成状态（done / pending）
    0.3 读取 stage-status.json 的 errors 数组（上轮记录的问题）
    0.4 输出"第 {N} 轮修复目标摘要"：
        - 本轮修复的触发原因（P0 Bug / 验收失败 / CRITICAL 重试超限）
        - 需要修复的具体问题列表
        - 上轮已完成的里程碑（保持 done，不重新实现）

  ── 4.1 Coding ──

  > 重启类型说明（GOTO LOOP 时由上游步骤指定 restart_type）：
  > - BUG_FIX：只修复受影响代码，已 done 的里程碑保持 done，本步骤完成后直接跳到 4.2
  > - DESIGN_GAP：更新 exec-plan，只实现新增/修改的里程碑
  > - FULL（默认）：实现所有未 done 的里程碑

  if restart_type == BUG_FIX:
    1. 读取 bug 描述（来自上轮的 errors 或 testing 输出）
    2. 读取受影响的代码文件
    3. 以 dev-agent 角色实现修复（仅修改受影响代码）
    4. 运行构建命令验证修复，确认 0 错误
    5. 完成后 → 直接跳至 4.2（跳过重新实现里程碑）
  else:
    1. 读取 docs/plans/active/{feature}.md 中的里程碑列表
    2. 读取对应 .claude/agents/（dev-agent 或技术栈特定 agent）
    3. 逐里程碑实现（仅执行状态为 pending 的里程碑，done 的跳过）：
       a. 编写代码
       b. 运行验证命令（exec-plan 中定义的验收命令）
       c. 通过 → 更新里程碑状态为 done
       d. 失败 → 修复 → 重试（单里程碑最多 3 次）
    4. 所有里程碑完成（done） → 进入 4.2

  5. 更新 stage-status.json: subStage=coding

  ── 4.2 Code Review ──

  internal_cr_retry = 0  // CRITICAL 内部重试计数

  CR_START:
    1. 读取 .claude/agents/reviewer-agent.md
    2. 审查范围：
       - Round 1：审查所有变更文件
       - Round N>1：审查本轮新增/修改的文件（增量审查），并对已修改模块运行全量测试
    3. 以 reviewer 角色执行两阶段审查（参见 reviewer-agent.md 执行步骤）
    4. 输出问题清单（CRITICAL/HIGH/MEDIUM/LOW）
    5. 记录所有 HIGH/MEDIUM/LOW 问题到 workspace/code-review-log.md（OPEN 状态）
    6. 更新 stage-status.json: subStage=code-review
    7. 更新 metrics.crCriticalCount += 本次发现的 CRITICAL 数
       更新 metrics.crHighCount += 本次发现的 HIGH 数

  // CRITICAL 处理
  if 有 CRITICAL:
    internal_cr_retry += 1
    if internal_cr_retry > 3:
      // CRITICAL 内部重试超限，提升为新轮次
      记录错误到 stage-status.json errors 数组
      当前轮次 += 1
      restart_type = FULL
      GOTO LOOP
    → 将 CRITICAL 问题反馈给 dev-agent 修复
    → 修复后 GOTO CR_START（内部重试，不算新轮次）

  // HIGH 处理（必须明确决策，不能静默略过）
  if 有 HIGH（reviewer 结论为 APPROVED_WITH_HIGH）:
    对每个 HIGH 问题，必须在此处做出明确决策：
    A. 立即修复 → 派发 dev-agent 修复 → 将 code-review-log.md 该条改为 RESOLVED → 重新执行 CR_START
    B. 登记为 tracked debt → 在 code-review-log.md 记录处理计划（哪次迭代修复）
       → 仅当所有 HIGH 都有明确处理计划时，才可继续 4.3
    （不可静默记录后就直接继续，必须有决策结论）

  // 无 CRITICAL，HIGH 已决策 → 进入 4.3
  无 CRITICAL 且 HIGH 已决策 → 进入 4.3

  ── 4.3 Testing ──
  1. 读取 .claude/agents/qa-agent.md（模式 B）
  2. 读取 docs/specs/{feature}/test-cases.md
  3. 逐条执行测试用例（P0 全部必须执行，不可跳过）
  4. 输出覆盖矩阵（必须包含每条用例的执行状态）
  5. 更新 stage-status.json: subStage=testing

  // 测试覆盖完整性门禁（必须通过才能继续）
  COVERAGE_CHECK:
    - 覆盖矩阵中是否有未执行的 P0 用例（状态为 pending/not-executed）？
      → 有 → 必须执行，不可跳过（除非记录物理上无法执行的原因）
    - 是否所有 P0 用例均为 PASS？
      → 否（有 P0 FAIL）→ 执行 BUG_FIX 流程（见下方）
      → 否（有 P0 BLOCKED）→ 记录阻塞原因，视情况继续或请求人工介入
    - P1/P2 FAIL 用例 → 记录到 workspace/code-review-log.md，继续
  // 覆盖矩阵完整且无 P0 Bug → 进入 4.4

  if 有 P0 Bug:
    → 将 Bug 描述记录到 stage-status.json errors 数组
    → 当前轮次 += 1
    → restart_type = BUG_FIX
    → GOTO LOOP

  if 无 P0 Bug 且覆盖矩阵完整 → 进入 4.4

  ── 4.4 Acceptance ──
  1. 读取 .claude/agents/arch-agent.md（模式 B）执行技术验收：
     - 实现是否符合 tech.md 设计？
     - 分层是否合规？
  2. 读取 .claude/agents/pm-agent.md（模式 C）执行功能验收：
     - AC 是否全部满足？
     - 用户流程是否正确？
  3. 更新 stage-status.json: subStage=acceptance

  if 验收不通过:
    // 验收失败必须输出失败分类，不允许模糊返回
    验收 agent 必须明确输出以下之一：

    类型A：实现 Bug（代码与设计一致，但实现有错误）
      → 将 Bug 描述记录到 errors 数组
      → restart_type = BUG_FIX（不 +1 轮次）
      → GOTO LOOP（直接跳到 4.2，跳过 Coding）

    类型B：设计缺口（tech.md 设计不足以实现 AC）
      → arch-agent 更新 tech.md 和 exec-plan（新增里程碑）
      → restart_type = DESIGN_GAP
      → 当前轮次 += 1
      → GOTO LOOP

    类型C：需求分歧（pm-agent 认为 AC 与用户真实意图不符）
      → 立即暂停（不消耗轮次）
      → 更新 stage-status.json: status=waiting_approval
      → 使用 AskUserQuestion 请求人工澄清需求
      → 人工澄清后：根据结果决定回退到 P2/P3 还是继续 P4

  5. 全部通过 → EXIT LOOP
```

## 退出条件（全部满足）

- ✅ 构建成功（0 errors）
- ✅ Code Review：无 CRITICAL，HIGH 问题已明确处理
- ✅ 测试覆盖矩阵完整，P0 用例全部 PASS
- ✅ 技术验收通过（arch-agent 模式B）
- ✅ 功能验收通过（pm-agent 模式C）

## 钢铁律令（Iron Law）

**声称完成 = 必须提供当前会话内刚运行的验证命令输出**

BEFORE 声称任何阶段完成，按顺序执行以下五步，缺一步均为无效声明：

```
1. IDENTIFY：哪个命令能证明这个声明？（写出命令）
2. RUN：在当前会话内执行完整命令（不是上次的输出，不是记忆）
3. READ：读取全部输出，检查退出码（exit 0 = 成功，非 0 = 失败）
4. VERIFY：输出确认声明吗？
   - 否 → 陈述实际状态 + 附原始输出
   - 是 → 给出声明 + 附带完整证据
5. ONLY THEN 声明完成
```

**跳过任意步骤 = 谎报，不是验证。无例外。**

- 上次运行成功 ≠ 当前成功。必须在当前会话重新运行。
- "应该能通过" ≠ 通过。必须运行看到实际输出。
- 超时/环境不可用 = 阻塞项，必须上报，不得绕过。

---

## 完成验证铁律

声称满足退出条件时，**必须提供实际证据**（不是声明，是证据）：

| 退出条件 | 需要的证据 |
|---------|-----------|
| 构建成功 | 贴出构建命令的实际终端输出（包含 "BUILD SUCCESS" 或 "0 errors"） |
| Code Review 通过 | 引用 reviewer-agent 的具体审查结论（APPROVED 或 APPROVED_WITH_HIGH + 处理决策） |
| 测试覆盖完整且 P0 全通过 | 贴出覆盖矩阵 + 测试命令实际终端输出（包含 "X passed, 0 failed"） |
| 技术验收通过 | 引用 arch-agent 的验收结论 |
| 功能验收通过 | 引用 pm-agent 的验收结论 |

**"如果不能提供证据，就不算完成。"**

## 退出后

更新 stage-status.json:
- stage=implementation, status=completed
- metrics.loopRoundTotal = 最终使用的轮次数
通知编排者：Close-Loop 完成，可进入 P5 收尾。
