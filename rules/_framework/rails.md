---
paths:
  - "**/config/routes.rb"
  - "**/app/models/**/*.rb"
  - "**/app/controllers/**/*.rb"
  - "**/app/views/**/*.erb"
  - "**/db/migrate/**/*.rb"
  - "**/Gemfile"
---

<rule name="rails-version">
  <convention>Rails 7+ (Hotwire / Turbo / Stimulus)</convention>
</rule>

<rule name="rails-convention-over-configuration">
  <convention>表名：users（复数小写）</convention>
  <convention>Model：User（单数驼峰）</convention>
  <convention>Controller：UsersController（复数）</convention>
  <convention>文件路径按约定（不自己造目录结构）</convention>
</rule>

<rule name="rails-fat-model-skinny-controller">
  <convention>业务逻辑放 Model / Service Object</convention>
  <convention>Controller 只负责：接参数、调业务、返响应</convention>
  <constraint severity="blocker">View 不写业务逻辑</constraint>
</rule>

<rule name="rails-model">
  <pattern>
    <code language="ruby">
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
    </code>
  </pattern>
  <convention>关联：has_many / belongs_to / has_one / has_and_belongs_to_many</convention>
  <constraint severity="blocker">验证在 Model（不信任 Controller 层）</constraint>
  <convention>Scope 封装查询</convention>
  <constraint severity="warning">Callback 谨慎（副作用难追踪）</constraint>
</rule>

<rule name="rails-migrations">
  <constraint severity="blocker">禁止修改已部署的 migration</constraint>
  <convention>rails db:rollback 可逆的 change 方法</convention>
  <convention>添加索引：add_index :users, :email, unique: true</convention>
  <convention>外键：add_reference :orders, :user, foreign_key: true</convention>
  <convention>大表改动：后台迁移 / strong_migrations gem 保护</convention>
</rule>

<rule name="rails-controller">
  <pattern>
    <code language="ruby">
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
    </code>
  </pattern>
  <constraint severity="blocker">Strong Parameters 强制 params.require().permit()</constraint>
  <convention>before_action 共享前置逻辑</convention>
  <convention>RESTful 动作：index / show / new / create / edit / update / destroy</convention>
</rule>

<rule name="rails-routes">
  <convention>Resource 风格：resources :users</convention>
  <convention>嵌套浅层：shallow: true</convention>
  <convention>限定 only / except：resources :users, only: [:index, :show]</convention>
  <convention>自定义路由：明确语义</convention>
</rule>

<rule name="rails-service-object">
  <description>复杂业务不放 Model，抽成 Service</description>
  <pattern>
    <code language="ruby">
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
    </code>
  </pattern>
</rule>

<rule name="rails-queries">
  <convention>includes 避免 N+1</convention>
  <convention>references 或 joins 跨表过滤</convention>
  <convention>pluck 只取特定列（少对象实例化）</convention>
  <convention>find_each 批量遍历（避免加载全表）</convention>
</rule>

<rule name="rails-views">
  <convention>部分视图：_form.html.erb</convention>
  <constraint severity="blocker">不在 view 写 DB 查询</constraint>
  <convention>Helper 抽取复杂逻辑</convention>
  <convention>HTML 自动 escape（安全）</convention>
</rule>

<rule name="rails-hotwire">
  <description>Rails 7+</description>
  <convention>Turbo Drive：自动 SPA 式导航</convention>
  <convention>Turbo Frames：局部更新</convention>
  <convention>Turbo Streams：服务器推送 DOM 片段</convention>
  <convention>Stimulus：轻量 JS 行为</convention>
</rule>

<rule name="rails-job-queue">
  <convention>Active Job + Sidekiq / SolidQueue</convention>
  <convention>perform_later 异步；perform_now 同步</convention>
  <convention>幂等（任务可能重跑）</convention>
  <convention>参数只传 ID（不传大对象）</convention>
</rule>

<rule name="rails-security">
  <convention>CSRF 启用（Rails 默认）</convention>
  <constraint severity="blocker">SQL 注入：不拼接 SQL，用参数化：.where('email = ?', email)</constraint>
  <convention>XSS：ERB 自动 escape；raw / html_safe 慎用</convention>
  <convention>Mass Assignment：Strong Parameters 防护</convention>
  <convention>secrets.yml / credentials.yml.enc 加密存储</convention>
</rule>

<rule name="rails-testing">
  <convention>RSpec 或 Minitest</convention>
  <convention>FactoryBot 造数据</convention>
  <convention>shoulda-matchers 简化断言</convention>
  <convention>System tests (Capybara) 做端到端</convention>
</rule>

<rule name="rails-anti-patterns">
  <constraint severity="blocker">Fat Controller / Fat View</constraint>
  <constraint severity="warning">Callback 做重要业务（难测难追）</constraint>
  <constraint severity="warning">rescue Exception（太宽）</constraint>
  <constraint severity="blocker">N+1 不检测</constraint>
  <constraint severity="blocker">在 view 查数据库</constraint>
  <constraint severity="warning">忽略 Gemfile.lock 冲突</constraint>
</rule>
