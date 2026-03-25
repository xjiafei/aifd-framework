---
paths: ["src/**", "lib/**", "app/**", "backend/**", "frontend/**", "api/**", "pkg/**", "internal/**", "cmd/**", "routers/**"]
---

# 架构编码规范

> 本规范在编辑上述路径下的代码文件时自动加载。详细架构规范和本项目的分层映射见 `docs/architecture.md`。

## 四条核心原则

### P1 单向依赖（禁止反向）

本项目的具体分层见 `docs/architecture.md` § 分层映射。通用规则：
- 外层可以依赖内层，内层**不得**依赖外层
- 禁止循环依赖（A → B → A）
- 同层谨慎互引，避免形成隐式循环

**违规示例**（Java 上下文）：
- Service 层 import Controller/Request 类 → CRITICAL
- Repository 层 import Service 类 → CRITICAL

**违规示例**（Python FastAPI 上下文）：
- `service/` import `routers/` → CRITICAL
- `models/` import `services/` → CRITICAL

**违规示例**（Go 上下文）：
- `internal/service` import `internal/handler` → CRITICAL

### P2 边界校验

当外部数据（HTTP Request、消息队列消息、用户输入）进入系统时：
- **必须**在边界层（Controller / Handler / Router）完成校验和类型转换
- **禁止**在业务逻辑层（Service / UseCase）直接处理原始外部数据

## 统一错误模型

所有错误必须封装为统一格式，三要素缺一不可：

```json
{
  "code": "模块前缀_错误类型",
  "message": "人类可读的错误描述",
  "details": {}
}
```

**错误码前缀规范**：
- `AUTH_` — 认证/授权相关
- `VALIDATION_` — 输入校验相关
- `BIZ_` — 业务逻辑相关
- `SYS_` — 系统/基础设施相关

**禁止**：裸抛 `Error` 或字符串错误，必须包含 code + message + details。

## 不可变原则

- 函数应返回新对象，不修改传入参数
- 避免全局状态变更
- 有状态操作需有明确的事务边界

## 文件规模控制

- 单文件建议 200-400 行，超过 600 行须拆分
- 函数/方法建议不超过 50 行
- 按功能/领域组织文件，不按类型（models/、services/ 等命名是组织方式，不是职责边界）
