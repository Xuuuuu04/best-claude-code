---
paths:
  - "**/*.dart"
---

<rule>
  <!-- ====== 版本 ====== -->
  <requirement>Dart 3+（records、patterns、sealed class）</requirement>
  <convention>Flutter 最新 stable</convention>

  <!-- ====== 命名 ====== -->
  <convention>类、枚举、扩展：`PascalCase`</convention>
  <convention>变量、函数：`camelCase`</convention>
  <convention>常量：`camelCase`（不是 SHOUTY_CASE）</convention>
  <convention>私有：下划线前缀 `_private`</convention>
  <convention>文件名：`snake_case.dart`</convention>

  <!-- ====== 空安全 ====== -->
  <constraint severity="blocker">null safety 必须开启</constraint>
  <constraint severity="blocker">避免 `!`（force unwrap）</constraint>
  <convention>使用 `?`、`??`、`??=`</convention>

  <!-- ====== 不可变 ====== -->
  <convention>`final` 优先于 `var`</convention>
  <convention>`const` 用于编译时常量（和 const widget）</convention>
  <convention>不可变数据类推荐 `freezed` 或 `@immutable`</convention>

  <!-- ====== Flutter Widget ====== -->
  <convention>`const` 构造器大量使用（减少重建）</convention>
  <convention>`StatelessWidget` > `StatefulWidget`（能不用 state 就不用）</convention>
  <convention>Widget 小而专：大于 100 行考虑拆分</convention>
  <convention>`Key` 用于列表、动画、状态保持</convention>

  <!-- ====== 状态管理 ====== -->
  <convention>简单：`setState`、`ValueNotifier`</convention>
  <convention>中等：`Provider` / `Riverpod`</convention>
  <convention>复杂：`Riverpod` / `Bloc`</convention>
  <constraint severity="blocker">项目内统一方案，不混用。</constraint>

  <!-- ====== 异步 ====== -->
  <convention>`async/await` 优先</convention>
  <convention>`Future.wait` 并行</convention>
  <convention>`Stream` 用于流式数据</convention>
  <convention>`StreamController` 注意关闭（`dispose`）</convention>

  <!-- ====== 错误处理 ====== -->
  <convention>抛 `Exception` / `Error` 的子类</convention>
  <convention>`try/catch` 具体类型优先</convention>
  <convention>用户友好错误向上转换</convention>
  <convention>`FlutterError.onError` 全局 hook</convention>

  <!-- ====== 性能 ====== -->
  <convention>`ListView.builder` 而非 `ListView`（虚拟化）</convention>
  <convention>避免 `build` 中做昂贵计算（用 `memo`、`Provider.select`）</convention>
  <convention>图片：`cached_network_image`、预 cache</convention>
  <convention>长动画用 `Ticker` / `AnimationController`</convention>

  <!-- ====== 导入 ====== -->
  <convention>按组：`dart:` → `package:` → relative</convention>
  <convention>相对导入：只在同包内用</convention>
  <convention>避免 barrel file（除非必要）</convention>

  <!-- ====== 测试 ====== -->
  <convention>`flutter_test`</convention>
  <convention>`testWidgets` 做组件测试</convention>
  <convention>`integration_test` 做集成测试</convention>
  <convention>Mockito / mocktail 做 mock</convention>

  <!-- ====== 工具 ====== -->
  <convention>`dart analyze`</convention>
  <convention>`dart format`</convention>
  <convention>`very_good_analysis` 或 `lint` lints 包</convention>
  <convention>`flutter_lints`（官方推荐）</convention>

  <!-- ====== 平台通道 ====== -->
  <convention>MethodChannel 线程：结果回到主 isolate</convention>
  <convention>错误传递：`PlatformException`</convention>
  <convention>版本兼容：检查 Android/iOS 方法存在性</convention>

</rule>
