---
paths:
  - "**/src/main/java/**/*.java"
  - "**/src/main/kotlin/**/*.kt"
  - "**/application.yml"
  - "**/application.properties"
  - "**/application-*.yml"
---

<rule name="spring-version">
  <convention>Spring Boot 3.x（Java 17+）</convention>
  <convention>Spring Framework 6+</convention>
</rule>

<rule name="spring-layers">
  <convention>Controller：接受 HTTP、参数校验、调用 Service、返回响应</convention>
  <convention>Service：业务逻辑，事务边界</convention>
  <convention>Repository：数据访问</convention>
  <convention>Entity / Domain：领域模型</convention>
  <convention>DTO：API 输入输出对象（不直接暴露 Entity）</convention>
  <constraint severity="blocker">不在 Controller 写业务逻辑。</constraint>
</rule>

<rule name="spring-di">
  <convention>构造器注入（便于测试、不可变）</convention>
  <pattern>
    <code language="java">
@Service
public class UserService {
    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}
    </code>
  </pattern>
  <convention>Lombok @RequiredArgsConstructor 简化（若项目用 Lombok）</convention>
  <constraint severity="warning">避免 @Autowired 字段注入</constraint>
</rule>

<rule name="spring-rest-controller">
  <pattern>
    <code language="java">
@RestController
@RequestMapping("/api/users")
public class UserController {
    @GetMapping("/{id}")
    public ResponseEntity<UserDto> getUser(@PathVariable Long id) { /* ... */ }

    @PostMapping
    public ResponseEntity<UserDto> createUser(@Valid @RequestBody CreateUserRequest req) { /* ... */ }
}
    </code>
  </pattern>
  <convention>@RestController 而非 @Controller</convention>
  <convention>@Valid 触发 JSR 380 校验</convention>
  <convention>返回 ResponseEntity<T> 控制状态码</convention>
</rule>

<rule name="spring-validation">
  <convention>JSR 380（Jakarta Validation）注解：@NotNull / @Size / @Email / @Min</convention>
  <convention>自定义校验器实现 ConstraintValidator</convention>
  <convention>全局异常处理：@RestControllerAdvice</convention>
</rule>

<rule name="spring-exception-handling">
  <pattern>
    <code language="java">
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorDto> handleNotFound(ResourceNotFoundException e) {
        return ResponseEntity.status(404).body(new ErrorDto("NOT_FOUND", e.getMessage()));
    }
}
    </code>
  </pattern>
  <constraint severity="blocker">不让 Spring 默认错误响应暴露到 API（泄露内部信息）。</constraint>
</rule>

<rule name="spring-transactions">
  <constraint severity="blocker">@Transactional 放 Service 层，不放 Controller</constraint>
  <convention>默认传播 REQUIRED，按需 REQUIRES_NEW / SUPPORTS</convention>
  <convention>只读查询加 @Transactional(readOnly = true)（性能提示）</convention>
  <constraint severity="warning">不在 private 方法上加 @Transactional（Spring AOP 失效）</constraint>
</rule>

<rule name="spring-data-jpa">
  <convention>@Entity 标注实体</convention>
  <convention>懒加载 FetchType.LAZY 默认（避免 N+1）</convention>
  <convention>批量操作用 @Modifying + @Query</convention>
  <convention>分页用 Pageable + Page<T></convention>
</rule>

<rule name="spring-config">
  <convention>application.yml 优先于 application.properties（可读性）</convention>
  <convention>环境特定：application-{profile}.yml</convention>
  <convention>@ConfigurationProperties 类型安全绑定</convention>
  <pattern>
    <code language="java">
@ConfigurationProperties(prefix = "app.email")
public record EmailConfig(String from, int timeoutMs) {}
    </code>
  </pattern>
  <constraint severity="blocker">敏感配置通过环境变量（不硬编码）</constraint>
</rule>

<rule name="spring-testing">
  <convention>@SpringBootTest 完整上下文（慢）</convention>
  <convention>@WebMvcTest 仅 Web 层</convention>
  <convention>@DataJpaTest 仅数据层</convention>
  <convention>TestContainers 真实数据库测试</convention>
  <convention>Mockito 做 mock</convention>
</rule>

<rule name="spring-security">
  <convention>Spring Security 配置认证与授权</convention>
  <constraint severity="blocker">密码 BCryptPasswordEncoder</constraint>
  <convention>CSRF 启用（REST API 可关闭，但配合 token）</convention>
  <convention>方法级授权：@PreAuthorize</convention>
</rule>

<rule name="spring-logging">
  <convention>SLF4J + Logback（默认）</convention>
  <convention>参数化：log.info("User {} logged in", userId)</convention>
  <convention>结构化日志（JSON）：Logstash encoder</convention>
</rule>

<rule name="spring-common-pitfalls">
  <constraint severity="warning">@Service 依赖 @Component 等同，但语义清晰：用正确注解</constraint>
  <constraint severity="blocker">Bean 循环依赖：重构设计，不要靠 @Lazy 掩盖</constraint>
  <constraint severity="warning">事务传播与 self-invocation（同类内调用 @Transactional 方法失效）</constraint>
  <convention>启动慢：减少 @ComponentScan 范围</convention>
  <constraint severity="blocker">application.yml 敏感值泄漏到 git</constraint>
</rule>

<rule name="spring-tools">
  <convention>Actuator（/actuator/health 等）暴露要限权</convention>
  <convention>Spring Boot DevTools 仅开发</convention>
  <convention>Gradle / Maven：选一并统一</convention>
</rule>
