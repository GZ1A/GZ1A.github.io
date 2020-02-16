---
# 常用定义
draft: false

title: "【博客升级】Coding 托管"
date: 2020-02-16T23:04:27+09:00					# 创建时间
author: "昼阴夜阳"             		# 作者

# 分类和标签
categories: ["技术"]		            # 分类
tags: ["博客升级","coding"]  						# 标签

# 自定义
comment: false   # 评论
toc: true        # 文章目录
contentCopyright: '<a rel="license noopener" href="https://creativecommons.org/licenses/by-nc-nd/4.0/" target="_blank">CC BY-NC-ND 4.0</a>'	#版权规则
reward: false	 # 打赏
mathjax: true    # 打开 mathjax

# 常用链接
# 网易云 https://music.163.com/#/search/m/?s=%20&type=1

---

辛辛苦苦写的博客当然想让别人看到了，最可行的方法就是被搜索引擎收录。然而 Github 屏蔽了百度爬虫，导致 Github Pages 无法被百度收录，就很难受。除开这个因素，为了更快收录或是更高的权重，还有一些工作可以做。今天就先让博客可以被百度收录吧。

先上前人指路：[想让你的博客被更多的人在搜索引擎中搜到吗？](https://blog.csdn.net/sunshine940326/article/details/70936988)

## 用 Coding 托管博客

> 前面已经提到过一个惨绝人寰的消息，那就是github是不允许百度的爬虫爬取内容的，所以我们的项目如果是托管在github上的话基本是不会被百度收录的

### 创建仓库

打开 [CODING](https://coding.net/) ，注册团队和个人账号。

在团队里创建一个项目，新建一个**代码托管项目**。

![](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/02/20200216231429.png)

这个项目里可以创建**多个代码仓库**，也就是说和 github 上的个人账户是同一级的。填写必要的信息后就初始化好第一个代码仓库了。

![](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/02/20200216233353.png)



### 推送仓库

接下来就需要把本地的文件推送到仓库。首先打开博客仓库的目录，根据链接添加一个新的远程仓库：

![](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/02/20200216234657.png)

```shell
git remote add coding_repo [链接 git@e.coding.net:gz1a/Blog.git]
```

用 `git remote -v` 验证一下是否成功。可以看到两个仓库都被添加上了。

```shell
coding_repo     git@e.coding.net:gz1a/Blog.git (fetch)
coding_repo     git@e.coding.net:gz1a/Blog.git (push)
origin  git@github.com:GZ1A/GZ1A.github.io.git (fetch)
origin  git@github.com:GZ1A/GZ1A.github.io.git (push)
```

然后进行推送。因为是第一次推送会有冲突，添加`-f` 参数强制推送。

```shell
git push coding_repo master -f
```

返回了以下信息，才发现忘记添加公钥了。

```shell
git@e.coding.net: Permission denied (publickey).
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

用过 git 同学应该生成过公钥了吧，没有的建议[百度](https://www.baidu.com/)。我的公钥在 `C:\Users\GZ1A\.ssh` 里，id_rsa.pub 用文本方式打开，复制出来，添加到个人账户里。

![](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/02/20200217000519.png)

再推送一次，就成功了。

### 部署

原来的 Coding Pages [官方文档](https://coding.net/help/doc/coding-service/coding-pages-introduction.html) 还没有更新，就说一下开启流程吧。先在项目设置里手动打开部署功能。

![](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/02/20200217002239.png)

然后新建一个静态网站：

![](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/02/20200217002457.png)

最后手动部署一下，然后点击访问地址就可以看到自己的页面啦。当然，以后推送的时候是会自动部署的。 

![](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/02/20200217002806.png)

## 绑定域名到 Coding 

先上[官方文档](https://coding.net/help/doc/pages/domain.html)。打开这个网页的设置界面，可以看到自定义域名相关的选项。

> 您可为此网站指定自定义域名，用以代替 3ehq79.coding-pages.com作为网站的访问地址。 最多可绑定 5 个自定义域名，绑定前请在域名 DNS 设置中添加 CNAME 记录指向 3ehq79.coding-pages.com

首先打开控制台，"在域名 DNS 设置中添加 CNAME 记录指向 3ehq79.coding-pages.com"。同时停用其他的解析线路，以免安全证书申请失败，像我一样进入[速率限制 CD](https://letsencrypt.org/zh-cn/docs/rate-limits/) ( 每个账户每小时每域名有最多**验证失败** 5 次的限制)  。又因为我闲着没事打开了强制 HTTPS ，现在就没办法访问了... 惨痛教训

原因参见官方 [常见问题](https://coding.net/help/faq/pages/coding-pages-faq.html#Hexo) ：证书错误的第5条。 

![](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2020/02/20200217010104.png)

那么摸了一个小时的鱼 ，证书终于通过了。尝试访问一下，我的博客成功出现！

## 自动化

增加了一个仓库，自然要在我的一键发布脚本里添加下对应代码 `git push coding_repo master`（虽然感觉 github pages 的仓库无意义了）

[原文传送门](https://disorder.ink/post/博客升级一键发布/)。

## 参考

[想让你的博客被更多的人在搜索引擎中搜到吗？](https://blog.csdn.net/sunshine940326/article/details/70936988)

[Github博客同步到Coding,自定义域名双线解析](https://saquarius.com/2019/07/github博客同步到coding自定义域名双线解析/)