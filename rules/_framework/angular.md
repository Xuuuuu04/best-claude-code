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

<rule name="angular-version">
  <convention>Angular 17+（Standalone Components 默认）</convention>
</rule>

<rule name="angular-standalone-components">
  <description>新项目优先 Standalone（无 NgModule）</description>
  <pattern>
    <code language="ts">
@Component({
  selector: 'app-user',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './user.component.html'
})
export class UserComponent {}
    </code>
  </pattern>
  <convention>老项目 NgModule 也可，但不混用。</convention>
</rule>

<rule name="angular-naming">
  <convention>组件 selector：app- 前缀</convention>
  <convention>文件：feature.type.ts（user.component.ts、user.service.ts）</convention>
  <convention>类：UserComponent、UserService</convention>
  <convention>事件 output：不要 on- 前缀（@Output() save 而非 onSave）</convention>
</rule>

<rule name="angular-signals">
  <description>新代码优先使用 Signals（Angular 17+）</description>
  <pattern>
    <code language="ts">
count = signal(0);
doubled = computed(() => this.count() * 2);

increment() {
  this.count.update(n => n + 1);
}
    </code>
  </pattern>
  <convention>在 template 中 {{ count() }}</convention>
  <convention>effect() 响应变化</convention>
</rule>

<rule name="angular-rxjs">
  <convention>async pipe 优先于手动订阅（自动取消）</convention>
  <convention>手动订阅：takeUntilDestroyed() 防泄漏</convention>
  <convention>subscribe 必须有 error handler</convention>
  <constraint severity="blocker">不嵌套 subscribe（用 switchMap / mergeMap / concatMap）</constraint>
</rule>

<rule name="angular-change-detection">
  <convention>OnPush 策略默认（性能）：@Component({ changeDetection: ChangeDetectionStrategy.OnPush })</convention>
  <convention>Immutable 输入（不修改 @Input 引用）</convention>
  <convention>Signals 自动配合 OnPush</convention>
</rule>

<rule name="angular-di">
  <convention>inject() 函数优于构造器参数（更灵活）：private userService = inject(UserService);</convention>
  <convention>Providers：providedIn: 'root' 单例</convention>
  <constraint severity="warning">避免在组件上直接 providers（除非刻意局部实例）</constraint>
</rule>

<rule name="angular-routing">
  <convention>provideRouter(routes) 配置</convention>
  <convention>Lazy loading：loadComponent: () => import(...)</convention>
  <convention>Guard：CanActivateFn 函数式</convention>
  <convention>Resolvers：预加载数据</convention>
</rule>

<rule name="angular-forms">
  <convention>Reactive Forms 优先于 Template-driven</convention>
  <convention>FormBuilder 简化构建</convention>
  <convention>自定义 validator：函数返回 ValidationErrors | null</convention>
  <convention>类型化表单（Typed Forms）</convention>
</rule>

<rule name="angular-http">
  <convention>HttpClient 注入</convention>
  <convention>拦截器：认证、错误、重试</convention>
  <convention>返回 Observable；用 firstValueFrom 转 Promise（如需）</convention>
</rule>

<rule name="angular-templates">
  <convention>新语法 @if / @for（17+ 推荐）取代 *ngIf / *ngFor</convention>
  <example type="good">
    <code language="html">
@for (user of users(); track user.id) {
  <div>{{ user.name }}</div>
} @empty {
  <div>No users</div>
}
    </code>
  </example>
  <constraint severity="blocker">trackBy / track 必要（大列表性能）</constraint>
</rule>

<rule name="angular-styles">
  <convention>View Encapsulation 默认（Emulated）</convention>
  <convention>SCSS 推荐</convention>
  <constraint severity="warning">深层选择器 ::ng-deep 慎用（deprecated）</constraint>
</rule>

<rule name="angular-testing">
  <convention>Jasmine + Karma（默认）或 Jest</convention>
  <convention>Cypress / Playwright 做 E2E</convention>
  <convention>TestBed 配置测试模块</convention>
  <convention>组件测试：Testing Library for Angular</convention>
</rule>

<rule name="angular-performance">
  <convention>Lazy load modules / components</convention>
  <convention>trackBy 列表</convention>
  <convention>OnPush + Signals</convention>
  <convention>优化 Bundle：angular.json 的 budgets 配置</convention>
</rule>

<rule name="angular-anti-patterns">
  <constraint severity="blocker">订阅不取消导致内存泄漏</constraint>
  <constraint severity="blocker">在组件写业务逻辑（抽到 service）</constraint>
  <constraint severity="warning">Template 中调用函数（每次变更检测都执行）</constraint>
  <constraint severity="warning">庞大组件（大于200 行，拆分）</constraint>
  <constraint severity="warning">直接操作 DOM（用 Renderer2 或指令）</constraint>
</rule>
