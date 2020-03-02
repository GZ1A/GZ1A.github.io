---
# 常用定义
draft: false

title: "【笔记】Shader 入门精要（二）Unity Shader"
date: 2020-02-26T02:08:40+09:00					# 创建时间
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

## 定义

Unity Shader 就是一个文本文件。通过将其赋予材质，可以改变该材质在渲染时的行为。主要是顶点、片元等着色器部分。

## Shader Lab

Unity 为编写 Unity Shader 提供的说明性语言，定义了**着色器代码**以及**渲染所需的数据**。Unity 渲染引擎会根据平台将 Unity Shader 编译成相应代码和 Shader 文件。

## 结构

### 名字

```
Shader "Custom/MyShader" {	}
```

用一个字符串定义 Unity Shader 的名字（及路径）

### 属性（Properties)

``` properties
Properties {
	PropName ("display name", PropertyType) = DefaultValue
	// ...
}
```

可以定义材质属性（渲染数据）的属性名、显示名、对应变量类型和初始值。在这里定义的属性会在材质面板中出现，便于修改。

|         PropertyType         |    DefaultValue     |
| :--------------------------: | :-----------------: |
| Int / Float / Range(min,max) |       number        |
|        Color / Vector        | （num,num,num,num)  |
|        2D / Cube / 3D        | "defaultTexture" {} |

### SubShader

为了兼容不同能力的硬件而产生。加载时 Unity 会选择第一个可在目标环境运行的 [SubShader](https://docs.unity3d.com/Manual/SL-SubShader.html)。一个 Unity Shader 中必须要有一个 SubShader 语义块。每个语义块中包含了多个 Pass，每个 Pass 定义了一次完整的渲染流程。

```
SubShader {
	// optional
	[Tags]			// 标签
	[CommonState]	// 通用状态
	
	Pass{	}
	// other Passes
}
```

### 渲染状态设置 RenderSetup

同[ Pass 渲染状态设置](https://docs.unity3d.com/Manual/SL-Pass.html)，但会对所有 Pass 生效。如：

* Cull 剔除模式

* ZTest 深度测试

* ZWrite 深度写入

* Blend 混合模式

* ...


```
Cull Front
```

### 标签 Tags

[Shader Tags](https://docs.unity3d.com/Manual/SL-SubShaderTags.html) 是两个字符串类型组成的**键值对**。

```
Tags { "TagName1" = "Value1" "TagName2" = "Value" = "Value2" }
```

### Pass 语义块

```
Pass {
	[Name]
	Name "MyPassName"	// 定义名称以便复用
	[Tags]
	Tags { "TagName1" = "Value1" "TagName2" = "Value" = "Value2" }
	[RenderSetup]
	// other code
}
```

还有些特殊的 Pass。

```
UsePass "MyShader/MYPASSNAME"	// 复用其他Pass *必须要全部大写
GrabPass { "TexPropName" }		// 负责抓取屏幕并储存
```

### FallBack

```
Fallback "name"	/ OFF
```

最低级 Shader，类似 Switch 语句的 default 情况。

## 形式

### 整体结构

```
Shader "MyShader" {
	Properties {
		// props
	}
	SubShader {
		// Shader 代码
		Pass {	}
	}
	SubShader {
		// ...
	}
}
```

### 表面着色器

Unity 自己创造的，**更抽象**的着色器代码类型，会被**转换为顶点/片元着色器**。

使用 CG/HLSL 编写，直接定义在 SubShader 语义块中。

```
SubShader {
	Tags { "RanderType" = "Opaque" }
	CGPROGRAM
	#pragma surface surf Lambert
	struct Input {
		float4 color : COLOR;
	};
	void surf (Input IN,inout SurfaceOutput o) {
		o.Albedo = 1;
	}
	ENDCG
}
```

### 顶点/片元着色器

使用 CG/HLSL 编写在 Pass 语义块内。相对复杂而灵活。

```
Pass{
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	float4 vert(float4 v:POSITION) : SV_POSITION{
		return mul (UITY_MATRIX_MVP, v);
	}
	fixed frag() : SV_Target {
		return fixed4(1.0,0,0,0,0,1,0);
	}
	ENDCG
}
```

### 固定函数着色器

定义在 Pass 内，纯 ShaderLab 渲染设置（不可编程）（~~不能编程的GPU现已不存在~~）。



