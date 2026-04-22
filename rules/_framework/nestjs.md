---
paths:
  - "**/*.module.ts"
  - "**/*.controller.ts"
  - "**/*.service.ts"
  - "**/*.guard.ts"
  - "**/*.interceptor.ts"
  - "**/*.pipe.ts"
  - "**/*.decorator.ts"
  - "**/main.ts"
---

# NestJS 规范

## 版本
- NestJS 10+（Node 18+）

## 分层

经典分层：
- **Controller**：HTTP 层，参数校验，调用 Service
- **Service**：业务逻辑
- **Repository**：数据访问（TypeORM / Prisma / Mongoose）
- **DTO**：输入输出模型（class-validator + class-transformer）
- **Entity**：领域/持久模型

## 模块

- 按功能划分模块（`users.module.ts`, `orders.module.ts`）
- 每模块 `providers` + `controllers` + `imports` + `exports`
- `forRoot` / `forRootAsync` / `forFeature` 动态模块模式

## 依赖注入

- 构造器注入（TS 类型元数据驱动）
- `@Injectable()` 标注可注入类
- Provider scope：`DEFAULT`（单例）、`REQUEST`（每请求）、`TRANSIENT`

## Controller

```ts
@Controller('users')
export class UsersController {
  constructor(private users: UsersService) {}

  @Get(':id')
  @UseGuards(AuthGuard)
  async findOne(@Param('id', ParseIntPipe) id: number): Promise<UserDto> {
    return this.users.findOne(id);
  }

  @Post()
  async create(@Body() dto: CreateUserDto): Promise<UserDto> {
    return this.users.create(dto);
  }
}
```

## DTO + 校验

- `class-validator` + `class-transformer`
- 全局 `ValidationPipe`：
  ```ts
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
  ```
- `whitelist`：剥离未声明字段
- `transform`：自动类型转换

```ts
export class CreateUserDto {
  @IsEmail() email!: string;
  @IsString() @MinLength(8) password!: string;
  @IsInt() @Min(18) age!: number;
}
```

## 异常

- 抛 `HttpException` 或派生类（`NotFoundException`, `BadRequestException`, `UnauthorizedException`）
- 全局过滤器 `@Catch()` 统一响应格式

```ts
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) { ... }
}
```

## Guards / Interceptors / Pipes

- **Guard**：鉴权（`CanActivate`）
- **Interceptor**：日志、缓存、转换响应
- **Pipe**：验证、转换参数
- **Filter**：异常处理

顺序：Guard → Interceptor（前置）→ Pipe → Handler → Interceptor（后置）→ Filter

## 数据库

- TypeORM / Prisma / Mongoose 任选
- **Prisma** 是流行选择（类型安全）
- Repository 模式封装 DB 访问
- 事务：TypeORM `@Transaction` 或 Prisma `$transaction`

## 配置

- `@nestjs/config` 模块
- `ConfigService` 类型安全（配合 Joi 或 class-validator 校验）
- `.env` 分环境

## 日志

- `Logger` 默认 + 自定义
- 生产用 pino / winston（高性能）

## 微服务

- `@nestjs/microservices`：gRPC / Kafka / Redis / NATS / MQTT
- 消息模式：request-response 与 event-based

## WebSocket

- `@WebSocketGateway()` + Socket.io
- 鉴权通过 Guard

## 测试

- Jest 默认
- `Test.createTestingModule()` 构建测试模块
- E2E：`@nestjs/testing` + supertest
- Mock providers 做单元测试

## 反模式

- 业务逻辑写在 Controller
- 多个 responsibilities 塞一个 Service（拆分）
- Global state（违反 DI 原则）
- 不使用 DTO（直接用 any 接收请求）
- 循环依赖（`forwardRef` 是补丁，重构设计）
