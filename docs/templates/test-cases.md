# {功能名称} — 测试用例
<!-- template-version: 1 -->

## Meta
- status: draft | reviewed | executed
- created: {YYYY-MM-DD}
- author: qa-agent
- traces_to:
  - upstream:
    - test-plan: docs/specs/{feature}/test-plan.md
    - requirement: docs/specs/{feature}/requirement.md
  - downstream: （测试执行后更新覆盖矩阵）

---

## 单元/集成测试用例

| 用例ID | 模块 | 前置条件 | 操作步骤 | 预期结果 | 优先级 | 状态 |
|--------|------|---------|---------|---------|--------|------|
| TC-001 | {模块名} | {前置条件描述} | 1. {步骤1} 2. {步骤2} | {预期结果} | P0 | pending |
| TC-002 | | | | | P1 | pending |

### 优先级说明
- **P0**: 核心功能，阻塞发布，不可跳过
- **P1**: 重要功能，应修复，可记录后继续
- **P2**: 边缘场景，可延后处理

### 状态说明
- **pending**: 待执行
- **pass**: 通过
- **fail**: 失败（需记录错误信息）
- **skip**: 跳过（需记录原因，P0 用例不可跳过）
- **blocked**: 被阻塞（需记录阻塞原因）

### 测试类型说明
- **unit**: 单元测试，使用 Bash 执行测试框架命令
- **integration**: 集成/API 测试，使用 Bash 执行
- **e2e**: 端到端测试，使用 Playwright MCP 或生成 Playwright 脚本执行

### 执行策略说明
- **Prong A**: MCP 直接执行，适合步骤 <= 5 的简单验证流（快速反馈，不生成文件）
- **Prong B**: 生成 `.spec.ts` 脚本后执行，适合复杂场景（可纳入 CI/CD 回归）

---

## E2E 测试用例

| 用例ID | 模块 | start_url | 前置条件 | 执行策略 | 优先级 | 状态 |
|--------|------|-----------|---------|---------|--------|------|
| TC-E-001 | {模块名} | http://localhost:{port}/{path} | {前置条件} | Prong A / Prong B | P0 | pending |

### TC-E-001: {用例标题}

**start_url**: `http://localhost:{port}/{path}`

**e2e_steps**:
1. `{ "action": "navigate", "url": "{start_url}", "description": "打开页面" }`
2. `{ "action": "click", "selector": "[data-testid='xxx']", "description": "点击按钮" }`
3. `{ "action": "type", "selector": "#input-field", "value": "test value", "description": "输入内容" }`
4. `{ "action": "wait", "text": "预期文本", "description": "等待结果出现" }`

**expected_dom_state**:
- `{ "selector": "[data-testid='result']", "assert": "visible", "text": "预期文本" }`
- `{ "selector": "[data-testid='error']", "assert": "hidden" }`

**执行策略**: Prong A（步骤 <= 5，适合 MCP 直接验证）

<!-- 复制以上块为每个 E2E 用例创建详细定义 -->

---

## 覆盖矩阵

> 测试执行后，汇总覆盖情况。

| AC 编号 | AC 描述 | 关联用例 | 覆盖状态 |
|---------|---------|---------|---------|
| AC-1 | {验收标准描述} | TC-001, TC-003 | covered / not-covered |

---

## Feedback Log
