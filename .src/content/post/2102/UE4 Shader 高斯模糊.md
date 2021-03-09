---
# 常用定义
draft: false

title: "UE4 Shader 高斯模糊"
date: 2021-02-14T10:03:50+08:00				# 创建时间
author: "昼阴夜阳"             				# 作者

# 分类和标签
categories: ["技术"]		            		# 分类
tags: ["UE4","Shader"]		    		# 标签
---

## 参考

[Unreal Engine 4 Custom Shaders Tutorial | raywenderlich.com](https://www.raywenderlich.com/57-unreal-engine-4-custom-shaders-tutorial)

材质编辑器的节点系统是个很棒的工具，但节点也有一些限制，比如不能创建 循环 和 switch。不过通过创建自定义节点可以绕过这些限制。自定义节点就是可以写入 GLSL 的节点。可以直接在代码属性里写入，也可以引用 ush 文件。

## 自定义节点使用

右键创建自定义节点，然后修改细节属性就可以了。可以直接修改代码。

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210214105626094.png" alt="image-20210214105626094" style="zoom: 67%;" />

## HLSL

Unreal 将为参与最终输出的任何节点生成HLSL。要查看整个材质的HLSL代码，选择“窗口\HLSL代码”。这将打开一个包含生成代码的单独窗口。

* 需要开启实时预览选项才会实时生成

![image-20210214110201043](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210214110201043.png)

生成出来的代码很长，所以复制出来并且使用文本编辑器来工作。

在 **`CalcPixelMaterialInputs`** 函数的末尾计算了材质的最终输出。如下代码中由于是后处理材质，只关心 EmissiveColor。Local 变量用于存储中间量，而且Local中最后一个（这里指 Local2 ）通常是可以忽略的 dummy。

```glsl
// Now the rest of the inputs
MaterialFloat4 Local0 = SceneTextureLookup(GetDefaultSceneTextureUV(Parameters, 14), 14, false);
MaterialFloat3 Local1 = CustomExpression0(Parameters,Local0.rgba);
MaterialFloat3 Local2 = lerp(Local1,Material.VectorExpressions[1].rgb,MaterialFloat(Material.ScalarExpressions[0].x));

PixelMaterialInputs.EmissiveColor = Local2;
PixelMaterialInputs.Opacity = 1.00000000;
PixelMaterialInputs.OpacityMask = 1.00000000;
PixelMaterialInputs.BaseColor = MaterialFloat3(0.00000000,0.00000000,0.00000000);
PixelMaterialInputs.Metallic = 0.00000000;
PixelMaterialInputs.Specular = 0.50000000;
PixelMaterialInputs.Roughness = 0.50000000;
PixelMaterialInputs.Anisotropy = 0.00000000;
PixelMaterialInputs.Tangent = MaterialFloat3(1.00000000,0.00000000,0.00000000);
PixelMaterialInputs.Subsurface = 0;
PixelMaterialInputs.AmbientOcclusion = 1.00000000;
PixelMaterialInputs.Refraction = 0;
PixelMaterialInputs.PixelDepthOffset = 0.00000000;
PixelMaterialInputs.ShadingModel = 0;
```

于是我们定位到了 SceneTextureLookup 这个函数。搜索查找定义，可以得知这个函数定义如下。

```glsl
/** Applies an offset to the scene texture lookup and decodes the HDR linear space color. */
float4 SceneTextureLookup(float2 UV, int SceneTextureIndex, bool bFiltered)
{
    //...
}
```

* uv就是（0,0)到(1,1)间了
* bFiltered 是场景贴图是否应该双线性过滤，通常是 **`false`**
* TexIndex 根据代码内容继续追踪，可以查到如下

```glsl
#define PPI_SceneColor 0
#define PPI_SceneDepth 1
#define PPI_DiffuseColor 2
#define PPI_SpecularColor 3
#define PPI_SubsurfaceColor 4
#define PPI_BaseColor 5
#define PPI_Specular 6
#define PPI_Metallic 7
#define PPI_WorldNormal 8
#define PPI_SeparateTranslucency 9
#define PPI_Opacity 10
#define PPI_Roughness 11
#define PPI_MaterialAO 12
#define PPI_CustomDepth 13
#define PPI_PostProcessInput0 14
#define PPI_PostProcessInput1 15
#define PPI_PostProcessInput2 16
#define PPI_PostProcessInput3 17
#define PPI_PostProcessInput4 18
#define PPI_PostProcessInput5 19 // (UNUSED)
#define PPI_PostProcessInput6 20 // (UNUSED)
#define PPI_DecalMask 21
#define PPI_ShadingModelColor 22
#define PPI_ShadingModelID 23
#define PPI_AmbientOcclusion 24
#define PPI_CustomStencil 25
#define PPI_StoredBaseColor 26
#define PPI_StoredSpecular 27
#define PPI_Velocity 28
#define PPI_WorldTangent 29
#define PPI_Anisotropy 30
```

