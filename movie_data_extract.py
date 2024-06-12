import requests
from datetime import date
from dateutil.relativedelta import relativedelta
import pandas as pd
import boto3
import json

def get_movies(mode):
    print(mode+" started!")
    movies_list = []
    
    # use discover to retrieve the ids of the best movies
    for i in range(1, 6):
        print(i)
        if mode == "rates":
            # Retrieve top rated movies
            url = "https://api.themoviedb.org/3/discover/movie?include_adult=false&include_video=false&language=en-US&page="+str(i)+"&sort_by=vote_average.desc&vote_count.gte=400"
        elif mode == "profit":
            # Retrieve top movies based on total revenue
            url = "https://api.themoviedb.org/3/discover/movie?include_adult=false&include_video=false&page="+str(i)+"&sort_by=revenue.desc&vote_count.gte=100"
        else:
            # Retrieve upcoming movies in a one-month period from today
            url = "https://api.themoviedb.org/3/discover/movie?include_adult=false&include_video=false&language=en-US&page="+str(i)+"&primary_release_date.gte="+str(date.today()-relativedelta(months=1))+"&primary_release_date.lte="+str(date.today()+relativedelta(months=1))+"&sort_by=popularity.desc"

        headers = {
            "accept": "application/json",
            "Authorization": "Bearer YOUR-BEARER-KEY" # Adapt to your bearer key
        }

        response = requests.get(url, headers=headers)
        response_json = response.json()
        results = response_json['results']
        
        # iterate over the top 100 movies of each catego
        for movie in results:
            # Get main cast names, characters and photo paths
            url = "https://api.themoviedb.org/3/movie/" + str(movie['id']) + "/credits?language=en-US"
            response = requests.get(url, headers=headers)
            response_json = response.json()
            
            # Determine the number of cast elements to process (minimum of the list length or 8 elements)
            n = min(len(response_json['cast']), 23)
            names = [response_json['cast'][i]['name'] for i in range(n)]
            characters = [response_json['cast'][i]['character'] for i in range(n)]
            profile_paths = [response_json['cast'][i]['profile_path'] for i in range(n)]
            profile_order = [response_json['cast'][i]['order'] for i in range(n)]
            
            # Format each element of the previous lists into a single string delimited by = and save them in a list
            cast_info_list = [f"{name}={character}={profile_path}={order}" for name, character, profile_path, order in zip(names, characters, profile_paths, profile_order)]

            # Get the details of each movie and save the desired info in a dictionary
            url = "https://api.themoviedb.org/3/movie/" + str(movie['id']) + '?language=en-US'
            response = requests.get(url, headers=headers)
            response_json = response.json()

            refined_movie = {
                "id": response_json['id'],
                "title": response_json['title'],
                "overview": response_json['overview'],
                "genres": ','.join(str(d['name']) for d in response_json['genres']),
                "origin_country": ','.join(str(e) for e in response_json['origin_country']),
                "production_company": ','.join(str(d['name']) for d in response_json['production_companies']),
                "release_date": response_json['release_date'],
                "runtime": response_json['runtime'],
                "budget": response_json['budget'],
                "revenue": response_json['revenue'],
                "popularity": response_json['popularity'],
                "vote_avg": response_json['vote_average'],
                "poster_path": response_json['poster_path'],
                "cast_name_role_photo_order": ';'.join(cast_info_list)
            }

            movies_list.append(refined_movie)
    
    df = pd.DataFrame(movies_list)
    csv_buffer = df.to_csv(index=False)
    s3_client = boto3.client('s3')
    bucket_name = 'movies-data-bucket'
    if mode == "rates":
        s3_client.put_object(Bucket=bucket_name, Key="top_rated_movies_tmdb.csv", Body=csv_buffer)
    elif mode == "profit":
        s3_client.put_object(Bucket=bucket_name, Key="most_profitable_movies_tmdb.csv", Body=csv_buffer)
    else:
        s3_client.put_object(Bucket=bucket_name, Key="popular_and_upcoming_movies_tmdb.csv", Body=csv_buffer)


def lambda_handler(event, context):
    # Get top rated movies, most profitable movies and upcoming movies from TMDB
    get_movies("rates")
    get_movies("profit")
    get_movies("upcoming")
    return {
        'statusCode': 200,
        'body': json.dumps('Data successfully extracted and stored in S3')
    }