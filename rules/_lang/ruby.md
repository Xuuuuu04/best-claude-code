---
paths:
  - "**/*.rb"
  - "**/Gemfile"
  - "**/*.gemspec"
  - "**/Rakefile"
---

# Ruby 编码规范

## 版本
- Ruby 3.2+ 优先（YJIT 性能）
- Gemfile 锁定版本

## 命名
- 类、模块：`PascalCase`
- 方法、变量：`snake_case`
- 常量：`UPPER_SNAKE_CASE`
- 谓词方法（返回 bool）：以 `?` 结尾 `valid?`
- 破坏性方法：以 `!` 结尾 `sort!`
- 文件名：`snake_case.rb`

## 风格（参考 RuboCop）
- 字符串优先 `'` 单引号，需插值时用 `"`
- Symbol 作 Hash key：`{ name: 'Alice' }` 而非 `{ 'name' => 'Alice' }`
- 2 空格缩进
- 行长 ≤120

## 方法
- 方法短小（<10 行理想）
- 参数 >3 个考虑 keyword args 或 options hash
- 显式 `return` 仅在早返；否则隐式返回最后表达式
- 避免副作用和返回值混合（Command-Query Separation）

## 块与 Yield
- 单行块用 `{ }`；多行用 `do...end`
- `&:method_name` 简写：`arr.map(&:to_s)`
- `yield` 比显式 block 参数更高效

## 鸭子类型
- 用 `respond_to?` 检查能力
- 避免 `is_a?` 做类型判断（除非真的需要）

## 异常
- 具体异常类继承 `StandardError`（不继承 `Exception`）
- 不 `rescue Exception`（会捕获 SignalException、SystemExit）
- `rescue StandardError => e` 或具体类型
- `ensure` 释放资源

## 元编程（谨慎使用）
- `define_method`、`method_missing`、`class_eval` 强大但易混乱
- 优先明确代码
- 使用时留清晰注释说明"为什么"

## 并发
- GIL 限制线程并行（纯 Ruby）
- Ractor（3.0+）真并行
- `Thread` 用于 IO 并发
- `Mutex` 保护共享状态

## 测试
- RSpec 或 Minitest（项目约定）
- `describe` / `context` / `it` 清晰
- FactoryBot 造测试数据

## Gem 管理
- `Gemfile.lock` 提交
- `bundle update` 谨慎（读 CHANGELOG）
- 指定版本约束：`gem 'rails', '~> 7.1'`

## 工具
- RuboCop 代码规范
- Reek / Standard 代码味道
- Brakeman 安全扫描（Rails 项目）

## 性能
- 慎用 `method_missing`（查找慢）
- 大集合用 `lazy` 避免中间数组
- `String#concat` / `<<` 不创建新对象
- `Set` 去重比 `uniq` 快
