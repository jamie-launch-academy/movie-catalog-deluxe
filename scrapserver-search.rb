require 'sinatra'
require 'pry'
require 'pg'

##############################
####### DB CONNECTION ########
##############################

def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end

##############################
####### ACTOR METHODS ########
##############################

def get_actors
  sql = 'SELECT name, id FROM actors
  ORDER BY name'

  @actors = db_connection do |db|
    db.exec(sql)
  end
  @actors.to_a
end

def find_actor_by_id(id)
  sql = ('SELECT m.title, a.name, cm.character, m.id FROM movies m
  JOIN cast_members cm ON cm.movie_id = m.id
  JOIN actors a ON cm.actor_id = a.id
  WHERE a.id = ($1)
  ORDER BY a.name')

  @actors_id = db_connection do |db|
    db.exec_params(sql, [id])

  end
  @actors_id.to_a
end

##############################
####### MOVIE METHODS ########
##############################

def search_movies
  sql = "SELECT title, id
  FROM movies
  ORDER BY title"

  movies = db_connection do |db|
    db.exec(sql)
  end
  movies.to_a
end

def get_movies(page_num)
  if page_num.to_i < 1
    offset = 0
  else
    offset = page_num.to_i * 20 - 20
  end
  sql = "SELECT title, id
  FROM movies
  ORDER BY title
  LIMIT 20
  OFFSET $1"
  movies = db_connection do |db|
    db.exec_params(sql, [offset])
  end
  movies.to_a
end

def find_movie_by_id(id)
  sql = ('SELECT movies.title, movies.year, movies.rating,
  genres.name AS genre_name, studios.name, actors.name AS actor_name,
  actors.id AS actor_id FROM movies
  JOIN genres ON movies.genre_id = genres.id
  LEFT JOIN studios ON movies.studio_id = studios.id
  JOIN cast_members ON cast_members.movie_id = movies.id
  JOIN actors ON actors.id = cast_members.actor_id
  WHERE movies.id = ($1)
  ORDER BY title')

  @movies_id = db_connection do |db|
    db.exec_params(sql, [id])
  end
  @movies_id.to_a
end

##############################
########## ROUTES ############
##############################

# * Limit the number of movies displayed at `/movies` to 20 with
# links to the next page of movies. To go to the second page, the URL
#  should change to `/movies?page=2` (the page number can be accessed
#  in the `params` hash).

get '/' do

  erb :index
end

get '/actors' do
  @actors = get_actors

  erb :'/actors/index'
end

get '/actors/:id' do
  @actor_info = find_actor_by_id(params['id'])

  erb :'/actors/show'
end

get '/movies' do
  @page_num = params['page'].to_i || 1
  @movies = get_movies(@page_num)
  @movie_search = params["movie_search"]
  @search_movies = search_movies
  erb :'/movies/index'
end

get '/movies/:id' do
  @movie_info = find_movie_by_id(params['id'])

  erb :'/movies/show'
end
