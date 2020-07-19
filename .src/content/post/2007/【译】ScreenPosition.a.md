---
# 常用定义
draft: false

title: "【译】Shader Graph 中 的 ScreenPosition.a 的含义"
date: 2020-07-19T23:23:23+09:00			# 创建时间
author: "昼阴夜阳"             		# 作者

# 分类和标签
categories: ["翻译"]		            # 分类
tags: ["Unity","Shader"]		    		# 标签
---

[论坛 | What does ScreenPosition.a means in shader graph?](https://forum.unity.com/threads/what-does-screenposition-a-means-in-shader-graph.909866/)

## Shader Graph 中 的 ScreenPosition.a 的含义？

**Q:**	I've search around and checked out [Documentation](https://docs.unity3d.com/Packages/com.unity.shadergraph@6.9/manual/Screen-Position-Node.html), but cannot understand what exactly does ShaderGraph's ScreenPosition node's **b** and **a ** components meaning.

Isn't **r** and **g** components enough to represent 2d screen position?

我已经在文档里找了一圈了，但是无法理解 ShaderGraph 的 ScreenPosition 节点的 b 和 a 的含义是什么。

r 和 g 分量不足以代表2d屏幕位置吗？

**A:**	For most of the modes, the b and a are hard coded 0.0 values.

However in the "raw" mode this is passing along the original interpolated clip space position z and w. The z/w (or rather b/a in shader graph) is the raw depth buffer value for that pixel, similar to the raw value you'd get from the Scene Depth node. The w or a depends on if you're using a perspective or orthographic camera. With an orthographic projection the w is always 1.0. With a perspective camera it's the view depth, equivalent to the Position node's negative b if set to Space View (view space is -Z forward).

对于大多数模式，b和a是硬编码的0.0值。

但是，在“原始”（Raw）模式下，b 和 a 传递 **插值后的裁剪空间中的 z 和 w**。z / w（即着色器图中的 b / a）（指除法）是该像素（片元）的原始深度缓冲区值，和“场景深度”节点获得的原始值一样。 w （即 a）的值取决于你使用的是透视相机还是正交相机。 使用正交投影时，w 始终为 1.0。 对于透视相机，它是 **（片元在）视角坐标系中的深度**，相当于视角空间下的“位置”（Position - Space View）节点的 -b（视角空间为-Z向前）。

Why is that the value for a? Because of how perspective correct interpolation works. The Screen Position node's rg values in the default mode are equal to rg/a in the raw mode. That's actually how the default mode calculates those values from the interpolated inputs. When using an orthographic projection you don't need to do any special handling of interpolated values, so the a is just always 1.0. As I said before, b/a is the depth, because the zw values are copies of the unmodified clip space position the vertex shader outputs and that the GPU normally uses to calculate the screen depth by doing that same z/w in the hardware.

为什么这是 a 的值？因为透视校正插值是这样工作的。默认模式下屏幕位置节点的 rg 值等于原始模式下的 rg/a 。这实际上就是默认模式根据插值输入计算这些值的方法。使用正交投影时，不需要对插值值进行任何特殊处理，因此 a 始终为 1.0。如前所述，b/a 是深度，因为 zw 值是顶点着色器输出的未修改的裁剪空间位置的副本，GPU 通常通过在硬件中执行相同的 z/w 来计算屏幕深度。