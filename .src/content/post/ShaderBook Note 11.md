---
# 常用定义
draft: false

title: "【笔记】Shader 入门精要（十一）屏幕后处理"
date: 2020-03-26T19:18:43+09:00			# 创建时间
author: "昼阴夜阳"        	     		# 作者

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

**屏幕后处理**就是利用渲染纹理，在场景渲染完之后对图像进行操作从而实现艺术效果的技术。（这不就是数字图像处理嘛）

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=477992781&auto=0&height=66"></iframe>

## 后处理脚本

#### 基类

后处理只需要三步：

* 得到屏幕图像
* 调用材质处理
* 重新贴回屏幕

这些调度工作就需要由一个绑定在摄像机上的脚本来完成。脚本不是现在学习的重点，看看就好了。定义一个基类，**确认资源可用** 后通过指定 Shader **生成材质**。

```c#
material = new Material(shader);
return material;
```

#### 脚本实现

`OnRenderImage` 会白给两张图像，将屏幕图像存储到 src 中，并将 dest 图像贴回屏幕。

`Graphics.Blit` 会将 src 图像经过 material 材质处理后保存到 dest 图像中。

通过基类函数创建材质后，使用这两个函数就可以完成特效处理。

```c#
void OnRenderImage(RenderTexture src, RenderTexture dest) {
    if (material != null) {
        material.SetFloat("_Brightness", brightness);
        material.SetFloat("_Saturation", saturation);
        material.SetFloat("_Contrast", contrast);

    	Graphics.Blit(src, dest, material);
    } else {
   		Graphics.Blit(src, dest);
    }
}
```

于是要关心的只剩下 Shader 了。

## 亮度、饱和度和对比度

Properties 中声明属性只是为了方便手动操作，如果由程序操作变量（`material.SetFloat`）就不用声明。但 Blit 传入的 **_MainTex 需要**，猜测是由操作方法决定的？当然仍要定义 CG 变量。

```c#
Properties {
    _MainTex ("Base (RGB)", 2D) = "white" {}
}
```

在采样纹理后，根据设置的图像属性对像素进行处理。

```c#
fixed4 frag(v2f i) : SV_TARGET{
    fixed4 renderTex = tex2D(_MainTex,i.uv);

    // Apply Brightness
    fixed3 finalColor = renderTex.rgb * _Brightness;

    // Apply Saturation
    fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
    fixed3 luminanceColor = fixed3(luminance,luminance,luminance);
    finalColor = lerp(luminanceColor,finalColor, _Saturation);

    // Apply Contrast
    fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
    finalColor = lerp(avgColor, finalColor, _Contrast);

    return fixed4(finalColor,renderTex.a);
}
```

lerp 函数并不只是 [0,1] 插值，而是在以 a 为原点，b-a 为单位 1 的坐标轴上取值。

```c#
float3 lerp(float3 a, float3 b, float w)
{
	return a + w *(b-a);
}
```

显然，这些属性的插值实现并不是顺序无关的，如图，顺序不同效果也不同。可能人为规定了固定顺序吧。

![image-20200327184826864](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200327184826864.png)

## 边缘检测

说到边缘检测，就得提到 ~~OpenCV~~ 卷积。先来复习一下。

### 卷积

使用卷积核对图像中每一个像素进行操作。将翻转后核中每个元素与对应像素值乘积并求和，就能获得锚点处的卷积结果。

### 边缘检测算子

即用于边缘检测的卷积核。检测边缘就是要检测像素值的**梯度（gradient）**。于是有以下几种边缘检测算子。

![image-20200327235748069](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200327235748069.png)

两个卷积核分别检测水平或垂直上的梯度。整体的梯度可以用勾股定理

$$ G=\sqrt{G_x^2 + G_y^2} $$

出于性能考虑，也可以使用绝对值

$$ G=\vert G_x \vert + \vert G_y \vert $$

### Shader 实现

将计算转移到上游以提高效率。在 v2f 结构体中定义 uv 数组并在 vert 中计算好顶点周围像素的 uv，线性插值后就成了片元周围像素的 uv。

```c#
struct v2f{
    float4 pos : SV_POSITION;
    half2 uv[9] : TEXCOORD0;
};
// 通过 _MainTex_TexelSize 获取该像素大小
v2f vert(appdata_img v) {
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    half2 uv = v.texcoord.xy;

    o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1,-1);                
	// ...              
    o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1,1);

    return o;
}
```

