---
# 常用定义
draft: false

title: "【笔记】Shader 入门精要（四） Shader 基础"
date: 2020-03-02T22:03:49+09:00		# 创建时间
author: "昼阴夜阳"             		# 作者

# 分类和标签
categories: ["笔记"]		            # 分类
tags: ["Shader","Shader入门精要"]  	# 标签

# 自定义
comment: true	 # 评论
toc: true        # 文章目录
contentCopyright: '<a rel="license noopener" href="https://creativecommons.org/licenses/by-nc-nd/4.0/" target="_blank">CC BY-NC-ND 4.0</a>'	#版权规则
reward: true	 # 打赏
mathjax: true    # 打开 mathjax

---

终于来到实践环节了！可喜可贺可喜可贺。

## 顶点/片元着色器

模型的每个顶点会调用顶点着色器。顶点间插值得到许多片元（像素）。每个片元会调用片元着色器。

### 整体结构

```
Shader "MyShader" {
	Properties {
		// props
	}
	SubShader {
		// 针对显卡 A 的 SubShader
		Pass {
        	// 设置渲染状态和标签
        	
        	// CG 代码片段
        	CGPROGRAM
        	// 编译指令 
        	// 通知 Unity 包含 vertex shader 的函数名
        	#pragma vertex vert
        	// 通知 Unity 包含 fragment Shader 的函数名
        	#pragma fragment frag
        	
        	// CG 代码
        	
        	ENDCG
        	
        	//其他设置
        }
	}
	SubShader {
		// 针对显卡 B 的 SubShader
	}
	
	Fallback "VertexLit" // 保底 Shader
}
```

### 语义

```
float4 vert(float4 v : POSITION) : SV_POSITION {
	// return mul (UNITY_MATRIX_MVP, v);
	// 新版被替换为如下代码
	return UnityObjectToClipPos (v);
}
fixed3 frag() : SV_Target {
	return fixed4(1,1,1,1);
}
```

语义（semantics），CG/HLSL 中的语法，如 `POSITION`,`SV_POSITION`,`SV_Target`。语义可以告诉系统，用户的输入和输出是什么，并**交由系统赋值**。这里的`POSITION`告知了 Unity 要把模型的顶点坐标赋给参数 v，`SV_POSITION`告知了顶点着色器输出的是裁剪空间中的的顶点坐标，`SV_Target`让渲染器把输出存储到一个渲染目标中（这里是帧缓存）。

对于自定义的结构体，创建时变量也会被赋值。在每帧的 Draw Call 时， Mesh Render 组件会把它赋值的模型数据发送给 Unity Shader。

```
struct a2v { // application to vertex shader
    float4 vertex : POSITION;	// 位置
    float3 normal : NORMAL;		// 顶点法向量
    float4 texcoord : TEXCOORD0;// 第0个纹理坐标
};
```

```
struct v2f { // vertex to fragment
	float4 pos : SV_POSITION;	// 裁剪空间内位置
	fixed3 color : COLOR0;		// 第0个颜色
};
```

### 属性

在 Shader 开头的属性语义块中声明的变量可以在 Unity 的材质面板中方便的操控。

```
Properties{
	_Color ("Color Tint", Color) = (1.0,1.0,1.0,1.0)
}
// ...
fixed4 _Color;	// 在 CG 代码中定义变量
// ...
fixed3 frag(v2f i) : SV_Target {
	fixed3 c = i.color;
	c *= _Color.rgb;
	return fixed4(c,1.0);
}
```

定义一个属性需要在属性语义块中按照格式进行定义。同时还要在 CG 代码中**定义一个同名变量**以访问属性。Unity 会把属性的值赋给这个 CG 变量。

## 内置文件和变量

包含文件（include file）含有一些变量和帮助函数。可通过 #include 将 .cginc 文件包含进 Shader 中的 CG 代码从而使用其中内容。

```
#include "UnityCG.cginc"
```

有很多不同的包含文件。最常用的是 UnityCG.cginc 。其中包含的结构体定义、变量和函数的具体说明建议直接查看 `安装路径/Data/CGIncludes/UnityCG.cginc`。

## 语义

### 定义

表达参数含义的字符串。有时输入和输出的语义名字一样但含义不一样，如`TEXCOORD0`作为输入语义指第一组纹理坐标，作为输出语义就不是了。

DirectX 10 以后定义了系统数值语义（system-value semantics），以 SV 开头。在某些平台，这些语义代表了该变量是流水线要用到的变量。为了更好的跨平台性，建议使用。

### Unity 常用语义

虽然没有使用 SV 开头，但 Unity 内部赋予了特殊含义的语义。

| 语义          | 描述                                | 类型            |
| :------------ | :---------------------------------- | --------------- |
| POSITION      | 模型空间中的顶点位置 (以下是 a2v)   | float4          |
| NORMAL        | 顶点法线                            | float3          |
| TANGENT       | 顶点切线                            | float4          |
| TEXCOORDn     | 纹理坐标，n为纹理下标               | float2 / float4 |
| COLOR         | 顶点颜色                            | fixed4 / float4 |
| SV_POSITION   | 裁剪空间中的顶点位置 (以下是 v2f)   | float4          |
| COLOR0 / 1    | 输出第一 / 第二组顶点颜色           | fixed4 / float4 |
| TEXCOORD0 ~ 7 | 输出纹理坐标                        | float2 / float4 |
| SV_Target     | 渲染目标，等同 COLOR 语义（f 输出） | fixed4 / float4 |

## Debug

Shader 由于不能输出，很难 Debug 。

### 假彩色图像

最原始的方法，通过把变量映射到 0 到 1 间并作为颜色输出到屏幕上，进行数据可视化。例如可视化法线信息，使用[拾色器](https://github.com/candycat1992/Unity_Shaders_Book/blob/master/Assets/Scripts/Chapter5/ColorPicker.cs)脚本在屏幕上获取对应数据。

```
v2f vert (appdata_full v) {
	// ... 
	o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
	return o;
}
```

![可视化法线信息](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200305062550133.png)



### Visual Studio

[Unity 官方文档](https://docs.unity3d.com/Manual/SL-DebuggingD3D11ShadersWithVS.html) 里写了。

# 【等待填充】

### 帧调试器

停止渲染，精确到每一个渲染事件，可以实时查看效果，建议使用。但并没有很多过程信息。真需要信息还得看外部工具。不过帅就完事了。

![image-20200305063715619](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200305063715619.png)

## 代码规范

### 数值类型

CG / HLSL 中有 3 种精度的数值类型。通常的定义如下

| 数值类型 | 存储位数 | 精度范围       |
| -------- | -------- | -------------- |
| float    | 32       |                |
| half     | 16       | -60000 ~ 60000 |
| fixed    | 11       | -2.0 ~ +2.0    |

在 PC 上，大多数 GPU 一律以最高精度计算。在移动平台上则会有不同范围和计算速度。尽可能使用精度较低的类型。

### 语法

严格要求语法以更好的跨平台。

### 减少不必要的计算

Shader Model 是微软提出的 Shader 能力分级。不同的 Shader Target 和着色器阶段可用的临时寄存器和指令数目都是不同的。

可通过指定更高等级的 Shader Target 消除错误（降低兼容性），但更好的方法是减少 Shader 中的运算。

### 慎用分支和循环

由于底层实现不同， Shader 中大量流程控制可能导致性能成倍下降。尽量把计算向流水线上游移动或预计算，同时

* 条件变量多用常数
* 减少分支内指令
* 减少嵌套

### 不要除 0

rt

---

![image-20200305071748712](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/image-20200305071417478.png)



