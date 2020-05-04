---
# 常用定义
draft: false

title: "【笔记】Shader 入门精要（五）基础光照"
date: 2020-03-05T07:22:34+09:00		# 创建时间
author: "昼阴夜阳"             		# 作者

# 分类和标签
categories: ["笔记"]		        # 分类
tags: ["Shader","Shader入门精要"]  	# 标签

# 自定义
comment: true	 # 评论
toc: true        # 文章目录
contentCopyright: '<a rel="license noopener" href="https://creativecommons.org/licenses/by-nc-nd/4.0/" target="_blank">CC BY-NC-ND 4.0</a>'	# 版权规则
reward: true	 # 打赏
mathjax: true    # 打开 mathjax
---

~~又是复习又是复习又是复习。可能这就是前置课程吧（指计算机图形学）。~~

原来复习完原理还要自己写着色器的啊，这波我的。图形学作业只要求了光追，确实没有实现过标准光照模型，建议写。

## 光照模型原理

通过模拟以下现象，来模拟真实的光照环境。

* 光源发射光线
* 光线和场景相交，发生吸收或散射。
* 摄像机吸收光，产生图像

### 光源

通常被抽象成一个点。通过 **辐照度（irradiance）** 量化强度。在垂直于光线方向的单位面积上单位时间内穿过的能量。

### 吸收和散射

**吸收**（absorption）：只改变光线的密度和颜色，不改变方向。

**散射**（scattering） ：只改变光线的方向，不改变密度和颜色。

散射包括**折射**（refraction）（也称透射（transmmision））和**反射**（reflection）。

辐照度经过高光反射和漫反射表示**出射度**（exitance）

**高光反射**（specular）：表示镜面反射。

**漫反射**（diffuse）：表示折射、吸收和非镜面反射。

### 着色

**着色（shading）** 指根据材质属性、光源信息，计算出沿某个观察方向的出射度的过程。**光照模型**就是用来计算的等式。

### BRDF

双向反射分布函数（Bidirectional Reflectance Distribution Function）是 用来给出 在给定（反射）情况下 某个出射方向上的光照能量分布 的函数 这一类函数的统称。

## 标准光照模型

即 Bui Tuong Phong (越) 提出的 Phong 模型，或是改进后的 Blinn-Phong 光照模型。是只关心直接光照的局部光模型，将摄像机捕捉到的光线分为四部分。包括

* 环境光（ambient）
* 自发光（emissive）
* 高光反射（specular）
* 漫反射（diffuse）

### 环境光

模拟间接光照。

$$ c_{ambient} = g _{ambient} m_{diffuse} $$

### 自发光

光源直接发射进入摄像机。

$$ c_{emmisive}=m_{emmisive} $$

### 漫反射

根据兰伯特定律，反射光线的强度与表面法线和 **光源方向（指向光源的方向）** 间夹角余弦值成正比。（就是入射光辐照度低了）

入射光强可由$ c_{light}\cdot \max (0,n\cdot I) $ 得到。其中 $\max$ 是为了防止法线 $ n $ 与光源方向 $I$ 点积为负而进行的截取。

$$ c_{diffuse} = (c_{light} m_{diffuse}) max(0,n\cdot I) $$

### 高光反射

主要有两种**经验模型**。

#### Phong 模型

计算沿着完全镜面反射方向反射的光线。需要知道表面法线 n、视角方向 v、光源方向 I、反射方向 r。

反射方向可通过计算得到：$$r = 2(\hat{n} \cdot I )\hat{n} - I$$

从而计算高光反射有

$$ c_{specular}=(c_{light}m_{specular})max(0,\hat v\cdot r)^{m_{gloss}} $$

gloss 是材质的 **光泽度（gloss)** ，又称反光度（shininess），控制着高光区域"亮点"范围。

#### Blinn 模型

避免了直接计算反射方向 $\hat r$ ，而用视角方向和光源方向平均后归一的 $\hat h$ 与法线 $\hat n$ 参与计算。

$$ \hat h = { {\hat v + I}\over{|\hat v + I|} } $$

$$ c_{specular}=(c_{light}\cdot m_{specular}max(0,\hat n \cdot \hat h)) ^{m_{gloss}}$$

![Blinn.png-32.1kB](http://static.zybuluo.com/candycat/nntler7jilkso6zufrbw447c/Blinn.png)

在**摄像机和光源距离都够远**的情况下，这两个矢量可以看做是常量而实现硬件层面的加速。否则可能反而是 Phong 模型快。

### 计算位置

#### 片元着色器

逐像素光照（per-pixel lighting)。对每个像素根据法线进行着色。法线可以用顶点法线插值或是法线纹理采样。在面片间通过顶点法线插值的技术被称为 **Phong 着色（Phong shading）**。

#### 顶点着色器

逐顶点光照，**高洛德着色（Gouraud shading）**。顶点计算光照，图元内部插值。计算量少，效果差。

### 不足

