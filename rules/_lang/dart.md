---
paths:
  - "**/*.dart"
---

# Dart / Flutter 编码规范

## 版本
- Dart 3+（records、patterns、sealed class）
- Flutter 最新 stable

## 命名
- 类、枚举、扩展：`PascalCase`
- 变量、函数：`camelCase`
- 常量：`camelCase`（不是 SHOUTY_CASE）
- 私有：下划线前缀 `_private`
- 文件名：`snake_case.dart`

## 空安全
- null safety 必须开启
- 避免 `!`（force unwrap）
- 使用 `?`、`??`、`??=`

## 不可变
- `final` 优先于 `var`
- `const` 用于编译时常量（和 const widget）
- 不可变数据类推荐 `freezed` 或 `@immutable`

## Flutter Widget
- **`const` 构造器**大量使用（减少重建）
- `StatelessWidget` > `StatefulWidget`（能不用 state 就不用）
- Widget 小而专：>100 行考虑拆分
- `Key` 用于列表、动画、状态保持

## 状态管理
- 简单：`setState`、`ValueNotifier`
- 中等：`Provider` / `Riverpod`
- 复杂：`Riverpod` / `Bloc`

项目内统一方案，不混用。

## 异步
- `async/await` 优先
- `Future.wait` 并行
- `Stream` 用于流式数据
- `StreamController` 注意关闭（`dispose`）

## 错误处理
- 抛 `Exception` / `Error` 的子类
- `try/catch` 具体类型优先
- 用户友好错误向上转换
- `FlutterError.onError` 全局 hook

## 性能
- `ListView.builder` 而非 `ListView`（虚拟化）
- 避免 `build` 中做昂贵计算（用 `memo`、`Provider.select`）
- 图片：`cached_network_image`、预 cache
- 长动画用 `Ticker` / `AnimationController`

## 导入
- 按组：`dart:` → `package:` → relative
- 相对导入：只在同包内用
- 避免 barrel file（除非必要）

## 测试
- `flutter_test`
- `testWidgets` 做组件测试
- `integration_test` 做集成测试
- Mockito / mocktail 做 mock

## 工具
- `dart analyze`
- `dart format`
- `very_good_analysis` 或 `lint` lints 包
- `flutter_lints`（官方推荐）

## 平台通道
- MethodChannel 线程：结果回到主 isolate
- 错误传递：`PlatformException`
- 版本兼容：检查 Android/iOS 方法存在性
