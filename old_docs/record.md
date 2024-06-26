> 其他日志可以在 [blog](https://jackyliu16.bitbucket.io/) [src](https://bitbucket.org/jackyliu16/blog/src/master/)
- 更早的进度不可考究 ... 但是大体上可以认定为在摆烂 ( 没什么时间弄
- 2/29 最终找到了调试失败的罪魁祸首，前面的人在复制别人代码的时候并没有注意到他在进行 jtag 调试的时候所使用的镜像与 chainboot 使用的镜像不同，
只修改 chainboot 的镜像并不会影响最终传输到板子上的仍然是 [rust-raspberrypi-OS-tutorials](https://github.com/rust-embedded/rust-raspberrypi-OS-tutorials)
提供的原始镜像文件（基本上约等于 wfe），他所看到的 load failure 实际上并不是因为加载错误而导致。这也告诉我一个问题，在对别人的工作进行 debug 的时候，
首先要检查前人工作是否出现过失。[record](https://jackyliu16.bitbucket.io/jtag-load-failure-debug-cn/) 
- 3/1 最终完成 Openocd 修复，便携化输出以及对应的[教程文档](https://bitbucket.org/jackyliu16/blog/src/master/content/jtag-debug-in-raspi4.md)，提交了 [PR](https://github.com/arceos-usb/arceos_experiment/pull/11), 目前已经被合并到 usb-next 分支。
- 3/3 完成了一个[简单的 GPIO 库](https://bitbucket.org/jackyliu16/arceos/commits/06efd8ba8dc1592cc678d07eb6cdb4740d48e3d9)的实现（单线程），现在已经可以通过 unsafe 的 寄存器操作，实现对于 raspberry4B 开发版上引脚的管理。 
并且通过简单的 LED 调用以及万能表测试，说明这套 GPIO 库已经实现了他的效果。
    - 这文档怎么明明白白写的 0x7e20_0000 作为 GPIO_REGISTERS_BASE_ADDRESS 然后实际上是 0xfe20_0000 :(
    - 收到了来自周睿同学的建议，可以参考 [embedded-hal](https://github.com/rust-embedded/embedded-hal) 提供的系统调用接口，产生与系统无关的驱动。
    - 未来的进度方向主要有两个，
        - 首先是在原先基础上的改进，尝试通过添加一对串口输入输出，实现对于外界按钮输入的获取，并且直接反馈到亮灯或者无缘蜂鸣器。
        - 其次是通过分析[前人工作经验](https://github.com/orgs/rcore-os/discussions/30)，尝试对于网卡驱动进行剪枝实现。
            - 他们主要是针对于 Cvitek DWMAC 这个驱动进行的实现
            - 根据设备树反汇编可以知道我需要实现的是 brcm,genet-mdio-v5 驱动 (树莓派使用BCM54213PE芯片[#ref](https://zhuanlan.zhihu.com/p/658073678))，应该还是有一些相同的地方的。
            比如说[Cvitek](https://github.com/orgs/rcore-os/discussions/30#discussioncomment-6745603) 和 [broadcom](https://forums.raspberrypi.com/viewtopic.php?t=294815#p1779679) 都采用类似的布局，
            即在 Soc 中包含一个 genet controller 还有一个 broadcom RGMII<->ethernet PHY 芯片。
            - 找到了一个可以发送以太网帧的[脚本](https://github.com/coding-fans/netcode/tree/master/src/c/sendether)
            - 有一个相关教程，说了一嘴他们使用了 MIO(Multiplexed I/O) 经由 RGMII 接口连接 PS，外加通过 EMIO 提供了 GMII 的接口防止有些地方需要实例化某些 PHY 子层。
            > the MAC Transmitter and Receiver modules (in the PS) are connected to a FIFO, which, in turn, exchanges data with memory through a DMA controller. When transmitting, data is first fetched from memory and written into this FIFO, then the FIFO passes this data on to the MAC Tx chain. In the opposite direction, the MAC Rx writes the received data into the FIFO, and the DMA sends this data to memory. This is depicted below in the diagram of the Ethernet controller.
            ![](https://igorfreire-personal-page.s3.us-east-1.amazonaws.com/wp-content/uploads/2016/11/07203043/1000base_t_osi_relationship_802_3_clause_40-1536x1188.png)
    - 一些链接
        - https://github.com/raspberrypi/linux/tree/rpi-5.4.y/drivers/net/ethernet/broadcom/genet
        - https://github.com/u-boot/u-boot/blob/master/drivers/net/bcmgenet.c
        - https://github.com/openbsd/src/blob/master/sys/dev/ic/bcmgenet.c
        - https://github.com/rsta2/circle/blob/master/lib/bcm54213.cpp
        - https://github.com/RT-Thread/rt-thread/blob/master/bsp/raspberry-pi/raspi4-32/driver/drv_eth.c
        - https://zhuanlan.zhihu.com/p/658073678
        - 树莓派4有线网卡驱动调试笔记: https://cloud.tencent.com/developer/article/1758280
        - BCM54213PE_datasheet.PDF: https://gitee.com/bigmagic/raspi_sd_fw/blob/master/doc/raspi4/BCM54213PE_datasheet.PDF

- 3/4
    - 找到一个方式，可以尝试通过 SPI 调用外部其他网络模块，而不一定需要一棵树上吊死
        - [Bare metal networking/Ethernet on Raspberry Pi 4](https://forums.raspberrypi.com/viewtopic.php?t=323242#p1934604)
        - [Writing a “bare metal” operating system for Raspberry Pi 4 (Part 14)](https://www.rpi4os.com/part14-spi-ethernet/)

        - 类似的还有[Weekly driver 4: ENC28J60, Ethernet for your microcontroller](http://blog.japaric.io/wd-4-enc28j60/)，
        这个似乎是基于 [rust-embedded/embedded-hal] 下的一个目前已经被删除的 crates 完成的。
        仓库目前已经处于弃用阶段，同时似乎 rpi4 不在默认支持行列。
        - 董卓睿学长建议通过[Hi-Link/海凌科FPM383F识别指纹模块功耗低半导体面阵传感器]来实现指纹识别效果，
        说是这个模块可以直接通过 UART 直接读。
    - 在 [Owner avatar awesome-embedded-rust ](https://github.com/rust-embedded/awesome-embedded-rust?tab=readme-ov-file#raspberry-pi-silicon)
    上找的一些有关的库。
        - [rainbow-hat-rs](https://crates.io/crates/rainbow-hat-rs):  Rust Driver for the Rainbow HAT for Raspberry Pi. 
            看上去是个单独的模块集成，估计没什么用
        - [rp2040-hal](https://crates.io/crates/rp2040-hal):  A Rust Embeded-HAL impl for the rp2040 microcontroller
            可能可以提供某种程度上的参考
        - [cortex-a](https://github.com/rust-embedded/cortex-a):  Low level access to Cortex-A processors
            看 README 似乎就是 aarch64-cpu 的定制化产品？
        - [enc28j60](https://crates.io/crates/enc28j60): A platform agnostic driver to interface the ENC28J60 (Ethernet controller)
            这个是基于 [embedded-hal] 实现的，应该可以用？找不到之前印象中出现的那个限制主控说明了。
        - [embedded-nal](https://github.com/rust-embedded-community/embedded-nal):  An Embedded Network Abstraction Layer
        - [smoltcp-nal](https://github.com/quartiq/smoltcp-nal):  An embedded-nal implementation for smoltcp
        - [embassy-start](https://github.com/titanclass/embassy-start): A template repository that accomodates a couple of applications and a shared library for embedded asynchronous Rust using the Embassy executor and Hardware Abstraction Layers.

    ![](https://pic1.zhimg.com/v2-f3379c539011186d8b1fbaa5265064f4_r.jpg)

- 3/5-8 今天基本上还在沿着前面一天的继续往后看，还根据朱懿同志的建议把前面的那个 [BCM54213PE] 手册看完了，基本上了解了 MAC 与 BCM54213PE 核心的 MDIO 通信逻辑，
    接下来就是基于现有的基础，尝试进一步理解原先的代码，比如说 [circle] 这种以 cpp 进行的实现带有面向对象的属性，相对来说应该较原始的 c 实现而言更好懂。
    不过好像似乎也不需要明白其中的设计逻辑，某人说像是这种移植的代码其实不太需要考虑其运行逻辑，能跑起来就好。
    最近真的状态不是很好，脑子晃荡晃荡的 ... 本来说 3/10 给初稿的，但是现在的进度其实还没有达到一个能给出初稿的地步，还得加油了。
    
    - DMA: 直接内存访问（Direct Memory Access）[ref](https://blog.csdn.net/phunxm/article/details/9452575) [man](https://www.openhacks.com/uploadsproductos/ar9331_datasheet.pdf)
        - 使我们可以在进行内存或者外设数据传输的时候，不经由 CPU 控制数据传输，转而通过 DMA 控制器。
        会在数据量特别大，速度特别快或者数据特别小，速度特别慢的时候，通过 DMA 的方式加速数据传输。
        - 代码中所指的 DMAC 特指 DMA 控制器。
        - 在一般实现中，DMA 会分为两种映射接口，一种是一致性映射（linux: dma_alloc_coherent），另一种是流式映射（dma_map_single）
    - Mailbox: 一种驱动框架，通过消息队列和中断驱动信号处理多处理器通信
        - 目前看来通过 mailbox 的实现并不是必要的
    - MDF: multifunction device [ref](https://blog.csdn.net/subfate/article/details/53464641)
        将设备注册到 platform 总线？
        感觉是不是有点类似 modules/axdriver 的效果？
- 3/8 今天熟悉了 arceos 上类似网卡驱动的调用堆栈，同时基于 bcm2711 实现了基于 tock_register 的 DMA controller mapping.
    [commit](https://bitbucket.org/jackyliu16/arceos/commits/d67fdcd64e27f28d3139b2fb9a8607ded6099e05)
    126131f..821d48d
    - 重新学习了 rust trait [ref](https://rust-book.junmajinlong.com/ch11/00.html),
    基本了解了原先华山派上 Cvitek 的实现过程，即通过 CvitekNicTraitImpl 对于 CvitekNicTrait 的实现，
    和 axdriver[module] 中对于 CvitekNicTraitImpl 的传递，实现了在 driver_net[crate] 中调用 modules 层面已经完成的实现
    比如说 axhal 下的 paging 功能。
    (有点不太明白这个地方和之前说特性的时候提到的 crate_interface 有什么关系据，据说这个东西是一个可以在用户层面注册的用户驱动方法)
    ![](https://github.com/rcore-os/arceos/raw/main/doc/figures/ArceOS.svg) 

- 3/9 写了下论文，把驱动程序在操作系统上跑起来了
- 3/10 根据 circle 原有的驱动程序，尝试将其移植的过程中出现，异常 panic 的情况，经过检查，发现二者寄存器操作完全一致，尚不了解为什么会出现这种情况。
- 3/11 经过一天的调试之后，发现问题出在下面这段代码

    ```rust
    let reg = read_volatile_wrapper!(ARM_BCM54213_BASE + GENET_UMAC_OFF + UMAC_MAX_FRAME_LEN);
    trace!("reg :{reg:0>32b}");
    write_volatile_wrapper!(
        ENET_MAX_MTU_SIZE,
        ARM_BCM54213_BASE + GENET_UMAC_OFF + UMAC_MAX_FRAME_LEN
    );
    write_volatile(
        (ARM_BCM54213_BASE + GENET_UMAC_OFF + UMAC_MAX_FRAME_LEN) as *mut u32,
        ENET_MAX_MTU_SIZE as u32,
    );
    trace!("ENET_MAX_MTU_SIZE: {ENET_MAX_MTU_SIZE:0>32b}");
        let reg = read_volatile_wrapper!(ARM_BCM54213_BASE + GENET_UMAC_OFF + UMAC_MAX_FRAME_LEN);
    ```

    其中对应的宏如下：

    ```rust
    // Generate I/O inline functions
    // #define GENET_IO_MACRO(name, offset)				\
    // static inline u32 name##_readl(u32 off)				\
    // {								\
    // 	return read32 (ARM_BCM54213_BASE + offset + off);	\
    // }								\
    // static inline void name##_writel(u32 val, u32 off)		\
    // {								\
    // 	write32 (ARM_BCM54213_BASE + offset + off, val);	\
    // }
    macro_rules! write_volatile_wrapper {
        // NOTE: Inverted for easy inspection
        ($val:expr, $reg:expr) => {
            write_volatile((($reg) as *mut usize), $val);
        };
    }

    macro_rules! read_volatile_wrapper {
        ($reg:expr) => {
            read_volatile(($reg as *const u32));
        };
    }

    use crate::consts::*;
    macro_rules! genet_io {
        ("ext", $reg:expr) => {
            (ARM_BCM54213_BASE + GENET_EXT_OFF + $reg)
        };
        ("umac", $reg:expr) => {
            (ARM_BCM54213_BASE + GENET_UMAC_OFF + $reg)
        };
        ("sys", $reg:expr) => {
            (ARM_BCM54213_BASE + GENET_SYS_OFF + $reg)
        };
        ("intrl2_0", $reg:expr) => {
            (ARM_BCM54213_BASE + GENET_INTRL2_0_OFF + $reg)
        };
        ("intrl2_1", $reg:expr) => {
            ARM_BCM54213_BASE + GENET_INTRL2_1_OFF + $reg
        };
        ("hfb", $reg:expr) => {
            ARM_BCM54213_BASE + HFB_OFFSET + $reg
        };
        ("hfb_reg", $reg:expr) => {
            ARM_BCM54213_BASE + HFB_REG_OFFSET + $reg
        };
        ("rbuf", $reg:expr) => {
            ARM_BCM54213_BASE + GENET_RBUF_OFF + $reg
        };
    }
    ```
3/12-3/16: 网卡驱动调试，中间有几天比较颓废，摆烂了下

1. 问题一： mdio_read 中调用 mdio_wait 可能实现不正确，返回值异常：

此处实现采用由 circle 使用的为 clock tick，但是在我实现的时候使用 A::current_time() 替换了这个部分，并且没有修改对应 CLOCKHZ 的参数可能产生错误。

```cpp
do
{
	if (m_pTimer->GetClockTicks ()-nStartTicks >= CLOCKHZ / 100) {
		break;
	}
}
while (umac_readl(UMAC_MDIO_CMD) & MDIO_START_BUSY);
```
        
2. 由于操作寄存器号移位不正确可能导致错误

    ```rust
        // 按照 MDIO 通信标准进行通信操作
        // 此处 PHY_ID 可能设置不正确
        let cmd = MDIO_RD | (PHY_ID << MDIO_PMD_SHIFT) | (reg << MDIO_PWD_SHIFT);
        write_volatile_wrapper!(cmd as u32, genet_io!("mdio", MDIO_CMD));

        let cmd = read_volatile_wrapper!(genet_io!("mdio", MDIO_CMD));
        debug!("write  cmd: {cmd:0>32b}"); // 此处显示与前文行为保持一致

        self.mdio_start(); // busy self.mdio_wait();

        A::udelay(2); // 尝试，未改善结果

        let cmd = read_volatile_wrapper!(genet_io!("mdio", MDIO_CMD));
        debug!("wait   cmd: {cmd:0>32b}");

        if cmd & (MDIO_READ_FAIL as u32) == 1 {
            warn!("mdio_read Failure");
            return -1;
        }

        let cmd = read_volatile_wrapper!(genet_io!("mdio", MDIO_CMD));
        debug!("wait 2 cmd: {cmd:0>32b}"); 
        // 此处与前文 wait cmd 输出结果不一致，其中 后者 BUSY 位被清空，同时在后 16 位中出现了由 PHY 发送的数据信息。

        debug!("(cmd) :        : {}, \t{:0>32b}", cmd, cmd);
        debug!("(cmd & 0xFFFF): {}, \t{:0>32b}", cmd & 0xFFFF, cmd & 0xFFFF);

        (cmd & 0xFFFF) as isize
    ```
    
    在这个地方 (reg << MDIO_REG_SHIFT) 被错误写成 (reg << MDIO_PWD_SHIFT), 可能导致错误。

3. 在类似 circle 实现 clrbits_32 的时候，在对寄存器进行 `reg &= !(clear) as u32` 的时候忘记加上 `=`，导致实际上并没有完成清除位操作。

4. 经过调试，发现是可以通过 mdio 修改 10h 寄存器中的 04？ 位，强制启用 RJ-45 的 LED 功能，
这说明在 MAC 与 RJ-45 之间经由 BCM54213PE(PHY) 的通信正常，
经过查阅文档以及 MII Status register(0x01) 显示 link_status == 0，PHY Extended Status(0x11) 显示 locked == 0, link_status == 0 
说明当前解扰器(Descrambler) 并没有锁定。

> The descrambler locks to the scrambler state after detecting a sufficient number of consecutive idle codes.

感觉有两种可能会导致这个情况，(1) 由于前导一未被检出 (2) 由于 RGMII_MDC 未配置
(1): 在 circle, u-boot 等实现中似乎均没有体现前导一的存在，感觉应该会是不需要的？但是需要测试以确保这个理解是正确的
(2): 可能由于 RGMII_MDC 相关的时钟信号实际上并不在对应 bcmgenet 实现文件中完成，我没抄到这个函数。

NOTE: 看上去由於樹莓派主板上 broadcom 的 PHY 芯片沒有與 JTAG 鏈路鏈接，因此沒有辦法通過 JTAG 方法對於特定端口的信息進行獲取。

能否通过 回环测试来确定是否 PHY 芯片工作正常？[尚未測試]

3/24: 感覺連續擺爛了好幾天的樣子，目前在 broadcom PHY 上沒有進展，不能排除上述任何原因，
目前嘗試將助攻方向轉換成爲 ENC28J60 芯片 SPI 支持。

- http://blog.japaric.io/wd-4-enc28j60/
- 4/16： 完成UART串口初次测试和以太网卡测试，均可以实现简单的收发包，目前正在等待重构。
