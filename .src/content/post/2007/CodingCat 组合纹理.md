---
# 常用定义
draft: false

title: "【笔记】CodingCat 组合纹理"
date: 2020-07-07T20:10:45+09:00			# 创建时间
author: "昼阴夜阳"             		# 作者

# 分类和标签
categories: ["技术"]		            # 分类
tags: ["CodingCat","Shader"]		    		# 标签
---

自己想学的时候，不做笔记就不会认真学。最近看到了有大佬翻译了 Coding Cat 的教程，很感谢了。快速学一下，练练手。先上参考。

[微信 | 基础渲染系列（三）多样化的表现——组合纹理](https://mp.weixin.qq.com/s/MQ_V78MmkPlQ1cbJyobtCw) 

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=32857745&auto=0&height=66"></iframe>

## 多纹理采样

是组合纹理的技术基础。对多个纹理进行采样，从而获得多种数据。

在纹理贴图中存入不同种类的数据。如 splat 贴图中存入的就是贴图的权重。

## 细节纹理

纹理大小是固定的，但显示大小是不定的，因此势必会进行缩放。缩小时可以通过 mipmap 保持清晰，而放大时通常使用细节纹理技术 **创造细节** 从而降低模糊。

将细节纹理 **平铺**，通过 **乘法修改** 主纹理颜色，在远处 **逐渐消隐**。

将原始值映射到 [0,2] 区间内从而提供上下的修改空间。

``` c#
// sample the texture
fixed4 col = tex2D(_MainTex, i.uv);
fixed4 colDetail = tex2D(_DetailTex,i.uvDetail);

// mix
col *= colDetail * unity_ColorSpaceDouble;
```

`unity_ColorSpaceDouble` 可在 UnityCG.cginc 中找到定义

```c#
#ifdef UNITY_COLORSPACE_GAMMA
#define unity_ColorSpaceDouble fixed4(2.0, 2.0, 2.0, 2.0)
// ...
#else // Linear values
#define unity_ColorSpaceDouble fixed4(4.59479380, 4.59479380, 4.59479380, 2.0)
```

## 纹理 Splatting

细节纹理在整个表面使用了相同的细节。想使用不同的细节，可以通过增加细节贴图，并使用 Splat 贴图控制这些细节贴图混合。

{{% mask "splatoon 大概也确实用了这个" %}} 

**非图像数据的导入设置**

当贴图保存的是非图像数据时，应该勾选上

- [ ] 绕过*sRGB* 采样 (*Bypass* *sRGB* *sampling*)
- [ ] 在线性空间中生成 MipMap
- [ ] Wrap Mode 根据情况变化

混合代码如下，当然混合方式要与贴图匹配。

```c#
// sample the texture
fixed4 col1 = tex2D(_MainTex1, i.uvDetail);
fixed4 col2 = tex2D(_MainTex2,i.uvDetail);

col += col1 * tex2D(_SplatTex,i.uv).r;
col += col2 * tex2D(_SplatTex,i.uv).g;
// ...
```

