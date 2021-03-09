---
# 常用定义
draft: false

title: "Unity 音量全局控制 脚本和UI "
date: 2021-02-25T23:34:28+08:00		# 创建时间
author: "昼阴夜阳"             						# 作者

# 分类和标签
categories: ["技术"]		            				# 分类
tags: ["Unity"]		    					# 标签

---

 [博客 | 使用Audio Mixer分别控制主音量、背景音乐和其他音效](https://blog.csdn.net/iFasWind/article/details/81182579)

详尽的操作步骤可以参考这篇博客。

## 需求分析

当我们做完了游戏的核心玩法，开始完善UI等系统功能，可能会想要来一个如图的设置界面，并且能分别控制音乐和音效。

![image-20210226023657287](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210226023657287.png)

要制作这个功能，需要三步。

* 做两个滑动条的 UI
* 找两个能改变声音的接口
* UI 调用接口

## 制作 UI

Hierarchy 右键 -> UI -> Canvas

Canvas 右键 -> UI -> Slider

拖拖拽拽修修改改就能变成图上那样的两个滑动条了。（左边的两个文本是单独拖上去的）

## 寻找声音接口

 当然，我们可以自己做一套音效控制，用一个类管理所有的 AudioSource 就可以了。但 Unity 其实自带了声音的一套控制。

[文档 | AudioMixer](https://docs.unity3d.com/Manual/AudioMixer.html) 

官方文档的第一句话就介绍完了。

> Unity音频混合器 (AudioMixer) 允许您混合各种 AudioSource，应用各种效果，并执行主控。

这是一个资产，本质上就是一个配置文件。然后在运行的时候引擎就会用这个配置的参数来控制各路声音。**而这个文件可以在运行的时候通过代码读取或者是修改**，所以用起来很方便。

### 设置音源

既然要分别控制不同的声音，首先就要把 **类型相同的声音分清楚**。各种技能特效的声音，游戏背景音乐都分的明明白白。

首先创建一个 AudioMixer 资产：在 Project 窗口 右键 -> Create -> AudioMixer。

然后双击，找到左边下图窗口左边的 Groups 一栏，右键 Master -> Add Child Group，再取个名字比如 `Music` 。这样就创建好了一个分组。同理创建 `Effects` 分组。

![image-20210226035255734](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210226035255734.png)

接下来找到所有想要管理的 AudioSource ，点开属性的 OutPut 然后**设置成对应的分组**。

做到这一步，就已经完成集中处理了！运行游戏然后点开这个 `Edit In Play Mode` 的按钮，滑动这些滑条，音量就会跟着一起变化。

![image-20210226040126616](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210226040126616.png)

不仅如此，选择了一个分组之后，右边的 Inspector 里甚至还有各种各样奇奇怪怪的参数给我们调整。

![image-20210226040700503](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210226040700503.png)

### 程序控制

不过在这时间，还没有找到可以在程序中调用的接口。不过也只是两步之遥。

* 第一步，在想要的接口上右键，把这个参数暴露给脚本。

![image-20210226041014136](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210226041014136.png)

* 第二步，在 AudioMixer 面板的右上角，给这些参数都改个清楚的名字。

![image-20210226041309131](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210226041309131.png)

这样，脚本里就可以通过

```csharp
public AudioMixer myAudioMixer;
// ...
myAudioMixer.SetFloat("BGMVolume", vol);
```

来控制这个 myAudioMixer 了。当然，myAudioMixer 需要被赋上资产引用，赋成刚刚在 Project 里创建的那个。 

## 调用

调用本身很简单，在 Slider 底下手拖一个物体进去，然后选择组件上的 public 函数就可以了。每帧如果值改变了就都会调用。

![image-20210226042534004](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210226042534004.png)

但调节音量的时候，发现自己控制拖拽起来的听感并不线性均匀。考虑到分贝的定义，和我的听感，凑了个映射（虽然没有任何依据）。

[百度百科 | DB（分贝）](https://baike.baidu.com/item/DB/498423)

``` csharp
public void SetBGMVolume(float value)
{
    // 记录一下音量
    // 从而让滑动条在每次打开设置界面的时候都能读取并显示现在的音量
    BGMValue = value;
	// 听着对的一个映射
    float vol = 0 - Mathf.Log(value, 0.5f) * 10;
    // 设置参数
    audioMixer.SetFloat("BGMVolume", vol);
}
```



