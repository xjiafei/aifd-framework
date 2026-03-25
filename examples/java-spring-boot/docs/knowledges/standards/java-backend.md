# Java 后端编码规范

## 命名规范

### Java 代码命名

| 类别 | 风格 | 示例 |
|------|------|------|
| 类名 | PascalCase | `UserService`, `OrderController`, `PaymentResultVO` |
| 方法名 | camelCase | `getUserById`, `createOrder`, `validateParams` |
| 变量名 | camelCase | `userName`, `orderList`, `pageSize` |
| 常量 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT`, `DEFAULT_PAGE_SIZE` |
| 枚举值 | UPPER_SNAKE_CASE | `ORDER_CREATED`, `PAYMENT_SUCCESS` |
| 包名 | 全小写 | `com.example.service.impl` |

### 类命名后缀约定

| 层级 | 后缀 | 示例 |
|------|------|------|
| Controller | `Controller` | `UserController` |
| Service 接口 | `Service` | `UserService` |
| Service 实现 | `ServiceImpl` | `UserServiceImpl` |
| Mapper | `Mapper` | `UserMapper` |
| Entity | 无后缀 / `Entity` | `User`, `UserEntity` |
| DTO | `DTO` | `UserCreateDTO`, `UserUpdateDTO` |
| VO | `VO` | `UserDetailVO`, `UserListVO` |
| Query | `Query` | `UserPageQuery` |
| 枚举 | `Enum` | `OrderStatusEnum` |
| 常量 | `Constants` | `CommonConstants` |

### 数据库字段命名

- 字段名使用 `lower_snake_case`：`user_name`, `created_at`, `order_status`
- 布尔字段使用 `is_` 前缀：`is_active`, `is_deleted`（但 Java Entity 中映射为不带 `is_` 的字段名）
- 外键字段使用 `{关联表}_id`：`user_id`, `order_id`

## 分层规范

### Controller 层

**职责**：参数校验 + 路由映射 + 响应封装

```java
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @PostMapping
    public Result<UserDetailVO> createUser(@RequestBody @Valid UserCreateDTO dto) {
        return Result.success(userService.createUser(dto));
    }
}
```

**规则**：
- 禁止在 Controller 中编写业务逻辑
- 禁止在 Controller 中直接调用 Mapper
- 使用 `@Valid` / `@Validated` 触发参数校验
- 返回值统一使用 `Result<T>` 包装

### Service 层

**职责**：业务逻辑 + 事务管理

```java
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserMapper userMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public UserDetailVO createUser(UserCreateDTO dto) {
        // 1. 业务校验
        if (userMapper.existsByEmail(dto.getEmail())) {
            throw new BusinessException(ErrorCode.USER_ALREADY_EXISTS);
        }
        // 2. 构建实体
        User user = UserConverter.INSTANCE.toEntity(dto);
        // 3. 持久化
        userMapper.insert(user);
        // 4. 返回 VO
        return UserConverter.INSTANCE.toDetailVO(user);
    }
}
```

**规则**：
- 所有业务逻辑写在 Service 层
- 写操作使用 `@Transactional(rollbackFor = Exception.class)`
- 只读操作使用 `@Transactional(readOnly = true)`
- Service 之间可以互相调用，但注意避免循环依赖
- 禁止在 Service 中出现 `HttpServletRequest`、`HttpServletResponse` 等 Web 层对象

### Mapper 层

**职责**：数据访问

```java
@Mapper
public interface UserMapper extends BaseMapper<User> {

    // 简单查询：使用 MyBatis-Plus 注解
    @Select("SELECT COUNT(*) > 0 FROM user WHERE email = #{email} AND deleted = 0")
    boolean existsByEmail(@Param("email") String email);

