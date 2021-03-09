---
# 常用定义
draft: false

title: "算法科普 Smooth Step"
date: 2021-01-28T17:13:18+08:00				# 创建时间
author: "昼阴夜阳"             				# 作者

# 分类和标签
categories: ["技术"]		            		# 分类
tags: ["Smooth Step","算法"]		    		# 标签

---

[SmoothStep 原理介绍](https://mp.weixin.qq.com/s/ovf05Meab-K8JjTHjWS6AA)

[SmoothStep 使用例](https://mp.weixin.qq.com/s/abIk2HLX26hNDh8MsfyYKA)

### 定义

一个 Smooth 了的 Step

第一个式子就是一个范围映射，**（并经过 saturate）**映射到 [0,1] 上。而第二个式子的 [0,1] 间就是直观感受的函数本体了。

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/01/image-20210128222033598.png" alt="image-20210128222033598" style="zoom:50%;" />

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/01/image-20210128220703021.png" alt="image-20210128220703021" style="zoom:50%;" />

### 计算

这个三次方程的构造想法其实也很简单，为了让最终函数在0和1处导数为0并平滑过渡，就先找了两个简单的有这样性质的函数。

![image-20210128230256635](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/01/image-20210128230256635.png)

然后在 [0,1] 间以 x 值为权重，做线性插值：

f(x) = x * f1(x) + (1-x) * f2(x)

f(x) = x * x^2 + 1 - (x-1)^2 - x + x-1^2 * x

再展开整理就行了。

### 应用

* 选取特定的数值区间（smoothStep * (1-smoothStep)）
* 平滑动画曲线，物体移动轨迹等

在UE4中试了一下这两个功能：

![8cb26189-dae6-43d5-a6f7-2ade97945bf9](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/01/8cb26189-dae6-43d5-a6f7-2ade97945bf9.gif)