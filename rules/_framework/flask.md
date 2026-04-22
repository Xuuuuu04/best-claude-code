---
paths:
  - "**/app.py"
  - "**/wsgi.py"
  - "**/blueprints/**/*.py"
---

# Flask 规范

## 版本
- Flask 3.0+

## 项目结构

- **Blueprint** 模块化：每个业务模块一个 blueprint
- Application Factory：`create_app()` 函数返回 app 实例
- 配置按环境：`config.py` 定义 `Development`/`Production` 类

```python
def create_app(config_name='default'):
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    # extensions init
    db.init_app(app)
    # blueprints
    from app.api import api_bp
    app.register_blueprint(api_bp, url_prefix='/api')
    return app
```

## 路由

- Blueprint 而非全部放 `app.route`
- 路由显式方法：`@bp.route('/', methods=['POST'])`
- 路径参数类型：`<int:id>` / `<string:name>`
- 命名视图：`endpoint='user.create'`

## 请求处理

- `request.get_json()` 而非 `request.json`（后者 deprecated）
- 强制 JSON：`force=True` 参数
- 表单：`request.form`
- 查询：`request.args`

## Marshmallow / Pydantic

Flask 无内置序列化。常用：
- **Marshmallow**：传统选择
- **Pydantic**：类型安全（配合 `flask-pydantic`）

```python
class UserSchema(Schema):
    id = fields.Int(dump_only=True)
    email = fields.Email(required=True)
```

## 响应

- `jsonify()` 返回 JSON（自动 Content-Type）
- 自定义状态码：`return jsonify(data), 201`
- 错误响应统一：`abort(404, description='...')` + error handler

## 错误处理

```python
@app.errorhandler(ValidationError)
def handle_validation(e):
    return jsonify({'error': {'code': 'VALIDATION', 'message': str(e)}}), 422
```

全局 handler 避免 Flask 默认 HTML 错误页。

## 扩展

- **Flask-SQLAlchemy**：ORM
- **Flask-Migrate**：Alembic 封装
- **Flask-Login**：会话认证
- **Flask-JWT-Extended**：JWT
- **Flask-RESTx**：REST + Swagger
- **Flask-Limiter**：限流
- **Flask-CORS**：CORS

## 配置

- `app.config` + 类式 Config
- 敏感值环境变量：`os.environ.get('SECRET_KEY')`
- `dotenv` 加载 `.env`

## 请求上下文

- `g` 对象：请求范围的数据（`g.current_user`）
- `before_request` 注入（如从 token 解析用户）
- `teardown_request` 清理资源

## 数据库

- 一个请求一个 session（SQLAlchemy 默认）
- `db.session.commit()` 显式提交
- 异常时 `db.session.rollback()`
- 不在事务内做 HTTP / 长 IO

## 测试

- `app.test_client()` 发起请求
- `pytest` fixture 提供 app 和 client
- 事务回滚模式提速

## 安全

- CSRF：`Flask-WTF` 表单自带（REST API 用 token）
- XSS：Jinja2 默认 escape（不用 `|safe` 除非可控）
- SQL 注入：ORM 参数化（不拼 raw SQL）
- 密码：`werkzeug.security.generate_password_hash`
- 密钥管理：`SECRET_KEY` 强随机

## 部署

- 生产用 gunicorn / uWSGI，**不用** `app.run()`
- 进程数：`workers = 2 * CPU + 1`（经验值）
- 反代 Nginx 处理静态、HTTPS

## 反模式

- 巨型单文件（>500 行）：拆 blueprint
- 路由内写业务逻辑（抽到 service）
- 不使用 blueprint
- 直接暴露 ORM 对象给 JSON（字段可能泄漏）
