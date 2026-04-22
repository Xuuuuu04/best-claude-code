---
paths:
  - "**/src/main/java/**/*.java"
  - "**/src/main/kotlin/**/*.kt"
  - "**/application.yml"
  - "**/application.properties"
  - "**/application-*.yml"
---

# Spring Boot 规范

## 版本
- Spring Boot 3.x（Java 17+）
- Spring Framework 6+

## 分层

经典分层：
- **Controller**：接受 HTTP、参数校验、调用 Service、返回响应
- **Service**：业务逻辑，事务边界
- **Repository**：数据访问
- **Entity / Domain**：领域模型
- **DTO**：API 输入输出对象（不直接暴露 Entity）

**不**在 Controller 写业务逻辑。

## 依赖注入

- **构造器注入**（便于测试、不可变）：
  ```java
  @Service
  public class UserService {
      private final UserRepository userRepository;
      
      public UserService(UserRepository userRepository) {
          this.userRepository = userRepository;
      }
  }
  ```
- Lombok `@RequiredArgsConstructor` 简化（若项目用 Lombok）
- **避免** `@Autowired` 字段注入

## REST Controller

```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    @GetMapping("/{id}")
    public ResponseEntity<UserDto> getUser(@PathVariable Long id) { ... }
    
    @PostMapping
    public ResponseEntity<UserDto> createUser(@Valid @RequestBody CreateUserRequest req) { ... }
}
```

- `@RestController` 而非 `@Controller`
- `@Valid` 触发 JSR 380 校验
- 返回 `ResponseEntity<T>` 控制状态码

## 校验

- JSR 380（Jakarta Validation）注解：`@NotNull` / `@Size` / `@Email` / `@Min`
- 自定义校验器实现 `ConstraintValidator`
- 全局异常处理：`@RestControllerAdvice`

## 异常处理

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorDto> handleNotFound(ResourceNotFoundException e) {
        return ResponseEntity.status(404).body(new ErrorDto("NOT_FOUND", e.getMessage()));
    }
}
```

不让 Spring 默认错误响应暴露到 API（泄露内部信息）。

## 事务

- `@Transactional` 放 Service 层，不放 Controller
- 默认传播 `REQUIRED`，按需 `REQUIRES_NEW` / `SUPPORTS`
- 只读查询加 `@Transactional(readOnly = true)`（性能提示）
- 不在 private 方法上加 `@Transactional`（Spring AOP 失效）

## Data JPA / R2DBC

- `@Entity` 标注实体
- 懒加载 `FetchType.LAZY` 默认（避免 N+1）
- 批量操作用 `@Modifying` + `@Query`
- 分页用 `Pageable` + `Page<T>`

## 配置

- `application.yml` > `application.properties`（可读性）
- 环境特定：`application-{profile}.yml`
- `@ConfigurationProperties` 类型安全绑定：
  ```java
  @ConfigurationProperties(prefix = "app.email")
  public record EmailConfig(String from, int timeoutMs) {}
  ```
- 敏感配置通过环境变量（不硬编码）

## 测试

- `@SpringBootTest` 完整上下文（慢）
- `@WebMvcTest` 仅 Web 层
- `@DataJpaTest` 仅数据层
- `TestContainers` 真实数据库测试
- Mockito 做 mock

## 安全

- Spring Security 配置认证与授权
- 密码 `BCryptPasswordEncoder`
- CSRF 启用（REST API 可关闭，但配合 token）
- 方法级授权：`@PreAuthorize`

## 日志

- SLF4J + Logback（默认）
- 参数化：`log.info("User {} logged in", userId)`
- 结构化日志（JSON）：Logstash encoder

## 常见陷阱

- `@Service` 依赖 `@Component` 等同，但语义清晰：用正确注解
- Bean 循环依赖：重构设计，不要靠 `@Lazy` 掩盖
- 事务传播与 `self-invocation`（同类内调用 `@Transactional` 方法失效）
- 启动慢：减少 `@ComponentScan` 范围
- `application.yml` 敏感值泄漏到 git

## 工具

- Actuator（`/actuator/health` 等）暴露要限权
- Spring Boot DevTools 仅开发
- Gradle / Maven：选一并统一
