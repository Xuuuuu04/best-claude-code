---
paths:
  - "**/*.go"
---

<rule>
  <!-- ====== 版本 ====== -->
  <requirement>Go 1.21+（泛型成熟）</requirement>

  <!-- ====== 项目结构 ====== -->
  <convention>`cmd/{app}/main.go`：应用入口</convention>
  <convention>`internal/`：仅本模块可见</convention>
  <convention>`pkg/`：可导出给其他模块（慎用，内部工具优先放 `internal/`）</convention>
  <convention>`api/`：接口定义（proto / OpenAPI）</convention>
  <convention>`go.mod` 定义模块路径</convention>

  <!-- ====== 命名 ====== -->
  <convention>包名：小写短名 `auth`、`dbx`（不下划线、不驼峰）</convention>
  <convention>导出标识：`PascalCase`</convention>
  <convention>非导出：`camelCase`</convention>
  <convention>接口名：单方法接口用 `{动词}er`（`Reader`, `Closer`）</convention>
  <convention>常量组：同类型用 `const ( ... )`</convention>

  <!-- ====== 错误处理 ====== -->
  <constraint severity="blocker">错误是值，不是异常：`if err != nil { return err }`</constraint>
  <convention>错误包装：`fmt.Errorf("doing X: %w", err)`（保留 `errors.Is` / `errors.As` 可用）</convention>
  <constraint severity="blocker">不 panic 作为正常控制流；`panic` 仅用于不可恢复</constraint>
  <constraint severity="blocker">不忽略 error 返回值（除非显式 `_ =`）</constraint>
  <convention>哨兵错误：`var ErrNotFound = errors.New("not found")`</convention>
  <convention>错误类型：需要携带上下文时自定义 `struct{...}` + `Error() string`</convention>

  <!-- ====== 并发 ====== -->
  <convention>goroutine + channel 优于共享内存</convention>
  <constraint severity="blocker">启动 goroutine 必须考虑如何结束（`context.Context` 取消、`done` channel）</constraint>
  <convention>`sync.Mutex` 保护共享可变状态；读多写少用 `sync.RWMutex`</convention>
  <convention>`context.Context` 作为第一个参数传递</convention>
  <convention>`errgroup.Group` 处理多 goroutine 错误聚合</convention>
  <constraint severity="blocker">避免 goroutine 泄漏：所有启动的 goroutine 都有明确终止路径</constraint>

  <!-- ====== 接口 ====== -->
  <convention>小接口（1-3 方法）优先</convention>
  <convention>接口定义在使用方包（consumer），不在实现方</convention>
  <convention>不返回接口，接受接口（"accept interfaces, return structs"）</convention>

  <!-- ====== 资源管理 ====== -->
  <convention>`defer` 关闭资源（file、conn、lock）紧跟获取</convention>
  <convention>HTTP body：`defer resp.Body.Close()`</convention>
  <convention>切片预分配：`make([]T, 0, n)`</convention>

  <!-- ====== 工具链 ====== -->
  <constraint severity="blocker">`gofmt` / `goimports` 强制格式化</constraint>
  <constraint severity="blocker">`go vet` 必过</constraint>
  <convention>`staticcheck` / `golangci-lint` 推荐</convention>
  <convention>`go test -race` 跑并发测试</convention>
  <convention>`go.sum` 提交到 git</convention>

  <!-- ====== 测试 ====== -->
  <convention>文件 `*_test.go`</convention>
  <convention>表驱动：</convention>
  <pattern>

```go
tests := []struct{ name, in, want string }{...}
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) { ... })
}
```

  </pattern>
  <convention>`testify` 或标准库 `testing` 按项目约定</convention>

  <!-- ====== 反模式 ====== -->
  <constraint severity="warning">`interface{}` / `any` 到处用（失去类型安全）</constraint>
  <constraint severity="blocker">忽略错误</constraint>
  <constraint severity="blocker">在 goroutine 中直接 panic 让主程序崩溃</constraint>
  <constraint severity="warning">长函数（大于 80 行）</constraint>
  <constraint severity="warning">循环变量闭包（Go 1.22 前的经典坑）</constraint>

</rule>
