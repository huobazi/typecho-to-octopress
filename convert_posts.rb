# coding: utf-8
require "rubygems"
require "sequel"
require "fileutils"
require "yaml"
require 'nokogiri'
require 'net/http'
require 'open-uri'


db_host = '127.0.0.1'
db_name = 'techblog'
db_user = 'root'
db_password = ''
db_table_prefix = 'typecho'

online_blog_prefix = 'http://www.youth2009.org/archives/'

%w(_posts _drafts).each{|folder| FileUtils.mkdir_p folder}

db = Sequel.mysql(db_name, :user => db_user,  :password => db_password, :host => db_host,:encoding => 'utf8')

posts_query = <<-EOS
			SELECT
				cid
				,title
				,slug
				,created
				,modified
				,text
				,status
			 FROM #{db_table_prefix}_contents
			 WHERE
			 	type='post'
 EOS

 metas_query = <<-EOS
		select 
			m.name,m.slug,m.type,m.description
		from
			#{db_table_prefix}_relationships  r
		inner join
			#{db_table_prefix}_metas m
		on r.mid=m.mid
		where r.cid = %d
EOS


def get_online_post_body(url)
  doc = Nokogiri::HTML(open(url))
  text = doc.xpath("//div[@class='entry']").inner_html  
  text = text.gsub('<BR>','<br>').gsub('<br>','<br />').gsub(/\t\t\t\t\t/,'')
end

db[posts_query].each do |post|
      title = post[:title]
      slug = post[:slug].downcase
      date = Time.at post[:created]
      body = get_online_post_body online_blog_prefix + post[:cid].to_s
      status = post[:status]
      name = "%02d-%02d-%02d-%s.markdown" % [date.year, date.month, date.day, slug]
      tags = []
      
      db[metas_query % post[:cid]].each do |c|
       	if(c[:type] == 'tag')
       		tags<< c[:name].force_encoding("UTF-8")
       	elsif(c[:type] == 'category')
       		tags << c[:description].force_encoding("UTF-8")
       	end
      end

      summary = {
         'layout' => 'post',
         'title' => title.to_s.force_encoding("UTF-8"),
         'comments' => true,
         'date' => date.strftime("%Y-%m-%d %H:%M"),
         'categories' => tags
       }.delete_if { |k,v| v.nil? || v == ''}.to_yaml
       
      File.open( (status == 'publish' ? '_posts' : '_drafts') + "/#{name}", "w") do |f|
        f.puts summary
        puts summary
        f.puts "---"
        f.puts body
      end

      puts title + '...ok'
end
puts ''
puts '～～～～都搬完拉～～～～.'
puts ''
