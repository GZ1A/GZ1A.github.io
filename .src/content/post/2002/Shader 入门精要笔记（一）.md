---
# 常用定义
draft: false

title: "【笔记】Shader 入门精要（一）渲染流水线"
date: 2020-02-25T08:47:07+09:00					# 创建时间
author: "昼阴夜阳"             		# 作者

# 分类和标签
categories: ["笔记"]		            # 分类
tags: ["Shader","Shader入门精要"]  						# 标签

# 自定义
comment: true	 # 评论
toc: true        # 文章目录
contentCopyright: '<a rel="license noopener" href="https://creativecommons.org/licenses/by-nc-nd/4.0/" target="_blank">CC BY-NC-ND 4.0</a>'	#版权规则
reward: true	 # 打赏
mathjax: true    # 打开 mathjax
---

汤老师确实心系学生，在群里发了网易雷火的实习内推链接。在雷火的[宣传页](http://leihuo.163.com/2019/rencai/)看到前辈新人5周做出来的游戏，完成度可以说是很高了，震撼花花。点开岗位，看到了[技术美术工程师](https://campus.163.com/app/jobDetail/index?projectId=25&id=625)，想起选专业的时候就研究过~~数媒对口岗位~~ TA，感觉相性很好所以在持续关注，看过拳头的[技术美术介绍](https://www.bilibili.com/video/av41216445?from=search&seid=15641735924452657164)，又在B站收藏过霜狼大佬的 [TA 学习体系框架](https://www.bilibili.com/video/av77755500)，甚至还加了群。然而也就仅限于此了，并没有更进一步的实际的努力过。总感觉是无法做到的事情所以不去做，自我设限也要有个限度啊！~~禁止套娃~~

于是就想努力往这个方向做做尝试。离校招（实习）截止还有一个多月，我也要加油了。就算不去提前实习，只要不停下来，（知识的）道路就会不断延伸！

脚踏实地，第一步就是打开《Unity Shader 入门精要》啃。为了提高效率，建议做下笔记。400页，每天 10 页起步，上不封顶。

# 渲染流水线

## 什么是渲染

输入三维场景数据（顶点、纹理、摄像机坐标等信息），输出二维图像。

## 概念阶段

### 应用阶段（CPU）

将场景数据（相机、模型、光源）加载到 VRAM 中

设置模型的渲染状态（材质、纹理、Shader）

调用 Draw Call 让 GPU 进行渲染

### 几何阶段（GPU）

输入：一批顶点数据

输出：顶点在屏幕空间中的**二维顶点坐标**、对应的深度、着色等信息。

### 光栅化阶段（GPU）

输出：屏幕上的像素（二维图像）

## GPU 流水线

![](http://static.zybuluo.com/candycat/jundxsf604yuoy2zr3r1qkzp/GPU流水线.png)

### 顶点着色器

* 坐标变换

* 计算颜色

* **从模型空间转换到齐次裁剪空间**（必要）输出后硬件会做透视除法，得到归一化设备坐标（Normalized Device Coordinates）

### 裁剪

将单位立方体外的图元和顶点舍弃，并在边界断点处生成新的顶点。

### 屏幕映射

将图元的 xy 坐标转换到屏幕坐标系（2维）。这和 z 坐标一起构成了窗口坐标系（3维）。

### 三角形设置

根据顶点计算出三角网格边界的表示数据。

### 三角形遍历

根据三角网格数据检查每个像素是否被三角网格覆盖，如果被覆盖则插值后在窗口坐标系中生成一个片元（fragment）。

### 片元着色器

将片元着色。完成纹理采样等渲染技术。

### 逐片元操作

输出合并阶段。对每一个片元进行操作。

* 通过模板测试、深度测试等工作决定片元的可见性（实践中可能在着色之前进行以提高性能）
* 将片元的颜色值和颜色缓冲区中的颜色合并

## Draw Call

### 定义

CPU 对图像编程接口的调用，以命令 GPU 进行渲染相关操作。**渲染速度往往快于 CPU 提交命令的速度**，所以性能问题的元凶通常是 CPU 发送指令改变渲染状态的次数过多。

![](http://static.zybuluo.com/candycat/h9oh7t35lbjrgogxywarmu55/CommandBuffer.png)

### 减少开销

使用批处理（Batching）的方法，减少 DrawCall 的调用次数。

* 合并小的网格
* 避免使用过多的材质

## Shader

Shader 就是 GPU 流水线上的一些可高度编程的阶段。我们可以通过修改 Shader 实现对流水线中渲染细节的控制。

同时，一个出色的效果需要包括 Shader 在内的所有渲染流水线阶段的共同参与。
