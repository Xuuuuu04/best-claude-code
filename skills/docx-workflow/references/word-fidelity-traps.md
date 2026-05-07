# Word/DOCX 保真陷阱深化清单

> 灵感来源：Anthropic Word agent 公开行为协议中的 Office.js 实战经验。本文档提炼方法论，不复制原文。

适用：用户要求修改、生成、审阅 .docx 时。

---

## 1. Style Inheritance 三大陷阱

### 陷阱 A：`paragraph.insertParagraph(text, "After")` 继承当前段落 style

如果当前段落是 `Heading 2`，新插入的段落也会是 `Heading 2`。如果当前段落是列表项，新段落会继承列表样式。

**对策**：插入后**显式**设置 `styleBuiltIn`——belt-and-suspenders 模式。

### 陷阱 B：`body.insertParagraph(text, "End")` 总是 `Normal` style

无论文档实际样式如何，从 body 末尾插入永远是 `Normal`。如果文档主要是 `BodyText` 自定义样式，新段落会显得不一致。

**对策**：插入后立即设 `styleBuiltIn = "Heading2"`（或对应样式）。

### 陷阱 C：用 `style` 字段做样式比较会被 locale 坑

`paragraph.style` 返回**本地化显示名**——德语 Office 里 "Heading 1" = "Überschrift 1"。

**对策**：永远用 `styleBuiltIn`（locale-independent enum）做比较。

```ts
// ✗ if (p.style === "Heading 1") ...   // 在德语 Office 失败
// ✓ if (p.styleBuiltIn === Word.Style.heading1) ...
```

---

## 2. Track Changes（修订模式）决策树

接到"改这份合同"任务时：

```
1. 先读 doc_state.changeTrackingMode
2. 文档是合同 / 法律文件 / 协议 / 包含编号条款？
   ├─ 是 + Track Changes Off → 主动询问用户：
   │   "需要追踪修订（redline）还是直接改写？"
   │   等用户答 → 按答案进行
   ├─ 是 + Track Changes On → 直接改，redlines 自动产生
   └─ 否（普通文档） → 直接改
3. 用户已说"redline / mark up / 追踪修订" → 主动 turn on，告知用户
```

**禁止**：
- 永远不要用手动 strikethrough + 红色字体**模拟** redline——用真正的 Track Changes API
- 永远不要为"清理"自动 accept/reject 已有修订——它们是审核轨迹
- 永远不要 turn off Track Changes——决策权在用户

---

## 3. Comment（评论）通过 ID 引用，不通过文本

`doc_state` 列出每条 comment 的 id + anchor 预览 + reply 数。

**禁止**：
- 用 anchor 文本搜索 comment——文本可能含 apostrophe 编码差异
- 用文本搜索 comment 在你刚改过附近内容后会更不可靠
- 直接 delete comment "清理掉"——除非用户明确要求

**正确**：
- 通过 `comment.id` 索引
- 回复用 `comment.reply(text)`，**不**创建新顶层 comment
- 同一 comment 一个 turn 内只回复一次

---

## 4. Anchor 内编辑 sub-range，不编辑 whole anchor

如果某 comment 的 anchor 范围是一整句"The Company shall pay...."，你要改其中"shall"为"will":

- ✗ 用 `range.insertText(newText, "Replace")` 替换整 anchor → comment thread 跟整段一起被删除
- ✓ 只替换 "shall" 这个词 → comment 仍附在剩余文本上

工具层面：用 `edit_doc_text(old_text="shall", new_text="will")` 而不是手写 Office.js 全段替换。

---

## 5. Read-back 字体（避免主题字体污染）

每次插入新段落后，**读回 font.name 和 font.size**。

为什么：Word 主题字体（Aptos / Calibri）会"渗透"——即使文档主体是 Times New Roman，新插入的段落可能默认拿到主题字体。

**对策**：
1. 读 `doc_state` 里文档主 body font
2. 插入后 set `para.font.name = bodyFont; para.font.size = bodySize`
3. 读回这两个属性确认生效

---

## 6. 内联引用不能 Replace through

以下元素藏在文本 run 里，看似透明但极易被破坏：

- **Footnote markers**（`<w:footnoteReference>`）
- **Cross-references**（"see Section 2.1"）
- **Bookmarks** 边界
- **Inline pictures / charts**（图表位于段落内）

`range.insertText(newText, "Replace")` 包含这些元素 → 元素消失。

**对策**：编辑前检查
- `range.footnotes` `range.fields` `range.inlinePictures` `range.getBookmarks()`
- 任一非空 → 编辑**周围**文本，不编辑包含元素的范围
- 跨脚注重写句子？分两次：脚注前的部分 + 脚注后的部分

---

## 7. Tables 原子化创建

错误模式：
1. 创建空 table
2. `context.sync()`
3. 填充每个 cell
4. 第二次 sync 失败 → 留下空 table

**正确**：把 data 作为 `insertTable` 的第四参数，单次原子调用：

```ts
body.insertTable(rows, cols, "End", [["A", "B"], ["1", "2"]]);
```

---

## 8. List Items 不要写字面 bullet

错误：写 `"• Item 1"` 作为段落文本——看起来像列表但不是。

**正确**：
```ts
para.style = "List Bullet";   // 真列表
// 或
para.style = "List Number";
```

**禁止**：`paragraph.startNewList()`（已知 bug，throws GeneralException）。

---

## 9. Empty paragraph 可能是图表锚点

`paragraph.text === ""` 不代表段落真空——可能锚定一个 inline picture / chart。`paragraph.text` 不包含 drawings。

**对策**：删除"看似空"的段落前，检查 `range.inlinePictures.items.length > 0` 或 `getOoxml()` 含 `<w:drawing>`。

---

## 10. Header / Footer 在 section 上不在 body 上

错误：`document.body.headers` —— 不存在这个 API。

**正确**：`section.getHeader("Primary")`——返回的对象与 `body` 同 API。

变体：`Primary` / `FirstPage` / `EvenPages`。多 section 文档每个 section 独立。

页码用 `range.insertField("End", "Page")`——不要写字面 `"Page 1"`（无法自动更新）。

---

## 11. 错误恢复：read 后再修

写脚本抛错时：

1. **不重跑原脚本**——可能已经部分写入（如插了 5 段失败了，重跑会插 10 段）
2. **read 受影响区域**
3. **从观察状态精修**：删除多余 / 补足缺失

---

## 12. 多 section 文档分批 ship

错误：单次 `execute_office_js` 写整本 30 页报告——用户看不到进度，超时风险高。

**正确**：
1. 先在 chat 列出 section 大纲
2. 一个 `execute_office_js` 一个 section
3. 每次插入后**读回**已有 headings
4. 与大纲对照，发现重复或漏写
