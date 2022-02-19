#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'active_record'
require 'digest/sha2'
require 'cgi'

set :environment, :production

set :sessions,
    expire_after: 7200,
    secret: 'abcdefghij0123456789'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

# ユーザーテーブル
class Users < ActiveRecord::Base
  self.table_name = 'users'
end

# メモテーブル
class Memos < ActiveRecord::Base
  self.table_name = 'memos'
end

# ID管理用テーブル
class Counts < ActiveRecord::Base
  self.table_name = 'counts'
end

get '/' do
  redirect '/login'
end

get '/login' do
  session[:message]
  erb :login
end

get '/register' do
  erb :register
end

post '/register' do
  # サニタイズ処理
  username = CGI.escapeHTML(params[:username])
  pass = CGI.escapeHTML(params[:pass])
  salt = [rand(64), rand(64)].pack('C*').tr("\x00-\x3f", 'A-Za-z0-9./')

  new_user = Users.new
  new_user.id = username
  new_user.hashed = Digest::SHA256.hexdigest(pass + salt)
  new_user.salt = salt
  new_user.save

  session[:message] = 'ユーザーが作成されました。'
  redirect '/login'
end

post '/auth' do
  username = CGI.escapeHTML(params[:username])
  pass = CGI.escapeHTML(params[:pass])

  if check_login(username, pass)
    session[:username] = username
    redirect '/memos/1'
  end

  session.clear
  session[:message] = 'IDまたはパスワードが違います。'
  redirect '/login'
end

get '/memos/:page' do
  @user = session[:username]
  if @user.nil?
    session[:message] = 'ログインしてください。'
    redirect '/login'
  end

  transition_page = params[:page].to_i
  session[:page] = transition_page
  @display_number = 5
  # DBのデータを取得する位置のインデックス
  @start_point = (transition_page - 1) * @display_number
  # 全項目の最後の位置（Nextのページング機能をOFFにするための仕掛け）
  @end_point = Memos.where(user_id: @user).count

  @memos = Memos.where(user_id: @user).order(id: :desc).limit(5).offset(@start_point)

  erb :memos
end

get '/users/:user_id/memos/new' do
  redirect '/badrequest' if params[:user_id] != session[:username]
  erb :new
end

post '/users/:user_id/memos/new' do
  redirect '/badrequest' if params[:user_id] != session[:username]
  # メモ全体のIDの中で一番大きいものに1加えたものをIDとする
  max_id = Counts.find_by_id(99)
  new_max_id = max_id.counts + 1
  max_id.counts = new_max_id
  max_id.save

  new_memo = Memos.new
  new_memo.id = new_max_id
  new_memo.user_id = session[:username]
  new_memo.title = CGI.escapeHTML(params[:title])
  new_memo.content = CGI.escapeHTML(params[:content])
  new_memo.save

  redirect '/memos/1'
end

get '/users/:user_id/memos/:memo_id' do
  redirect '/badrequest' if params[:user_id] != session[:username]
  @memo = Memos.find_by_id(CGI.escapeHTML(params[:memo_id]))
  erb :edit
end

patch '/users/:user_id/memos/:memo_id' do
  redirect '/badrequest' if params[:user_id] != session[:username]
  @memo = Memos.find_by_id(params[:memo_id])
  @memo.title = CGI.escapeHTML(params[:title])
  @memo.content = CGI.escapeHTML(params[:content])
  @memo.save
  redirect '/memos/1'
end

delete '/users/:user_id/memos/delete' do
  redirect '/badrequest' if params[:user_id] != session[:username]
  delete_memo = Memos.find(params[:id])
  delete_memo.destroy
  redirect '/memos/1'
# 既に消えているメモに再度デリート処理がされた時のため
rescue ActiveRecord::RecordNotFound => e
  p e
  redirect '/memos/1'
end

get '/logout' do
  session.clear
  erb :logout
end

get '/badrequest' do
  erb :badrequest
end

def check_login(username, pass)
  searched_user = Users.find(username)
  user_salt = searched_user.salt
  user_hashed = searched_user.hashed
  matched_hash = Digest::SHA256.hexdigest(pass + user_salt)
  true if matched_hash == user_hashed
rescue ActiveRecord::RecordNotFound => e
  p e
  false
end

not_found do
  erb :unknown
end
