---
# 常用定义
draft: false

title: "【笔记】Shader 入门精要（十二）深度和法线纹理"
date: 2020-03-30T02:23:54+09:00			# 创建时间
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

屏幕后处理除了利用图像的颜色信息，还可以利用深度和法线信息。这些信息不受纹理和光照的影响，能给出更多的细节。

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=1367954548&auto=0&height=66"></iframe>

## 获取深度和法线纹理

### 原理

深度纹理就是一张存着高精度深度值的渲染纹理。深度值 [0, 1] 对应着 **NDC 中坐标** 的 z 分量 [-1, 1]。延迟渲染下，深度纹理可以从 Gbuffer 得到。前向渲染下则会单独渲染  Opaque 物体的 ShadowCaster Pass（如果没有就不会被渲染进深度纹理）。

法线纹理就是一张存着**观察空间下法线信息**的渲染纹理。前向渲染下同样需要通过再次渲染来得到。

### 获取

通过**设置相机模式**就可以在 Shader 直接访问特定的纹理属性了，Unity 会负责渲染并输入到 Shader 属性中。例如设定深度模式：

```c#
// 通过 _CameraDepthTexture 访问
camera.depthTextureMode = DepthTextureMode.Depth;
```

就可以在 CG 中定义并访问对应 `sampler2D` 变量。还可以组合模式，同时生成多个纹理：

```c#
// 通过 _CameraDepthTexture 访问
camera.depthTextureMode |= DepthTextureMode.Depth;	
// 通过 _CameraDepthNormalsTexture 访问
camera.depthTextureMode |= DepthTextureMode.DepthNormals;
```

#### 深度值

获取到深度纹理后，大部分时候可以通过 `tex2D` 进行采样。但由于 PS3 、PSP2 等平台的差异，建议使用 Unity 提供的宏 `SAMPLE_DEPTH_TEXTURE` 宏对深度纹理进行采样。

``` c#
// 返回 float 深度值
float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
```

采样得到的深度值通常并不能直接使用，因为它对应的是 NDC ，是**非线性的**[^1]。在空间经过裁剪矩阵（即投影矩阵）的平移缩放后，会经过透视除法（齐次除法）的处理。z 轴坐标不需要进行屏幕映射，有关系如下

$$ z_{ndc} = {z_{clip} \over w_{clip} }$$

以透视投影为例，根据裁剪矩阵可知

$$ w_{clip} = -z_{view} $$

由于 $1/z_{view}$ 非线性，这次除法导致了 NDC 坐标的非线性[^2]。为了重新得到线性的坐标，就需要倒退变换过程。Unity 提供了两个辅助函数来进行变换。这两个函数了使用内置 `_ZBufferParams` 得到远近裁剪平面的距离，`LinearEyeDepth` 返回视角空间下的 $z_{view}$，`Linear01Depth` 返回在 [0,1] 间的线性深度值。

#### 深度和法线

深度和法线纹理经过 Unity 的编码，xy 分量保存了法线信息，zw 分量保存了深度信息。首先使用 `tex2D` 进行采样，然后通过调用内置 `DecodeDepthNormal` 函数解码采样得到的结果，就可以得到**视角空间下的法线**和**线性深度值**。

### 查看

通过帧调试器可以查看到深度纹理、深度和法线纹理。

有需要的信息（如线性空间下的深度信息）可以自行在片元着色器中输出。（因为是透明的所以是透明的球瞩目）

![image-20200331053328167](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200331053328167.png)

## 运动模糊

上一节的运动模糊是通过混合屏幕图像模拟的，也可以通过**速度映射图**实现。这种技术使用速度缓冲得到每个像素的速度，以此决定模糊的方向和大小。

速度缓冲的一种生成方法是将场景中所有物体的速度渲染到一张纹理中。但这样需要修改所有物体的 Shader 代码进行计算并渲染。《GPU Gem3》中介绍了另一种方法。记录 **视角*投影矩阵**(VP)，用逆矩阵将深度缓冲中的每个 NDC  坐标变换回世界空间，再用前一帧的视角*投影矩阵得到这个坐标在前一帧的 NDC 坐标。位置差就是这个像素的速度了。

### 脚本实现

脚本部分比较简单。首先需要获取处理用的信息。通过 Camera 组件可以得到 **VP 矩阵** 以及 **深度纹理**。

```c#
// 定义变量存储上一帧的 VP 矩阵
private Matrix4x4 previousViewProjectionMatrix;

// 开启时启用深度纹理，并给变量赋初值
void OnEnable() {
    camera.depthTextureMode |= DepthTextureMode.Depth;

    previousViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
}
```

在 `OnRenderImage` 处理时计算并传入这些要用到的变量，并为下次调用做准备。

```c#
// 向 Shader 传入各种需要的变量
material.SetFloat("_BlurSize", blurSize);

material.SetMatrix("_PreviousMatrix", previousViewProjectionMatrix);
Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
material.SetMatrix("_CurrentMatrixInverse", currentViewProjectionInverseMatrix);

// 保存当前帧的 VP 矩阵，供下一帧调用
previousViewProjectionMatrix = currentViewProjectionMatrix;
```

### Shader 实现

#### 属性和变量

Unity 中没有对应 Matrix 的属性，因此矩阵不用声明，只要在 CG 中定义 `float4x4` 变量就可以了。

```c#
sampler2D _MainTex;
half4 _MainTex_TexelSize;
float4x4 _CurrentMatrixInverse;
float4x4 _PreviousMatrix;
half _BlurSize;
sampler2D _CameraDepthTexture;
```

#### 顶点着色器

