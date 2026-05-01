---
paths:
  - "**/*.java"
---

<rule>
  <!-- ====== 版本 ====== -->
  <requirement>Java 17+ 优先（LTS），新特性：record、sealed class、pattern matching、text block</requirement>
  <convention>Gradle / Maven 项目按实际</convention>

  <!-- ====== 命名 ====== -->
  <convention>类、接口、枚举：`PascalCase`</convention>
  <convention>方法、变量：`camelCase`</convention>
  <convention>常量：`UPPER_SNAKE_CASE`</convention>
  <convention>包名：全小写 `com.example.project`</convention>

  <!-- ====== 空值与 Optional ====== -->
  <constraint severity="blocker">公共 API 不返回 null，用 `Optional<T>`</constraint>
  <constraint severity="warning">`Optional` 不用于字段和参数，仅用于返回值</constraint>
  <constraint severity="blocker">不 `.get()` 不检查：用 `.orElse`、`.orElseThrow`、`.ifPresent`</constraint>
  <constraint severity="warning">避免 `NullPointerException`：使用 `@Nullable` / `@NonNull` 注解</constraint>

  <!-- ====== 集合 ====== -->
  <convention>优先不可变：`List.of()`、`Map.of()`</convention>
  <convention>Guava / Apache Commons 慎用（标准库足够时优先）</convention>
  <convention>Stream API 用于数据转换，但不过度嵌套（可读性 > 简洁）</convention>
  <convention>并发集合：`ConcurrentHashMap`、`CopyOnWriteArrayList`</convention>

  <!-- ====== 异常 ====== -->
  <requirement>检查异常 vs 运行时异常：
  - 业务上调用方必须处理的 → 检查异常
  - 程序逻辑错误（不该发生的）→ RuntimeException</requirement>
  <convention>自定义异常继承合适的基类</convention>
  <constraint severity="blocker">不吞异常（`catch { }` 禁止）</constraint>
  <constraint severity="blocker">`try-with-resources` 管理 `AutoCloseable`</constraint>
  <pattern>

```java
try (var conn = pool.getConnection()) {
    // ...
} catch (SQLException e) {
    throw new RepositoryException("Failed to ...", e);
}
```

  </pattern>

  <!-- ====== 并发 ====== -->
  <convention>`java.util.concurrent` 优先于 `synchronized`（除非极简单场景）</convention>
  <convention>`ExecutorService` 管理线程，不直接 `new Thread`</convention>
  <convention>`CompletableFuture` 组合异步</convention>
  <convention>Virtual Thread（21+）用于 IO 密集</convention>

  <!-- ====== 现代特性 ====== -->
  <convention>record 替代简单 DTO：</convention>
  <pattern>

```java
public record User(int id, String name, String email) {}
```

  </pattern>
  <convention>sealed class 限制继承层次</convention>
  <convention>pattern matching（switch expression + instanceof）</convention>
  <convention>text block 多行字符串</convention>

  <!-- ====== 工程 ====== -->
  <convention>字段尽量 `final`</convention>
  <convention>方法参数尽量 `final`（某些团队约定）</convention>
  <convention>不在字段初始化中做复杂逻辑（用构造器或 factory）</convention>
  <convention>避免 setter：构造器传入 + 不可变（record）</convention>

  <!-- ====== 日志 ====== -->
  <convention>SLF4J + Logback / Log4j2</convention>
  <convention>参数化日志：`log.info("User {} logged in", userId)` 而非字符串拼接</convention>
  <convention>日志级别合理：DEBUG 可能被关闭，不要依赖</convention>

  <!-- ====== 测试 ====== -->
  <convention>JUnit 5</convention>
  <convention>AssertJ 提供流畅断言</convention>
  <convention>Mockito 做 mock</convention>
  <convention>测试方法名：`shouldXxxWhenYyy`</convention>

  <!-- ====== Spring Boot（如适用） ====== -->
  <constraint severity="blocker">构造器注入 > 字段注入（便于测试）</constraint>
  <convention>`@Transactional` 放在 Service 层，不放 Controller</convention>
  <convention>配置用 `@ConfigurationProperties` + 类型安全</convention>
  <constraint severity="blocker">不在 Controller 写业务逻辑</constraint>

  <!-- ====== 安全 ====== -->
  <constraint severity="blocker">JPA / JDBC 参数化查询，禁止字符串拼接 SQL</constraint>
  <constraint severity="blocker">不用 `Random` 做安全相关的随机数（用 `SecureRandom`）</constraint>
  <convention>密码哈希用 `BCryptPasswordEncoder`</convention>

  <!-- ====== 性能 ====== -->
  <convention>避免过早优化</convention>
  <constraint severity="warning">大集合操作警惕 O(n2)</constraint>
  <convention>String concatenation 在循环中用 `StringBuilder`</convention>
  <convention>大对象在热路径避免频繁创建</convention>

</rule>
