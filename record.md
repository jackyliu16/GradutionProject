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
        - 树莓派4有线网卡驱动调试笔记: https://cloud.tencent.com/developer/article/1758280
        - BCM54213PE_datasheet.PDF: https://gitee.com/bigmagic/raspi_sd_fw/blob/master/doc/raspi4/BCM54213PE_datasheet.PDF

            

