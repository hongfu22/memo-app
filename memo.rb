#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'cgi'
require 'json'

set :environment, :production

class Connection
  attr_accessor :memo, :memo_content

  def initialize
    @memo = JSON.parse(File.read('public/memos.json'))
    @memo_content = @memo['memos']
  end

  def update_json_file()
    File.open('public/memos.json', 'w') { |f| JSON.dump(@memo, f) }
  end

  def find_same_id(memo_id)
    @memo_content.find { |memo| memo['id'] == memo_id.to_i }
  end

  def find_target(memo_id)
    @memo_content.find_index { |memo| memo['id'] == memo_id.to_i }
  end

end

memo_path = Connection.new()

get '/' do
  redirect '/memos'
end

get '/memos' do
  @memos = memo_path.memo['memos']
  erb :memos
end

get '/memos/new' do
  erb :new
end

post '/memos' do
  # file_content = JSON.parse(File.read('public/memos.json'))
  new_memo =
    if memo_path.memo_content.empty?
      {
        'id' => 1,
        'title' => params[:title],
        'content' => params[:content]
      }
    else
      {
        'id' => memo_path.memo_content.last['id'] + 1,
        'title' => params[:title],
        'content' => params[:content]
      }
    end
  memo_path.memo_content.push(new_memo)
  memo_path.update_json_file
  # File.open('public/memos.json', 'w') { |f| JSON.dump(file_content, f) }
  redirect '/memos'
end

get '/memos/:memo_id' do
  # memos = JSON.parse(File.read('public/memos.json'))['memos']
  @target_memo = memo_path.find_same_id(params[:memo_id])
  # @target_memo = memos.find { |memo| memo['id'] == params[:memo_id].to_i }
  erb :show
end

get '/memos/:memo_id/edit' do
  # memos = JSON.parse(File.read('public/memos.json'))['memos']
  # @target_memo = memos.find { |memo| memo['id'] == params[:memo_id].to_i }
  @target_memo = memo_path.find_same_id(params[:memo_id])
  erb :edit
end

patch '/memos/:memo_id' do
  # file_content = JSON.parse(File.read('public/memos.json'))
  # target_memo_index = file_content['memos'].find_index { |memo| p memo['id'] == params[:memo_id].to_i }
  # file_content['memos'][target_memo_index]['title'] = params[:title]
  # file_content['memos'][target_memo_index]['content'] = params[:content]
  target_memo_index = memo_path.find_target(params[:memo_id])
  memo_path.memo_content[target_memo_index]['title'] = params[:title]
  memo_path.memo_content[target_memo_index]['content'] = params[:content]
  memo_path.update_json_file
  redirect '/memos'
end

delete '/memos/delete' do
  # file_content = JSON.parse(File.read('public/memos.json'))
  # target_memo_index = file_content['memos'].find_index { |memo| memo['id'] == params[:memo_id].to_i }
  # file_content['memos'].delete_at(target_memo_index)
  # File.open('public/memos.json', 'w') { |f| JSON.dump(file_content, f) }
  target_memo_index = memo_path.find_target(params[:memo_id])
  memo_path.memo_content.delete_at(target_memo_index)
  memo_path.update_json_file
  redirect '/memos'
end

not_found do
  erb :unknown
end
