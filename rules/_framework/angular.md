---
paths:
  - "**/*.component.ts"
  - "**/*.service.ts"
  - "**/*.module.ts"
  - "**/*.guard.ts"
  - "**/*.pipe.ts"
  - "**/*.directive.ts"
  - "**/angular.json"
---

# Angular 规范

## 版本
- Angular 17+（Standalone Components 默认）

## Standalone Components

新项目优先 Standalone（无 NgModule）：

```ts
@Component({
  selector: 'app-user',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './user.component.html'
})
export class UserComponent {}
```

老项目 NgModule 也可，但不混用。

## 命名

- 组件 selector：`app-` 前缀
- 文件：`feature.type.ts`（`user.component.ts`、`user.service.ts`）
- 类：`UserComponent`、`UserService`
- 事件 output：不要 `on-` 前缀（`@Output() save` 而非 `onSave`）

## Signals（Angular 17+）

新代码优先使用 Signals：

```ts
count = signal(0);
doubled = computed(() => this.count() * 2);

increment() {
  this.count.update(n => n + 1);
}
```

- 在 template 中 `{{ count() }}`
- `effect()` 响应变化

## RxJS

- `async` pipe 优先于手动订阅（自动取消）
- 手动订阅：`takeUntilDestroyed()` 防泄漏
- `subscribe` 必须有 error handler
- 不嵌套 subscribe（用 `switchMap` / `mergeMap` / `concatMap`）

## Change Detection

- `OnPush` 策略默认（性能）：
  ```ts
  @Component({ changeDetection: ChangeDetectionStrategy.OnPush })
  ```
- Immutable 输入（不修改 @Input 引用）
- Signals 自动配合 OnPush

## 依赖注入

- `inject()` 函数优于构造器参数（更灵活）：
  ```ts
  private userService = inject(UserService);
  ```
- Providers：`providedIn: 'root'` 单例
- 避免在组件上直接 `providers`（除非刻意局部实例）

## 路由

- `provideRouter(routes)` 配置
- Lazy loading：`loadComponent: () => import(...)`
- Guard：`CanActivateFn` 函数式
- Resolvers：预加载数据

## 表单

- **Reactive Forms** 优先于 Template-driven
- `FormBuilder` 简化构建
- 自定义 validator：函数返回 `ValidationErrors | null`
- 类型化表单（Typed Forms）

## HTTP

- `HttpClient` 注入
- 拦截器：认证、错误、重试
- 返回 Observable；用 `firstValueFrom` 转 Promise（如需）

## 模板

- `*ngIf` / `*ngFor` → 新语法 `@if` / `@for`（17+ 推荐）：
  ```html
  @for (user of users(); track user.id) {
    <div>{{ user.name }}</div>
  } @empty {
    <div>No users</div>
  }
  ```
- `trackBy` / `track` 必要（大列表性能）

## 样式

- View Encapsulation 默认（`Emulated`）
- SCSS 推荐
- 深层选择器：`::ng-deep`（慎用，deprecated）

## 测试

- Jasmine + Karma（默认）或 Jest
- Cypress / Playwright 做 E2E
- `TestBed` 配置测试模块
- 组件测试：Testing Library for Angular

## 性能

- Lazy load modules / components
- `trackBy` 列表
- `OnPush` + Signals
- 优化 Bundle：`angular.json` 的 budgets 配置

## 反模式

- 订阅不取消 → 内存泄漏
- 在组件写业务逻辑（抽到 service）
- Template 中调用函数（每次变更检测都执行）
- 庞大组件（>200 行，拆分）
- 直接操作 DOM（用 `Renderer2` 或指令）
