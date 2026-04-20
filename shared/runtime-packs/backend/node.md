> 源：core.md §Domain 1.2 Node.js Stack

# 后端开发师 — Node.js Stack

## 1.2 Node.js Stack

├── 1.2.1 NestJS — Controller/Injectable/InjectRepository, Guard/Interceptor/Pipe lifecycle, ValidationPipe with whitelist, RBAC guard
├── 1.2.2 Express — asyncHandler, express-validator, helmet(), centralized error middleware
└── 1.2.3 Prisma ORM — prisma.user.findMany, $transaction, prisma migrate dev, prisma.$queryRaw

---

## NestJS Patterns

**Controller + Injectable + InjectRepository**

```typescript
import { Controller, Post, Body, Get, Param, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() createUserDto: CreateUserDto): Promise<UserResponseDto> {
    return this.usersService.create(createUserDto);
  }

  @Get(':id')
  async findOne(@Param('id') id: string): Promise<UserResponseDto> {
    return this.usersService.findOne(+id);
  }
}

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async create(dto: CreateUserDto): Promise<UserResponseDto> {
    const existing = await this.userRepository.findOne({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException({ code: 'EMAIL_ALREADY_EXISTS', message: 'Email already registered' });
    }
    const user = this.userRepository.create({
      ...dto,
      password: await bcrypt.hash(dto.password, 12),
    });
    const saved = await this.userRepository.save(user);
    return plainToInstance(UserResponseDto, saved);
  }
}
```

**Guard / Interceptor / Pipe lifecycle**

```typescript
// ValidationPipe with whitelist — strips unknown properties, enforces DTO types
app.useGlobalPipes(new ValidationPipe({
  whitelist: true,           // strip unknown properties
  forbidNonWhitelisted: true, // throw on unknown properties
  transform: true,           // auto-transform primitives to declared types
}));

// RBAC Guard
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!requiredRoles) return true;
    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.some((role) => user.roles?.includes(role));
  }
}
```

---

## Express Patterns

**asyncHandler + express-validator + centralized error middleware**

```typescript
import { RequestHandler } from 'express';
import { body, validationResult } from 'express-validator';
import asyncHandler from 'express-async-handler';
import helmet from 'helmet';

// Security middleware
app.use(helmet());

// Validation rules (defined separately for reuse)
export const createUserValidation = [
  body('email').isEmail().normalizeEmail().isLength({ max: 254 }),
  body('password').isLength({ min: 8, max: 128 }),
  body('display_name').trim().isLength({ min: 1, max: 100 }).escape(),
];

// Route handler with asyncHandler (eliminates try/catch boilerplate)
router.post('/', createUserValidation, asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      type: 'https://api.example.com/errors/validation',
      title: 'Validation Failed',
      status: 400,
      errors: errors.array(),
    });
  }
  const user = await userService.create(req.body);
  res.status(201).json(user);
}));

// Centralized error middleware (must have 4 params)
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  logger.error({ err, url: req.url, method: req.method }, 'Unhandled error');
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ code: err.code, message: err.message });
  }
  res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Internal server error' });
});
```

---

## Prisma ORM Patterns

**Core query patterns**

```typescript
// findMany with relations and pagination
const users = await prisma.user.findMany({
  where: { isActive: true },
  include: { profile: true, roles: { include: { role: true } } },
  orderBy: { createdAt: 'desc' },
  skip: (page - 1) * pageSize,
  take: pageSize,
});

// $transaction for multi-table writes
const [invitation, _ ] = await prisma.$transaction([
  prisma.invitation.create({ data: invitationData }),
  prisma.auditLog.create({ data: { action: 'INVITATION_CREATED', userId: currentUser.id } }),
]);
```

**prisma migrate workflow**

```bash
# Check current migration status — BLOCK if pending
npx prisma migrate status

# Apply pending migrations (development)
npx prisma migrate dev --name add_invitation_table

# Production: generate and apply
npx prisma migrate deploy
```

**Raw query with parameterization**

```typescript
// GOOD: parameterized raw query
const result = await prisma.$queryRaw<User[]>`
  SELECT * FROM users WHERE email = ${email} AND is_active = true
`;

// BAD: never do this
// const result = await prisma.$queryRawUnsafe(`SELECT * FROM users WHERE email = '${email}'`);
```
