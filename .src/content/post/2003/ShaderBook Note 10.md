---
# 常用定义
draft: false

title: "【笔记】Shader 入门精要（十）动画效果"
date: 2020-03-25T12:03:14+09:00			# 创建时间
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

引入时间变量，实现动画效果。

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=1433340584&auto=0&height=66"></iframe>

## 内置变量

Unity Shader 内置有许多时间相关的变量用于访问。

| 名称            | t                          | 分量                             |
| --------------- | -------------------------- | -------------------------------- |
| _Time           | 自该场景加载开始经过的时间 | (t/20, t, 2t, 3t)                |
| _SinTime        | 时间的正弦值               | (t/8, t/4, t/2, t)               |
| _CosTime        | 时间的余弦值               | (t/8, t/4, t/2, t)               |
| unity_DeltaTime | 时间增量                   | (dt, 1/dt, smoothDt, 1/smoothDt) |

## 纹理动画

### 序列帧动画

依次播放关键帧实现的动画。灵活性强但美术工程量大。实现比较简单，只要在对纹理采样前根据时间重新计算 uv 到对应关键帧处。

```
// 使用时间变量播放逐帧动画
float frame = floor(_Time.y * _Speed);
float row = floor(frame / _HorizonalAmount );
float col = frame - row * _HorizonalAmount;
half2 uv = i.uv + half2(col, - row);
uv.x /= _HorizonalAmount;
uv.y /= _VerticalAmount;
```

![boomAnim](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/978c864b-54be-4921-a9a8-cfa2fd5d9e80.gif)

### 滚动背景

通过多个层模拟视差效果。只需要分别计算动画后插值渲染即可。

```
// 使用时间变量计算滚动位置
o.uv.xy += frac(float2(_ScrollX, 0) * _Time.y);
o.scrolluv.xy += frac(float2(_Scroll2X,0) * _Time.y);
// 用 detail 的透明度混合前后纹理
fixed4 detailColor = tex2D(_DetailTex, i.scrolluv.xy);
fixed4 texColor = lerp(tex2D(_MainTex, i.uv.xy),detailColor,detailColor.a); 
```

### 流动河流

首先在标签中设置 `"DisableBatching" = "True"`，让这个 SubShader 逃离批处理的大锅，否则 Unity 会把相关模型合并处理，也就没有单独的模型空间供顶点位移了（虽然没有看出差别）。核心就是让面片的顶点随着时间左右横跳，并且使不同的顶点相位不同。

```
// 在 vertex 变换前添加计算 offset
fixed4 offset = fixed4(0,0,0,0);
offset.x = _Magnitude * sin( _Frequency * _Time.y + _InvWaveLength * (v.vertex.x + v.vertex.y + v.vertex.z));
o.pos = UnityObjectToClipPos(v.vertex + offset);
```

要有好的效果，主要工作还得看调参（笑）。

![239cb0bf-06f6-4515-a978-4b2f31c15b03](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/03/150d6caf-75d9-4510-b8a4-c0028634e790.gif)

### 广告牌

即 Billboard 技术。让多边形跟随视角方向旋转。本质就是构造变换矩阵（normal, up, right），通常 up 与 normal 中的一个是确定的。以 normal 确定（~~向日葵形态~~）为例，在左手坐标系下有
$$
right = up \times normal \\
up' = normal \times right
$$
因此，在将顶点坐标从模型空间变换到裁剪空间之前，构造变换矩阵并对顶点坐标进行变换就可以实现广告牌效果。

```
// 修改模型空间中对应的顶点位置
// 计算 法线方向
float3 center = float3(0,0,0);
float3 viewDir = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1));
float3 normalDir = -viewDir;
// 控制法线的 y 轴变化程度
normalDir.y *= _VerticalBillboard;
normalDir = normalize(normalDir);

// 获取大致向上方向和向右方向
float3 upDir = normalDir.y > 0.99? float3(1,0,0):float3(0,1,0);
float3 rightDir = normalize(cross(upDir,normalDir));
upDir = normalize(cross(normalDir,rightDir));
// 旋转
float3 centerOffset = v.vertex.xyz - center;
float3 localPos = center + centerOffset.x * rightDir + centerOffset.y * upDir + centerOffset.z * normalDir;

// 输出最终位置
o.pos = UnityObjectToClipPos(localPos);
```

### 注意事项

* 可以在顶点中存储顶点到锚点距离，供批处理使用从而提高效率

* 顶点动画的物体阴影需要提供自定义 ShadowCaster Pass

  

