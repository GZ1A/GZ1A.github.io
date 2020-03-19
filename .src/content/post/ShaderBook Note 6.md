---
# 常用定义
draft: false

title: "【笔记】Shader 入门精要（六）基础纹理"
date: 2020-03-08T03:06:23+09:00					# 创建时间
author: "昼阴夜阳"             		# 作者

# 分类和标签
categories: ["笔记"]		            # 分类
tags: ["Shader","Shader入门精要"]  		# 标签

# 自定义
comment: true	 # 评论
toc: true        # 文章目录
contentCopyright: '<a rel="license noopener" href="https://creativecommons.org/licenses/by-nc-nd/4.0/" target="_blank">CC BY-NC-ND 4.0</a>'	#版权规则
reward: true	 # 打赏
mathjax: true    # 打开 mathjax
---

纹理最初的目的就是通过 **纹理映射（texture mapping)** 控制模型的外观，逐纹素（texel） 控制模型的颜色。保存了映射关系的 纹理映射坐标（texture-mapping coordinates）由于通常使用`（u,v）`表示，又被称为 **UV 坐标**。

## 单张纹理

### 实现

使用一张纹理来代替物体的漫反射颜色。首先定义一个纹理属性和对应的 CG 变量。其中 `_MainTex_ST` 的 `xy` 坐标传递了该纹理的缩放（Scale），`zw` 传递了平移（Translation）。

``` 
// properties
_MainTex ("Main Tex", 2D) = "white" {}

// in cg program
sampler2D _MainTex;
float4 _MainTex_ST;
```

在顶点着色器中计算根据 模型的 uv 坐标 和 纹理的 ST 变换 计算出对应顶点的 UV 值并传入像素着色器。

```
o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
// or call function
// o.uv = TRANSFORM_TEX(v.texcoord, _MainTex_ST);
```

像素着色器根据插值之后的 UV 值对纹理进行采样，并将得到的纹素值作为反射率使用。

```
// use texture to sample diffuse color
fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb; 
```

效果如下

![image-20200308045417756](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200308045417756.png)

### 纹理属性

#### 纹理类型

包括 Texture、Normal map、Cubemap 等不同类型的纹理。Unity 可以进行对应的限制和优化。

#### 纹理格式

图片的存储格式。

#### Warp Mode

决定了纹理坐标在 [0，1] 以外的 **平铺（Tiling）** 方式。（Unity 的纹理坐标系原点在左下角，和 OpenGL 一样） Clamp 模式在超出范围时会截取到 0 或 1，从而产生边缘填充的效果。Repeat 模式会舍弃整数部分后采样，使得纹理不断重复。

#### Filter Mode

决定了纹理变换拉伸时用到的滤波模式，改变变换后的纹理质量。Point，Bilinear 和 Trilinear 性能开销和效果都依次提升。

#### Mip Mapping

多层渐远纹理。通过预处理，将降采样的纹理保存下来从而在实际运行时快速得到结果像素。

#### 最大尺寸

过大的纹理会被缩放为最大分辨率的大小。为了性能和空间，尽量使用 2 的幂大小的纹理。

## 凹凸映射

凹凸映射是使用一张纹理来修改模型表面的法线从而为模型提供更多细节。使用**高度纹理**来模拟 **表面位移（displacement）** 或者使用**法线纹理**直接存储法线。

### 原理

#### 高度纹理

高度图中存储的 **强度值（intensity）** 用于表示模型表面的海拔高度，越浅越高。直观但要实时计算法线，性能开销大。

#### 法线纹理

法线要保存到像素中要经过映射，通常是 $ \text pixel = {{\text normal +1 } \over 2}  $ 。而 Shader 中纹理采样后就要用逆函数反映射。

实际制作中，模型空间的法线纹理用的很少。往往使用 **切线空间（tangent space）** 来存储法线。

##### 切线空间

