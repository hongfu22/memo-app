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

  def find_target_index(memo_id)
    @memo_content.find_index { |memo| memo['id'] == memo_id.to_i }
  end

  def create_memo(title, content)
    new_memo =
      if @memo_content.empty?
        {
          'id' => 1,
          'title' => title,
          'content' => content
        }
      else
        {
          'id' => @memo_content.last['id'] + 1,
          'title' => title,
          'content' => content
        }
      end
    @memo_content.push(new_memo)
    update_json_file()
  end

  def update_memo(memo_id, title, content)
    target_memo_index = find_target_index(memo_id)
    @memo_content[target_memo_index]['title'] = title
    @memo_content[target_memo_index]['content'] = content
    update_json_file()
  end

  def delete_memo(memo_id)
    target_memo_index = find_target_index(memo_id)
    @memo_content.delete_at(target_memo_index)
    update_json_file()
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
  memo_path.create_memo(params[:title], params[:content])
  redirect '/memos'
end

get '/memos/:memo_id' do
  @target_memo = memo_path.find_same_id(params[:memo_id])
  erb :show
end

get '/memos/:memo_id/edit' do
  @target_memo = memo_path.find_same_id(params[:memo_id])
  erb :edit
end

patch '/memos/:memo_id' do
  memo_path.update_memo(params[:memo_id].to_i, params[:title], params[:content])
  redirect '/memos'
end

delete '/memos/delete' do
  memo_path.delete_memo(params[:memo_id])
  redirect '/memos'
end

not_found do
  erb :unknown
end
