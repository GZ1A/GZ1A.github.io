---
# 常用定义
draft: false

title: "【笔记】Unity 美术工具"
date: 2020-07-12T23:39:12+09:00			# 创建时间
author: "昼阴夜阳"             		# 作者

# 分类和标签
categories: ["笔记"]		            # 分类
tags: ["Unity"]		    		# 标签
---

实习了才发现自由时间的宝贵，平时的空余还有周末的时间都需要好好利用起来了。周末收拾装修的房间以及补觉都是碎片化的时间，就刷刷视频了解了一下美术工作流程入个门罢。[HDRP 下]

[B站 | Unity2018.1中的艺术家工作流（摘要）](https://www.bilibili.com/video/BV1PW411g7er)

[B站 | Unity 最佳艺术家工作流（实践）](https://www.bilibili.com/video/av201287480) 

[B站 | [官方直播]Unity与Substance技术美术工作流](https://www.bilibili.com/video/BV1Gt411a7Kx)

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=1293938559&auto=0&height=66"></iframe>

## 建模

### ProBuilder

在 Unity 中建模。

#### 安装

Package Manager->ProBuilder

Tools->ProBuilder

#### 使用

新建/转换（ProBuilderlize）原有网格，然后类似其他建模软件，进行建模。

![image-20200714010608761](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200714010608761.png)

### FBX Exporter

在 Unity 和外部工具间建立链接。从而可以快速交换模型，无需重复导入导出。

#### 安装

Project Settings -> Fbx Exporter (2020.7 还是 Preview，要在右上角 Adv 里勾选才能找到)

Project Settings -> Fbx Export -> 3D app -> Install Unity Integration (首次使用时在美术工具里安装扩展以反向导出)

#### 使用

右键物体 Convert to FBX Linked Prefab

![image-20200714015501602](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200714015501602.png)

在美术工具中 Import 对应的 fbx

![image-20200714030454427](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200714030454427.png)

修改完后同理 Export 对应的 fbx，就能在 Unity 中实时看见变化

![image-20200714030556352](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200714030556352.png)

## 材质

### Shader Graph

制作着色器。

连 连 看，便捷版 Shader Lab。

![image-20200720001655154](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200720001655154.png)

![image-20200720021148031](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200720021148031.png)

### Substance

制作材质。

> 没看呢

## 动画

### Cinemachine

镜头控制，实现摄像系统。

> 没看呢

### Timeline

动画演出时间轴 / 游戏机制时间轴。

> 没看呢

## 后处理

### Post-processing

进行后处理。Volume 系统可以便捷的实现切换。

#### 安装

Package Manager

#### 使用

创建 Volume，在 Profile 中配置各种效果。{{% mask "后处理yyds" %}}

![image-20200720023432811](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200720023432811.png)

![image-20200720023327499](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200720023327499.png)