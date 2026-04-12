## LBA28 (Logical Block Address)

| Primary通道 | Secondary通道 | in操作       | out操作      |
|-------------|---------------|--------------|--------------|
| 0x1f0       | 0x170         | Data         | Data         |
| 0x1f1       | 0x171         | Error        | Features     |
| 0x1f2       | 0x172         | Sector count | Sector count |
| 0x1f3       | 0x173         | LBA Low      | LBA Low      |
| 0x1f4       | 0x174         | LBA Mid      | LBA Mid      |
| 0x1f5       | 0x175         | LBA High     | LBA High     |
| 0x1f6       | 0x176         | Device       | Device       |
| 0x1f7       | 0x177         | status       | Command      |

- 0x1f0: 数据读写端口
- 0x1f1: 读取错误端口/功能端口
- 0x1f2: 扇区数设置端口
- 0x1f3: 起始扇区低8位
- 0x1f4: 起始扇区中8位
- 0x1f5: 起始扇区高8位
- 0x1f6: 
    - 0~3: 起始扇区
    - 4: 0 主盘，1 从盘
    - 5: 固定为1
    - 6: 0 CHS，1 LBA
    - 7: 固定为1
- 0x1f7: out 操作
    - 0xEC: 识别硬盘
    - 0x20: 读硬盘
    - 0x30: 写硬盘
- 0x1f7: in 操作
    - 0: ERR
    - 3: DRQ 数据准备完毕
    - 7: BSY 硬盘忙

这些 IO 端口是独立编址，不是内存映射，所以访问端口要通过 in/out 指令，而不能用 mov 指令
