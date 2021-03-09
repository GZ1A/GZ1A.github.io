---
# 常用定义
draft: false

title: "UE4 Shader FlowMap 燃烧"
date: 2021-02-15T15:03:26+08:00		# 创建时间
author: "昼阴夜阳"             						# 作者

# 分类和标签
categories: ["技术"]		            				# 分类
tags: ["Shader","UE4","FlowMap"]		    					# 标签

---

[知乎 | Flow Map](https://zhuanlan.zhihu.com/p/33288033)

[博客 | Flowmapped-Burn-Shader](https://deepspacebanana.github.io/deepspacebanana.github.io/blog/shader/art/unreal%20engine/Flowmapped-Burn-Shader)

## Flow Map

Flow Map 就是控制UV动画的烘焙数据。始于水面流动的时候水面贴图要平移，但只平移是不够的，有点挤压扰动在里面才逼真。

预先烘焙好的 Flow Map 可以提供这些扰动数据。

### 实现

![image-20210224170034338](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210224170034338.png)

```glsl
float2 AdjustUV = UV* Tiling;
float HalfPeriod = PeriodSec * 0.5;
// 缩放到 [0,1] 区间?
float2 Flow = Texture2DSample(FlowMap, FlowMapSampler, AdjustUV).rg * 0.5 + float2(0.5, 0.5);
Flow *= Direction.xy; // 乘上方向系数（图里还没加上
// 周期内时间乘上Flow系数和速度后，得到偏差 Bias,进行uv平移
float2 Bias = fmod(View.RealTime, PeriodSec) * Flow * Speed;
float2 NewUV = AdjustUV + Bias;
float4 C1 = Texture2DSample(Tex,TexSampler,NewUV);
// 采样一个半周期相位的 Bias
Bias = fmod(View.RealTime + HalfPeriod,PeriodSec)* Flow * Speed;
NewUV = Bias * Speed + AdjustUV;
float4 C2 = Texture2DSample(Tex,TexSampler,NewUV);

// 根据 1->0->1 折线进行 Lerp
// 就是从 C2 0.5Flow *1 ,到C2 1Flow *0，C1 0.5Flow*1
// 每个采样点从0Flow到1Flow，在 0.5 flow 附近最明显（渐入渐出）从而一直滚动
// 因为有speed影响，不一定能循环滚动，所以连接处淡出不显示，防尬）
float a = abs(HalfPeriod - fmod(View.RealTime,PeriodSec))/HalfPeriod;
return lerp(C1,C2,a);
```

效果图如下

![c03fe98d-4c0a-4431-9a03-f823742b8ca7](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/c03fe98d-4c0a-4431-9a03-f823742b8ca7.gif)![image-20210224220740212](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210224220740212.png)

## 球体遮罩

这一步的最终目的是通过一个标量来控制这个效果。所以有很多种方法来实现。这里使用了球体遮罩，从而通过蓝图改变燃烧的部分。

### MPC

首先，通过材质参数集 MPC(Material Parameter Collection) 来存储位置并在Shader 中读取。内容浏览器中右键->材质和纹理->材质参数集。双击打开后新增变量。

![image-20210224211330399](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210224211330399.png)

### 设置蓝图

右键创建个新的蓝图类 Actor，事件图表中如图连接。这样这个 Actor 的位置就会每 Tick 更新到 Texloc 上了。

![image-20210224212154847](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210224212154847.png)

### 创建Spheremask

UE4 内置了SphereMask，所以用就行了。Rad 是世界单位所以很大。Mask 内是1外是0。如图连线到SphereMask节点里。然后为了将遮罩限制在sphere周围，乘2使 Sphere 外的部分不会受到影响。

![image-20210224222142079](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210224222142079.png)

## 动态遮罩

最后把 SphereMask  和 FlowMap 部分相减，通过 Hardness 来控制 Sphere 的扩散量。

![image-20210224220359257](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210224220359257.png)

把这个全新的**动态遮罩**用于不透明度蒙版，就可以得到动态的燃烧图啦！

![image-20210224223444859](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210224223444859.png)

FlowMap 遮罩 和 静态遮罩

![5236bfb3-3e58-4ece-a2a7-34627b4351e2](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/5236bfb3-3e58-4ece-a2a7-34627b4351e2.gif)

![cf3710c2-edbe-4659-b0d5-9292e2b2d550](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/5236bfb3-3e58-4ece-a2a7-34627b4351e2.gif)

## 边缘发光和碳化

获取这两部分的遮罩，然后分别着色就可以了。

### 发光部分

取遮罩上的值与一个中值 `0.45` 的距离，靠近0.45就会有很大黑色，所以乘上系数（10）来缩小黑色的部分。最后取反Clamp得到如图遮罩。

![image-20210224225412202](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210224225412202.png)

着色一下放到自发光上。

![image-20210224232349309](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210224232349309.png)

### 碳化部分

这个要比发光部分宽。改变中值（0.5）。然后减少收缩系数（2），最后一步用减法来降低黑色阈值，扩大黑色面积。

![image-20210224230311513](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210224230311513.png)

乘上初始的BaseColor，再放回到BaseColor上。

![image-20210224232704143](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210224232704143.png)

## 最后效果

![59940923-f0dc-40c3-9d49-587af4a42839](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/59940923-f0dc-40c3-9d49-587af4a42839.gif)

用了 FlowMap 之后的原地动态燃烧还行。

![42e74712-bb6e-4ccd-a10f-6d4f7d477fed](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/42e74712-bb6e-4ccd-a10f-6d4f7d477fed.gif)