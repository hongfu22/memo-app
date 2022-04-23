#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'cgi'
require 'json'

set :environment, :production

get '/' do
  redirect '/memos'
end

get '/memos' do
  @memos = JSON.parse(File.read('public/memos.json'))['memos']
  erb :memos
end

get '/memos/new' do
  erb :new
end

post '/memos' do
  file_content = JSON.parse(File.read('public/memos.json'))
  new_memo =
    if file_content['memos'].empty?
      {
        'id' => 1,
        'title' => params[:title],
        'content' => params[:content]
      }
    else
      {
        'id' => file_content['memos'].last['id'] + 1,
        'title' => params[:title],
        'content' => params[:content]
      }
    end
  file_content['memos'].push(new_memo)
  File.open('public/memos.json', 'w') { |f| JSON.dump(file_content, f) }
  redirect '/memos'
end

get '/memos/:memo_id' do
  memos = JSON.parse(File.read('public/memos.json'))['memos']
  @target_memo = memos.find { |memo| memo['id'] == params[:memo_id].to_i }
  erb :show
end

get '/memos/:memo_id/edit' do
  memos = JSON.parse(File.read('public/memos.json'))['memos']
  @target_memo = memos.find { |memo| memo['id'] == params[:memo_id].to_i }
  erb :edit
end

patch '/memos/:memo_id' do
  file_content = JSON.parse(File.read('public/memos.json'))
  target_memo_index = file_content['memos'].find_index { |memo| p memo['id'] == params[:memo_id].to_i }
  file_content['memos'][target_memo_index]['title'] = params[:title]
  file_content['memos'][target_memo_index]['content'] = params[:content]
  File.open('public/memos.json', 'w') { |f| JSON.dump(file_content, f) }
  redirect '/memos'
end

delete '/memos/delete' do
  file_content = JSON.parse(File.read('public/memos.json'))
  target_memo_index = file_content['memos'].find_index { |memo| memo['id'] == params[:memo_id].to_i }
  file_content['memos'].delete_at(target_memo_index)
  File.open('public/memos.json', 'w') { |f| JSON.dump(file_content, f) }
  redirect '/memos'
end

not_found do
  erb :unknown
end
