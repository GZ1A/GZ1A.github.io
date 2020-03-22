---
# 常用定义
draft: false

title: "【笔记】Shader 入门精要（八）复杂光照"
date: 2020-03-19T15:52:48+09:00					# 创建时间
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

本章在处理更多数目类型光源的同时实现阴影。

## Unity 渲染路径

**渲染路径（Rendering Path)** 决定了光照如何应用到 Unity Shader 中。主要分为前向渲染和延迟渲染。指定渲染路径可以**让 Unity 提供对应的内置光照变量**。

### 前向渲染

前向照明渲染路径，传统渲染。经过深度测试光照计算后更新帧缓冲，且对于**每个逐像素光源**都要执行一个 Pass。

#### 光源

Unity 中，包括**逐像素**，**逐顶点**，**球谐函数**这三种光照处理方式，由光源类型和渲染模式决定。Unity 会根据场景中各个光源的设置和对物体的影响程度进行重要度排序，然后依次设置处理方式（逐顶点最多4个）。

### Pass

有两种 Pass，**Base Pass** 可以渲染一个逐像素的平行光和所有逐顶点、SH光源，也可以实现所有光照效果。**Additional Pass** 通常通过 `Blend One One` 负责且只负责其他逐像素光源，会自动对其余每个逐像素光源执行一次。

#### 内置光照变量

| 名称                          | 描述                                   |
| ----------------------------- | -------------------------------------- |
| _LightColor0                  | 该 Pass 处理的逐像素光源颜色           |
| _WorldSpaceLightPos0          | 光源位置，平行光时 w 为 0，否则 w 为 1 |
| _LightMatrix0                 | 世界空间到光源空间变换矩阵             |
| unity_4LightPosX0 \| Y0 \| Z0 | Base Pass。前 4 个非重要点光源世界坐标 |
| unity_4LightAtten0            | Base Pass。...衰减因子                 |
| unity_LightColor              | Base Pass。...光源颜色（ half4[4] ）   |

### 顶点照明渲染路径

前向渲染的子集，只填充了逐顶点相关的光源变量。不支持逐像素效果，如阴影、法线映射、高精度的高光反射等。可以使用8个光源，可区分是否是聚光灯。已成为遗留路径。

### 延迟渲染

由于 Addtional Pass 要对每个逐像素光源执行一次，前向渲染在有物体受到多个实时光源影响时性能会急速下降。而因为不同的 Pass 间有很多计算是重复的。因此使用延迟渲染。

#### 原理

延迟渲染把渲染分成两步，第一步是渲染关心表面的法线、位置、材质属性等信息并存入额外的缓冲区 **G-buffer** (Geometry) ，其中的每个 **渲染纹理（Render Texture）** 都存储了一部分的渲染数据。第二步是利用这些计算好的数据通过固定模型进行渲染。

### 光源类型

光源有许多属性，常用的有位置、(到某点的)方向、衰减以及颜色、强度等。

#### 平行光

没有位置属性，只有方向。没有衰减。

#### 点光源

有位置，方向计算得到。有衰减。

#### 聚光灯

有位置，方向计算得到，有衰减，而且由于要判断椎体，函数更复杂。

### 前向渲染实践

首先要给 Pass 设置正确的渲染路径标签，并使用 **对应编译指令 对应编译指令 对应编译指令**。

```
Tags {"LightMode" = "ForwardBase"}
CGPROGRAM
#pragma multi_compile_fwdbase
///////////////////////////////////////
Tags {"LightMode" = "ForwardAdd"}
Blend One One
CGPROGRAM
#pragma multi_compile_fwdadd
```

其次要注意分类讨论。Base Pass 只会渲染平行光，但 Additional Pass 可能渲染其他类型的光源。因此一些变量就要进行对应的计算。

```
#ifdef USING_DIRECTIONAL_LIGHT
fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
fixed atten = 1.0;
#else
fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPosition.xyz);
// use Lookup Table
float3 lightCoord = mul(_LightMatrix0,float4(i.worldPosition,1)).xyz;
fixed atten = tex2D(_LightTexture0,dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
#endif
```

## 光照衰减

点光源或聚光灯离顶点距离越远， **衰减值（attenation）** 越大。

### 纹理查找

Unity 中使用了名为 _LightTexture0 的纹理，通常只关心对角线上的纹理颜色并作为**查找表**计算衰减值。虽然需要预处理，精度有限，不直观且不能灵活变化，但是快。

首先要得到光源空间中的顶点位置。

```
float3 lightCoord = mul(_LightMatrix0, float4(i.worldPos, 1)).xyz;
```

然后使用坐标的模的平方对光照纹理采样，获取衰减分量。

```
fixed attenuation = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
```

### 公式计算

可以自己使用数学公式计算光源衰减，但由于 Shader 内置变量缺少光源范围等参数，在离开范围时会产生突变，效果一般。

## 阴影

### 阴影映射纹理

即 **Shadow Map** 技术，在光源处放置摄像机并渲染深度图来判断阴影区域。

#### 投射阴影

相比调用 Base / Additional Pass，LightMode 为 **ShadowCaster** 的 Pass 更高效。因此，在开启了光源阴影和物体投射时 Unity 会寻找有这个标签的 Pass 更新光源的阴影映射纹理。

#### 接收阴影

##### 光源空间映射

传统方法是在正常渲染的 Pass 中将顶点位置变换到光源空间下，从而得到三维位置信息。使用 xy 分量对阴影映射纹理采样后根据 z 分量判断是否在光源阴影中。最后将采样结果和光照结果相乘。

##### 屏幕空间映射

Unity 中用 ShadowCaster Pass 得到光源的阴影映射纹理和摄像机的深度纹理，从而得到屏幕空间的阴影图，接收阴影时对这个阴影图进行采样。

### 不透明物体

#### 投射阴影

满足设置时就会自动寻找 ShadowCaster Pass，当前 Shader 内没有时就会去 FallBack 中找，然后生成阴影映射纹理或是阴影图。

```
FallBack "VertexLit"
```

#### 接收阴影

大概使用一下内置宏，从定义坐标变量，计算坐标再到采样一气呵成。

```
#include "AutoLight.cginc"
// v2f
SHADOW_COORDS(2)
// vert
TRANSFER_SHADOW(o);
// frag
fixed shadow = SHADOW_ATTENUATION(i);
color *= shadow;
```

### 透明物体

#### 透明度测试

由于透明度测试会在片元着色器中舍弃部分片元，如果不处理，阴影投射就会出现差错。因此不同于基础的 VertexLit，使用

```
Fallback "Transparent/Cutout/VertexLit"
```

![image-20200322164656558](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200322164656558.png)

#### 透明度混合

Unity 内置的透明度混合 Shader 都不包含阴影投射的 Pass。由于关闭了深度写入，要生成正确的阴影需要在每个光源空间下仍严格从后往前渲染，复杂且代价大。当然也可以 Fallback VertexLit 强行开启阴影接收和投射，然而结果一般不正确。

