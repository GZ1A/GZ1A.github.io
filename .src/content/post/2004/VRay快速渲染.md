---
# 常用定义
draft: false

title: "记 V-Ray 快速渲染"
date: 2020-04-20T23:46:09+09:00			# 创建时间
author: "昼阴夜阳"        	     		# 作者

# 分类和标签
categories: ["技术"]		            # 分类
tags: ["3dMax","VRay"]  		# 标签

# 自定义
comment: true	 # 评论
toc: true        # 文章目录
contentCopyright: '<a rel="license noopener" href="https://creativecommons.org/licenses/by-nc-nd/4.0/" target="_blank">CC BY-NC-ND 4.0</a>'	# 版权规则
reward: true	 # 打赏
mathjax: true    # 打开 mathjax
---

《关于以为延期的动画作业其实要按时展示这件事》。本来还想好好建个什么东西，为了赶时间只能找个最快的整个相机游走。老方块人当场想到 MC，遂 B 站搜之。确实找到了教程[^1]。

![image-20200420225632500](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/04/image-20200420225632500.png)

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=4010207&auto=0&height=66"></iframe>

## 建模

### 方块

画一个边长 10 cm 的立方体。然后{{% mask "从 MC 1.12 中" %}}获取纹理并按面制作材质。

### 箱子

找了一个箱子材质。建个大概差不多的模型，然后直接把箱子的 UV 展开[^2]，手动强行拉伸对应到贴图上。

### 场景

然后就是对齐拖拖拽拽的事情。其中由于树叶方向一致的效果很差，使用 MaxScript 进行随机旋转[^3]。{{% mask "然而手动随机旋转了一遍才想到去找点例程...不知道在急什么" %}}

```c
for leaf in $ do
(
    dir = #(0,90,180,270)
    dx = dir[random 1 4]
    dy = dir[random 1 4]
    dz = dir[random 1 4]
    rotate leaf (eulerangles dx dy dz)
)
```

## 动画

调调相机位置，展示一下场景。

## 渲染

V-Ray 好看是好看，就是建模五分钟，调参两小时。{{% mask "然后渲染一年" %}}

虽然有 Demo 参考，也能大概看懂参数，但刚接触 V-Ray 面对那么多的参数还是会不知所措。就暂时先把最后看得过去同时效率还行的渲染选项记录下来，不求甚解的用着好了。

### 光源

指 VraySun。创建时可以自动生成对应的环境贴图并添加到场景，属性由 VraySun 决定。

![image-20200421054720280](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/04/image-20200421054720280.png)

### 渲染器

![image-20200421053624675](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/04/image-20200421053624675.png)

![image-20200421054112326](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/04/image-20200421054112326.png)

![image-20200421054259811](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/04/image-20200421054259811.png)

![image-20200421054408370](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/04/image-20200421054408370.png)

## PS

找图偶然找到了以前的游戏截图。泪，流了下来。

{{% mask "是离线都打不过实时光影的不学无术的泪水" %}}

![image-20200421105815210](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/04/image-20200421105815210.png)

![image-20200421105936013](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/04/image-20200421105936013.png) 


[^1]: 原教程 [视频链接](https://www.bilibili.com/video/BV1Mx411n7W1)
[^2]: 方法见 [参考链接](https://jingyan.baidu.com/article/c33e3f48e89d06ea14cbb56e.html)
[^3]: 感谢大胖老师 [参考链接](https://www.sohu.com/a/197982218_359909)