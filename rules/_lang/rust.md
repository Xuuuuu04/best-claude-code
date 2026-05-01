---
paths:
  - "**/*.rs"
---

<rule>
  <!-- ====== 版本 ====== -->
  <requirement>Rust 稳定版最新（Edition 2021 / 2024）</requirement>
  <convention>`rust-toolchain.toml` 锁定版本</convention>

  <!-- ====== 所有权与借用 ====== -->
  <convention>优先借用（`&T`）而非克隆</convention>
  <convention>必要的克隆显式：`.clone()` 而非隐式</convention>
  <convention>`Cow<'_, T>` 用于可能拥有或借用的场景</convention>
  <convention>生命周期标注：能省略就省略（遵循省略规则），必要时显式</convention>

  <!-- ====== 错误处理 ====== -->
  <constraint severity="blocker">`Result<T, E>` 优于 panic</constraint>
  <convention>`?` 操作符传播错误</convention>
  <convention>错误类型用 `thiserror`（库）或 `anyhow`（应用）</convention>
  <constraint severity="blocker">`panic!` 仅用于不可能的不变量破坏</constraint>
  <constraint severity="blocker">`unwrap()` / `expect()`：测试代码可用，生产代码几乎不用（除非 100% 确定）</constraint>
  <convention>`expect()` 带描述比 `unwrap()` 好（失败时消息更有用）</convention>

  <!-- ====== 类型 ====== -->
  <convention>避免 `String` vs `&str` 混乱：参数接受 `&str`，返回 `String`</convention>
  <convention>`Vec<T>` vs `&[T]`：参数接受切片</convention>
  <convention>Newtype 包装：`struct UserId(u64)` 增强类型安全</convention>
  <convention>`Option<T>` 替代空值</convention>
  <convention>`From` / `Into` 实现类型转换</convention>

  <!-- ====== 并发 ====== -->
  <convention>Send + Sync trait 保证线程安全</convention>
  <convention>`Arc<Mutex<T>>` 共享可变状态</convention>
  <convention>`tokio` 是异步事实标准</convention>
  <convention>`async fn` + `.await`</convention>
  <constraint severity="warning">`spawn` 的 Task 必须有明确的生命周期管理</constraint>

  <!-- ====== 模块组织 ====== -->
  <convention>`mod` 定义子模块</convention>
  <convention>`pub` 显式导出（默认私有）</convention>
  <convention>`use` 简化路径</convention>
  <convention>`lib.rs` / `main.rs` 入口</convention>

  <!-- ====== Cargo ====== -->
  <convention>`Cargo.toml` 依赖固定：使用具体版本或 caret（`^1.2.3`）</convention>
  <convention>`Cargo.lock` 应用项目提交；库项目不提交</convention>
  <convention>feature flag 组织可选功能</convention>
  <convention>dev-dependencies 仅测试</convention>

  <!-- ====== 测试 ====== -->
  <convention>`#[cfg(test)] mod tests`</convention>
  <convention>`#[test]` 函数</convention>
  <convention>集成测试：`tests/` 目录</convention>
  <convention>文档测试：`///` 示例自动运行</convention>

  <!-- ====== 工具 ====== -->
  <constraint severity="blocker">`cargo fmt`</constraint>
  <constraint severity="blocker">`cargo clippy -- -D warnings`</constraint>
  <convention>`cargo test`</convention>
  <convention>`cargo audit` 依赖漏洞扫描</convention>

  <!-- ====== 常见陷阱 ====== -->
  <constraint severity="warning">迭代器消耗后不可再用：`.iter()` vs `.into_iter()` vs `.iter_mut()`</constraint>
  <constraint severity="warning">`String` 不能直接索引字符（用 `.chars()`）</constraint>
  <constraint severity="warning">整数溢出：release 默认 wrap，`checked_*` / `saturating_*` 方法</constraint>
  <convention>`mem::replace` / `mem::take` 处理所有权难题</convention>

</rule>
