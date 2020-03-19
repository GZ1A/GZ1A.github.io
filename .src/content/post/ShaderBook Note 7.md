---
# 常用定义
draft: false

title: "【笔记】Shader 入门精要（七）透明效果"
date: 2020-03-16T05:00:26+09:00					# 创建时间
author: "昼阴夜阳"             		# 作者

# 分类和标签
categories: ["笔记"]		            # 分类
tags: ["Shader","Shader入门精要"]  		# 标签

# 自定义
comment: true	 # 评论
toc: true        # 文章目录
contentCopyright: '<a rel="license noopener" href="https://creativecommons.org/licenses/by-nc-nd/4.0/" target="_blank">CC BY-NC-ND 4.0</a>'	# 版权规则
reward: true	 # 打赏
mathjax: true    # 打开 mathjax
---

每个片元都有颜色值、深度值和**透明度**属性。利用这个属性，通过透明度测试（Alpha Test）或者透明度混合（Alpha Blending）实现透明效果。透明度测试就是一刀切的阈值判断，真正要有透明度还得看混合。

## 渲染顺序

由于透明度混合技术要把表面颜色和缓存中的颜色相混合，渲染顺序就十分重要了。通常渲染引擎会首先渲染不透明物体，然后对半透明物体在**排序**之后渲染。但由于半透明物体可以循环重叠，可能出现错误结果。通常的解决方法是拆分模型，**分割网格**，也可以通过深度写入的半透明等方法解决问题。

### Unity 渲染队列

渲染队列（render queue）是 Unity 为渲染顺序提供的解决方案。这通过 SubShader 的 **Queue 标签** 决定。例如

```
Tags { 
	"Queue"="Transparent" 
}
```

通过一系列整数索引来表示渲染队列。索引号越小渲染越早。Unity 提前定义了5个渲染队列。

| 名称        | 队列索引号 | 用处描述                         |
| ----------- | ---------- | -------------------------------- |
| Background  | 1000       | 最先渲染，用于背景上物体         |
| Geometry    | 2000       | 不透明物体的默认渲染队列         |
| AlphaTest   | 2450       | 需要透明度测试的物体，这样更高效 |
| Transparent | 3000       | 透明度混合，从后往前渲染         |
| Overlay     | 4000       | 叠加效果                         |

## 透明度测试

透明度测试就是如果片元的透明度不满足条件（如小于阈值）就舍弃。否则按不透明物体的处理。通常在片元着色器中使用 CG 内置的 **clip** 函数处理。只要添加一句话就可以完成。

``` 
// Alpha test
clip(texColor.a - _Cutoff);
// equal to
// if((texColor.a - _Cutoff) < 0.0){discard;}
```

![image-20200318182628620](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200318182628620.png)

## 透明度混合

混合是一个逐片元的，将片元着色器输出 **源颜色（source color）** 和颜色缓存中的 **目标颜色（destination color）** 乘上混合参数进行混合等式运算的**可配置**操作（不可编程）。

通常使用的加法混合等式是
$$
O_{rgb} = \text{SrcFactor}\times S_{rgb} + \text{DstFactor}\times D_{rgb}\\
O_{a} = \text{SrcFactorA}\times S_{a} + \text{DstFactorA}\times D_{a}
$$


### 开启混合

将当前片元颜色与缓冲中的颜色通过指定的**混合因子**混合。在 Pass 中使用 `Blend` 命令可以设置混合模式。

```
Pass{
    ZWrite Off
    // src(frag) + dst(buffer)
    Blend SrcAlpha OneMinusSrcAlpha
	// ...
}
```

最终输出的颜色就会根据 alpha 值和混合模式混入缓冲。

![image-20200318185751301](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200318185751301.png)

### 开启深度写入

关闭深度写入虽然可以避免物体间的剔除问题，但没有解决模型内部交错导致的渲染错误。要让**模型与背景混合**一般使用一个 **深度写入 Pass** 来解决：第一个将模型的深度值写入深度缓冲但不着色；第二个进行透明度混合，通过深度检测只渲染多个片元中最前面的片元。

```
Pass{
	Zwrite On
	ColorMask 0
}
```

通过 `ColorMask 0` 命令设置了颜色通道的写掩码（write mask），可以设置 `RGBA` 的任意组合或是 `0` 代表不写入任何颜色通道。

![image-20200319075711644](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200319075711644.png)

### ShaderLab 混合命令

```
// 设置混合操作（混合等式）
BlendOp BlendOperation
// 设置 S,D 颜色的混合因子，可单独设置 alpha 通道因子
Blend SrcFactor DstFactor [,SrcFactorA DstFactorA]
```

#### 混合操作

| 混合操作 | 对应每个通道等式（S/D 已乘混合因子） |
| -------- | ------------------------------------ |
| Add      | O = S + D                            |
| Sub      | O = S - D                            |
| RevSub   | O = D - S                            |
| Min      | O = Min(s,d)                         |
| Max      | O = Max(s,d)                         |

#### 混合因子

包括 One,Zero,SrcColor,SrcAlpha,DstColor,DstAlpha,OneMinusSrcColor...

## 双面渲染

### 剔除

无法观察到物体背面结构是因为渲染引擎默认剔除了物体背面的渲染图元。要得到双面渲染的效果，就要关闭剔除。

```
Cull Back | Front | Off
```

### 透明度测试下的实现

在透明度测试下，只要把剔除关闭就可以有效果。

### 透明度混合下的实现

由于第一个 Pass 启用了深度写入，背面肯定无法渲染。首先删除深度写入 Pass。但此时如果关闭剔除，渲染背面和正面的顺序是不确定的。

![image-20200319131850340](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200319131850340.png)

由于 Pass 会顺序执行，一个解决方法是把渲染工作分成两个 Pass，第一个渲染背面（剔除正面），第二个渲染正面（剔除背面）。这种方法虽然无法应对模型内部交错，但是在凸模型上可以保证正确的深度渲染关系。复杂模型的深度关系大概需要别的技术保证吧。

![image-20200319132018922](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200319131850340.png)

