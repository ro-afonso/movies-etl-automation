# movies-etl-automation

End-to-end fully automated ETL pipeline designed to handle movie data, integrating technologies such as:
* **AWS Lambda and S3** for data processing
* **Snowflake** for data warehousing
* [**Power BI dashboard**](https://app.powerbi.com/view?r=eyJrIjoiZmJlNDgxMmItMjIxYi00MmM0LTljOTYtN2Q4ZTNmZDY3MWM2IiwidCI6ImU1NmZkNzJjLTVhMjctNDhhZC1iN2I1LTYyMWJlYzgyMmU2NiIsImMiOjl9) with daily updated data

The following diagram illustrates the pipeline flow:

![Movies data pipeline github](https://github.com/ro-afonso/movies-etl-automation/assets/93609933/6f1363d9-f016-4de6-950e-1d7aabc33668)

The data extraction is performed using an AWS Lambda function written in Python, which fetches data from the TMDB API. The dataset includes the top 100 movies for the following categories:
* Top-rated movies of all time
* Most profitable movies of all time
* Popular and upcoming movies (past 30 days and next 30 days)

The extracted data is saved as CSV files in an S3 bucket. These files are then loaded into a Snowflake database using an external stage integration and a scheduled CRON task. Finally, the database is connected to a [Power BI dashboard](https://app.powerbi.com/view?r=eyJrIjoiZmJlNDgxMmItMjIxYi00MmM0LTljOTYtN2Q4ZTNmZDY3MWM2IiwidCI6ImU1NmZkNzJjLTVhMjctNDhhZC1iN2I1LTYyMWJlYzgyMmU2NiIsImMiOjl9) that refreshes daily to display the latest data.

The data model is depicted below:

![Movie data model](https://github.com/ro-afonso/movies-etl-automation/assets/93609933/7f1c1960-cf11-4763-9a15-28882b6a0819)

## Requirements
* [TMDB account](https://developer.themoviedb.org/reference/intro/authentication) (free API key for movie data)
* [AWS account](https://aws.amazon.com/free) (1-Year Free Tier)
* [Snowflake account](https://signup.snowflake.com/?trial=student) (120-Day Free Trial)
* [Microsoft Business account](https://signup.microsoft.com/get-started/signup?products=35dffc92-9eb4-4d5c-82c2-2582b37bb9c4&mproducts=CFQ7TTC0LDPB:0005&fmproducts=CFQ7TTC0LDPB:0005) (publish Power BI dashboards for free)

## Pipeline Setup with Video Demonstration

Follow the steps below to set up and deploy the pipeline. The video demos visually guide you through each step, highlighting the pipeline's features and functionality:

### AWS Lambda and S3

https://github.com/user-attachments/assets/09f6619d-2c10-4b11-9f32-f0685687ec15

1) Create a new Lambda function with "Python 3.12" as the runtime
2) Copy the Python code from "movie_data_extract.py" and paste it into your Lambda function
3) Adapt the code using your TMDB API key
4) Add the "AWSSDKPandas-Python312" layer to import the required packages
5) Increase the function timeout value to 3 minutes
6) Add the "AmazonS3FullAccess" policy to the IAM role of your Lambda function
7) Create an S3 bucket, name it "movies-data-bucket", and unblock all public access
8) Deploy and test the Lambda function to ensure the CSV files are added to the S3 bucket
9) Open EventBridge and schedule the Lambda function to run every day at midnight

### Snowflake

https://github.com/user-attachments/assets/75fe2694-4ffe-4beb-90c9-816e2f157e84

1) Copy the SQL code from "aws_s3_movies_snowflake_worksheet.sql" and paste it into your Snowflake worksheet
2) Create a new policy in AWS to provide bucket access to Snowflake (refer to the [official documentation](https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration#creating-an-iam-policy))
   * Change the bucket name to "movies-data-bucket" and set "s3:prefix" to "*"
3) Create a new role in AWS using your AWS account as the entity type
   * Select the policy created previously to add the required permissions
4) Copy the role ARN and use it to create the Storage Integration in the Snowflake worksheet
5) Run the worksheet until the storage integration description to get the IAM_USER_ARN and AWS_EXTERNAL_ID
6) Edit the trust policy of the AWS role to link the Snowflake stage (refer to the [official documentation](https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration#step-5-grant-the-iam-user-permissions-to-access-bucket-objects))
   * Adapt the policy using the IAM_USER_ARN and AWS_EXTERNAL_ID from the Snowflake integration
7) Run the rest of the worksheet to create the stage with access to S3, the procedures responsible for populating the tables with movie data, and the task scheduled to call said procedures every day at 10 past midnight
   * This ensures the Lambda function stores updated data in S3 before sending it to Snowflake
   * You can manually populate the tables anytime with `CALL load_all_movies();`

### Power BI Dashboard

https://github.com/user-attachments/assets/e2a4e14a-78ca-44a3-8256-3f670688fc2b

1) Open "TMDB_Dashboard_github.pbix" with Power BI and access the Advanced Editor under Data Sources
2) Uncomment the Snowflake code section and delete the local setup code found below
3) Change the data source using your Snowflake account URL (remove the initial "https://" part)
   * Log in with your Snowflake account in Power BI to access the "MOVIES_DB" database
3) Apply these changes to each table and close the Advanced Editor when finished
4) Log in with your Microsoft Business account to publish the report into your workspace
5) Configure the data source settings in your workspace to connect the Snowflake database to your web report
   * Simply log in using your Snowflake credentials once again
6) Set a refresh schedule to update the data every day (for example, at half past midnight)
7) With the pipeline fully automated, explore the dashboard and share it with the world
