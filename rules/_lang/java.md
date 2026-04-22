---
paths:
  - "**/*.java"
---

# Java 编码规范

## 版本

- Java 17+ 优先（LTS），新特性：record、sealed class、pattern matching、text block
- Gradle / Maven 项目按实际

## 命名

- 类、接口、枚举：`PascalCase`
- 方法、变量：`camelCase`
- 常量：`UPPER_SNAKE_CASE`
- 包名：全小写 `com.example.project`

## 空值与 Optional

- 公共 API 不返回 null，用 `Optional<T>`
- `Optional` **不用于字段和参数**，仅用于返回值
- 不 `.get()` 不检查：用 `.orElse`、`.orElseThrow`、`.ifPresent`
- 避免 `NullPointerException`：使用 `@Nullable` / `@NonNull` 注解

## 集合

- 优先不可变：`List.of()`、`Map.of()`
- Guava / Apache Commons 慎用（标准库足够时优先）
- Stream API 用于数据转换，但不过度嵌套（可读性 > 简洁）
- 并发集合：`ConcurrentHashMap`、`CopyOnWriteArrayList`

## 异常

- 检查异常 vs 运行时异常：
  - 业务上调用方必须处理的 → 检查异常
  - 程序逻辑错误（不该发生的）→ RuntimeException
- 自定义异常继承合适的基类
- 不吞异常（`catch { }` 禁止）
- `try-with-resources` 管理 `AutoCloseable`

```java
try (var conn = pool.getConnection()) {
    // ...
} catch (SQLException e) {
    throw new RepositoryException("Failed to ...", e);
}
```

## 并发

- `java.util.concurrent` 优先于 `synchronized`（除非极简单场景）
- `ExecutorService` 管理线程，不直接 `new Thread`
- `CompletableFuture` 组合异步
- Virtual Thread（21+）用于 IO 密集

## 现代特性

- **record** 替代简单 DTO：
  ```java
  public record User(int id, String name, String email) {}
  ```
- **sealed class** 限制继承层次
- **pattern matching**（switch expression + instanceof）
- **text block** 多行字符串

## 工程

- 字段尽量 `final`
- 方法参数尽量 `final`（某些团队约定）
- 不在字段初始化中做复杂逻辑（用构造器或 factory）
- 避免 setter：构造器传入 + 不可变（record）

## 日志

- SLF4J + Logback / Log4j2
- 参数化日志：`log.info("User {} logged in", userId)` 而非字符串拼接
- 日志级别合理：DEBUG 可能被关闭，不要依赖

## 测试

- JUnit 5
- AssertJ 提供流畅断言
- Mockito 做 mock
- 测试方法名：`shouldXxxWhenYyy`

## Spring Boot（如适用）

- 构造器注入 > 字段注入（便于测试）
- `@Transactional` 放在 Service 层，不放 Controller
- 配置用 `@ConfigurationProperties` + 类型安全
- 不在 Controller 写业务逻辑

## 安全

- JPA / JDBC 参数化查询，**禁止**字符串拼接 SQL
- 不用 `Random` 做安全相关的随机数（用 `SecureRandom`）
- 密码哈希用 `BCryptPasswordEncoder`

## 性能

- 避免过早优化
- 大集合操作警惕 O(n²)
- String concatenation 在循环中用 `StringBuilder`
- 大对象在热路径避免频繁创建
