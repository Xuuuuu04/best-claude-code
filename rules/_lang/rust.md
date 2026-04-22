---
paths:
  - "**/*.rs"
---

# Rust 编码规范

## 版本
- Rust 稳定版最新（Edition 2021 / 2024）
- `rust-toolchain.toml` 锁定版本

## 所有权与借用
- 优先借用（`&T`）而非克隆
- 必要的克隆显式：`.clone()` 而非隐式
- `Cow<'_, T>` 用于可能拥有或借用的场景
- 生命周期标注：能省略就省略（遵循省略规则），必要时显式

## 错误处理
- `Result<T, E>` 优于 panic
- `?` 操作符传播错误
- 错误类型用 `thiserror`（库）或 `anyhow`（应用）
- `panic!` 仅用于不可能的不变量破坏
- `unwrap()` / `expect()`：测试代码可用，生产代码**几乎不用**（除非 100% 确定）
- `expect()` 带描述比 `unwrap()` 好（失败时消息更有用）

## 类型
- 避免 `String` vs `&str` 混乱：参数接受 `&str`，返回 `String`
- `Vec<T>` vs `&[T]`：参数接受切片
- Newtype 包装：`struct UserId(u64)` 增强类型安全
- `Option<T>` 替代空值
- `From` / `Into` 实现类型转换

## 并发
- Send + Sync trait 保证线程安全
- `Arc<Mutex<T>>` 共享可变状态
- `tokio` 是异步事实标准
- `async fn` + `.await`
- `spawn` 的 Task 必须有明确的生命周期管理

## 模块组织
- `mod` 定义子模块
- `pub` 显式导出（默认私有）
- `use` 简化路径
- `lib.rs` / `main.rs` 入口

## Cargo
- `Cargo.toml` 依赖固定：使用具体版本或 caret（`^1.2.3`）
- `Cargo.lock` 应用项目提交；库项目不提交
- feature flag 组织可选功能
- dev-dependencies 仅测试

## 测试
- `#[cfg(test)] mod tests`
- `#[test]` 函数
- 集成测试：`tests/` 目录
- 文档测试：`///` 示例自动运行

## 工具
- `cargo fmt`
- `cargo clippy -- -D warnings`
- `cargo test`
- `cargo audit` 依赖漏洞扫描

## 常见陷阱
- 迭代器消耗后不可再用：`.iter()` vs `.into_iter()` vs `.iter_mut()`
- `String` 不能直接索引字符（用 `.chars()`）
- 整数溢出：release 默认 wrap，`checked_*` / `saturating_*` 方法
- `mem::replace` / `mem::take` 处理所有权难题
