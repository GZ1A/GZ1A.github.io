---
# 常用定义
draft: true	                		# 是否是草稿？

title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}					# 创建时间
author: "昼阴夜阳"             		# 作者

# 分类和标签
categories: [""]		            # 分类
tags: [""]  						# 标签，可设置多个，用逗号隔开。Hugo会自动生成标签的子URL

# 用户自定义
comment: false   # 关闭评论
toc: false       # 关闭文章目录
contentCopyright: '<a rel="license noopener" href="https://creativecommons.org/licenses/by-nc-nd/4.0/" target="_blank">CC BY-NC-ND 4.0</a>'	#自定义文章的版权规则
reward: false	 # 关闭打赏
mathjax: true    # 打开 mathjax​
---
