# 系统架构设计

## 技术栈

| 类别 | 技术选型 | 版本 | 用途 |
|------|---------|------|------|
| 框架 | Spring Boot | 2.7.x | 应用框架 |
| ORM | MyBatis-Plus | 3.5.x | 数据访问层 |
| 数据库 | MySQL | 8.0 | 主数据存储 |
| 缓存 | Redis | 6.x | 缓存 + 分布式锁 + Session |
| 消息队列 | Kafka | 3.x | 异步消息、事件驱动 |
| 构建工具 | Maven | 3.8+ | 依赖管理、构建 |
| JDK | OpenJDK | 11 / 17 | 运行时环境 |

## 分层架构

```
┌──────────────────────────────────────────────┐
│                  客户端请求                     │
└────────────────────┬─────────────────────────┘
                     ▼
┌──────────────────────────────────────────────┐
│  Controller 层（接入层）                        │
│  - 参数校验（JSR-303）                          │
│  - 路由映射                                    │
│  - 请求/响应转换（VO ↔ DTO）                    │
│  - 统一响应封装                                 │
└────────────────────┬─────────────────────────┘
                     ▼
┌──────────────────────────────────────────────┐
│  Service 层（业务层）                           │
│  - 业务逻辑编排                                 │
│  - 事务管理（@Transactional）                   │
│  - 缓存管理                                    │
│  - 消息发送                                    │
└────────────────────┬─────────────────────────┘
                     ▼
┌──────────────────────────────────────────────┐
│  Mapper 层（数据访问层）                        │
│  - MyBatis-Plus BaseMapper                   │
│  - XML Mapper（复杂查询）                       │
│  - 数据库交互                                  │
└────────────────────┬─────────────────────────┘
                     ▼
┌──────────────────────────────────────────────┐
│  Model 层（数据模型）                           │
│  - Entity（数据库实体）                         │
│  - DTO（层间传输对象）                          │
│  - VO（接口响应对象）                           │
│  - Query（查询参数对象）                        │
└──────────────────────────────────────────────┘
```

### DTO / VO 分离原则

- **Entity**：与数据库表一一对应，不直接暴露给前端
- **DTO（Data Transfer Object）**：Service 层之间传递数据，或接收前端请求参数
- **VO（View Object）**：Controller 返回给前端的数据结构，按页面需求裁剪字段
- **Query**：封装分页、排序、筛选等查询条件

## Maven 多模块结构

```
project-root/
├── pom.xml                          # 父 POM，统一依赖版本管理
├── project-common/                  # 公共模块
│   ├── pom.xml
│   └── src/main/java/
│       └── com/example/common/
│           ├── config/              # 公共配置
│           ├── constant/            # 常量定义
│           ├── enums/               # 枚举类
│           ├── exception/           # 异常体系
│           │   ├── BaseException.java
│           │   ├── BusinessException.java
│           │   └── ErrorCode.java
│           ├── result/              # 统一响应
│           │   └── Result.java
│           └── util/                # 工具类
├── project-api/                     # API 接口模块（对外暴露）
│   ├── pom.xml
│   └── src/main/java/
│       └── com/example/api/
│           ├── controller/          # Controller 层
│           ├── dto/                 # 请求 DTO
│           └── vo/                  # 响应 VO
├── project-service/                 # 业务逻辑模块
│   ├── pom.xml
│   └── src/main/java/
│       └── com/example/service/
│           ├── impl/               # Service 实现
│           └── converter/          # 对象转换器（MapStruct）
├── project-dao/                     # 数据访问模块
│   ├── pom.xml
│   └── src/main/java/
│       └── com/example/dao/
│           ├── entity/             # 数据库实体
│           ├── mapper/             # MyBatis Mapper 接口
│           └── mapper/xml/         # MyBatis XML 映射文件
└── project-boot/                    # 启动模块
    ├── pom.xml
    └── src/main/
        ├── java/
        │   └── com/example/
        │       └── Application.java
        └── resources/
            ├── application.yml
            ├── application-dev.yml
            ├── application-prod.yml
            └── logback-spring.xml
```

### 模块依赖关系

```
project-boot → project-api → project-service → project-dao → project-common
```

每个模块只依赖其下层模块，禁止反向依赖或跨层依赖。

## 数据库约定

### 表命名

- 表名使用 `lower_snake_case`，如 `user_account`、`order_item`
- 业务表加业务前缀，如 `biz_order`、`sys_config`
- 关联表命名：`{表A}_{表B}_rel`，如 `user_role_rel`

### 索引命名

| 类型 | 命名规则 | 示例 |
|------|---------|------|
| 主键 | `pk_{表名}` | `pk_user_account` |
| 唯一索引 | `uk_{表名}_{字段}` | `uk_user_account_email` |
| 普通索引 | `idx_{表名}_{字段}` | `idx_order_create_time` |
| 联合索引 | `idx_{表名}_{字段1}_{字段2}` | `idx_order_user_id_status` |

### 通用字段

每张业务表必须包含以下字段：

