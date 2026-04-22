---
paths:
  - "**/*.php"
  - "**/composer.json"
---

# PHP 编码规范

## 版本
- PHP 8.2+ 优先（Readonly classes、Enum 等现代特性）
- `declare(strict_types=1);` 文件顶部开启严格类型

## PSR 规范
- PSR-1 / PSR-12 代码风格
- PSR-4 自动加载
- PSR-7 HTTP 消息
- PSR-11 容器
- PSR-15 HTTP 中间件

## 命名
- 类：`PascalCase`
- 方法、变量：`camelCase`
- 常量：`UPPER_SNAKE_CASE`
- 接口：以 `Interface` 后缀 或 无后缀（项目统一）
- Trait：以 `Trait` 后缀

## 类型
- 参数、返回值、属性类型必标注
- `readonly` 属性（8.1+）：构造后不可变
- 联合类型：`int|string`
- `null` 类型：`?Type` 或 `Type|null`
- `never` 表示不返回（异常/退出）

```php
public function findUser(int $id): ?User {
    // ...
}
```

## 错误处理
- 抛出具体异常（继承 `\Exception` 或自定义基类）
- 业务异常与基础设施异常分离
- `try/catch` 具体类型优先
- `finally` 释放资源

## null 处理
- Null-safe operator：`$user?->profile?->name`
- `??` null 合并：`$name ?? 'default'`
- `??=` 赋值：`$config['key'] ??= 'default'`

## 数组
- 短数组语法 `[]` 优先于 `array()`
- 关联数组 key 严格类型：`string` 或 `int`
- `array_*` 函数库丰富，优先使用

## 面向对象
- 组合优于继承
- `final` 类默认（防止意外继承）
- `readonly class`（8.2+）天然不可变
- Enum（8.1+）替代类常量集合

## 命名空间
- 一个文件一个类
- `use` 简化长命名空间
- 不在全局命名空间定义类

## Composer
- `composer.json` 和 `composer.lock` 提交
- 依赖用 `^`（兼容更新）或 `~`（补丁更新）
- dev 依赖和 runtime 分开（`require` vs `require-dev`）

## 安全
- SQL 预处理语句（PDO / MySQLi prepared statements），禁止拼接
- XSS：`htmlspecialchars($var, ENT_QUOTES, 'UTF-8')`
- CSRF：框架 token 验证
- 密码：`password_hash()` / `password_verify()`，**禁** MD5/SHA1
- `include` / `require` 不传用户输入

## 测试
- PHPUnit 主流
- Pest 简洁风格（可选）
- 数据提供者：`@dataProvider`

## 工具
- PHPStan / Psalm 静态分析（level 最高）
- PHP CS Fixer 自动格式化
- Rector 自动升级

## 反模式
- `eval`（除非极其必要）
- `@` 抑制错误
- 全局变量
- 巨型控制器（MVC 项目）
- magic method 滥用
