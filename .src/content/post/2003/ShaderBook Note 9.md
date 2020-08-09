---
# 常用定义
draft: false

title: "【笔记】Shader 入门精要（九）高级纹理"
date: 2020-03-22T20:45:32+09:00			# 创建时间
author: "昼阴夜阳"        	     		# 作者

# 分类和标签
categories: ["笔记"]		            # 分类
tags: ["Shader","Shader入门精要"]  		# 标签
---

本章学习更复杂的纹理。

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=1408262540&auto=0&height=66"></iframe>

## 立方体纹理

**立方体纹理（Cubemap）** 是**环境映射（Environment Mapping）**的一种实现。包含了立方体的 6 个面，表示了世界空间下从内往外观察的结果，通过三维纹理坐标（方向向量）进行采样。

优点是实现简单快速。缺点是场景/物体变化后要重新生成纹理，且不能模拟多次反射。

### 创建 CubeMap

#### 预处理

可以通过预先准备好的纹理创建。直接由特殊布局的纹理或用6张单面纹理创建 CubeMap。

#### 程序创建

`Camera.RenderToCubemap` 函数可以将任意位置观察到的场景图像存储到6张图像中。

``` c#
void OnWizardCreate () {
    // create temporary camera for rendering
    GameObject go = new GameObject( "CubemapCamera");
    go.AddComponent<Camera>();
    // place it on the object
    go.transform.position = renderFromPosition.position;
    // render into cubemap		
    go.GetComponent<Camera>().RenderToCubemap(cubemap);

    // destroy temporary camera
    DestroyImmediate( go );
}
```

利用程序采样场景并渲染纹理。

![image-20200323124756834](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200323124756834.png)

### 天空盒

模拟背景的一种方法。将场景包围在一个立方体里，每个面都使用立方体纹理映射技术。可以在场景中或者单个摄像机上设置天空盒材质。Unity 中天空盒会在所有不透明物体后渲染。

### 反射

反射效果可以通过计算并利用反射方向对立方体纹理采样实现。效果如上。

```
fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb * _ReflectColor.rgb;
```

### 折射

根据 **斯涅尔定律（Snell's law）** ，当 **折射率（index of refraction）** 为 $\eta$，入射角和出射角（与表面法线夹角）为 $\theta$ 时，有

$$ \eta_1\sin\theta_1 = \eta_2\sin\theta_2 $$

在实时渲染中，由于模拟两次性价比不高，通常仅模拟第一次折射。

```
o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractionRatio);
// ...
fixed3 refraction = texCUBE(_Cubemap,i.worldRefr).rgb * _RefractionColor.rgb;
```

![image-20200323205330832](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200323205330832.png)

### 菲涅尔反射 

Fresnel reflection 描述了一种普遍存在的光学现象：光线照到物体上时反射光和折射光间的比例与入射光角度存在一定关系。在实时渲染中常用 **Schlick 菲涅尔近似等式** 进行计算。$F_0$ 是基础反 射系数，有：

$$ F_{schlick}(v,n) = F_0 + (1-F_0)(1-v\cdot n)^5 $$

将 fresnel 变量混合漫反射与反射光照，或者与反射光照相乘后叠加到漫反射上模拟边缘光照。

```
fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldViewDir, worldNormal), 5);
fixed3 color = ambient + lerp(diffuse, reflection, saturate(fresnel)) * atten;
```

![image-20200324034457371](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200324034457371.png)

## 渲染纹理

现代 GPU 支持将三维场景渲染到一个中间缓冲：**渲染目标纹理（Render Target Texture, RTT）** 。相关技术有 GPU 将场景同时渲染到多个纹理中的多重渲染目标（MRT）技术。

Unity 为此定义了纹理类型 **渲染纹理（Render Texture）**，可以通过设置相机渲染目标或者使用 **GrabPass** / OnRenderImage 获取当前屏幕图像。

### 镜子效果

首先创建在镜子后创建一个相机，从镜子后观察，并将结果渲染到一个渲染纹理上。然后在镜子材质的 Shader 中将 uv 的 x 坐标反向，并对纹理进行采样。

![image-20200324180735507](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200324180735507.png)

### 玻璃效果

GrabPass 也可以获取图像，绘制在纹理中供后面的 Pass 使用。通常设置成透明队列来保证渲染顺序。

```
// grabs screen behind the object into texture with a custom name
GrabPass {"_RefractionTex" }
```

使用时除了要定义纹理本身变量，还要接收**纹理的纹素大小**用于坐标偏移。

```
// grab pass 生成
sampler2D _RefractionTex;
float4 _RefractionTex_TexelSize;
```

然后是分别计算折射和反射光线。反射光线就是通过 `texCUBE`，用入射光方向对 cubemap 采样。折射光却是直接用系数乘上切线空间下的法线偏移：奇怪的方法增加了！

```
// 取法线
fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
// 在切线空间中计算 offset 模拟折射，用了奇怪的方法 ??
float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
i.scrPos.xy += offset;
fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;
```

![image-20200324231232527](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200324231232527.png)

### 对比

#### GrabPass

实现起来简单，快捷。但无法控制分辨率等参数。

#### 渲染纹理

实现复杂但可控，效率高。

#### 命令缓冲

 新的方式，类似全局的，固定时机触发的 GrabPass 。

## 程序纹理

### 生成纹理

**程序纹理（Procedural Texture）** 是由算法生成的纹理。程序化生成可以说是很重要的操作了。

```
Texture2D tex = new Texture2D(textureWidth, textureWidth);
// ...
tex.SetPixel(w,h,pixel);
// 最后调用，强制写入纹理
tex.Apply();
```

![image-20200325004439393](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200325004439393.png)

### 程序材质

Unity 中专门有一种 **程序材质（Procedural Materials）**，使用程序纹理，通过 **Substance Designer** 在 Unity 外部生成。