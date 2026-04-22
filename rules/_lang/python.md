---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# Python 编码规范

## 版本与工具

- Python ≥ 3.10（除非项目锁定旧版本）
- 使用 type hints（PEP 484），新代码强制
- Linter: Ruff（或项目已有的 flake8/pylint）
- Formatter: Ruff format / Black
- 类型检查: mypy 或 pyright

## 类型注解

```python
# 好
def get_user(user_id: int) -> User | None:
    ...

# 不好
def get_user(user_id):
    ...
```

- 使用 `|` 而非 `Union`（3.10+）
- 使用 `X | None` 而非 `Optional[X]`
- 内置泛型直接用（`list[int]` 而非 `List[int]`）

## 命名

- 变量、函数：`snake_case`
- 类：`PascalCase`
- 常量：`UPPER_SNAKE_CASE`
- 私有：单下划线前缀 `_private`
- 强私有（name mangling）：双下划线前缀 `__very_private`（慎用）
- 模块：`lowercase` 或 `snake_case`

## 函数与方法

- 参数默认值**不用可变对象**（`def f(x=[])` 是经典陷阱）
- 长参数列表用 keyword-only：`def f(*, x, y)`
- 返回单一类型（避免 `return dict or None or list` 混合）
- 文档字符串按 Google / NumPy 风格

## 数据类

- 简单结构：`@dataclass`（`frozen=True` 提高不可变性）
- 校验需求：Pydantic
- 高性能：`__slots__` + dataclass

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class User:
    id: int
    name: str
    email: str
```

## 异常

- 具体异常优于 `Exception`：`raise ValueError` 而非 `raise Exception`
- 自定义异常继承 `Exception`（或更具体的）
- `except Exception as e:` 而非裸 `except:`
- 链式异常：`raise NewError(...) from e`

## 上下文管理器

资源一定用 `with`：

```python
with open(path) as f:
    data = f.read()

# 数据库连接、锁、定时器同理
```

自定义：实现 `__enter__` / `__exit__` 或用 `@contextmanager`。

## 异步

- `async def` + `await`
- `asyncio.gather` 并行
- **禁止**在异步函数内做同步阻塞（`time.sleep`、`requests.get`）
- httpx / aiohttp 而非 requests（异步场景）

## 导入

- 按 isort 分组：标准库 → 第三方 → 本项目
- 避免 `from x import *`
- 避免循环导入（如出现，重构模块结构）

## 其他

- `pathlib.Path` 而非 `os.path`
- f-string 而非 `%` 或 `.format()`
- `logging` 模块而非 `print`（生产代码）
- 不要在模块顶层执行有副作用的代码（IO、网络）

## 测试

- pytest 优先
- 测试文件 `test_*.py` 或 `*_test.py`
- fixture > setUp
- 参数化：`@pytest.mark.parametrize`

## 安全

- **禁止**字符串拼接 SQL，用参数化或 ORM
- 不用 `pickle` 反序列化不可信数据
- `yaml.safe_load` 而非 `yaml.load`
- 不用 `eval` / `exec` 处理用户输入

## 性能

- 列表推导优于 filter+map
- 生成器处理大数据流
- `collections.defaultdict` / `Counter` 优于手动初始化
- 批量 DB 操作（`bulk_create`）而非循环
