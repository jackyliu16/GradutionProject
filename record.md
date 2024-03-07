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
        
        

