CREATE OR REPLACE DATABASE MOVIES_DB;
CREATE OR REPLACE SCHEMA MOVIES_SCHEMA;

// Create storage integration to gain access to S3
CREATE OR REPLACE STORAGE INTEGRATION aws_s3_movies_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'YOUR_ARN' //Adapt with your S3 role ARN
  STORAGE_ALLOWED_LOCATIONS = ('s3://movies-data-bucket/');
  
SHOW INTEGRATIONS;

// Copy IAM_USER_ARN and AWS_EXTERNAL_ID to use in AWS access role
DESC INTEGRATION aws_s3_movies_integration;

GRANT USAGE ON INTEGRATION aws_s3_movies_integration TO ROLE accountadmin;

//Create stage for AWS external access
CREATE OR REPLACE STAGE movies_aws_stage
    STORAGE_INTEGRATION = aws_s3_movies_integration,
    URL = 's3://movies-data-bucket/';

SHOW STAGES;
    
LIST @movies_aws_stage;

// Create tables to store movie data
CREATE OR REPLACE TABLE snowflake_top_rated_movies (
    id INTEGER,
    title STRING,
    overview STRING,
    genres STRING,
    origin_country STRING,
    production_company STRING,
    release_date DATE,
    runtime INTEGER,
    budget INTEGER,
    revenue INTEGER,
    popularity FLOAT,
    vote_avg FLOAT,
    poster_path STRING,
    cast_name_role_photo_order STRING
);

CREATE OR REPLACE TABLE snowflake_most_profitable_movies LIKE snowflake_top_rated_movies;
CREATE OR REPLACE TABLE snowflake_popular_and_upcoming_movies LIKE snowflake_top_rated_movies;

//Create a stored procedure to overwrite each table with data from S3
CREATE OR REPLACE PROCEDURE load_top_rated_movies()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  -- Truncate top_rated_movies table
  TRUNCATE TABLE snowflake_top_rated_movies;

  -- Load new data from S3 into the table
  COPY INTO snowflake_top_rated_movies
  FROM @movies_aws_stage/top_rated_movies_tmdb.csv
  FILE_FORMAT = (type = 'CSV', field_optionally_enclosed_by='"', skip_header=1);

  RETURN 'Top rated movies data refreshed successfully';
END
$$;

CREATE OR REPLACE PROCEDURE load_most_profitable_movies()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  -- Truncate most_profitable_movies table
  TRUNCATE TABLE snowflake_most_profitable_movies;

  -- Load new data from S3 into the table
  COPY INTO snowflake_most_profitable_movies
  FROM @movies_aws_stage/most_profitable_movies_tmdb.csv
  FILE_FORMAT = (type = 'CSV', field_optionally_enclosed_by='"', skip_header=1);

  RETURN 'Most profitable movies data refreshed successfully';
END
$$;

CREATE OR REPLACE PROCEDURE load_popular_and_upcoming_movies()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
  -- Truncate popular_and_upcoming_movies table
  TRUNCATE TABLE snowflake_popular_and_upcoming_movies;

  -- Load new data from S3 into the table
  COPY INTO snowflake_popular_and_upcoming_movies
  FROM @movies_aws_stage/popular_and_upcoming_movies_tmdb.csv
  FILE_FORMAT = (type = 'CSV', field_optionally_enclosed_by='"', skip_header=1);

  RETURN 'Popular and upcoming movies data refreshed successfully';
END
$$;

//Create a master procedure to call the three procedures above
CREATE OR REPLACE PROCEDURE load_all_movies()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
    CALL load_top_rated_movies();
    CALL load_most_profitable_movies();
    CALL load_popular_and_upcoming_movies();
    RETURN 'All Movies Loaded';
END;
$$;

// Create a task to run the procedures every day
CREATE OR REPLACE TASK refresh_movies_data_task
WAREHOUSE = COMPUTE_WH
SCHEDULE = 'USING CRON 10 0 * * * UTC' //Run every day at 00:10 UTC
AS
CALL load_all_movies();

ALTER TASK refresh_movies_data_task RESUME;

SELECT * FROM snowflake_top_rated_movies;

//ALTER TASK refresh_movies_data_task SUSPEND;
