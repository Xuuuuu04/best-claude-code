# 约束说明<a name="ZH-CN_TOPIC_0000002531172022"></a>

-   bfloat16\_t等数据类型在Host侧不支持，使用这些数据类型时，Host和Device不能写在同一个实现文件里。Host侧不支持的数据类型如下：

    Ascend 950PR/Ascend 950DT：bfloat16\_t、hifloat8\_t、fp8\_e5m2\_t、fp8\_e4m3fn\_t、fp8\_e8m0\_t、fp4x2\_e2m1\_t、fp4x2\_e1m2\_t、int4x2\_t。
