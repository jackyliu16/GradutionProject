# 毕业论文复现指引

##############################################################################
# 开源说明：本项目根据开源毕设要求，在[github](https://github.com/jackyliu16/GradutionProject),[bitbucket](https://bitbucket.org/jackyliu16/workspace/repositories/)网站上开源毕设实现代码 #
# 后续可能进一步完善对应项目。                                               #
# 项目地址为: https://github.com/jackyliu16/GradutionProject                 #
# git clone https://github.com/jackyliu16/GradutionProject.git 后            #
# 使用下面的指令可以获取最新的版本                                           #
# git submodule init; git submodule update;                                  #
# 部分文档在当前尚未完成，因此尚未计入项目中                                 #
# https://jackyliu16.bitbucket.io/                                           #
##############################################################################

本文档将会分为以下部分展开：

1. 了解本项目所必要的基础知识讲解
2. 本项目中各文件说明
3. 如何实际运行本项目

## 基础知识说明

由于本项目采用 Nix 管理整体项目文件，大部分的 source 来自境外。
虽然 sjtug 提供了国内镜像站服务，但是部分依赖下载仍极度依赖代理。
众所周知，使用代理是中国境内的计算机，软件等相关专业的必要工具，因此不做更加详细的讲解。

虽然实际上是存在手工配置对应依赖的操作方式的（参见 [arceos](https://github.com/arceos-org/arceos/) 项目提供的依赖安装工具），
但是我并没有在实机上测试这种配置方式，因此不能保证一定能复现成功。

### 安装 Nix 包管理工具

对于如下的系统而言，可以直接安装 Nix 包管理工具（尚未在 drawin 上测试软件，目前仅支持 x86_64-linux 下编译）。


| Platform                     | Multi User         | `root` only | Maturity          |
|------------------------------|:------------------:|:-----------:|:-----------------:|
| Linux (x86_64 & aarch64)     | ✓ (via [systemd])  | ✓           | Stable            |
| MacOS (x86_64 & aarch64)     | ✓                  |             | Stable (See note) |
| Valve Steam Deck (SteamOS)   | ✓                  |             | Stable            |
| WSL2 (x86_64 & aarch64)      | ✓ (via [systemd])  | ✓           | Stable            |
| Podman Linux Containers      | ✓ (via [systemd])  | ✓           | Stable            |
| Docker Containers            |                    | ✓           | Stable            |
| Linux (i686)                 | ✓ (via [systemd])  | ✓           | Unstable          |

下面的指令通过使用 [nix-installer](https://github.com/DeterminateSystems/nix-installer) 仓库所提供的方便安装工具，
实现社区级别的 Nix 安装效果。

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

请注意，安装的时间相对较长而且很大程度上有可能收到代理或者国内网络环境 DNS 污染的影响，如果出现类似的情况，
请 STFW 有关的信息。（考虑到国内网络环境情况，不一定确定我在当前这一时间写下的相关内容是否能符合进行检查时候的）

不过，还请首先检查能否通过 ping 或者 curl 在本地终端中连接到 www.google.com，如果出现 usercontent.github.com 相关的报错，
请先检查能否在终端层面连接到 github，如果不行，参照 [github520](https://github.com/521xueweihan/GitHub520) 或者其镜像站（cn.bing.com 搜索 github520）的指引进行。

### 基础 Nix 指令说明

由于，在本毕业设计的实现中大部分的内容均被涵盖在 nix flake 的管理范畴之中，可以直接使用 

- `nix develop .#` 在对应的目录中打开对应的开发环境，受到你使用的开发环境可能没有完全配置号 nix 的各项参数的影响，
可以在命令行中添加下面的部分来执行对应的代码：
  - 如果出现相关报错，可以直接在 nix develop 后面加上 `--extra-experimental-features nix-command --extra-experimental-features flakes` 
    这是因为 nix flake 相关的指令属于一种相对 experimental 的方法，不能直接执行。
  - 如果下载时间过长，可以考虑通过[上海交通大学](https://sjtug.org/post/mirror-help/nix-channels/) 提供的二进制分发源来进行下载
    具体方式为在后面添加 `--option substituters https://mirror.sjtu.edu.cn/nix-channels/store`。
    - 不过这只在部分情况下起效，因为对应的 substituters 不一定包含所有的包。
    - 如果出现某种说明，提到了使用的这个 substituters 是 untrusted 的，
      考虑将用户切换成为 root 或者在 /etc/nix/nix.conf 中添加当前用户为可信用户。

### 如何删除 nix 包管理器

一旦包管理器经由 `nix-installer` 成功安装，即可通过下面的方式删除对应的文件

```bash
/nix/nix-installer uninstall
```

如果不是经由 `nix-installer` 完成的安装，可以参考 [我之前的小组作业中使用的删除方式](https://github.com/jackyliu16/devenv-flask/blob/7fbf044a58bb55a299771d0c947268bed7c84303/Makefile#L21-L35) 来尝试解决，但是不保证一定能用。

## 本项目中各文件说明
  
```
GradutionProject
├── arceos        # 贾跃凯博士论文所使用的操作系统内核
│   ├── api       # 避免内部循环依赖，构建统一的可复用，可替换接口
│   ├── apps      # 指纹识别应用实际放置的位置
│   ├── crates    # 与操作系统无关的模块
│   ├── doc
│   ├── modules   # 与操作系统相关的模块
│   ├── platforms # 平台相关参数设定的位置
│   ├── scripts   # 构建脚本
│   ├── tools     # 一些开发小工具
│   └── ulib
├── hosts_backend # 一些简单的脚本实现服务端相应功能
├── old_docs      # 古早年代的一些记录文件
├── test_script   # 用于流量测试，连通性测试的一些脚本文件
│   ├── c_src
│   └── src       # 实际并未使用
└── Thesis        # 论文主体部分
    ├── docs      # 论文主体部分文章
    ├── fonts     # 字体仓库（考虑到许可问题，并未开源）
    ├── help      # ?
    └── imgs
```

本次项目的主要内容，驱动以及对应的嵌入式被实现在 arceos 的 merge-try3 中。一个赶工完成的临时客户端被实现在 host_backend
中，其中提供了一些简单的 python 脚本实现服务端对应的功能，如数据处理与回报等。

## 如何实际复现本项目

1. 切换到项目分支中（需要电脑里面有 git），如果没有可以通过 nix-shell -p git 临时使用

```
cd arceos 
git checkout merge-try3
```

2. 运行 `nix develop` 打开 nix 的 devShells（各个不同项目有不同的 devShells），在各自的文件夹下运行该命令后
执行下列不同的操作

3. 按照论文中的要求连接线缆

3. 运行 ArceOS 编译命令

```bash
make A=apps/boards/raspi4-finger PLATFORM=aarch64-raspi4 LOG=debug chainboot
```

4. 运行后端程序

```bash
python3 ./server.py
```

### 可用性说明
当前由网络端下发数据包更新指纹识别模块部分尚未修复完成(目前实现了简单LED包的发送，但大量数据包传输会因中断导致问题)，会在进行完善的单元测试后公开。







