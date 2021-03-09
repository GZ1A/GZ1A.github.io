---
# 常用定义
draft: false

title: "UE4 Shader 水墨"
date: 2021-02-05T23:43:45+08:00				# 创建时间
author: "昼阴夜阳"             				# 作者

# 分类和标签
categories: ["技术"]		            		# 分类
tags: ["UE4","Shader"]		    		# 标签
---

## 目标效果

[B站 | 【虚幻4】_水墨风格动画练习](https://www.bilibili.com/video/av91667691/)

![image-20210204024131340](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210204024131340.png)

## 最终效果

![aShot3](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/aShot3-1612467681271.png)

![aShot2](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/aShot2-1612467398192.png)

## 实现

![image-20210205033953827](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210205033953827.png)

## 思路

首先感谢UP主在评论区里讲解了这个效果的实现思路。

> 用菲涅尔做边缘，中间用墨迹贴图。后面的山和竹子都是这个思路来弄。其实还是没有很好模拟出墨在宣纸上晕染的感觉。
>
> 内部的思路是一个普通的noise贴图，然后在ue4里面纵向拉伸一下贴图，就有笔触的感觉了。uv要注意一下，不然某些地方的纹理就会方向不一致了
>
> 笔划是后期合成的，UE4里面实现也是可以的，还省去跟踪的麻烦 

没时间了所以就先只做一下渲染部分吧。

然后虽然没看代码，但是看了个大概思路 [知乎 | Unity-一个简单的水墨渲染方法](https://zhuanlan.zhihu.com/p/98948117)

## 菲涅尔边缘

### Fresnel 节点

核心还是 N dot V。

== 官方文档 ==

**菲涅尔（Fresnel）** 表达式根据**表面法线与摄像机方向的标量积**来计算衰减。当表面法线正对着摄像机时，输出值为0。当表面法线垂直于摄像机时，输出值为1。结果限制在[0,1]范围内，以确保不会在中央产生任何负颜色。

| 项目                                      | 说明                                                         |
| :---------------------------------------- | :----------------------------------------------------------- |
| 属性                                      |                                                              |
| **指数（Exponent）**                      | 指定输出值的衰减速度。值越大，意味着衰减越紧或越快。         |
| **基本反射小数（Base Reflect Fraction）** | 指定从正对表面的方向查看表面时，镜面反射的小数。值为1将有效地禁用菲涅耳效果。 |
| Inputs                                    |                                                              |
| **指数输入（ExponentIn）**                | 指定输出值的衰减速度。值越大，意味着衰减越紧或越快。如果使用此输入，那么值将始终取代"指数"（Exponent）属性值。 |
| **基本反射小数（Base Reflect Fraction）** | 指定从正对表面的方向查看表面时，镜面反射的小数。值为1将有效地禁用菲涅耳效果。如果使用此输入，那么值将始终取代"指数"（Exponent）属性值。 |
| **法线（Normal）**                        | 接收三通道矢量值，该值代表表面在全局空间中的法线。要查看应用于菲涅耳对象表面的法线贴图的结果，请将该法线贴图连接到材质的"法线"（Normal）输入，然后连接一个[PixelNormalWS](https://docs.unrealengine.com/zh-CN/RenderingAndGraphics/Materials/ExpressionReference/Vector/index.html#pixelnormalws) 表达式到Fresnel上的此输入。如果未指定任何法线，那么将使用网格的切线法线。 |

### 主边缘实现

首先把材质属性设置一下，比如无光照什么的。然后创建一个菲涅尔节点，然后连接到自发光，然后调参。然而如图，对于有着平滑法线的模型，菲涅尔肯定是在边缘比较大，意味着就像参考图里那样外部硬，向内有平滑过渡。

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210205035531017.png" alt="image-20210205035531017" style="zoom:50%;" />

这就很不科学。墨在纸张上渲染，肯定是两边都会扩散，所以应该是**内外都有有平滑过渡**才对。很自然的想到用一个映射，加入一张RampTexture(渐变纹理)，然后把菲涅尔的结果看做是离模型边缘的距离信息，在纹理上采样。于是画了一些 ramp 图备用。

![image-20210205041228402](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210205041228402.png)

接下来就是换图片，改菲涅尔指数的调参时间。在 Tex7，exp = 0.3 的情况下画面如下。

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210205041702810.png" alt="image-20210205041702810" style="zoom:50%;" />

### 噪声

然后看看这个球。好工整的圆。这有点超越人类的极限了。而且毛笔是需要蘸墨的，笔迹也就会不稳定：断断续续，粗细不均匀。所以加入噪声贴图，对边缘乘一个系数，就更像水墨画出来的了。（下图只看边缘就好）

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210204082017791.png" alt="image-20210205042249786" style="zoom:50%;" />

![image-20210204082017791](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210204082017791.png)

### 副边缘

发现 [知乎 | Unity-一个简单的水墨渲染方法](https://zhuanlan.zhihu.com/p/98948117) 这篇文章里用了多 pass 扩张法来做轮廓，用了第二个 Pass 做了一次更远带noise剔除的轮廓。类似的，我也可以再画一遍轮廓。和主边缘用了相同噪声，并且可以修改这次轮廓的

* 菲涅尔指数、ramp 贴图（改变位置）
* 权重（颜色深度）
* 噪声的额外值（让副边缘与主边缘相比更连续 / 更破碎）

由此可以得到更加精细的控制。比如上述的主边缘完整，让副边缘略宽并更破碎:

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210205044802615.png" alt="image-20210205044802615" style="zoom: 67%;" />

副边缘

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210205044910435.png" alt="image-20210205044910435" style="zoom:50%;" />

也可以让完整的笔触中出现沿着笔刷方向的空白，更有层次感。（做一个对应范围不重叠的ramp图更好，这里懒了）

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210205045453332.png" alt="image-20210205045453332" style="zoom: 50%;" />

![image-20210205045746609](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210205045453332.png)

## 内部细节

> noise贴图，然后在ue4里面纵向拉伸一下贴图，就有笔触的感觉了

所以抛弃原来的贴图，直接在UV上贴上细节贴图。拉伸、位移了一个噪声，确实有种笔触的感觉...

![image-20210204074815738](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210205045453332.png)

然而模型 UV 不连续的问题很大。可以考虑手动调整改 UV，但这也很有可能带来很大的工作量。当然也可以用贴图映射。这里考虑采样别的信息，比如模型空间坐标。

虽然模型空间坐标不能用在骨骼动画体上（顶点对应的位置会变化），但对于大多数的场景物体也已经够用了。优点是 **纹理可以很连续** ，缺点是 **纹理只能很连续**。

相比起来各有优劣。重要物体还是改UV比较美观、受控。很多物体要快速出效果的话，模型空间坐标效果应该更好。

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210205051740304.png" alt="image-20210205051740304" style="zoom:80%;" />

![image-20210205051921898](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210205051921898.png)

![image-20210204080915230](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210204080915230.png)

## 参数调整

于是完成了基本的材质。接下来就可以创建各种材质实例了。相似的物体可以用相同的材质、重要的物体单独设定材质。再加上一些图片纹理，最后就能得到如图的效果。 要更还原参考场景，可以再叠一层细密的细节纹理，不过个人比较喜欢这种素一点的风格。

![image-20210205062226974](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210205062226974.png)

