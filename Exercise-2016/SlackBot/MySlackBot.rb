# coding: utf-8
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'sinatra'
require 'SlackBot'
require 'cgi'
require 'open-uri-post'
require 'rexml/document'
require 'json'



class MySlackBot < SlackBot
  
  CLIENT_ID       = 'kanzawa'
  CLIENT_SECRET   = 'yYAzwfdIsWPJBAGaQSEQjzTL/RUZm7Bu+wM33fj9flU='
  AUTHORIZE_URL   = 'https://datamarket.accesscontrol.windows.net/v2/OAuth2-13'
  TRANSLATION_URL = 'http://api.microsofttranslator.com/V2/Http.svc/Translate'
  SCOPE           = 'http://api.microsofttranslator.com'
  

  def get_access_token
    access_token = nil
    open(AUTHORIZE_URL,
         'postdata' => "grant_type=client_credentials&client_id=#{CGI.escape(CLIENT_ID)}&client_secret=#{CGI.escape(CLIENT_SECRET)}&scope=#{CGI.escape(SCOPE)}") do |f| 
      json           = JSON.parse(f.read)
      access_token   = json['access_token']
    end
    return access_token
  end
  
  
  def say_xxx(params, options = {})
    return nil if params[:user_name] == "slackbot" || params[:user_id] == "USLACKBOT"
    user_name = params[:user_name] ? "@#{params[:user_name]}" : ""
    text = params[:text] ? params[:text].match(/「(.*)」[\s　]*と言って/) : ""
    return {text: "#{user_name} #{text[1]}"}.merge(options).to_json
  end

  def translate(params, options = {})
    return nil if params[:user_name] == "slackbot" || params[:user_id] == "USLACKBOT"
    user_name = params[:user_name] ? "@#{params[:user_name]}" : ""
    access_token = get_access_token
    if text = params[:text].match(/翻訳[\s　]+([^→]+?)→([^→]+?)[\s　]+"(.+)"/) then
      text = text.to_a
      1.upto(text.length-2) do |n|
        case text[n]
        when "英" then
          text[n] = "en"
        when "日" then
          text[n] = "ja"
        when "仏" then
          text[n] = "fr"
        when "西" then
          text[n] = "es"
        when "露" then
          text[n] = "ru"
        when "アラビア" then
          text[n] = "ar"
        else
          return{text: "#{user_name} 対応している言語は以下の言語です．\n日本語：日\n英語：英\nフランス語：仏\nスペイン語：西\nロシア語：露\nアラビア語：アラビア"}.merge(options).to_json
        end
      end
      
      res = open("#{TRANSLATION_URL}?from=#{text[1]}&to=#{text[2]}&text=#{URI.escape(text[-1])}",
                 'Authorization' => "Bearer #{access_token}").read
      xml = REXML::Document.new(res)
      return {text: "#{user_name} \"#{xml.root.text}\""}.merge(options).to_json
    else return{text: "#{user_name} 翻訳のフォーマットは以下のとおりです．\n翻訳 翻訳前の言語→翻訳後の言語 \"文字列\""}.merge(options).to_json
    end
    
  end
  
end


slackbot = MySlackBot.new

set :environment, :production

get '/' do
  "SlackBot Server!!"
end

post '/slack' do
  content_type :json
  if params[:text].match(/「(.*)」[\s　]*と言って/) then
    slackbot.say_xxx(params, username: "Bot")
  elsif params[:text].match(/翻訳/) then
    slackbot.translate(params, username: "Bot")
  else slackbot.naive_respond(params, username: "Bot")
    
  end
  
end

