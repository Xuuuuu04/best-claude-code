# 常用的编译选项

常用的编译选项说明如下，全量的编译选项请参考[《毕昇编译器用户指南》](https://www.hiascend.com/document/redirect/CannCommunityBiSheng)。

| 选项 | 是否必需 | 说明 |
| --- | --- | --- |
| -help | 否 | 查看帮助。 |
| --npu-arch | 是 | 编译时指定的AI处理器架构，取值为dav-，其中为NPU架构版本号，各产品型号对应的架构版本号请通过[对应关系表](../../语言扩展层/SIMD-BuiltIn关键字.md#table65291052154114)进行查询。 |
| -x | 否 | 指定编译语言。<br>指定为asc时表示Ascend C编程语言。 |
| -o  | 否 | 指定输出文件的名称和位置。 |
| -c | 否 | 编译生成目标文件。 |
| --enable-simt | 是 | 指定SIMT编程场景。 |
