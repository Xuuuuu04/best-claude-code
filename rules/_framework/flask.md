---
paths:
  - "**/app.py"
  - "**/wsgi.py"
  - "**/blueprints/**/*.py"
---

<rule name="flask-version">
  <convention>Flask 3.0+</convention>
</rule>

<rule name="flask-project-structure">
  <convention>Blueprint 模块化：每个业务模块一个 blueprint</convention>
  <convention>Application Factory：create_app() 函数返回 app 实例</convention>
  <convention>配置按环境：config.py 定义 Development/Production 类</convention>
  <pattern>
    <code language="python">
def create_app(config_name='default'):
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    # extensions init
    db.init_app(app)
    # blueprints
    from app.api import api_bp
    app.register_blueprint(api_bp, url_prefix='/api')
    return app
    </code>
  </pattern>
</rule>

<rule name="flask-routing">
  <convention>Blueprint 而非全部放 app.route</convention>
  <convention>路由显式方法：@bp.route('/', methods=['POST'])</convention>
  <convention>路径参数类型：<int:id> / <string:name></convention>
  <convention>命名视图：endpoint='user.create'</convention>
</rule>

<rule name="flask-request-handling">
  <convention>request.get_json() 而非 request.json（后者 deprecated）</convention>
  <convention>强制 JSON：force=True 参数</convention>
  <convention>表单：request.form</convention>
  <convention>查询：request.args</convention>
</rule>

<rule name="flask-serialization">
  <description>Flask 无内置序列化。常用：Marshmallow（传统选择）或 Pydantic（类型安全，配合 flask-pydantic）</description>
  <pattern>
    <code language="python">
class UserSchema(Schema):
    id = fields.Int(dump_only=True)
    email = fields.Email(required=True)
    </code>
  </pattern>
</rule>

<rule name="flask-response">
  <convention>jsonify() 返回 JSON（自动 Content-Type）</convention>
  <convention>自定义状态码：return jsonify(data), 201</convention>
  <convention>错误响应统一：abort(404, description='...') + error handler</convention>
</rule>

<rule name="flask-error-handling">
  <pattern>
    <code language="python">
@app.errorhandler(ValidationError)
def handle_validation(e):
    return jsonify({'error': {'code': 'VALIDATION', 'message': str(e)}}), 422
    </code>
  </pattern>
  <convention>全局 handler 避免 Flask 默认 HTML 错误页。</convention>
</rule>

<rule name="flask-extensions">
  <convention>Flask-SQLAlchemy：ORM</convention>
  <convention>Flask-Migrate：Alembic 封装</convention>
  <convention>Flask-Login：会话认证</convention>
  <convention>Flask-JWT-Extended：JWT</convention>
  <convention>Flask-RESTx：REST + Swagger</convention>
  <convention>Flask-Limiter：限流</convention>
  <convention>Flask-CORS：CORS</convention>
</rule>

<rule name="flask-config">
  <convention>app.config + 类式 Config</convention>
  <constraint severity="blocker">敏感值环境变量：os.environ.get('SECRET_KEY')</constraint>
  <convention>dotenv 加载 .env</convention>
</rule>

<rule name="flask-request-context">
  <convention>g 对象：请求范围的数据（g.current_user）</convention>
  <convention>before_request 注入（如从 token 解析用户）</convention>
  <convention>teardown_request 清理资源</convention>
</rule>

<rule name="flask-database">
  <convention>一个请求一个 session（SQLAlchemy 默认）</convention>
  <convention>db.session.commit() 显式提交</convention>
  <convention>异常时 db.session.rollback()</convention>
  <constraint severity="warning">不在事务内做 HTTP / 长 IO</constraint>
</rule>

<rule name="flask-testing">
  <convention>app.test_client() 发起请求</convention>
  <convention>pytest fixture 提供 app 和 客户需求整理师</convention>
  <convention>事务回滚模式提速</convention>
</rule>

<rule name="flask-security">
  <convention>CSRF：Flask-WTF 表单自带（REST API 用 token）</convention>
  <convention>XSS：Jinja2 默认 escape（不用 |safe 除非可控）</convention>
  <constraint severity="blocker">SQL 注入：ORM 参数化（不拼 raw SQL）</constraint>
  <convention>密码：werkzeug.security.generate_password_hash</convention>
  <convention>密钥管理：SECRET_KEY 强随机</convention>
</rule>

<rule name="flask-deployment">
  <constraint severity="blocker">生产用 gunicorn / uWSGI，不用 app.run()</constraint>
  <convention>进程数：workers = 2 * CPU + 1（经验值）</convention>
  <convention>反代 Nginx 处理静态、HTTPS</convention>
</rule>

<rule name="flask-anti-patterns">
  <constraint severity="warning">巨型单文件（大于500 行）：拆 blueprint</constraint>
  <constraint severity="blocker">路由内写业务逻辑（抽到 service）</constraint>
  <constraint severity="warning">不使用 blueprint</constraint>
  <constraint severity="warning">直接暴露 ORM 对象给 JSON（字段可能泄漏）</constraint>
</rule>