每个顶点都有自己的切线空间，x 轴是切线方向（t），z 轴是法线方向（n），y 轴是法线和切线叉积（左手坐标系），被称为副切线（bitangent）。（[存疑](https://www.zhihu.com/question/23706933)）

当法线为（0,0,1），映射后的像素为（0.5,0.5,1），即常见的浅蓝色。这说明大部分法线与原先相比没有偏移或偏移不大。

##### 模型空间优点

* 简单直观，不需要模型信息。
* 尖锐边角部分法线可以插值，更平滑。

##### 切线空间

* 相对信息，可以复用。
* 可以进行 uv 动画
* 可以压缩

### 实践

由于法线信息存储在切线空间，要参与光照运算的话就需要变换。一种选择是在切线空间下进行计算，把光照、视角方向变换到切线空间。还有一种是把法线变换到世界空间。

效率上来说，第一种选择快。光照视角方向可以在顶点着色器进行运算。而法线信息需要在片元着色器才能采样得到并变换。

兼容上来说，第二种选择好。cubemap 等技术需要这种方式。但由于需要存储变换矩阵，占用的插值寄存器更多。

#### 切线空间

在 vertex shader 中计算模型空间切线空间的变换矩阵。然后使用这个矩阵将光源方向和视角方向变换到切线空间，然后传入 fragment shader。

```
// compute binormal
float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) ) * v.tangent.w;
// construct a matrix which transform vec from obj space to tangent space
float3x3 rotation = float3x3(v.tangent.xyz,binormal,v.normal);

// transform light dir and view dir from object space to tangent space
o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;
```

然后在 fragment shader 中根据对应的 uv ~~（但是存储在 zw 里）~~ 读取出切线空间下的法线。在使用bump scale 变量调整凹凸程度，对法线的 xy 坐标（切线 和 切线法线叉积方向）进行调节后归一化。最后使用这个法线和切线空间的光源方向、视角方向一同参与光照模型运算。

```
// Get texel in normal map
fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
fixed3 tangentNormal;
tangentNormal = UnpackNormal(packedNormal);
tangentNormal.xy *= _BumpScale;
tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
```

![image-20200312064513716](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200312064513716.png)

####  世界空间

将切线坐标系在世界坐标下的表示按列排列，构成 TtoW **转换矩阵 **并传入片元着色器。同时传入顶点的 **世界坐标** 以获取世界坐标下的光源和视角方向。

![img](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/5e69688de4b00fb1da109b27.png)

### 法线纹理

为什么要把纹理类型设置为**法线纹理**呢？说到底还是因为空间。法线纹理中，每个纹素只需要保存法线的 xy 分量信息，z 分量可以由 xy 分量推导出，即法线贴图**只需要保留两个通道**就可以了。所以 Unity 会将法线贴图根据平台进行对应压缩来节省内存空间，也因此获取信息也需要调用 Unity 的函数。

## 渐变纹理

### 实现

纹理可以用于存储任何表面属性，比如使用渐变纹理控制漫反射光照的映射关系。

```
// 将原始漫反射颜色进行映射变换
fixed3 diffuseColor = tex2D(_RampTex,fixed2(originDiffuseColor,originDiffuseColor)).rgb;
```

当使用的纹理有色调突变，就可以实现类似卡通渲染的效果。

![image-20200315032710946](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200315032710946.png)

### Warp Mode

由于浮点数误差，原始漫反射值可能会出现 1.000 01。若 Warp Mode 为 Repeat，则会出现对 0.000 01 采样的黑点等现象。因此需要设置为 **Clamp 模式**。

## 遮罩纹理

遮罩纹理可以用来**存储区域信息**。这些信息通常来更加精确的控制某种表面属性 。

### 实践

以高光反射遮罩为例，只需要在原来的高光反射结果中乘上遮罩纹理采样值即可。

```
// get mask value
float maskValue = tex2D(_SpecularMask,i.uv).r * _SpecularScale;
// get specular term with mask
fixed3 specular *=  maskValue;
```

很明显可以看出高光反射的强度受到了遮罩影响。

![image-20200316044624841](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200316044624841.png)

