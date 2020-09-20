require './config/environment'
require 'sinatra/base'
require 'rack-flash'


class ApplicationController < Sinatra::Base
  enable :sessions
  use Rack::Flash
  configure do
    set :session_secret, "secret"
    set :public_folder, 'public'
    set :views, 'app/views'
  end

  get '/' do
    erb :index
  end

  get '/signup' do
    if Helpers.is_logged_in?(session)
      redirect to '/tweets'
    end

    erb :"/users/create_user"
  end

  post '/signup' do
    params.each do |label, input|
      if input.empty?
        flash[:new_user_error] = "Please enter a value for #{label}"
        redirect to '/signup'
      end
    end

    user = User.create(:username => params["username"], :email => params["email"], :password => params["password"])
    session[:user_id] = user.id

    redirect to '/ideas'
  end

  get '/login' do
    if Helpers.is_logged_in?(session)
      redirect to '/ideas'
    end

    erb :"/users/login"
  end

  post '/login' do
    user = User.find_by(:username => params["username"])

    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect to '/ideas'
    else
      flash[:login_error] = "Incorrect login. Please try again."
      redirect to '/login'
    end
  end

  get '/ideas' do
    if !Helpers.is_logged_in?(session)
      redirect to '/login'
    end
    @ideas = Tweet.all
    @user = Helpers.current_user(session)
    erb :"/ideas/ideas"
  end

  get '/ideas/new' do
    if !Helpers.is_logged_in?(session)
      redirect to '/login'
    end
    erb :"/ideas/create_tweet"
  end

  post '/ideas' do
    user = Helpers.current_user(session)
    if params["content"].empty?
      flash[:empty_tweet] = "Please enter content for your tweet"
      redirect to '/ideas/new'
    end
    tweet = Tweet.create(:content => params["content"], :user_id => user.id)

    redirect to '/ideas'
  end

  get '/ideas/:id' do
    if !Helpers.is_logged_in?(session)
      redirect to '/login'
    end
    @tweet = Tweet.find(params[:id])
    erb :"ideas/show_tweet"
  end

  get '/ideas/:id/edit' do
    if !Helpers.is_logged_in?(session)
      redirect to '/login'
    end
    @tweet = Tweet.find(params[:id])
    if Helpers.current_user(session).id != @tweet.user_id
      flash[:wrong_user_edit] = "Sorry you can only edit your own tweets"
      redirect to '/ideas'
    end
    erb :"ideas/edit_tweet"
  end

  patch '/ideas/:id' do
    tweet = Tweet.find(params[:id])
    if params["content"].empty?
      flash[:empty_tweet] = "Please enter content for your tweet"
      redirect to "/ideas/#{params[:id]}/edit"
    end
    tweet.update(:content => params["content"])
    tweet.save

    redirect to "/ideas/#{tweet.id}"
  end

  post '/ideas/:id/delete' do
    if !Helpers.is_logged_in?(session)
      redirect to '/login'
    end
    @tweet = Tweet.find(params[:id])
    if Helpers.current_user(session).id != @tweet.user_id
      flash[:wrong_user] = "Sorry you can only delete your own ideas"
      redirect to '/ideas'
    end
    @tweet.delete
    redirect to '/ideas'
  end

  get '/users/:slug' do
    slug = params[:slug]
    @user = User.find_by_slug(slug)
    erb :"users/show"
  end

  get '/logout' do
    if Helpers.is_logged_in?(session)
      session.clear
      redirect to '/login'
    else
      redirect to '/'
    end
  end

end