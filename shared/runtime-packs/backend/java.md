> 源：core.md §Domain 1.4 Java Stack

# 后端开发师 — Java Stack

## 1.4 Java Stack

├── 1.4.1 Spring Boot — @RestController, @Transactional, self-invocation trap, @ControllerAdvice, @ExceptionHandler
├── 1.4.2 MyBatis — XML mapper with resultMap, @Param, dynamic SQL, #{field} vs ${field}
└── 1.4.3 Spring Security — SecurityFilterChain, JWT filter, @PreAuthorize, AuthenticationManager

---

## Spring Boot Patterns

**@RestController + @Transactional**

```java
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Validated
public class UserController {

    private final UserService userService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UserResponse create(@Valid @RequestBody CreateUserRequest request) {
        return userService.create(request);
    }

    @GetMapping("/{id}")
    public UserResponse findById(@PathVariable Long id) {
        return userService.findById(id);
    }
}

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public UserResponse create(CreateUserRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new ConflictException("EMAIL_ALREADY_EXISTS", "Email already registered");
        }
        User user = User.builder()
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .displayName(request.getDisplayName())
                .build();
        return UserResponse.from(userRepository.save(user));
    }
}
```

**@Transactional self-invocation trap**

```java
// BAD: self-invocation bypasses Spring proxy — @Transactional has NO effect
@Service
public class OrderService {
    public void processOrder(Long orderId) {
        this.createAuditLog(orderId); // calls self — proxy bypassed
    }

    @Transactional
    public void createAuditLog(Long orderId) { /* not in transaction */ }
}

// GOOD: inject self or extract to separate bean
@Service
@RequiredArgsConstructor
public class OrderService {
    private final AuditService auditService; // separate bean — proxy works

    public void processOrder(Long orderId) {
        auditService.createAuditLog(orderId); // goes through Spring proxy
    }
}
```

**@ControllerAdvice + @ExceptionHandler**

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ConflictException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    public ErrorResponse handleConflict(ConflictException ex) {
        return new ErrorResponse(ex.getCode(), ex.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleValidation(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
                .map(e -> e.getField() + ": " + e.getDefaultMessage())
                .collect(Collectors.joining(", "));
        return new ErrorResponse("VALIDATION_ERROR", message);
    }

    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public ErrorResponse handleUnexpected(Exception ex, HttpServletRequest req) {
        log.error("Unhandled exception for {}", req.getRequestURI(), ex);
        return new ErrorResponse("INTERNAL_ERROR", "Internal server error");
    }
}
```

---

## MyBatis Patterns

**XML mapper with resultMap + @Param**

```xml
<!-- UserMapper.xml -->
<mapper namespace="com.example.mapper.UserMapper">
    <resultMap id="userResultMap" type="User">
        <id column="id" property="id"/>
        <result column="email" property="email"/>
        <result column="display_name" property="displayName"/>
        <collection property="roles" ofType="Role" select="selectRolesByUserId" column="id"/>
    </resultMap>

    <select id="findByEmailAndActive" resultMap="userResultMap">
        SELECT id, email, display_name, created_at
        FROM users
        WHERE email = #{email}
          AND is_active = #{isActive}
    </select>

    <!-- Dynamic SQL -->
    <select id="findWithFilters" resultMap="userResultMap">
        SELECT id, email, display_name
        FROM users
        <where>
            <if test="email != null and email != ''">
                AND email = #{email}
            </if>
            <if test="isActive != null">
                AND is_active = #{isActive}
            </if>
        </where>
        ORDER BY created_at DESC
        LIMIT #{pageSize} OFFSET #{offset}
    </select>
</mapper>
```

**#{field} vs ${field} — critical security distinction**

```java
// GOOD: #{field} — parameterized, SQL injection safe
@Mapper
public interface UserMapper {
    @Select("SELECT * FROM users WHERE email = #{email}")
    Optional<User> findByEmail(@Param("email") String email);
}

// BAD: ${field} — string interpolation, SQL injection risk
// @Select("SELECT * FROM users WHERE email = '${email}'")  // NEVER use ${} for user input
// ${} is valid ONLY for column names / table names that are developer-controlled enums
```

---

## Spring Security Patterns

**SecurityFilterChain**

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(csrf -> csrf.disable())
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/v1/auth/**").permitAll()
                        .requestMatchers("/health", "/ready").permitAll()
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
                .build();
    }
}
```

**JWT filter**

```java
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        final String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            chain.doFilter(request, response);
            return;
        }
        final String token = authHeader.substring(7);
        final String userEmail = jwtService.extractUsername(token); // validates sig+exp+iss+aud
        if (userEmail != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            UserDetails userDetails = userDetailsService.loadUserByUsername(userEmail);
            if (jwtService.isTokenValid(token, userDetails)) {
                UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                        userDetails, null, userDetails.getAuthorities());
                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        }
        chain.doFilter(request, response);
    }
}
```

**@PreAuthorize + IDOR guard**

```java
@GetMapping("/{id}")
@PreAuthorize("hasRole('ADMIN') or #id == authentication.principal.id")
public UserResponse findById(@PathVariable Long id) {
    // Spring Security enforces at method level — no manual check needed when annotation is correct
    return userService.findById(id);
}

// For complex IDOR: manual check in service layer
@Transactional(readOnly = true)
public InvitationResponse findInvitation(Long invitationId, Long currentUserId) {
    Invitation invitation = invitationRepository.findById(invitationId)
            .orElseThrow(() -> new NotFoundException("INVITATION_NOT_FOUND", "Invitation not found"));
    // IDOR guard: verify ownership
    if (!invitation.getOwnerId().equals(currentUserId)) {
        throw new ForbiddenException("FORBIDDEN", "Not authorized to access this invitation");
    }
    return InvitationResponse.from(invitation);
}
```
