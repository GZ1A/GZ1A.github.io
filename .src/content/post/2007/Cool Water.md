---
# 常用定义
draft: false

title: "水面复现"
date: 2020-07-31T01:21:02+09:00			# 创建时间
author: "昼阴夜阳"             		# 作者

# 分类和标签
categories: ["技术"]		            # 分类
tags: ["Unity","Shader"]		    		# 标签
---

工作之后时间是真的少。又刚巧舟游炉石解神者和装修活动全撞在一起了。预定内的事完全做不完...

很久没有做效果了。现在先试着复现一个简单的效果练练手。

## 目标效果

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200731022752088.png" alt="image-20200731022752088" style="zoom:50%;" />

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200731023209075.png" alt="image-20200731023209075" style="zoom:50%;" />

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200731023518012.png" alt="image-20200731023518012" style="zoom:50%;" />

## 分析

如图有两种水，游泳池和大海。

**游泳池**

* 蓝白条纹 漫反射
* 凹凸不平 法线
* 一个反射特性

**大海** 就是在游泳池的基础上添加了

* 奇怪的折射
* 微妙的顶点动画（贴图性存疑）
* 深度mapping的漫反射

## 制作

### 游泳池

#### 漫反射

从视频里直接截图出来透视变换+手动均衡化一下

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200801204905056.png" alt="image-20200801204905056" style="zoom:50%;" />

#### 法线

硬盘搜索法线，安排上一张。UV 随着时间飘一下，然后调一下颜色。然而因为用的是 HDRP，不知道怎么改变高光颜色。试着改了光源颜色，但高光本身依旧是白色的？还是不太熟悉这套流程。

![image-20200801212159390](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200801212159390.png)

> 仔细排查发现后处理里的 HDRI SKY 又白又亮...所以反射才这么亮

![image-20200801232141850](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200801232141850.png)

问题还是没解决，全向反光依然存在，光源全部关闭后如图。突然发现现在反射的颜色和天空完全一致，于是打开 HDRP 设置找到了天空反射的开关...{{% mask "Quick Search 不支持 HDRP 设置的搜索真是难受，建议添加" %}}

![image-20200801235347997](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200801235347997.png)

![image-20200801235208341](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/07/image-20200801235208341.png)

（最后得到纯黑的平面，就不放图了）

#### 反射

反射的原理在初中就学过，成个虚像嘛。把物体全部放到对于平面对称的位置然后渲染就可以了。但通常物体都很多，移动起来挺麻烦，于是考虑移动相机到对称位置（及朝向）。渲染了之后存到纹理里再放到材质上显示。

这个变换怎么实现呢？一开始走了弯路，寻思着讨巧写个特殊情况。然而不仅出处还 debug 不能。迫不得已去计算通解（不愿面对.jpg)

最后得到了顶点变换的反射矩阵（已知平面方程 pn+ d = 0, 有一点 Q, 求 Q'）{{% mask "就是将 Q' 用 n,d,Q 表示，然后拆成用来左乘 Qx Qy Qz 1 列的 4x4 矩阵" %}} 最后结果如下

$$\begin{bmatrix} 1-2n_xn_x&-2n_yn_x&-2n_zn_x&-dn_x \\ -2n_xn_y&1-2n_yn_y&-2n_zn_y&-dn_y\\ -2n_xn_z&-1n_yn_z&1-2n_zn_z&-dn_z\\0&0&0&1\end{bmatrix} \begin{bmatrix} x\\y\\z\\1 \end{bmatrix}$$

于是写到脚本里，在每帧的 prerender 时

* 放置相机
* 渲染反射图像

然鹅出现了奇怪的效果。

![image-20200808181729782](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/08/image-20200808181729782.png)

反射和正确位置有着微妙的偏差...

感谢双屏（的分辨率不一样），在百思不得其解的时候无意间移动窗口，反射居然也随着变化了！举个极端的例子

<img src="C:/Users/GZ1A/AppData/Roaming/Typora/typora-user-images/image-20200808181856745.png" alt="image-20200808181856745" style="zoom:50%;" />

突然反应过来，采样反射纹理用的是屏幕空间坐标。但屏幕的长宽比会变化，反射纹理的长宽比却不会变...于是在渲染前判断一下反射纹理的尺寸。如果不对就重新生成一张。顺便也可以同步一下相机设置。

```c#
float scale = 0.5f;

ReflectionCam.CopyFrom(Camera.main);

if(!m_ReflectTexture || ReflectionCam.pixelWidth * scale != m_ReflectTexture.width||
   ReflectionCam.pixelHeight * scale != m_ReflectTexture.height)
{
    if(m_ReflectTexture)m_ReflectTexture.Release();
    m_ReflectTexture = new RenderTexture(Mathf.FloorToInt(ReflectionCam.pixelWidth * scale),
                                         Mathf.FloorToInt(ReflectionCam.pixelHeight * scale), 24);
    m_ReflectTexture.hideFlags = HideFlags.DontSave;

    ReflectionCam.targetTexture = m_ReflectTexture;
    WaterPlane.GetComponent<Renderer>().material.SetTexture("_ReflectTex", m_ReflectTexture);
}
```

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/08/image-20200808190325105.png" alt="image-20200808190325105" style="zoom:50%;" />

终于有画面了！

还有一些问题，比如渲染的面反了，比如水面下的部分也被反射了。

[GAD | 镜面反射原理及实现](https://gameinstitute.qq.com/community/detail/106151)

[CA | Portals](https://www.youtube.com/watch?v=cWpFZbjtSQg)

[GAD |斜视锥体深度投影和裁剪-Oblique View Frustum Depth Projection and Clipping](https://gameinstitute.qq.com/community/detail/106203)

本来应该翻转消隐渲染正确表面，使用斜投影（Oblique）裁剪掉水下的物体。但总是会出现 **很奇怪的效果** ，如图上下移似乎使近裁剪面将反射裁剪掉了。因为参考的 water.cs 等脚本都不能在HDRP中使用，怀疑是 HDRP 有什么特殊处理。

[博客 | 似乎确实](https://blog.csdn.net/skylovecrayon/article/details/90812293)

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/08/image-20200809131027478.png" alt="image-20200809131027478" style="zoom:50%;" />

```c+
// 开启裁剪不知道为什么就会出现问题
//ReflectionCam.projectionMatrix = cam.CalculateObliqueMatrix(clipPlaneCameraSpace);
GL.invertCulling = true;
```

资料过少，看官方文档也没有头绪...感觉已经超出我的能力范围了...建议暂时搁置。不过 HDRP 既然带来了这些限制，也当然有相应的优点。使用 Planar Reflection Probe 做个镜面反射暂时结尾吧（虽然看起来完全不一样）>>>

![image-20200809134336076](C:/Users/GZ1A/AppData/Roaming/Typora/typora-user-images/image-20200809134336076.png)

> #### 补充 使用 Build in 管线可以实现
>
> #### SRP 下的实现参考 [博客 | URP应用 – 0 – 镜面反射](https://acgmart.com/render/planar-reflection-based-on-distance/)