无法表现许多物理现象，如**菲涅尔反射（Fresnel reflection）**。同时标准模型是 **各向同性（isotropic）** 的，无法表现如拉丝金属，毛发等 **各向异性（anisotropic）** 的表面。

## 在 Unity 中实现标准光照模型

### 环境光

通过 `UNITY_LIGHTMODEL_AMBIENT` 就可以得到环境光的颜色和强度信息。

```
v2f vert(a2f v) {
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

    o.color = ambient*_Diffuse; 

    return o;
}
```

简单的实现了对环境光照的反射。

![image-20200307035456958](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200307035456958.png)

### 自发光

在片元着色器输出前增加材质的自发光颜色。

### 漫反射

#### 逐顶点

首先实现逐顶点的漫反射光照。在着色过程加入**漫反射项**的计算。

```
v2f vert(a2f v) {

    v2f o;
    // transform the vertex from object space to projection space
    o.pos = UnityObjectToClipPos(v.vertex);

    // get ambient term
    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

    // get world space normal / light direction
    fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
    fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

    // get diffuse term
    fixed3 diffuse = _LightColor0.rgb * saturate(dot(worldLight,worldNormal)); 

    o.color = (diffuse + ambient) *_Diffuse;

    return o;
}
```

![image-20200307043558002](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200307043558002.png)

#### 逐片元

将对光照的计算放到片元着色器中，使用插值后的法线进行着色计算，从而得到更细腻的结果。

```
v2f vert(a2f v) {
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);                
    o.worldNormal = UnityObjectToWorldNormal(v.normal);
    return o;
}

fixed4 frag(v2f i) : SV_TARGET{

    // get ambient term
    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

    // get world space normal / light direction
    fixed3 worldNormal = normalize(i.worldNormal);
    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

    // get diffuse term
    fixed3 diffuse = _LightColor0.rgb * saturate(dot(worldLightDir,worldNormal)); 

    fixed3 color = (ambient + diffuse) * _Diffuse;
    return fixed4(color,1.0);
}

```



![image-20200307045426632](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200307045426632.png)

#### 半兰伯特模型

半兰伯特模型是一种没有物理依据的视觉加强技术。通过修改~~映射函数~~模型，允许法向量与光源方向的点积为负数，使得背光面也会有明暗变化。常用公式为

$$ c_{diffuse} = (c_{light}\cdot m_{diffuse} )(0.5(\hat n \cdot I) + 0.5)$$

![image-20200307235740774](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200307050656944.png)

### 高光反射

#### 顶点着色器

通过在顶点着色器中计算高光反射分量，增加高光效果。

```
 // get specular term
 fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));
 fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,v.vertex).xyz);
 fixed3 specular = _LightColor0.rgb * _Specular * pow (saturate(dot(reflectDir,viewDir)),_Gloss);
 
 o.color = specular + (diffuse + ambient) *_Diffuse;
```

![image-20200307050656944](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200307235740774.png)

由于高光反射是非线性的，而顶点计算高光后在片元着色器中经过的插值是线性的，很明显出现了偏差。

#### 片元着色器

将计算移至片元着色器，实现逐像素光照。

```
fixed4 frag(v2f i) : SV_TARGET{
    // get ambient term
    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

    fixed3 worldNormal = normalize(i.worldNormal);
    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

    // get diffuse term
    fixed3 diffuse = _LightColor0.rgb * saturate(dot(worldLightDir,worldNormal)); 

    // get specular term
    fixed3 reflectDir = reflect(-worldLightDir,worldNormal);
    fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
    fixed3 specular = _LightColor0.rgb * _Specular * pow(saturate(dot(viewDir,reflectDir)),_Gloss);

    fixed3 color = specular+(ambient + diffuse) * _Diffuse;
    return fixed4(color,1.0);
}
```

![image-20200308004151307](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200308004151307.png)

#### Blinn 光照模型

Blinn 光照模型使用将视角方向和光照方向相加的 $\hat h$ 参与运算，实践中用的更多。在原先的 shader 上修改高光计算方法。

$$ \hat h = { {\hat v + I}\over{|\hat v + I|} } $$

$$ c_{specular}=(c_{light}\cdot m_{specular}max(0,\hat n \cdot \hat h))^{m_{gloss}}$$

翻译成 cg 就是

```
fixed3 h = normalize(viewDir + worldLightDir);
fixed3 specular = _LightColor0.rgb * _Specular * pow(saturate(dot(worldNormal,h)),_Gloss);
```

![image-20200308005321554](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200308005321554.png)

### 总结

如图。

![image-20200308011744227](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200308011744227.png)

## 内置函数

面对更多更复杂的光照类型，计算要分类讨论，相对麻烦。而 UnityCG.cginc 中定义了许多有用的帮助函数，可以不那么底层。包括了

* 取观察方向（ViewDir)
* 取光照方向（LightDir）
* 法线/矢量在模型空间和世界空间间转换（ObjectToWorld）