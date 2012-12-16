# coding: utf-8
require "rubygems"
require 'builder'
require "sequel"
require "fileutils"
require "iconv"

converter = Iconv.new 'UTF-8//IGNORE', 'UTF-8'


db_host = '127.0.0.1'
db_name = 'techblog'
db_user = 'root'
db_password = ''
db_table_prefix = 'typecho'

FileUtils.mkdir_p '_comments'
db = Sequel.mysql(db_name, :user => db_user,  :password => db_password, :host => db_host, :encoding => 'utf8')

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

comments_query = <<-EOS
SELECT * FROM #{db_table_prefix}_comments 
WHERE type ='comment' and  cid = %d
EOS

output = ''
xml = Builder::XmlMarkup.new(:target => output, :indent => 2)
xml.instruct!(:xml, :encoding => "UTF-8")
xml.rss(
  :version => '2.0', 
  'xmlns:dsq' => "http://www.disqus.com/",
  'xmlns:content' => "http://purl.org/rss/1.0/modules/content/",
	'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
	'xmlns:wp' => "http://wordpress.org/export/1.0/"
) do
  xml.channel do
    xml.title "dawncold\'s tech blog"
    xml.link 'http://www.youth2009.org'
    xml.description "dawncold\'s tech blog"
    xml.pubDate( Time.now.strftime("%a, %d %b %Y %H:%M:%S %z") )
    xml.generator 'Builder::XmlMarkup'
    xml.language 'zh-cn'
    xml.tag!('wp:wxr_version', '1.0' ) 
    xml.wp(:wxr_version, '1.0' ) 
    xml.wp(:base_site_url, 'http://www.youth2009.org' ) 
    xml.wp(:base_blog_url, 'http://www.youth2009.org')
    
    db[posts_query].each do |post|
    	date = Time.at post[:created]
    	post_title = post[:title]

    	post_id = post[:cid]
    	post_slug = post[:slug].downcase
    	post_url = 'http://http://www.youth2009.org/' + "%02d/%02d/%02d/%s/" % [date.year, date.month, date.day, post_slug]

      xml.item do 
        xml.link post_url
        xml.title post_title
        xml.pubDate( date.strftime("%a, %d %b %Y %H:%M:%S %z") )
        xml.dc(:creator) { xml.cdata!('dawncold') }
        xml.guid( post_url, :isPermalink => 'true' )
        xml.wp_id post_id.to_s
        xml.wp(:id, post_id.to_s)
        xml.wp(:post_id, post_id.to_s)
    	  xml.wp(:post_date_gmt, date.strftime("%Y-%d-%m %H:%M:%S") )
        xml.wp(:comment_status, 'open')
        xml.wp(:ping_status, 'open')
        xml.wp(:status, 'published')
        xml.wp(:post_parent, '0')
        xml.wp(:post_type, 'post')
        xml.dsq(:thread_identifier, post_url)
        xml.content(:encoded) do
              xml.cdata!('') 
        end
        db[comments_query % post_id].each do |comment|
          xml.wp(:comment) do
            email = comment[:mail]
            if(email == 'mail@localhost.com')
              email = 'mail_' + comment[:coid].to_s + '@localhost.com'
            end
            xml.wp(:comment_id, comment[:coid])
            xml.wp(:comment_author) { xml.cdata!(converter.iconv comment[:author]) }
            xml.wp(:comment_author_email, email)
            xml.wp(:comment_author_url, comment[:url])
            xml.wp(:comment_author_IP, comment[:ip])
            xml.wp(:comment_date_gmt, Time.at(comment[:created]).strftime("%Y-%d-%m %H:%M:%S") )
            xml.wp(:comment_content) do
              comment_body = converter.iconv comment[:text]
              comment_body = comment_body.gsub('�','')
              xml.cdata!( comment_body ) 
            end
            approved = comment[:status] == 'approved' ? 1 : 0
            xml.wp(:comment_approved, approved.to_s)
            xml.wp(:comment_type)
            xml.wp(:comment_parent, '0')
            xml.wp(:comment_user_id, '0')
          end
        end
      end
    end
  end
end

date_time_text = Time.now.strftime("%Y-%d-%m-%H-%M-%S")
File.open("_comments/comments" + date_time_text + ".xml", "w") do |f|
f.puts output
end