    // 复杂查询：使用 XML mapper
    List<UserDetailVO> selectUserWithRoles(@Param("query") UserPageQuery query);
}
```

**规则**：
- 继承 `BaseMapper<T>`，利用 MyBatis-Plus 内置 CRUD
- 简单单表查询使用注解方式
- 多表 JOIN、动态条件、子查询等复杂 SQL 使用 XML mapper
- 禁止在 Mapper 中编写业务逻辑

### Model 层

**职责**：数据结构定义

```java
@Data
@TableName("user")
public class User {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String userName;
    private String email;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    @TableLogic
    private Integer deleted;
    @Version
    private Integer version;
}
```

## MyBatis 规范

### 简单 CRUD — 使用 MyBatis-Plus 内置方法

```java
// 插入
userMapper.insert(user);

// 根据 ID 查询
User user = userMapper.selectById(id);

// 条件查询
List<User> users = userMapper.selectList(
    new LambdaQueryWrapper<User>()
        .eq(User::getStatus, status)
        .orderByDesc(User::getCreatedAt)
);

// 分页查询
Page<User> page = userMapper.selectPage(
    new Page<>(pageNum, pageSize),
    new LambdaQueryWrapper<User>().eq(User::getStatus, 1)
);
```

### 复杂查询 — 使用 XML Mapper

```xml
<!-- UserMapper.xml -->
<select id="selectUserWithRoles" resultType="com.example.api.vo.UserDetailVO">
    SELECT u.id, u.user_name, u.email, r.role_name
    FROM user u
    LEFT JOIN user_role_rel ur ON u.id = ur.user_id
    LEFT JOIN role r ON ur.role_id = r.id
    WHERE u.deleted = 0
    <if test="query.userName != null and query.userName != ''">
        AND u.user_name LIKE CONCAT('%', #{query.userName}, '%')
    </if>
    <if test="query.status != null">
        AND u.status = #{query.status}
    </if>
    ORDER BY u.created_at DESC
</select>
```

### MyBatis 安全规则

- **必须使用 `#{}`**（预编译参数），禁止使用 `${}` 拼接 SQL
- 唯一例外：动态表名、动态排序字段可用 `${}`，但必须在代码层做白名单校验

## 异常处理

### 异常体系

```
Exception
 └── RuntimeException
      └── BaseException              # 基础异常（抽象类）
           ├── BusinessException     # 业务异常（可预期）
           ├── AuthException         # 认证/授权异常
           └── RemoteCallException   # 远程调用异常
```

### 使用规范

- **业务异常**：使用 `BusinessException`，携带错误码和错误信息
- **系统异常**：不要捕获后吞掉，让全局异常处理器统一处理
- **禁止**：`catch (Exception e) {}` 空 catch 块
- **禁止**：在 Service 层使用 `try-catch` 包裹整个方法体（会影响事务回滚）

```java
// 正确：抛出业务异常
if (user == null) {
    throw new BusinessException(ErrorCode.USER_NOT_FOUND);
}

// 错误：吞掉异常
try {
    userMapper.insert(user);
} catch (Exception e) {
    // 什么都不做 ← 严禁！
}
```

### 全局异常处理器

使用 `@RestControllerAdvice` + `@ExceptionHandler` 统一捕获异常，返回标准响应格式。参考 `architecture.md` 中的示例。

## 事务管理

### 基本规则

```java
// 写操作 — 需要事务
@Transactional(rollbackFor = Exception.class)
public void createOrder(OrderCreateDTO dto) { ... }

// 只读操作 — 只读事务
@Transactional(readOnly = true)
public OrderDetailVO getOrderById(Long id) { ... }

// 不需要事务的操作 — 不加注解
public String generateOrderNo() { ... }
```

### 注意事项

- `@Transactional` 仅在 **public** 方法上生效
- 同一个类中方法互调，被调方法的 `@Transactional` **不生效**（Spring AOP 代理限制）
- 大事务拆分：避免在事务中执行 RPC 调用、文件 IO 等耗时操作
- 需要精细控制时，使用编程式事务 `TransactionTemplate`

## API 规范

### RESTful 路径

```
GET    /api/v1/{resources}           # 列表查询（分页）
GET    /api/v1/{resources}/{id}      # 详情查询
POST   /api/v1/{resources}           # 创建
PUT    /api/v1/{resources}/{id}      # 全量更新
PATCH  /api/v1/{resources}/{id}      # 部分更新
DELETE /api/v1/{resources}/{id}      # 删除
POST   /api/v1/{resources}/actions/{action}  # 非 CRUD 操作
```

### 统一响应格式

所有接口必须返回 `Result<T>` 格式：

```java
@Data
public class Result<T> {
    private int code;
    private String message;
    private T data;
    private long timestamp;

    public static <T> Result<T> success(T data) {
        Result<T> result = new Result<>();
        result.setCode(200);
        result.setMessage("操作成功");
        result.setData(data);
        result.setTimestamp(System.currentTimeMillis());
        return result;
    }

    public static <T> Result<T> fail(int code, String message) {
        Result<T> result = new Result<>();
        result.setCode(code);
        result.setMessage(message);
        result.setTimestamp(System.currentTimeMillis());
        return result;
    }
}
```

### 分页参数

统一使用 `page`（页码，从 1 开始）和 `size`（每页条数，默认 20，最大 100）。

## 测试规范

### Service 层单测（必须）

```java
@ExtendWith(MockitoExtension.class)
class UserServiceImplTest {

    @InjectMocks
    private UserServiceImpl userService;

    @Mock
    private UserMapper userMapper;

    @Test
    void createUser_success() {
        // given
        UserCreateDTO dto = new UserCreateDTO();
        dto.setEmail("test@example.com");
        dto.setUserName("testUser");

        when(userMapper.existsByEmail(dto.getEmail())).thenReturn(false);
        when(userMapper.insert(any(User.class))).thenReturn(1);

        // when
        UserDetailVO result = userService.createUser(dto);

        // then
        assertNotNull(result);
        verify(userMapper).insert(any(User.class));
    }

    @Test
    void createUser_duplicateEmail_throwsException() {
        // given
        UserCreateDTO dto = new UserCreateDTO();
        dto.setEmail("existing@example.com");

        when(userMapper.existsByEmail(dto.getEmail())).thenReturn(true);

        // when & then
        assertThrows(BusinessException.class, () -> userService.createUser(dto));
    }
}
```

### 测试规则

- **Service 层**：必须有单元测试，使用 Mockito Mock 所有依赖
- **Controller 层**：使用 `@WebMvcTest` + `MockMvc` 做接口测试（可选）
- **Mapper 层**：使用 `@MybatisPlusTest` + H2 内存数据库（可选）
- **测试方法命名**：`{方法名}_{场景}_{预期结果}`，如 `createUser_duplicateEmail_throwsException`
- **测试结构**：统一使用 Given-When-Then 模式
- **覆盖范围**：正常流程 + 异常流程 + 边界值

## 安全规范

### 参数校验（JSR-303）

```java
@Data
public class UserCreateDTO {
    @NotBlank(message = "用户名不能为空")
    @Size(min = 2, max = 32, message = "用户名长度 2-32 个字符")
    private String userName;

    @NotBlank(message = "邮箱不能为空")
    @Email(message = "邮箱格式不正确")
    private String email;

    @NotBlank(message = "密码不能为空")
    @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,20}$",
             message = "密码需包含大小写字母和数字，长度 8-20")
    private String password;
}
```

### SQL 注入防护

- MyBatis 中一律使用 `#{}`（参数化查询）
- 禁止使用 `${}` 拼接用户输入
- 动态排序字段必须做白名单校验：

```java
private static final Set<String> ALLOWED_SORT_FIELDS = Set.of("created_at", "updated_at", "id");

public void validateSortField(String sortField) {
    if (!ALLOWED_SORT_FIELDS.contains(sortField)) {
        throw new BusinessException(ErrorCode.PARAM_ERROR, "非法排序字段");
    }
}
```

### XSS 防护

- 用户输入在存储前做 HTML 转义
- 使用 `commons-text` 的 `StringEscapeUtils.escapeHtml4()` 或自定义 Jackson 序列化器
- 富文本内容使用白名单过滤（如 jsoup 的 `Whitelist`）

### 敏感数据

- 密码必须加密存储（BCrypt）
- 日志中禁止打印密码、Token、身份证号等敏感信息
- 接口响应中禁止返回密码字段
