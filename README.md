# movies-etl-automation
End-to-end automated ETL pipeline designed to handle movie data. Leveraging AWS Lambda, EventBridge, and S3 for data processing, and Snowflake for data warehousing, this pipeline seamlessly integrates with a Power BI dashboard for daily updates.

The following diagram illustrates the pipeline flow:

![Movies data pipeline github](https://github.com/ro-afonso/movies-etl-automation/assets/93609933/6f1363d9-f016-4de6-950e-1d7aabc33668)

The data extraction is performed using an AWS Lambda function written in Python, which fetches data from the TMDB API. The dataset includes the top 100 movies for the following categories:
* Top-rated movies of all time
* Most profitable movies of all time
* Popular and upcoming movies (past 30 days and next 30 days)

The extracted data is saved as CSV files in an S3 bucket. These files are then loaded into a Snowflake database using an external stage integration and a scheduled CRON task. Finally, the database is connected to a Power BI dashboard that refreshes daily to display the latest data.

The Power BI dashboard is available [here](https://app.powerbi.com/view?r=eyJrIjoiYWI2MWI3MzItYTg0Yi00NTZkLWE4YmUtNTk5NmIzNzQ0NjczIiwidCI6ImU1NmZkNzJjLTVhMjctNDhhZC1iN2I1LTYyMWJlYzgyMmU2NiIsImMiOjl9).

The data model is depicted below:

![Movie data model](https://github.com/ro-afonso/movies-etl-automation/assets/93609933/7f1c1960-cf11-4763-9a15-28882b6a0819)

## Requirements
* [AWS account](https://aws.amazon.com/free) (1-Year Free Tier)
* [Snowflake account](https://signup.snowflake.com/?trial=student) (120-day free trial)
* [Microsoft Business account](https://signup.microsoft.com/get-started/signup?products=35dffc92-9eb4-4d5c-82c2-2582b37bb9c4&mproducts=CFQ7TTC0LDPB:0005&fmproducts=CFQ7TTC0LDPB:0005) (30-day free trial for publishing Power BI dashboard)

## Setup and Installation
Follow these steps to set up and deploy the pipeline:

Lambda Setup:
  * Copy the code from "movie_data_extract.py" and paste it into your Lambda function
  * Add the "AWSSDKPandas-Python312" layer to import required packages
  * Add the "S3 full access" policy to the IAM role of your Lambda function
  * Create an S3 bucket and test the Lambda function to ensure the CSV files are added

Snowflake Setup:
* Copy the SQL code from "aws_s3_movies_snowflake_worksheet.sql" and paste it into your Snowflake worksheet
* Run the worksheet until the storage integration section and copy the IAM_USER_ARN and AWS_EXTERNAL_ID to use in the AWS access role for Snowflake
* Adapt the stage block to include your AWS ARN, bucket names, and desired CRON schedule
* Run the rest of the worksheet to populate the tables with data from S3 and schedule future "COPY INTO" statements with your stage

Power BI Setup:
* Open the Power BI report "TMDB_Dashboard_github.pbix", set up the connection between the dashboard and your database by logging in with your Snowflake account and change the data source to your account URL 
* (Optional) Log in with your Microsoft Business account to publish the report into your workspace and configure the settings to publish the dashboard to the internet with daily refresh
