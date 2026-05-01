---
paths:
  - "**/*.php"
  - "**/composer.json"
---

<rule>
  <!-- ====== 版本 ====== -->
  <requirement>PHP 8.2+ 优先（Readonly classes、Enum 等现代特性）</requirement>
  <constraint severity="blocker">`declare(strict_types=1);` 文件顶部开启严格类型</constraint>

  <!-- ====== PSR 规范 ====== -->
  <convention>PSR-1 / PSR-12 代码风格</convention>
  <convention>PSR-4 自动加载</convention>
  <convention>PSR-7 HTTP 消息</convention>
  <convention>PSR-11 容器</convention>
  <convention>PSR-15 HTTP 中间件</convention>

  <!-- ====== 命名 ====== -->
  <convention>类：`PascalCase`</convention>
  <convention>方法、变量：`camelCase`</convention>
  <convention>常量：`UPPER_SNAKE_CASE`</convention>
  <convention>接口：以 `Interface` 后缀 或 无后缀（项目统一）</convention>
  <convention>Trait：以 `Trait` 后缀</convention>

  <!-- ====== 类型 ====== -->
  <constraint severity="blocker">参数、返回值、属性类型必标注</constraint>
  <convention>`readonly` 属性（8.1+）：构造后不可变</convention>
  <convention>联合类型：`int|string`</convention>
  <convention>`null` 类型：`?Type` 或 `Type|null`</convention>
  <convention>`never` 表示不返回（异常/退出）</convention>
  <pattern>

```php
public function findUser(int $id): ?User {
    // ...
}
```

  </pattern>

  <!-- ====== 错误处理 ====== -->
  <constraint severity="blocker">抛出具体异常（继承 `\Exception` 或自定义基类）</constraint>
  <convention>业务异常与基础设施异常分离</convention>
  <convention>`try/catch` 具体类型优先</convention>
  <convention>`finally` 释放资源</convention>

  <!-- ====== null 处理 ====== -->
  <convention>Null-safe operator：`$user?->profile?->name`</convention>
  <convention>`??` null 合并：`$name ?? 'default'`</convention>
  <convention>`??=` 赋值：`$config['key'] ??= 'default'`</convention>

  <!-- ====== 数组 ====== -->
  <convention>短数组语法 `[]` 优先于 `array()`</convention>
  <convention>关联数组 key 严格类型：`string` 或 `int`</convention>
  <convention>`array_*` 函数库丰富，优先使用</convention>

  <!-- ====== 面向对象 ====== -->
  <convention>组合优于继承</convention>
  <convention>`final` 类默认（防止意外继承）</convention>
  <convention>`readonly class`（8.2+）天然不可变</convention>
  <convention>Enum（8.1+）替代类常量集合</convention>

  <!-- ====== 命名空间 ====== -->
  <convention>一个文件一个类</convention>
  <convention>`use` 简化长命名空间</convention>
  <constraint severity="warning">不在全局命名空间定义类</constraint>

  <!-- ====== Composer ====== -->
  <convention>`composer.json` 和 `composer.lock` 提交</convention>
  <convention>依赖用 `^`（兼容更新）或 `~`（补丁更新）</convention>
  <convention>dev 依赖和 runtime 分开（`require` vs `require-dev`）</convention>

  <!-- ====== 安全 ====== -->
  <constraint severity="blocker">SQL 预处理语句（PDO / MySQLi prepared statements），禁止拼接</constraint>
  <constraint severity="blocker">XSS：`htmlspecialchars($var, ENT_QUOTES, 'UTF-8')`</constraint>
  <constraint severity="blocker">CSRF：框架 token 验证</constraint>
  <constraint severity="blocker">密码：`password_hash()` / `password_verify()`，禁 MD5/SHA1</constraint>
  <constraint severity="blocker">`include` / `require` 不传用户输入</constraint>

  <!-- ====== 测试 ====== -->
  <convention>PHPUnit 主流</convention>
  <convention>Pest 简洁风格（可选）</convention>
  <convention>数据提供者：`@dataProvider`</convention>

  <!-- ====== 工具 ====== -->
  <convention>PHPStan / Psalm 静态分析（level 最高）</convention>
  <convention>PHP CS Fixer 自动格式化</convention>
  <convention>Rector 自动升级</convention>

  <!-- ====== 反模式 ====== -->
  <constraint severity="blocker">`eval`（除非极其必要）</constraint>
  <constraint severity="blocker">`@` 抑制错误</constraint>
  <constraint severity="blocker">全局变量</constraint>
  <constraint severity="warning">巨型控制器（MVC 项目）</constraint>
  <constraint severity="warning">magic method 滥用</constraint>

</rule>
