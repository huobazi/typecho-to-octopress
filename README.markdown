### typecho 到 octopress 的转换程序

根据typecho数据直接生成octopress的source文件,拷贝到你的octopress的source/_posts目录就ok了

	1.修改typecho的永久链接方式为默认格式
	2.确保文章内容在class=entry的div中包裹，如果不是请修改当前主题的post.php页面

根据typecho数据生成disqus格式的import文件，去[http://yourname.disqus.com/admin/tools/import/](http://yourname.disqus.com/admin/tools/import/)导入文件就OK了

