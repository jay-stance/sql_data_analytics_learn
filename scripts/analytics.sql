/*
  DIMENTIONS AND MEASURES

  is it Numeric?
  NO: it is a dimension
  YES: 
    Does it make sense to aggregate it?
    YES: it is a measure
    NO: it is a dimension

  - why do we need dimensions and measures?
  we need dimensions for grouping the data (S axios in a chart), and we need measure for answering how much, quantifying data, to what measure is this dimension (Y axis
  
  
  STEPS TAKEN IN DOING ANALYTICS FOR DATASETS
  
  - data exploratio: just to know what we have here, the number of tables, columns present etc)
  - Dimensions exploration: helps us identify unique values in each dimension, recognizing how data might be grouped or segmented, which is useful for later analysis. juse use DISTINCT COLUMN NAME
      - date explorations
        - identify the earliest adn latest boundaries
        - understand the scope of data and the timespan using MIN/MAX[DATE]
*/

-- Create the database if it does not exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'DataWarehouseAnalytics')
BEGIN
    CREATE DATABASE DataWarehouseAnalytics;
END

USE DataWarehouseAnalytics;

-- Explore all objects in the database
SELECT * FROM INFORMATION_SCHEMA.TABLES

-- Explore all columns in the database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
-- WHERE TABLE_NAME = 'dim_customers'

-- 2. DIMENSIONS EXPLORATION
SELECT DISTINCT country FROM gold.dim_customers

-- 3. DATE EXPLORATION: identify the earliest adn latest boundaries
SELECT * FROM gold.fact_sales
SELECT 
  MIN(order_date) first_order,
  MAX(order_date) last_order,
  DATEDIFF(YEAR, MIN(order_date), MAX(order_date)) timespan
FROM gold.fact_sales