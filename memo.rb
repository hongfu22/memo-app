#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'cgi'
require 'pg'

set :environment, :production

set :sessions,
    expire_after: 7200,
    secret: 'abcdefghij0123456789'

# class for connecting memo_apps DB
class Memo
  attr_accessor :memo, :memo_content

  def initialize
    @conn = PG.connect(dbname: 'memo_apps')
  end

  def find_same_id(memo_id)
    target_memo = @conn.exec('SELECT * FROM memos WHERE id = $1;', [memo_id])
    target_memo[0]
  end

  def fetch_memos(start_point)
    @conn.exec('SELECT * FROM memos ORDER BY id DESC LIMIT 5 OFFSET $1;', [start_point])
  end

  def fetch_count
    @conn.exec('SELECT COUNT(*) FROM memos;')[0]['count'].to_i
  end

  def create_memo(title, content)
    current_counts = @conn.exec('SELECT * FROM counts;')
    max_id = current_counts[0]['counts'].to_i
    new_max_id = max_id + 1
    @conn.exec('UPDATE counts SET counts = $1 WHERE id = $2', [new_max_id, 99])
    @conn.exec('INSERT INTO memos VALUES ($1, $2, $3)', [new_max_id, title, content])
  end

  def update_memo(memo_id, title, content)
    @conn.exec('UPDATE memos SET (title, content) = ($1, $2) WHERE id = $3', [title, content, memo_id])
  end

  def delete_memo(memo_id)
    @conn.exec('DELETE FROM memos WHERE id = $1', [memo_id])
  end
end

memo_connection = Memo.new

get '/' do
  redirect '/memos/1/list'
end

get '/memos/:page/list' do
  transition_page = params[:page].to_i
  session[:page] = transition_page
  @display_number = 5
  @start_point = (transition_page - 1) * @display_number
  @end_point = memo_connection.fetch_count
  @memos = memo_connection.fetch_memos(@start_point)
  erb :memos
end

get '/memos/new' do
  erb :new
end

post '/memos' do
  memo_connection.create_memo(params[:title], params[:content])
  redirect '/memos/1/list'
end

get '/memos/:memo_id/show' do
  @target_memo = memo_connection.find_same_id(params[:memo_id])
  erb :show
end

get '/memos/:memo_id/edit' do
  @target_memo = memo_connection.find_same_id(params[:memo_id])
  erb :edit
end

patch '/memos/:memo_id' do
  memo_connection.update_memo(params[:memo_id].to_i, params[:title], params[:content])
  redirect '/memos/1/list'
end

delete '/memos/delete' do
  memo_connection.delete_memo(params[:memo_id])
  redirect '/memos/1/list'
end

not_found do
  erb :unknown
end
