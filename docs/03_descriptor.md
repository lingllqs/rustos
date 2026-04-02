## GDT

```text
+------------------------------------------------------------------------+
|      Base      |G |D |B |A | Limit  |P |PL|S |  Type  |     Base       |
+------------------------------------------------------------------------+
|              Base                   |              Limit               |
+------------------------------------------------------------------------+
```

```c
struct {
    unsigned short limit_low : 16; // Limit
    unsigned int base_low : 24;    // Base
    unsigned char type : 4;        // Type
    unsigned char segment : 1;     // S
    unsigned char DPL : 2;         // PL
    unsigned char present : 1;     // P
    unsigned char limit_high : 4;  // Limit
    unsigned char available : 1;   // Avaliable
    unsigned char long_mode : 1;   // B(64位模式)
    unsigned char big : 1;         // D(代码段:操作数16bit/32畢，数据段:栈指针大小)
    unsigned char granularity : 1; // G(granularity)
    unsigned char base_high;       // Base
};
```
