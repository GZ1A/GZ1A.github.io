---
# 常用定义
draft: false

title: "【笔记】Shader 入门精要（三）数学基础"
date: 2020-02-27T01:02:33+09:00					# 创建时间
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

## 笛卡尔坐标系

### 二维

略。

### 三维

* 基矢量 basis vector
* 正交基 orthogonal basis
* 标准正交基 orthonormal basis

Unity 模型空间、世界空间左手坐标系（相机前向为z轴负方向，即观察空间中为右手坐标系）

## 点和矢量

### 矢量间乘法

#### 点积（dot product）| 内积（inner product）

$$ a\cdot b= (|a|\hat a)\cdot (|b|\hat b) = |a||b|(\hat a\cdot\hat b) =|a||b|\cos\theta $$

$$ a \cdot b=(a_x,a_y,a_z)\cdot (b_x,b_y,b_z)=a_xb_x+a_yb_y+a_zb_z $$

二式可由一式、余弦定理及距离公式推得。

#### 叉积（corss product）| 外积（outer product）

$$ a\times b=(a_x,a_y,a_z)\times(b_x,b_y,b_z)=(a_yb_z-a_zb_y,a_zb_x-a_xb_z,a_xb_y-a_yb_x) $$

$$ |a\times b|=|a||b|\sin\theta $$

##   矩阵

### 矩阵乘法

结果矩阵中的每个元素等于对应行矩阵和列矩阵的矢量点积。

### 逆矩阵

可逆性：行列式不为 0（满秩）。（可通过累加任意一行展开后项与代数余子式积得到）

求逆：初等行变换。

不可逆说明变换降维丢失信息。

### 正交矩阵

每行都是单位矢量。行与行间互相垂直。（列即行的转置）例如一组**标准正交基**。

和其转置矩阵乘积为单位矩阵的矩阵。即逆矩阵等于转置矩阵。

### 行/列矩阵

Unity 中通常将矢量转换为**列矩阵**$(x\quad y\quad z)^T $进行计算。因此通常是**右乘**，即$CBAv=(C(B(Av)))$ 。

## 变换

### 线性变换

指可以保留矢量加和标量乘的变换。包括**旋转**、**缩放**、错切、镜像、正交投影等。使用 3×3 的矩阵就可以表示。

### 仿射变换

在线性变换的基础上增加了平移变换。需要把矢量扩展到齐次坐标空间（四维）。使用 4×4 的矩阵。

### 复合变换

多个仿射变换的组合。为便于理解和使用，通常先**缩放**，再**旋转**，最后**平移**。

在旋转中， Unity 的三轴旋转顺序是 **zxy**（虽然是右乘，但不旋转坐标系，直接表示为$M_{Z\theta }M_{X\theta }M_{Y\theta }$）

## 坐标空间

### 空间转换

给定子坐标空间 C 中一点 $A_c = (a,b,c)$。已知自坐标空间原点 $O_c$，及坐标轴在父坐标空间 P 下的表示 $x_c,y_c,z_c$。要确定 $A_p$ ，需要从原点开始，分别向 x,y,z 轴方向平移 a,b,c 个单位。有

$$ A_p = M_{c\rightarrow p}A_c$$

$$M_{c\rightarrow p}= \begin{bmatrix}| & | & | & | \\\  x_c & y_c & z_c & O_c\\\ | & | & | & |\\\ 0 & 0 & 0 & 1 \end{bmatrix}$$

$$ M_{p\rightarrow c} =M_{c\rightarrow p}^{-1} $$ 

当对方向的坐标空间进行变换时，原点变换可以忽略。故仅需左上角的 3×3 矩阵。

当原点不变时，转换矩阵是正交矩阵，有 $ M_{p\rightarrow c} =M_{c\rightarrow p}^{-1}= M_{c\rightarrow p}^T $ 。

### 转换流程

#### 模型空间

模型的顶点信息里使用的的坐标空间。

#### 世界空间

我们所关心的最外层的坐标空间，用来描述绝对位置。

#### 观察空间

以相机为原点，**右手坐标系**，-z 轴指向摄像机前方（对编程无太大影响）。除了计算坐标系后求得转换矩阵的逆矩阵，还可以想象平移整个观察空间，将相机反向变换到原点且坐标轴重合，以获得变换矩阵。

#### 裁剪空间

通过投影矩阵将顶点转换到裁剪空间，为投影（三维到二维）做准备。

#### 屏幕空间

经过透视除法，得到 NDC （范围为 [-1,1] ） 。然后进行屏幕映射。（视口空间范围为 [0,1] ）

#### 总结

![vertex_conversion.png-100.9kB](http://static.zybuluo.com/candycat/z0ibvp779phr1hb0l902n1qy/vertex_conversion.png)

## 法线变换

切线和法线都是模型顶点携带的额外信息。如果直接使用变换矩阵对法线进行变换，可能使新法线不与表面垂直了 。变换矩阵有如下关系

$$G = (M^T_{A\rightarrow B}) ^{-1} = (M^{-1}_{A\rightarrow B}) ^{T}  $$

当 $M_{A\rightarrow B}$ 为正交矩阵（只包含旋转变换），则可使用原变换矩阵。

## Unity Shader 的内置变量

先上参考路径`U3D\2020.1.0a12\Editor\Data\CGIncludes\UnityShaderVariables.cginc`

### 变换矩阵

UNITY_MATRIX_MVP 指经过 模型（M）观察（V）投影（P）变换的矩阵。

UNITY_MATRIX_IT_MV 指经过 逆（I）转置（T）的模型·观察矩阵。可以用来变换法线。

### 内置参数

见参考文件内注释。