要同时处理多张渲染纹理，就需要做平台差异化处理（见上一篇的链接）。因此把深度纹理的采样坐标单独拿出来。

```c#
v2f vert(appdata_base v){
    v2f o;

    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    o.uv_depth = v.texcoord;

    #if UNITY_UV_STARTS_AT_TOP
        if (_MainTex_TexelSize.y <0)
            o.uv_depth.y = 1 - o.uv_depth.y;
    #endif

    return o;
}
```

#### 片元着色器

要得到速度缓冲，首先要获取当前 NDC，然后转换得到世界坐标，再转换成上一帧的 NDC。

```c#
// 从深度纹理得到 NDC
float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth);
float4 ndcPos = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depth * 2 -1, 1);

// 将 NDC 转换回 世界坐标
float4 worldPos = mul(_CurrentMatrixInverse,ndcPos);
worldPos /= worldPos.w; 

// 再次转换得到上一帧的 NDC
float4 previousNdcPos = mul(_PreviousMatrix, worldPos);
previousNdcPos /= previousNdcPos.w;
```

这些步骤中里的第 7 行引起了我的注意。世界坐标到 NDC 的转换明明是先经过 VP 矩阵，然后再进行了透视除法，除以 $clip_w$ 得到的；要反向变换也就是需要乘上 $clip_w$ 并右乘 VP 的逆矩阵。经过一番调查[^3]悟到了这两个操作是等价的。

然后计算得到像素在屏幕上的速度，并将速度方向上的颜色与当前屏幕颜色叠加...然而至少在我测试的情况下效果挺差的。

```c#
float2 velocity = (ndcPos.xy - previousNdcPos.xy)/2.0f;

float2 uv = i.uv;
float4 color = tex2D(_MainTex, uv);
uv += velocity * _BlurSize;
for(int it = 1;it < 3;it++, uv += velocity * _BlurSize){
    color += tex2D(_MainTex, uv);
}
color /=3;
```

而且这种计算方法只考虑了相机的移动，无法反映出物体的移动。

## 全局雾效

Unity 内置了基于距离的线性/指数雾效，在 Shader 中使用编译指令和内置宏即可。但这种方法需要为所有物体添加相关代码，并且不能定制。

现在有了深度纹理，就可以基于屏幕后处理方便自由的模拟各种雾效，关键在于重建像素的世界坐标。

### 重建世界坐标

上一节通过矩阵变换得到了世界坐标，但这样在着色器中进行矩阵乘法会影响游戏性能（换取了像素的帧间对应关系）。通过**插值**和**相对位置**得到世界坐标的方法更快更好。

首先通过插值算出到近裁剪平面上对应点的单位（并不）向量，再乘上线性的 z 轴深度就是像素在视角空间下的坐标，即相对相机的偏移量。最后和相机的世界空间位置相加即完成重建 。

```c#
float4 worldPos = _WorldSpaceCameraPos + linearEyeDepth * interpolatedRay;
```

#### 世界坐标

shader 内置变量 `_WorldSpaceCameraPos`。

#### 线性深度

在开启相机的深度纹理模式后，将采样经过 `LinearEyeDepth()` 处理，得到线性深度。

#### 对应向量

interpolatedRay 即内插光线。源于对近裁剪平面四个角的方向向量的插值（事实上是到 **z 轴距离为 1** 平面的四个角）。以左上值 TL 为例，首先计算从近裁剪面中心指向摄像机上方和右方的向量 `toTop` 和 `toRight`。
$$
halfHeight = Near \times \tan \bigg({FOV \over 2  }\bigg)\\
toTop = camera.up \times halfHeight \\
toRight = camera.right \times halfHeight.aspect
$$
于是就可以得到 TL ，其他几个点同理。

$$ TL = camera.forward \cdot Near + toTop - toRight $$

由于 TL 方向是点到摄像机的欧氏距离，不是深度值表示的到摄像机的 z 轴距离，在计算偏移量时就要乘上 $ 1 \over \cos\theta$（夹角）。即乘上偏移方向的模与 Z 轴方向之比。

$$scale = {|TL| \over|Near|}$$

最后将归一化的方向向量乘上 Scale 就可以得到原点指向 `linearEyeDepth == 1` 的平面的向量。

![我画了一年](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/04/image-20200415034949460.png)

### 计算雾效

 雾效就是根据 **雾效系数 f** ，将雾的颜色与原始颜色混合。效果的关键就是参数的计算了。

```c#
float3 afterFog = f * fogColor + (1-f) * originColor;
```

在 Unity 的内置雾效实现中，有三种雾的计算方式——线性、指数、指数的平方，本节使用类似线性雾的方式，实现高度相关的雾。

```c#
float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);
```

##### 线性

d 表示雾影响的最大最小距离，有
$$
f = {d_{max} - |z|\over d_{max} - d_{min}}
$$

##### 指数

d 控制浓度
$$
f = e^{-d-|z|}
$$

##### 指数平方

$$
f = e^{-(d-|z|)^2}
$$

### 实现

就硬做。{{% mask 间隔了两周实在是懒得补了 %}}

![image-20200415035719212](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/04/image-20200415035719212.png)







[^1]:冯乐乐. Unity Shader 入门精要[M].北京：人民邮电出版社,2016;  270.
[^2]: [这篇博客](https://blog.csdn.net/puppet_master/article/details/77489948) 的投影部分从实用价值的角度出发解释这个非线性，也挺好
[^3]:感谢 [指路博客](https://www.cnblogs.com/sword-magical-blog/p/10483459.html) 以及 [参考链接](http://feepingcreature.github.io/math.html)

