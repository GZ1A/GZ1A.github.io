---
# 常用定义
draft: false

title: "UE4 RayMarching 史莱姆"
date: 2021-02-02T23:01:11+08:00				# 创建时间
author: "昼阴夜阳"             				# 作者

# 分类和标签
categories: ["技术"]		            		# 分类
tags: ["RayMarching","UE4"]		    		# 标签

---

## 参考

[【UE4】史莱姆材质制作流程](https://www.bilibili.com/video/av78907474)

## 自定义节点

可以写入 GLSL 的节点。可以直接在代码属性里写入，也可以引用 ush 文件。

### 代码

文件放在 `引擎路径\UE_4.26\Engine\Shaders` 下，可以通过 `#include "/Engine/xxxxx.ush"`进行引用，需要 return 0，但不影响结果。

![image-20210203041058099](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210203041058099.png)

Shift+Enter 换行（修改内容），然后 Enter 触发重编译。

### 输入

可以设置各种输入，在代码中可以通过对应名称进行引用。

## RayMarching

最小可跑的球。参考 RayMarching 笔记。

```glsl
float4 col=0;
float3 pos=WorldPos;

for(int i=0; i<MaxSteps; i++) {

    if(SceneDepth < length(pos - CameraPos)){
        break;
    }
	
    // SDFSphere
    float distance=length(pos - ObjectPos) - 50;

    if(distance < 0.1) {
        col=1.;
        break;
    }

    pos+=CameraVector * distance;
}

return col;
```

### 点到相机距离

RayMarching 后需要禁用网格深度检测并**自行深度检测**。`SceneDepth < SDF像素深度` 时就需要停止后续渲染（Marching 循环）了。而 SDF 像素深度可以通过点到相机间的距离 **转换到线性深度** 得到：乘上`像素的CameraVector 和 相机方向 的 点积`。

又有 SceneDepth < distance * dotFactor  **=>**  SceneDepth / dotFactor < distance 

所以也可以线性的 Scene Depth 除以 【像素的CameraVector 和 相机方向 的 点积】变大，获得深度缓存里的点到相机的距离，然后进行对比。

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210203054059108.png" alt="image-20210203054059108" style="zoom:67%;" />

### 修正法线

打开默认着色模型后，会发现法线用的是当前像素对应的网格上的法线。所以就需要集合 xyz 分量得到 SDF 的法线，再把法线传到主节点（材质结果节点）里。

```glsl
float3 RMNormal(float3 pos) {
    float2 Off = float2(0.01, 0);

    return normalize(float3(
        RMScene(pos) - RMScene(pos - Off.xyy),
        RMScene(pos) - RMScene(pos - Off.yxy),
        RMScene(pos) - RMScene(pos - Off.yyx)
    ));
}
```

由于这里计算出来的法线是世界空间法线，所以取消`切线空间法线`选项。

![image-20210203083023390](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210203083023390.png)

### 平滑并集

[distance functions](https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm) 的 Primitive combinations 部分中介绍了对图元进行并集以及平滑并集的运算方法，并在 [smooth minimum](https://www.iquilezles.org/www/articles/smin/smin.htm) 里进行了详细介绍。

```glsl
float opSmoothUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return lerp(d2, d1, h) - k * h * (1.0 - h);	// mix => lerp
}
```

### 近似距离

于是用采样点对应的深度buffer上的点来近似，计算出采样点到场景的距离，然后内部 SDF 部分和外部的场景**取平滑并集**。

然而用这个点算出来的距离很不准，距离越远，相机和场景法线角度越大，这个近似的距离误差也就越大。所以就不能利用这个距离来优化迭代的步长，只能进行最朴实无华的固定长度步进。

然后使用普通光照模型，加上各种材质参数。

![image-20210203101354418](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210203101354418.png)

## UE 距离场

在项目设置里搜索 DistanceField，可以打开距离场功能。选中物体，进入编辑窗口，会出现距离场设置。

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210203103417116.png" alt="image-20210203103417116" style="zoom:50%;" />

在编辑器窗口的 `显示>>可视化>>全局距离场` 可以看到距离场。

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210203103417116.png" alt="image-20210203103654959" style="zoom:50%;" />

### 修改 Shader

* 在细节中关闭这个网格的`影响距离场光照`
* 使用 DistanceToNearestSurface 节点 / GetDistanceTo.... 函数 代替原本的近似
* GetDistanceToNearestSurfaceGlobal(pos)之后没效果了的话，将skyLight设置为movable
* 调节参数

### 查找函数

利用 PI 之类的好找的数字定位，在编译完成的代码中找到对应的函数。

![image-20210203105521948](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210203105521948.png)

<img src="https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210203120409514.png" alt="image-20210203120409514" style="zoom:50%;" />