在片元着色器中调用 Sobel 函数计算梯度。其实现如下

```c#
// 计算像素值的亮度
fixed luminance(fixed4 color){
    return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
}
// 计算梯度大小,寻找边缘
half Sobel(v2f i){
    // 定义卷积核
    const half Gx[9] = 
    {-1, -2, -1,
    0, 0, 0,
     1, 2, 1};
    const half Gy[9] = 
    {-1, 0, 1,
     -2, 0, 2,
     -1, 0, 1};
    
    half texColor;
    half edgeX = 0;
    half edgeY = 0;
    
    // 计算每个元素与对应像素亮度的乘积并累加
    for(int it = 0; it < 9; it ++){
        texColor = luminance(tex2D(_MainTex, i.uv[it]));
        edgeX += Gx[it] * texColor;
        edgeY += Gy[it] * texColor;
    }
    // 近似计算梯度大小
    half edge = abs(edgeX) + abs(edgeY);
    return edge;
}
```

描个边，调下色，还挺好看的。

![image-20200328024432024](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200328024432024.png)

## 高斯模糊

模糊有好多种，比如均值模糊、中值模糊、高斯模糊。

### 高斯滤波

高斯模糊使用了基于**二维高斯函数**[^1] 的卷积核，能很好的模拟领域像素对当前像素的影响程度。

$$ G(x,y) = {1\over{2 \pi \sigma^2} } e ^ {{x^2 + y^2}\over{2 \sigma^2} } $$

由其性质，二维高斯函数可以被拆成两个一维函数。而一维高斯函数也是对称的，故想用  5×5 的高斯核滤波，只需要记录 3 个权重值。

### 脚本实现

高斯模糊的实现在脚本中应用了 **迭代** 和 **降采样（downSample）** 的方法。同时每一次迭代都需要分别使用垂直和水平方向的高斯核进行滤波，**执行两个 Pass** 。

#### 迭代

就是循环。多次调用材质处理图像来提高模糊程度。

#### 降采样

利用缩放，减少需要处理的像素个数以提高性能。同时适当的降采样也可以得到更好的模糊效果。

```c#
int rtW = src.width / downSample;
int rtH = src.height / downSample;
// 创建双线性滤波的渲染纹理
RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
buffer.filterMode = FilterMode.Bilinear;
// 复制的同时缩放
Graphics.Blit(src, buffer0);
```

#### 分别执行

为了垂直水平分别滤波，在单独调用第一个 Pass 后将结果保存在 buffer 中再单独调用第二个 buffer。

```c#
// Render the vertical pass
Graphics.Blit(buffer0, buffer1, material, 0);

RenderTexture.ReleaseTemporary(buffer0);
buffer0 = buffer1;
buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

// Render the horizontal pass
Graphics.Blit(buffer0, buffer1, material, 1);

RenderTexture.ReleaseTemporary(buffer0);
buffer0 = buffer1;
```

### Shader 实现

在 vert 中定义 水平/垂直 方向的卷积核位置。以垂直方向（水平模糊）为例

```c#
o.uv[0] = uv;
// _BlurSize 控制卷积核元素间距
o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0 ) * _BlurSize;
o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0 ) * _BlurSize;
o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0 ) * _BlurSize;
o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0 ) * _BlurSize;
```

 在 frag 中定义好卷积核权重，累加每个卷积核位置上像素值与对应权重的积。

```c#
float weight[3] = {0.4026, 0.2442, 0.0545};

fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];

for(int it = 1; it < 3; it++){
    sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
    sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
}
```

将函数定义在 CGINCLUDE 语义块中，实际的 Pass 里只要调用就可以了。为 Pass 取名便于其他文件调用 Pass。

```c#
Pass{
    NAME "GAUSSIAN_BLUR_VERTICAL"

    CGPROGRAM

    #pragma vertex vertBlurVertical
    #pragma fragment frag

    ENDCG
}
```

![image-20200329001524914](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200329001524914.png)

## Bloom 效果

又被称为 ~~开花~~ 光华或 glow 效果，用于模拟真实世界相机成像时，亮区扩散形成的**朦胧**效果。

### 原理