```sql
id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键ID',
created_by  VARCHAR(64)  DEFAULT NULL COMMENT '创建人',
created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
updated_by  VARCHAR(64)  DEFAULT NULL COMMENT '更新人',
updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
deleted     TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '逻辑删除(0=未删除,1=已删除)',
version     INT          NOT NULL DEFAULT 0 COMMENT '乐观锁版本号'
```

### 字段类型约定

| 数据类型 | MySQL 字段类型 | Java 类型 |
|---------|---------------|----------|
| 主键 | `BIGINT` | `Long` |
| 金额 | `DECIMAL(18,2)` | `BigDecimal` |
| 时间 | `DATETIME` | `LocalDateTime` |
| 布尔 | `TINYINT(1)` | `Boolean` |
| 短文本 | `VARCHAR(n)` | `String` |
| 长文本 | `TEXT` | `String` |
| 枚举/状态 | `TINYINT` / `SMALLINT` | `Integer` + 枚举类 |

## API 约定

### RESTful 路径规范

```
GET    /api/v1/users          # 查询用户列表（分页）
GET    /api/v1/users/{id}     # 查询单个用户
POST   /api/v1/users          # 创建用户
PUT    /api/v1/users/{id}     # 更新用户（全量）
PATCH  /api/v1/users/{id}     # 更新用户（部分字段）
DELETE /api/v1/users/{id}     # 删除用户
```

- 路径使用 `kebab-case`，如 `/api/v1/user-accounts`
- 版本号放在路径中：`/api/v1/`、`/api/v2/`
- 资源名使用复数形式

### 统一响应格式

```json
{
  "code": 200,
  "message": "操作成功",
  "data": { },
  "timestamp": 1700000000000
}
```

**分页响应格式：**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [],
    "total": 100,
    "page": 1,
    "size": 20
  },
  "timestamp": 1700000000000
}
```

### HTTP 状态码使用

| 状态码 | 含义 | 使用场景 |
|--------|------|---------|
| 200 | 成功 | 查询、更新成功 |
| 201 | 已创建 | 创建资源成功 |
| 400 | 请求错误 | 参数校验失败 |
| 401 | 未认证 | 未登录或 Token 过期 |
| 403 | 无权限 | 权限不足 |
| 404 | 未找到 | 资源不存在 |
| 500 | 服务器错误 | 系统内部异常 |

## 错误处理

### 全局异常处理器

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public Result<?> handleBusinessException(BusinessException e) {
        return Result.fail(e.getCode(), e.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public Result<?> handleValidationException(MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getFieldErrors().stream()
            .map(FieldError::getDefaultMessage)
            .collect(Collectors.joining(", "));
        return Result.fail(ErrorCode.PARAM_ERROR.getCode(), message);
    }

    @ExceptionHandler(Exception.class)
    public Result<?> handleException(Exception e) {
        log.error("系统异常", e);
        return Result.fail(ErrorCode.SYSTEM_ERROR);
    }
}
```

### 错误码枚举

```java
public enum ErrorCode {
    SUCCESS(200, "操作成功"),
    PARAM_ERROR(400, "参数错误"),
    UNAUTHORIZED(401, "未认证"),
    FORBIDDEN(403, "无权限"),
    NOT_FOUND(404, "资源不存在"),
    SYSTEM_ERROR(500, "系统内部错误"),

    // 业务错误码：模块前缀 + 序号
    USER_NOT_FOUND(10001, "用户不存在"),
    USER_ALREADY_EXISTS(10002, "用户已存在"),
    ORDER_STATUS_INVALID(20001, "订单状态不合法"),
    ;

    private final int code;
    private final String message;
}
```

错误码分配规则：
- `200`：成功
- `400-499`：客户端错误
- `500-599`：系统错误
- `10000-19999`：用户模块业务错误
- `20000-29999`：订单模块业务错误
- 以此类推，每个业务模块分配一个万位段

## 日志规范

### 技术选型

使用 SLF4J + Logback，通过 `logback-spring.xml` 配置。

### 日志级别使用规范

| 级别 | 使用场景 |
|------|---------|
| `ERROR` | 系统异常、不可恢复的错误 |
| `WARN` | 可恢复的异常、需要关注的情况 |
| `INFO` | 关键业务操作（创建、更新、删除）、外部调用 |
| `DEBUG` | 调试信息，生产环境关闭 |

### 结构化日志字段

所有日志必须包含以下上下文信息：

```java
// 使用 MDC 设置请求级上下文
MDC.put("traceId", traceId);
MDC.put("userId", userId);
MDC.put("requestUri", requestUri);

// 日志输出示例
log.info("创建订单成功, orderId: {}, userId: {}, amount: {}", orderId, userId, amount);
```

### Logback 配置要点

```xml
<pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] [%X{traceId}] [%X{userId}] %-5level %logger{36} - %msg%n</pattern>
```

- 日志文件按天滚动，保留 30 天
- 单文件最大 200MB
- 异步写入，避免阻塞业务线程
- 生产环境日志级别为 `INFO`，禁止开启 `DEBUG`
