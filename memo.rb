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
  memo_file = File.read('public/memos.json')
  file_content = JSON.parse(memo_file)
  @memos = file_content['memos']
  erb :memos
end

get '/memos/new' do
  erb :new
end

post '/memos/new' do
  memo_file = File.read('public/memos.json')
  file_content = JSON.parse(memo_file)
  new_memo =
    if file_content['memos'].empty?
      {
        'id' => 1,
        'title' => CGI.escapeHTML(params[:title]),
        'content' => CGI.escapeHTML(params[:content])
      }
    else
      {
        'id' => file_content['memos'].last['id'] + 1,
        'title' => CGI.escapeHTML(params[:title]),
        'content' => CGI.escapeHTML(params[:content])
      }
    end
  file_content['memos'].push(new_memo)
  File.open('public/memos.json', 'w') { |f| JSON.dump(file_content, f) }
  redirect '/memos'
end

get '/memos/:memo_id' do
  memo_file = File.read('public/memos.json')
  file_content = JSON.parse(memo_file)
  memos = file_content['memos']
  selected_memo =
    memos.select do |memo|
      memo['id'] == params[:memo_id].to_i
    end
  @target_memo = selected_memo[0]
  erb :show
end

get '/memos/:memo_id/edit' do
  memo_file = File.read('public/memos.json')
  file_content = JSON.parse(memo_file)
  memos = file_content['memos']
  selected_memo =
    memos.select do |memo|
      memo['id'] == params[:memo_id].to_i
    end
  @target_memo = selected_memo[0]
  erb :edit
end

patch '/memos/:memo_id/edit' do
  memo_file = File.read('public/memos.json')
  file_content = JSON.parse(memo_file)
  memos = file_content['memos']
  target_memo_index =
    memos.each_index.select do |index|
      memos[index]['id'] == params[:memo_id].to_i
    end
  file_content['memos'][*target_memo_index]['title'] = CGI.escapeHTML(params[:title])
  file_content['memos'][*target_memo_index]['content'] = CGI.escapeHTML(params[:content])
  File.open('public/memos.json', 'w') { |f| JSON.dump(file_content, f) }
  redirect '/memos'
end

delete '/memos/delete' do
  memo_file = File.read('public/memos.json')
  file_content = JSON.parse(memo_file)
  memos = file_content['memos']
  target_memo_index =
    memos.each_index.select do |index|
      memos[index]['id'] == params[:memo_id].to_i
    end
  file_content['memos'].delete_at(*target_memo_index)
  File.open('public/memos.json', 'w') { |f| JSON.dump(file_content, f) }
  redirect '/memos'
end

not_found do
  erb :unknown
end
