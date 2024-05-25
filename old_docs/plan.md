

## WHY

  通过 arceos 实现这个项目主要是想尝试下通过幺内核(unikernel)这种相对少见的内核形态（相较于宏内核和微内核而言），
  尝试重构一些简单的，甚至是古早年代风格的工程。并且在充足时间的情况下，完成一种现有的RTOS，标准linux内核，以及unikernel之间的实现对比（根据目前相关工具等的实现情况来看，只能实现一些相对简单的对比）
  并且在尽可能的前提下，使用更便宜的硬件完成对应的工作。

## WHAT

  主要完成的工作基本上相当于需要通过一系列方法，在一块开发版上完成最基础的基于外界输入实现的网络或串口输出效果，
  并且通过局域网内主机或者其他开发版对于其发送的包或者串口信息进行收取。
  在本地计算机或者嵌入式设备中以数据库方式存储对应加密信息，
  当受到客户端发来的验证请求之后，经由数据库检查之后向客户端发出完成打卡信号，
  客户端在收到打卡信号完成之后，自动显示对应指示灯以说明完成打卡活动。

## HOW

  任务主要以阶段性方式完成，主要考虑优先达到一个能毕业的要求，比如说先通过 RTThread 完成对照组网络或串口信息发包设计，然后再跨步到 arceos 完成后续比较。

  1. 基于一款文档相对来说比较全面的开发板 raspberry 4B bcm2711 进行实现
    1. 能通过串口连接设备，并且通过外置的按钮，在操作系统串口终端上输出对应信息。并且能够使某一指示灯亮起（通过引脚控制等方式）。
    2a. 能够通过 Gigabit Ethernet controller driver 或者其缩水实现，完成简单 UDP 发包实验，以能在同一局域网内或另一树莓派主机抓到对应包为准。
        - 缩水实现指通过简化常见的多层网络协议栈形式，降低实现难度（当前选用的操作系统尚未实现对应的网卡驱动）[1](https://forums.raspberrypi.com/viewtopic.php?t=271651#p1654653) [2](https://www.eevblog.com/forum/projects/bare-metal-udp-what_s-involved/msg937862/#msg937862)
        - UDP 发包实验可由本质上简化成为最简单的以太网帧发送模式，以降低实现难度，具体只为了证明确实可以实现这样的操作。
        - 或者说根据 arceos 的需求，直接通过实现 driver_net 中所规定的 trait, 来间接调用对应的服务。
    2b. 或者能够通过串口发送加密数据包方式，实现两台树莓派之间的通信以及授权，授权通过之后，某一指示灯亮起。
    3. 在其他操作系统（RTOS, Linux）中复现现有工作，并且尝试对比同等情况下的性能。
    3. 提供更多其他识别驱动支持，比如说指纹识别，NFC，ID卡，液晶显示等现代考勤系统中常见的驱动模块。
        - 液晶显示理论上可以通过串口输出的方式予以实现(临时)
  2. 尝试在一些相对比较便宜的开发版上复现原先实现效果，比如说 luckfox 等。
  

- [bare-metal-led-access](https://raspberrypi.stackexchange.com/questions/135867/bare-metal-led-access-on-rpi-4)
- [raspi3-tutorial](https://github.com/bztsrc/raspi3-tutorial)
- receiving and transmitting of raw Ethernet packets
  - [recvRawEth.c](https://gist.github.com/austinmarton/2862515) [sendRawEth.c](https://gist.github.com/austinmarton/1922600)
- tcpdump will read traffic at layer 2
- [genet/bcmgenet.c](https://github.com/raspberrypi/linux/blob/rpi-4.19.y/drivers/net/ethernet/broadcom/genet/bcmgenet.c)
- [10BASE-T FPGA interface](https://www.fpga4fun.com/10BASE-T.html)



