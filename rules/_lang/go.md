---
paths:
  - "**/*.go"
---

# Go 编码规范

## 版本
- Go 1.21+（泛型成熟）

## 项目结构
- `cmd/{app}/main.go`：应用入口
- `internal/`：仅本模块可见
- `pkg/`：可导出给其他模块（慎用，内部工具优先放 `internal/`）
- `api/`：接口定义（proto / OpenAPI）
- `go.mod` 定义模块路径

## 命名
- 包名：小写短名 `auth`、`dbx`（不下划线、不驼峰）
- 导出标识：`PascalCase`
- 非导出：`camelCase`
- 接口名：单方法接口用 `{动词}er`（`Reader`, `Closer`）
- 常量组：同类型用 `const ( ... )`

## 错误处理
- 错误是值，不是异常：`if err != nil { return err }`
- 错误包装：`fmt.Errorf("doing X: %w", err)`（保留 `errors.Is` / `errors.As` 可用）
- 不 panic 作为正常控制流；`panic` 仅用于不可恢复
- 不忽略 error 返回值（除非显式 `_ =`）
- 哨兵错误：`var ErrNotFound = errors.New("not found")`
- 错误类型：需要携带上下文时自定义 `struct{...}` + `Error() string`

## 并发
- goroutine + channel 优于共享内存
- 启动 goroutine **必须**考虑如何结束（`context.Context` 取消、`done` channel）
- `sync.Mutex` 保护共享可变状态；读多写少用 `sync.RWMutex`
- `context.Context` 作为第一个参数传递
- `errgroup.Group` 处理多 goroutine 错误聚合
- 避免 goroutine 泄漏：所有启动的 goroutine 都有明确终止路径

## 接口
- 小接口（1-3 方法）优先
- 接口定义在**使用方**包（consumer），不在实现方
- 不返回接口，接受接口（"accept interfaces, return structs"）

## 资源管理
- `defer` 关闭资源（file、conn、lock）紧跟获取
- HTTP body：`defer resp.Body.Close()`
- 切片预分配：`make([]T, 0, n)`

## 工具链
- `gofmt` / `goimports` 强制格式化
- `go vet` 必过
- `staticcheck` / `golangci-lint` 推荐
- `go test -race` 跑并发测试
- `go.sum` 提交到 git

## 测试
- 文件 `*_test.go`
- 表驱动：
  ```go
  tests := []struct{ name, in, want string }{...}
  for _, tt := range tests {
      t.Run(tt.name, func(t *testing.T) { ... })
  }
  ```
- `testify` 或标准库 `testing` 按项目约定

## 反模式
- `interface{}` / `any` 到处用（失去类型安全）
- 忽略错误
- 在 goroutine 中直接 panic 让主程序崩溃
- 长函数（>80 行）
- 循环变量闭包（Go 1.22 前的经典坑）
