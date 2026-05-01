---
paths:
  - "**/*.rb"
  - "**/Gemfile"
  - "**/*.gemspec"
  - "**/Rakefile"
---

<rule>
  <!-- ====== 版本 ====== -->
  <requirement>Ruby 3.2+ 优先（YJIT 性能）</requirement>
  <convention>Gemfile 锁定版本</convention>

  <!-- ====== 命名 ====== -->
  <convention>类、模块：`PascalCase`</convention>
  <convention>方法、变量：`snake_case`</convention>
  <convention>常量：`UPPER_SNAKE_CASE`</convention>
  <convention>谓词方法（返回 bool）：以 `?` 结尾 `valid?`</convention>
  <convention>破坏性方法：以 `!` 结尾 `sort!`</convention>
  <convention>文件名：`snake_case.rb`</convention>

  <!-- ====== 风格（参考 RuboCop） ====== -->
  <convention>字符串优先 `'` 单引号，需插值时用 `"`</convention>
  <convention>Symbol 作 Hash key：`{ name: 'Alice' }` 而非 `{ 'name' => 'Alice' }`</convention>
  <convention>2 空格缩进</convention>
  <convention>行长 <= 120</convention>

  <!-- ====== 方法 ====== -->
  <convention>方法短小（小于 10 行理想）</convention>
  <convention>参数大于 3 个考虑 keyword args 或 options hash</convention>
  <convention>显式 `return` 仅在早返；否则隐式返回最后表达式</convention>
  <convention>避免副作用和返回值混合（Command-Query Separation）</convention>

  <!-- ====== 块与 Yield ====== -->
  <convention>单行块用 `{ }`；多行用 `do...end`</convention>
  <convention>`&:method_name` 简写：`arr.map(&:to_s)`</convention>
  <convention>`yield` 比显式 block 参数更高效</convention>

  <!-- ====== 鸭子类型 ====== -->
  <convention>用 `respond_to?` 检查能力</convention>
  <convention>避免 `is_a?` 做类型判断（除非真的需要）</convention>

  <!-- ====== 异常 ====== -->
  <constraint severity="blocker">具体异常类继承 `StandardError`（不继承 `Exception`）</constraint>
  <constraint severity="blocker">不 `rescue Exception`（会捕获 SignalException、SystemExit）</constraint>
  <convention>`rescue StandardError => e` 或具体类型</convention>
  <convention>`ensure` 释放资源</convention>

  <!-- ====== 元编程（谨慎使用） ====== -->
  <convention>`define_method`、`method_missing`、`class_eval` 强大但易混乱</convention>
  <convention>优先明确代码</convention>
  <convention>使用时留清晰注释说明"为什么"</convention>

  <!-- ====== 并发 ====== -->
  <convention>GIL 限制线程并行（纯 Ruby）</convention>
  <convention>Ractor（3.0+）真并行</convention>
  <convention>`Thread` 用于 IO 并发</convention>
  <convention>`Mutex` 保护共享状态</convention>

  <!-- ====== 测试 ====== -->
  <convention>RSpec 或 Minitest（项目约定）</convention>
  <convention>`describe` / `context` / `it` 清晰</convention>
  <convention>FactoryBot 造测试数据</convention>

  <!-- ====== Gem 管理 ====== -->
  <convention>`Gemfile.lock` 提交</convention>
  <convention>`bundle update` 谨慎（读 CHANGELOG）</convention>
  <convention>指定版本约束：`gem 'rails', '~> 7.1'`</convention>

  <!-- ====== 工具 ====== -->
  <convention>RuboCop 代码规范</convention>
  <convention>Reek / Standard 代码味道</convention>
  <convention>Brakeman 安全扫描（Rails 项目）</convention>

  <!-- ====== 性能 ====== -->
  <convention>慎用 `method_missing`（查找慢）</convention>
  <convention>大集合用 `lazy` 避免中间数组</convention>
  <convention>`String#concat` / `<<` 不创建新对象</convention>
  <convention>`Set` 去重比 `uniq` 快</convention>

</rule>
