# E2E 测试模式 — Playwright MCP + 脚本生成

## Meta
- **类型**：设计模式
- **适用场景**：包含前端 UI 的全栈项目需要进行端到端测试时
- **关键词**：E2E, Playwright, MCP, 端到端测试, 浏览器测试, 自动化测试
- **创建时间**：2026-03-26
- **来源功能**：框架增强 — E2E 测试集成

---

## 模式描述

AIFD 框架使用两种互补的 E2E 测试执行策略，在 P4 Testing 阶段的 Tier 3 中执行。

### Prong A — MCP 直接执行

通过 Playwright MCP 工具在 qa-agent 执行过程中直接操作浏览器。

**适用条件**：
- 步骤数 <= 5
- 不涉及复杂断言（像素对比、性能指标）
- 烟雾测试和简单功能验证

**优势**：即时反馈、无需额外文件、快速迭代
**局限**：不可在 CI/CD 中重放、不适合复杂场景

**MCP 工具调用序列模板**：
```
1. browser_navigate(url=start_url)
2. browser_snapshot() → 获取页面快照和元素 ref
3. 对每个 e2e_step：
   - click: browser_click(ref=快照中的元素ref, element="描述")
   - type: browser_type(ref=快照中的元素ref, text="输入值")
   - wait: browser_wait_for(text="等待文本")
   - 每步操作后: browser_snapshot() → 获取新 ref 用于下一步
4. browser_snapshot() → 最终快照
5. 比对最终快照中的文本/元素与 expected_dom_state
```

**关键约束**：
- 每次交互前必须先 browser_snapshot 获取最新 ref（ref 在页面变化后会失效）
- 使用 browser_wait_for 确保页面状态稳定后再断言

### Prong B — 生成 Playwright 脚本

qa-agent 根据 test-cases.md 中的 E2E 用例生成 `.spec.ts` 文件。

**适用条件**：
- 步骤数 > 5
- 涉及循环/条件逻辑、多页面导航、文件上传
- 需要在 CI/CD 中持续回归

**优势**：可重复执行、CI/CD 集成、版本控制
**局限**：生成后需维护选择器、首次执行较慢

**Playwright .spec.ts 生成模板**：
```typescript
import { test, expect } from '@playwright/test';

test('{TC-ID}: {用例描述}', async ({ page }) => {
  // 前置条件
  await page.goto('{start_url}');

  // 执行步骤（从 e2e_steps 逐条生成）
  await page.locator('{selector}').click();
  await page.locator('{selector}').fill('{value}');
  await page.getByText('{text}').waitFor();

  // 断言（从 expected_dom_state 逐条生成）
  await expect(page.locator('{selector}')).toBeVisible();
  await expect(page.locator('{selector}')).toHaveText('{expected_text}');
});
```

### 服务生命周期管理

E2E 测试需要真实运行的前后端服务。标准流程：

```
STARTUP:
  1. 后台启动后端: Bash run_in_background → 记录进程信息
  2. 健康检查轮询（每 5 秒，最多 startup_timeout_seconds）:
     curl -sf {backend_health_url}
     - 成功 → 继续
     - 超时 → 所有 E2E 用例标记 BLOCKED，附日志最后 50 行
  3. 后台启动前端: Bash run_in_background → 记录进程信息
  4. 前端健康检查:
     browser_navigate({frontend_url}) + browser_snapshot()
     - 页面加载成功 → 继续
     - 失败 → 所有 E2E 用例标记 BLOCKED

TEARDOWN（无条件执行，即使测试全部 FAIL）:
  1. 停止前端和后端进程
  2. browser_close() 关闭浏览器
```

**关键约束**：
- TEARDOWN 是无条件执行的，即使测试全部 FAIL 也必须执行
- 健康检查超时 = 所有 E2E 用例标记 BLOCKED（不是 SKIP 或 PASS）
- 进程信息必须记录，确保可靠清理

---

## E2E 用例格式规范

E2E 用例在 test-cases.md 中需要以下额外字段：

| 字段 | 说明 | 示例 |
|------|------|------|
| start_url | 起始页面 URL | `http://localhost:5173/` |
| e2e_steps | 结构化步骤列表 | JSON 格式的 action/selector/value |
| expected_dom_state | 断言列表 | JSON 格式的 selector/assert/text |
| 执行策略 | Prong A 或 Prong B | 根据步骤复杂度选择 |

### e2e_steps action 类型

| action | 参数 | 对应 MCP 工具 |
|--------|------|-------------|
| navigate | url | browser_navigate |
| click | selector | browser_click |
| type | selector, value | browser_type |
| press | key | browser_press_key |
| wait | text | browser_wait_for |
| fill_form | fields[] | browser_fill_form |
| select | selector, values | browser_select_option |
| screenshot | filename | browser_take_screenshot |

### expected_dom_state assert 类型

| assert | 含义 | Playwright 等价 |
|--------|------|----------------|
| visible | 元素可见 | toBeVisible() |
| hidden | 元素不可见 | toBeHidden() |
| text | 元素包含指定文本 | toHaveText() / toContainText() |
| count | 元素数量匹配 | toHaveCount() |

---

## 使用指南

1. **P3 阶段**：qa-agent 模式 A 规划 E2E 用例（从 product.md 用户流程识别关键路径）
2. **P3 阶段**：在 test-plan.md 填写 E2E 测试环境配置和用例分配
3. **P3 阶段**：在 test-cases.md 按格式编写 E2E 用例详细定义
4. **P4 Testing**：qa-agent 模式 B 按 Tier 3 执行（Tier 1-2 通过后）
5. **P4 Testing**：Prong B 生成的脚本保存在 `testing/e2e/{feature}/` 目录
6. **P5 GC**：E2E 脚本随代码一起 git commit
7. **CI/CD**：devops-agent 在流水线中加入 E2E 测试阶段