* 根据阈值提取较亮区域，存储在渲染纹理中
* 利用高斯模糊模拟光线扩散，自发光效果
* 将原图与自发光图像混合

### Shader 实现

#### 提取亮区

根据原始图像亮度超过阈值的大小算出图像的自发光亮度。

```c#
fixed4 fragExtractBright (v2f v) : SV_TARGET{
    fixed4 c = tex2D(_MainTex, i.uv);
    fixed4 val = clamp(luminance(c) - _LuminanceThreshold,0,0,1.0);

    return c * val;
}
```

#### 高斯模糊

直接调用。

```c#
UsePass "Unity Shaders Book/Chapter 12/Gaussian Blur/GAUSSIAN_BLUR_VERTICAL"
UsePass "Unity Shaders Book/Chapter 12/Gaussian Blur/GAUSSIAN_BLUR_HORIZONAL"
```

#### 图像混合

首先进行了平台差异化处理[^2]。借助 `_Bloom ` 纹理暂存自发光结果，简单粗暴地将自发光与原图相加。

```c#
v2fBloom vertBloom(appdata_img v){
    v2fBloom o;

    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv.xy = v.texcoord;
    o.uv.zw = v.texcoord;
    
	// 如果坐标原点在纹理顶部（Direct3D 行为）
    #if UNITY_UV_START_AT_TOP
        // 且开启了抗锯齿，就需要手动翻转生成的屏幕纹理
        if (_MainTex_TexelSize.y < 0.0)
            o.uv.w = 1.0 - o.uv.w;
    #endif

    return o;
}
fixed4 fragBloom(v2fBloom i):SV_TARGET {
    return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
}
```

![image-20200329053029761](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200329053029761.png)

## 运动模糊

模拟真实世界中的摄像效果。如果在相机曝光时场景发生变化，画面就会模糊。

### 实现原理

实现方法有许多种，包括使用 **累计缓存（accumulation buffer）** 混合多张连续图像和使用 **速度缓存（velocity buffer）** 通过像素的运动速度决定模糊的大小和方向。

暂且先用类似累计缓存的方法实现，但不是暴力渲染多张图像取均，而是直接保存之前的渲染结果并叠加到当前结果上。

### 脚本实现

就像其他脚本一样，主要写个 OnRenderTexture。

首先要获取到积累缓存纹理。然后使用原始图像根据模糊参数和积累纹理（之前渲染的帧）混合，最后将结果输出到屏幕。

```c#
// init accumulationTexture
if(accumulationTexture == null || accumulationTexture.width != src.width || accumulationTexture.height != src.height){
    // 重置纹理
    DestroyImmediate(accumulationTexture);
    accumulationTexture = RenderTexture.GetTemporary(src.width, src.height,0);
    accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
    // 初始化内容
    Graphics.Blit(src, accumulationTexture);
}

// 纹理被渲染时，如果没被清空或者销毁就需要恢复操作？
// 然而这里的手动恢复 貌似注释掉也没有什么关系...
accumulationTexture.MarkRestoreExpected();

// 设置模糊程度
motionBlurMaterial.SetFloat("_BlurAmount", blurAmount);

Graphics.Blit(src, accumulationTexture, material);
Graphics.Blit(accumulationTexture, dest);
```

### Shader 实现

这个 Shader 将会当前图像渲染到积累纹理上。分为两个 Pass，第一个 Pass 负责将当前结果的 RGB 通道与积累纹理混合。由于这个过程利用了 A 通道实现，所以第二个 Pass 负责将 A 通道改回来（虽然现在没看出意义）。

```c#
// 配合 Blend 透明度 使用，利用 A 通道效率叠加图像
fixed4 fragRGB(v2f i):SV_TARGET{
    return fixed4(tex2D(_MainTex, i.uv).rgb, _BlurAmount);
}

// 配合 Blend Zero One & ColorMask A 将 A 修改回来
fixed4 fragA(v2f i) : SV_TARGET {
    return tex2D(_MainTex, i.uv);
}
```

![image-20200330004851553](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200330004851553.png)

***

[^1]:即二维正态分布函数。[参考链接](https://www.cnblogs.com/herenzhiming/articles/5276106.html)
[^2]:[参考链接]( https://blog.csdn.net/WPAPA/article/details/72721185?locationNum=5&fps=1)

