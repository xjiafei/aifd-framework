<!-- template-version: 1 -->
# 测试计划文档

## Meta

| 字段 | 值 |
|------|-----|
| status | draft |
| traces_to | upstream: design: docs/specs/{feature}/tech.md, requirement: docs/specs/{feature}/requirement.md; downstream: test-cases: docs/specs/{feature}/test-cases.md |
| created | YYYY-MM-DD |
| author | |
| last_updated | YYYY-MM-DD |

---

## 测试策略

<!-- 定义各层级测试的范围和目标 -->

### 单元测试

**范围：**

<!-- 需要覆盖的模块和函数 -->

-

**目标：**

<!-- 覆盖率目标、关键逻辑验证点 -->

-

### 集成测试

**范围：**

<!-- 需要验证的模块间交互和数据流 -->

-

**目标：**

<!-- 接口契约验证、数据一致性验证 -->

-

### 端到端测试（E2E）

**范围：**

<!-- 需要覆盖的用户场景和关键流程（从 product.md 用户流程图识别） -->

-

**目标：**

<!-- 用户体验验证、全链路功能验证、跨服务集成验证 -->

-

**E2E 执行策略：**

| 策略 | 适用场景 | 工具 | 产出物 |
|------|---------|------|--------|
| Prong A — MCP 直接 | 简单流（<= 5 步）、烟雾测试 | Playwright MCP 工具 | 快照验证记录（写入 test-report.md） |
| Prong B — 生成脚本 | 复杂流（> 5 步）、回归测试 | Playwright Test | `testing/e2e/{feature}/*.spec.ts`（纳入 CI/CD） |

**E2E 测试环境配置：**

| 配置项 | 值 |
|--------|-----|
| backend_start_cmd | <!-- 后端启动命令，如 cd ../app/backend && mvn spring-boot:run --> |
| frontend_start_cmd | <!-- 前端启动命令，如 cd ../app/frontend && npm run dev --> |
| backend_health_url | <!-- 健康检查 URL，如 http://localhost:8080/actuator/health --> |
| frontend_url | <!-- 前端地址，如 http://localhost:5173 --> |
| startup_timeout_seconds | 120 |

**E2E 用例分配：**

| 用例ID | 描述 | 执行策略 | 理由 |
|--------|------|---------|------|
| TC-E-001 | | Prong A / Prong B | |

---

## AC → 测试映射

<!-- 将每条验收标准映射到具体的测试用例，确保完整覆盖 -->

| AC 编号 | AC 描述 | 测试类型 | 执行方式 | 测试文件/函数 | 状态 |
|---------|---------|----------|---------|--------------|------|
| AC-1 | | 单元/集成/E2E | Bash / Prong A / Prong B | `path/to/test::test_name` | 未编写/已编写/已通过/已失败 |
| AC-2 | | 单元/集成/E2E | Bash / Prong A / Prong B | `path/to/test::test_name` | 未编写/已编写/已通过/已失败 |
| AC-3 | | 单元/集成/E2E | Bash / Prong A / Prong B | `path/to/test::test_name` | 未编写/已编写/已通过/已失败 |

---

## 集成验证

<!-- 针对多仓库场景的跨服务集成验证 -->

| 验证项 | 涉及服务 | 验证方法 | 预期结果 |
|--------|----------|----------|----------|
| | | 自动化测试/手动验证/脚本检查 | |
| | | 自动化测试/手动验证/脚本检查 | |

---

## 测试执行命令

<!-- 提供一行命令运行所有相关测试 -->

```bash
# 运行全部相关测试
{测试执行命令}

# 运行 E2E 测试（Prong B 脚本）
npx playwright test testing/e2e/{feature}/ --reporter=json
```

---

## 验收结论

<!-- 在所有测试完成后逐项确认 -->

- [ ] 所有 AC 对应的测试已编写
- [ ] 所有测试通过
- [ ] traces_to 链条完整
- [ ] 文档已同步

---

## Feedback Log

<!-- 记录来自上游（需求规格、设计）的反馈，用于追溯和持续改进 -->

| 日期 | 来源 | 反馈内容 | 处理结果 |
|------|------|----------|----------|
| | | | |
