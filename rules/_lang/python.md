---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

<rule>
  <!-- ====== 版本与工具 ====== -->
  <constraint severity="blocker">Python ≥ 3.10（除非项目锁定旧版本）</constraint>
  <constraint severity="blocker">使用 type hints（PEP 484），新代码强制</constraint>
  <convention>Linter: Ruff（或项目已有的 flake8/pylint）</convention>
  <convention>Formatter: Ruff format / Black</convention>
  <convention>类型检查: mypy 或 pyright</convention>

  <!-- ====== 类型注解 ====== -->
  <example type="good">

```python
def get_user(user_id: int) -> User | None:
    ...
```

  </example>
  <example type="bad">

```python
def get_user(user_id):
    ...
```

  </example>
  <convention>使用 `|` 而非 `Union`（3.10+）</convention>
  <convention>使用 `X | None` 而非 `Optional[X]`</convention>
  <convention>内置泛型直接用（`list[int]` 而非 `List[int]`）</convention>

  <!-- ====== 命名 ====== -->
  <convention>变量、函数：`snake_case`</convention>
  <convention>类：`PascalCase`</convention>
  <convention>常量：`UPPER_SNAKE_CASE`</convention>
  <convention>私有：单下划线前缀 `_private`</convention>
  <convention>强私有（name mangling）：双下划线前缀 `__very_private`（慎用）</convention>
  <convention>模块：`lowercase` 或 `snake_case`</convention>

  <!-- ====== 函数与方法 ====== -->
  <constraint severity="blocker">参数默认值**不用可变对象**（`def f(x=[])` 是经典陷阱）</constraint>
  <convention>长参数列表用 keyword-only：`def f(*, x, y)`</convention>
  <convention>返回单一类型（避免 `return dict or None or list` 混合）</convention>
  <convention>文档字符串按 Google / NumPy 风格</convention>

  <!-- ====== 数据类 ====== -->
  <convention>简单结构：`@dataclass`（`frozen=True` 提高不可变性）</convention>
  <convention>校验需求：Pydantic</convention>
  <convention>高性能：`__slots__` + dataclass</convention>
  <pattern>

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class User:
    id: int
    name: str
    email: str
```

  </pattern>

  <!-- ====== 异常 ====== -->
  <constraint severity="blocker">具体异常优于 `Exception`：`raise ValueError` 而非 `raise Exception`</constraint>
  <convention>自定义异常继承 `Exception`（或更具体的）</convention>
  <constraint severity="blocker">`except Exception as e:` 而非裸 `except:`</constraint>
  <convention>链式异常：`raise NewError(...) from e`</convention>

  <!-- ====== 上下文管理器 ====== -->
  <constraint severity="blocker">资源一定用 `with`：</constraint>
  <pattern>

```python
with open(path) as f:
    data = f.read()

# 数据库连接、锁、定时器同理
```

  </pattern>
  <convention>自定义：实现 `__enter__` / `__exit__` 或用 `@contextmanager`。</convention>

  <!-- ====== 异步 ====== -->
  <convention>`async def` + `await`</convention>
  <convention>`asyncio.gather` 并行</convention>
  <constraint severity="blocker">禁止在异步函数内做同步阻塞（`time.sleep`、`requests.get`）</constraint>
  <convention>httpx / aiohttp 而非 requests（异步场景）</convention>

  <!-- ====== 导入 ====== -->
  <convention>按 isort 分组：标准库 → 第三方 → 本项目</convention>
  <constraint severity="warning">避免 `from x import *`</constraint>
  <constraint severity="warning">避免循环导入（如出现，重构模块结构）</constraint>

  <!-- ====== 其他 ====== -->
  <convention>`pathlib.Path` 而非 `os.path`</convention>
  <convention>f-string 而非 `%` 或 `.format()`</convention>
  <convention>`logging` 模块而非 `print`（生产代码）</convention>
  <constraint severity="blocker">不要在模块顶层执行有副作用的代码（IO、网络）</constraint>

  <!-- ====== 测试 ====== -->
  <convention>pytest 优先</convention>
  <convention>测试文件 `test_*.py` 或 `*_test.py`</convention>
  <convention>fixture > setUp</convention>
  <convention>参数化：`@pytest.mark.parametrize`</convention>

  <!-- ====== 安全 ====== -->
  <constraint severity="blocker">禁止字符串拼接 SQL，用参数化或 ORM</constraint>
  <constraint severity="blocker">不用 `pickle` 反序列化不可信数据</constraint>
  <constraint severity="blocker">`yaml.safe_load` 而非 `yaml.load`</constraint>
  <constraint severity="blocker">不用 `eval` / `exec` 处理用户输入</constraint>

  <!-- ====== 性能 ====== -->
  <convention>列表推导优于 filter+map</convention>
  <convention>生成器处理大数据流</convention>
  <convention>`collections.defaultdict` / `Counter` 优于手动初始化</convention>
  <convention>批量 DB 操作（`bulk_create`）而非循环</convention>

</rule>
