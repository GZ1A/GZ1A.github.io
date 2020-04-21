---
# 常用定义
draft: false  
 
title: "【博客升级】Valine 评论系统"
date: 2020-02-17T02:56:17+09:00		# 创建时间
author: "昼阴夜阳"             		# 作者

# 分类和标签
categories: ["技术"]		            # 分类
tags: ["博客升级","Valine"]  			# 标签

# 自定义
comment: true	 # 评论
toc: true        # 文章目录
contentCopyright: '<a rel="license noopener" href="https://creativecommons.org/licenses/by-nc-nd/4.0/" target="_blank">CC BY-NC-ND 4.0</a>'	#版权规则
reward: true	 # 打赏
mathjax: true    # 打开 mathjax

# 常用链接
# 网易云 https://music.163.com/#/search/m/?s=%20&type=1
---

托管到 `Coding` 之后，这个站点已经可以被百度收录了。虽然感觉不会有什么人看，但是万一呢 : ) 为了更好的交流，此处应有一个评论系统。恰好我用的主题`Jane`已经配置好了几种评论系统，只需要启用一下就可以了。

先上一个 [Valine 官方文档](https://valine.js.org/) ，可以参考。还有这篇 [hugo博客添加评论系统Valine](https://www.smslit.top/2018/07/08/hugo-valine/) 。

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=41651113&auto=0&height=66">
</iframe>

## 注册和创建应用

跟随[快速开始](https://valine.js.org/quickstart.html)。

## 配置 HTML

本来讲道理是要手动修改 HTML 插入`Valine` 组件的，但是由于主题已经配置好了，我就打开来看看吧。这个组件配置在主题中评论相关的布局文件`\themes\jane\layouts\partials\comments.html`里，具体的代码如下：

```html
  <!-- valine -->
  {{- if .Site.Params.valine.enable -}}
  <div id="comments"></div>
  <script src="//cdn1.lncld.net/static/js/3.0.4/av-min.js"></script>
  <script src='//unpkg.com/valine/dist/Valine.min.js'></script>
  <script>
    if(window.location.hash){
        var checkExist = setInterval(function() {
            if ($(window.location.hash).length) {
              $('html, body').animate({scrollTop: $(window.location.hash).offset().top-90}, 700);
              clearInterval(checkExist);
            }
        }, 10);
    }
  </script>
  <script type="text/javascript">
    new Valine({
        el: '#comments' ,
        appId: '{{ .Site.Params.valine.appId }}',
        appKey: '{{ .Site.Params.valine.appKey }}',
        notify: {{ .Site.Params.valine.notify }}, 
        verify: {{ .Site.Params.valine.verify }}, 
        avatar:'{{ .Site.Params.valine.avatar }}', 
        placeholder: '{{ .Site.Params.valine.placeholder }}',
        visitor: {{ false }}
    });
  </script>
  {{- end }}

```

## 配置  Config

因为从当前主题的文档处配置过这个网站的`Config` ，现在只要打开工程下的 `Config.toml` 文件并修改一下参数项就好了。具体含义可以看[配置项解释](https://valine.js.org/configuration.html)。

```toml
  # Valine.
  # You can get your appid and appkey from https://leancloud.cn
  # more info please open https://valine.js.org
  [params.valine]
    enable = false
    appId = ''
    appKey = ''
    notify = false
    verify = false
    avatar = 'mm'
    placeholder = ''
```

配置完成后如下：

```toml
[params.valine]
    enable = true
    appId = 'L***z'
    appKey = 'w***o'
    notify = false	# If you are using valine-admin(https://github.com/DesertsP/Valine-Admin) to notify users, do NOT enable this.
    verify = false
    avatar = 'retro'
    placeholder = '随便说点什么吧~（填写邮箱可以收到回复提醒哦）'
```

## 完善评论

添加 [Valine Admin](https://github.com/zhaojun1998/Valine-Admin)，跟随快速开始一路走到底。

要注意**添加环境变量**的时候`SMTP_PASS`会根据不同的服务商变化。我用的是`Outlook`，和邮箱的登录密码是一样的，但是要把以下的选项打开。

![](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/02/20200217231340.png)

然后还要解决 [LeanCloud 休眠策略](https://github.com/zhaojun1998/Valine-Admin/blob/master/%E9%AB%98%E7%BA%A7%E9%85%8D%E7%BD%AE.md#leancloud-%E4%BC%91%E7%9C%A0%E7%AD%96%E7%95%A5)的问题 ，只要按照 [LeanCloud 自带定时器](https://github.com/zhaojun1998/Valine-Admin/blob/master/%E9%AB%98%E7%BA%A7%E9%85%8D%E7%BD%AE.md#leancloud-%E8%87%AA%E5%B8%A6%E5%AE%9A%E6%97%B6%E5%99%A8%E6%8E%A8%E8%8D%90)的教程去做就可以了。

> 如果像我一样在博客中添加了valine的评论系统，需要在Leancloud的安全中心中的Web安全域名中加入Coding Pages的访问地址。——@[saquarius](https://saquarius.com/2019/07/github%E5%8D%9A%E5%AE%A2%E5%90%8C%E6%AD%A5%E5%88%B0coding%E8%87%AA%E5%AE%9A%E4%B9%89%E5%9F%9F%E5%90%8D%E5%8F%8C%E7%BA%BF%E8%A7%A3%E6%9E%90/#git%E4%B8%AD%E6%B7%BB%E5%8A%A0%E7%AC%AC%E4%BA%8C%E4%B8%AA%E8%BF%9C%E7%A8%8B%E4%BB%93%E5%BA%93)

当然不加入也可以，就是所有的域名都可以访问，会有风险。

> 我尝试了好多次都没有成功，仔细检查发现是配置**云引擎**的时候忘记填 **Master** **分支**了...大意失邮件

## 留言测试

在**文章头部**的`front matter`的参数项（如果你的模板里有的话）里把评论系统打开。

```yaml
# 自定义
comment: true	# 评论
```

在本地启动`hugo server`进行调试。如果配置的没什么问题的话就可以看到评论的界面了。

![](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/02/20200217221436.png)

这个评论系统支持 Markdown 语法（虽然好像有点不一样），可以点击左下角的图标获取参考，也可以打开右下角的预览实时查看。输入测试用评论并回复。

```markdown
# *评论* 试试 🐱 
试试 [**链接**](https://disorder.ink/post/博客升级评论/)
```

![](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/02/20200217221347.png)

可以看到已经成功评论了。同时又用另一个邮箱回复了评论，不到 5 秒就在邮箱里收到了提醒邮件，有点快。

![](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/02/20200218023304.png)

## 留言管理

 Valine 没有后端，要管理的话直接打开 LeanCloud [控制台](https://leancloud.cn/dashboard/applist.html#/apps)，选择对应的应用并打开数据库。接下来自然是随你增删查改。第一篇参考博客里提到 Valine Admin 有后台管理系统，然而并没有在现在的文档里找到，博客里写的也不太细，就放弃了。反正体量小，这样不也挺好吗？

![](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/02/20200217222853.png)

## 效果

在下面**留言**就可以看到了哦~

