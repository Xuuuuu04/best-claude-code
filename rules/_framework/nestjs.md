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

<rule name="nestjs-version">
  <convention>NestJS 10+（Node 18+）</convention>
</rule>

<rule name="nestjs-layered-architecture">
  <convention>Controller：HTTP 层，参数校验，调用 Service</convention>
  <convention>Service：业务逻辑</convention>
  <convention>Repository：数据访问（TypeORM / Prisma / Mongoose）</convention>
  <convention>DTO：输入输出模型（class-validator + class-transformer）</convention>
  <convention>Entity：领域/持久模型</convention>
</rule>

<rule name="nestjs-modules">
  <convention>按功能划分模块（users.module.ts, orders.module.ts）</convention>
  <convention>每模块 providers + controllers + imports + exports</convention>
  <convention>forRoot / forRootAsync / forFeature 动态模块模式</convention>
</rule>

<rule name="nestjs-di">
  <convention>构造器注入（TS 类型元数据驱动）</convention>
  <convention>@Injectable() 标注可注入类</convention>
  <convention>Provider scope：DEFAULT（单例）、REQUEST（每请求）、TRANSIENT</convention>
</rule>

<rule name="nestjs-controller">
  <pattern>
    <code language="ts">
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
    </code>
  </pattern>
</rule>

<rule name="nestjs-dto-validation">
  <convention>class-validator + class-transformer</convention>
  <convention>全局 ValidationPipe：app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));</convention>
  <convention>whitelist：剥离未声明字段</convention>
  <convention>transform：自动类型转换</convention>
  <pattern>
    <code language="ts">
export class CreateUserDto {
  @IsEmail() email!: string;
  @IsString() @MinLength(8) password!: string;
  @IsInt() @Min(18) age!: number;
}
    </code>
  </pattern>
</rule>

<rule name="nestjs-exceptions">
  <convention>抛 HttpException 或派生类（NotFoundException, BadRequestException, UnauthorizedException）</convention>
  <convention>全局过滤器 @Catch() 统一响应格式</convention>
  <pattern>
    <code language="ts">
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) { /* ... */ }
}
    </code>
  </pattern>
</rule>

<rule name="nestjs-guards-interceptors-pipes-filters">
  <convention>Guard：鉴权（CanActivate）</convention>
  <convention>Interceptor：日志、缓存、转换响应</convention>
  <convention>Pipe：验证、转换参数</convention>
  <convention>Filter：异常处理</convention>
  <pattern>顺序：Guard -> Interceptor（前置）-> Pipe -> Handler -> Interceptor（后置）-> Filter</pattern>
</rule>

<rule name="nestjs-database">
  <convention>TypeORM / Prisma / Mongoose 任选</convention>
  <convention>Prisma 是流行选择（类型安全）</convention>
  <convention>Repository 模式封装 DB 访问</convention>
  <convention>事务：TypeORM @Transaction 或 Prisma $transaction</convention>
</rule>

<rule name="nestjs-config">
  <convention>@nestjs/config 模块</convention>
  <convention>ConfigService 类型安全（配合 Joi 或 class-validator 校验）</convention>
  <convention>.env 分环境</convention>
</rule>

<rule name="nestjs-logging">
  <convention>Logger 默认 + 自定义</convention>
  <convention>生产用 pino / winston（高性能）</convention>
</rule>

<rule name="nestjs-microservices">
  <convention>@nestjs/microservices：gRPC / Kafka / Redis / NATS / MQTT</convention>
  <convention>消息模式：request-response 与 event-based</convention>
</rule>

<rule name="nestjs-websocket">
  <convention>@WebSocketGateway() + Socket.io</convention>
  <convention>鉴权通过 Guard</convention>
</rule>

<rule name="nestjs-testing">
  <convention>Jest 默认</convention>
  <convention>Test.createTestingModule() 构建测试模块</convention>
  <convention>E2E：@nestjs/testing + supertest</convention>
  <convention>Mock providers 做单元测试</convention>
</rule>

<rule name="nestjs-anti-patterns">
  <constraint severity="blocker">业务逻辑写在 Controller</constraint>
  <constraint severity="blocker">多个 responsibilities 塞一个 Service（拆分）</constraint>
  <constraint severity="warning">Global state（违反 DI 原则）</constraint>
  <constraint severity="blocker">不使用 DTO（直接用 any 接收请求）</constraint>
  <constraint severity="warning">循环依赖（forwardRef 是补丁，重构设计）</constraint>
</rule>