于是试着去掉前面的节点，修改一下代码属性里的代码来通过代码采样。

`return SceneTextureLookup(GetDefaultSceneTextureUV(Parameters, 8), 8, false);`

![image-20210214114138279](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210214114138279.png)

然而会报错？！

```python
[SM5] /Engine/Generated/Material.ush(2023,8-76):  error X3004: undeclared identifier 'SceneTextureLookup'
```

为什么手动调用就不行？使用了 SceneTexture 节点时，编译器才会自动 Include SceneTextureLookup() 的定义。由于断开连接，没有使用这个节点，编译的时候也就没有 include 这段定义了。

所以需要建立一个引用，让引擎包含这段。只要连接到Custom节点的一个 **有名字的引脚** 就可以了。（虚晃一枪而不使用，或者实际用到都可以）

![image-20210214115024591](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210214115705304.png)

## 使用外部 Shader 文件

代码比较长，就可以在编辑器里编写usf/ush文件，并在代码属性中引用。

引擎会自动在 Shaders 文件夹下查找。（包括项目目录下的和引擎目录下的）

![image-20210214115705304](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210214115705304.png)

可以分别通过如下代码进行引用。需要 return 0，但不影响结果。

[博客 | UE4 材质CustomNode引入自定义.usf/.ush文件](https://blog.csdn.net/weixin_43369654/article/details/92607776) 指出 /Project 的 mapping 在 C++ 模板下才会默认创建。相对路径不成功的话建议使用绝对路径。

```glsl
#include "/Project/Gaussian.usf"
#include "/Engine/RMBlob.ush"
```

![image-20210203041058099](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210203041058099.png)

Shift+Enter 换行（修改内容），然后 Enter 触发重编译。

## 创建高斯模糊

就像在卡通轮廓教程中一样，这种效果使用卷积。最终输出是内核中所有像素的平均值。在经典的框模糊中，每个像素具有相同的权重。这将导致更宽模糊的伪影。高斯模糊通过减少像素的权重来避免这种情况，因为它离中心越远。这使得中心像素更加重要。

由于所需的样本数量大，使用材质节点进行卷积并不理想。例如，在5×5内核中，我们将需要25个样本。 将尺寸加倍到10×10内核，会需要100个样本！ 那时，节点图看起来就像一碗意大利面！

使用 Custom 节点，我们可以编写一个小的for循环，以对内核中的每个像素进行采样。 第一步是设置一个参数来控制样本半径。

### 创建全局函数

自定义节点实际上做了一个复制粘贴的工作。输入

```cpp
return 1;
```

就会被复制粘贴成这样：

```cpp
MaterialFloat3 CustomExpression0(FMaterialPixelParameters Parameters)
{
	return 1;
}
```

所以合理利用机制：手动完成前面的内部（命名）函数，在最后定义一个全局函数来吃掉后面补上的大括号。中间也就可以定义全局函数、变量啦。

```cpp
    return 1;
}

float MyGlobalVariable;

int MyGlobalFunction(int x)
{
    return x;
```

#### 一维高斯函数

简化的一维高斯函数如下

![unreal engine shaders](https://koenig-media.raywenderlich.com/uploads/2018/03/unreal-engine-shaders-19.jpg)

创建一个新的自定义节点并将其命名为Global。然后，将代码中的文本替换为以下内容，全新的高斯函数就创建好啦！

```cpp
return 1;
}

float Calculate1DGaussian(float x)
{
    return exp(-0.5 * pow(3.141 * (x), 2));
```

要让这个节点被引入，我们可以把Global（return 1）与图中的第一个节点相乘。从而确保其他自定义节点要使用全局函数的时候已经定义好了。和 Texture 相乘，所以改一下输出类型到 float4。

### 采样多个像素

* 计算样本像素的相对偏移量并将其转换为UV空间

* 使用偏移量对场景纹理进行采样（在本例中为后期处理输入0）

* 计算采样像素的权重。要计算二维高斯函数，只需将两个一维高斯函数相乘即可。需要除以半径来标准化到一维高斯函数的（-1，1）范围。

* 将加权的结果添加到PixelSum

* 将权重添加到WeightSum

* 最后计算加权平均值。

```cpp
static const int SceneTextureId = 14;
float2 TexelSize = View.ViewSizeAndInvSize.zw;
float2 UV = GetDefaultSceneTextureUV(Parameters, SceneTextureId);
float3 PixelSum = float3(0, 0, 0);
float WeightSum = 0;

for (int x = -Radius; x <= Radius; x++) {
    for (int y = -Radius; y <= Radius; y++) {
        float2 Offset = UV + float2(x, y) * TexelSize;
        float3 PixelColor = SceneTextureLookup(Offset, SceneTextureId, 0).rgb;
        float Weight = Calculate1DGaussian(x / Radius) * Calculate1DGaussian(y / Radius);
        PixelSum += PixelColor * Weight;
        WeightSum += Weight;
    }
}

return PixelSum / WeightSum;
```

![image-20210214132842355](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210214132842355.png)