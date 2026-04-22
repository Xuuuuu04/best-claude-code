---
paths:
  - "**/config/routes.rb"
  - "**/app/models/**/*.rb"
  - "**/app/controllers/**/*.rb"
  - "**/app/views/**/*.erb"
  - "**/db/migrate/**/*.rb"
  - "**/Gemfile"
---

# Ruby on Rails 规范

## 版本
- Rails 7+ (Hotwire / Turbo / Stimulus)

## 约定优于配置（CoC）

- 表名：`users`（复数小写）
- Model：`User`（单数驼峰）
- Controller：`UsersController`（复数）
- 文件路径按约定（不自己造目录结构）

## Fat Model, Skinny Controller

- 业务逻辑放 Model / Service Object
- Controller 只负责：接参数、调业务、返响应
- View 不写业务逻辑

## Model

```ruby
class User < ApplicationRecord
  has_many :orders, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  scope :active, -> { where(status: 'active') }
  
  before_save :normalize_email
  
  private
  
  def normalize_email
    self.email = email.downcase.strip
  end
end
```

- 关联：`has_many` / `belongs_to` / `has_one` / `has_and_belongs_to_many`
- 验证在 Model（不信任 Controller 层）
- Scope 封装查询
- Callback 谨慎（副作用难追踪）

## Migration

- **禁止** 修改已部署的 migration
- `rails db:rollback` 可逆的 change 方法
- 添加索引：`add_index :users, :email, unique: true`
- 外键：`add_reference :orders, :user, foreign_key: true`
- 大表改动：后台迁移 / `strong_migrations` gem 保护

## Controller

```ruby
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :update, :destroy]
  
  def index
    @users = User.active.page(params[:page])
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  end
  
  def user_params
    params.require(:user).permit(:email, :name)
  end
end
```

- Strong Parameters 强制 `params.require().permit()`
- `before_action` 共享前置逻辑
- RESTful 动作：`index / show / new / create / edit / update / destroy`

## Routes

- Resource 风格：`resources :users`
- 嵌套浅层：`shallow: true`
- 限定 only / except：`resources :users, only: [:index, :show]`
- 自定义路由：明确语义

## Service Object

复杂业务不放 Model，抽成 Service：

```ruby
class RegisterUser
  def initialize(params)
    @params = params
  end

  def call
    ActiveRecord::Base.transaction do
      user = User.create!(@params)
      SendWelcomeEmail.new(user).call
      user
    end
  end
end
```

## 查询

- `includes` 避免 N+1
- `references` 或 `joins` 跨表过滤
- `pluck` 只取特定列（少对象实例化）
- `find_each` 批量遍历（避免加载全表）

## 视图（传统 ERB）

- 部分视图：`_form.html.erb`
- 不在 view 写 DB 查询
- Helper 抽取复杂逻辑
- HTML 自动 escape（安全）

## Hotwire（Rails 7+）

- **Turbo Drive**：自动 SPA 式导航
- **Turbo Frames**：局部更新
- **Turbo Streams**：服务器推送 DOM 片段
- **Stimulus**：轻量 JS 行为

## 任务队列

- **Active Job** + Sidekiq / SolidQueue
- `perform_later` 异步；`perform_now` 同步
- 幂等（任务可能重跑）
- 参数只传 ID（不传大对象）

## 安全

- CSRF 启用（Rails 默认）
- SQL 注入：**不**拼接 SQL，用参数化：`.where('email = ?', email)`
- XSS：ERB 自动 escape；`raw` / `html_safe` 慎用
- Mass Assignment：Strong Parameters 防护
- `secrets.yml` / `credentials.yml.enc` 加密存储

## 测试

- RSpec 或 Minitest
- FactoryBot 造数据
- `shoulda-matchers` 简化断言
- System tests (Capybara) 做端到端

## 反模式

- Fat Controller / Fat View
- Callback 做重要业务（难测难追）
- `rescue Exception`（太宽）
- N+1 不检测
- 在 view 查数据库
- 忽略 Gemfile.lock 冲突
