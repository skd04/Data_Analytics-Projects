# Nashville Housing Data Cleaning — SQL Project

## Project Overview

This project focuses on cleaning and preparing a real-world housing dataset using Microsoft SQL Server. Raw datasets often contain inconsistencies, missing values, duplicate records, and formatting issues. The goal of this project is to transform messy data into a clean, structured format ready for analysis and visualization.

---

## Objectives

- Standardize date formats  
- Handle missing property address values  
- Split combined address fields into separate columns  
- Normalize categorical values for consistency  
- Detect and remove duplicate records  
- Remove unnecessary columns  

---

## Data Cleaning Steps

### 1. Date Standardization

Converted the SaleDate column from DATETIME to DATE to remove time information and ensure consistency across records.

---

### 2. Handling Missing Property Addresses

Some records had missing property addresses.  
A self-join based on ParcelID was used to populate missing values from matching records with the same parcel.

---

### 3. Splitting Property Address

The original property address field contained both address and city in a single column.

It was split into:

- Address  
- City  

using SQL string functions.

---

### 4. Splitting Owner Address

Owner address contained address, city, and state in one field.

It was separated into three new columns:

- OwnerAddress  
- OwnerCity  
- OwnerState  

using the PARSENAME technique after replacing commas.

---

### 5. Standardizing SoldAsVacant Field

The column contained inconsistent values (Y and N).  
These were converted into readable values:

- Y → Yes  
- N → No  

---

### 6. Removing Duplicate Records

Duplicate entries were identified using:

- ROW_NUMBER()  
- PARTITION BY key columns  

All duplicate rows (except the first occurrence) were removed.

---

### 7. Removing Unused Columns

After cleaning and restructuring, redundant columns were dropped to simplify the dataset.

---

## Tools and Technologies Used

- Microsoft SQL Server  
- T-SQL (Transact-SQL)  
- Window Functions (ROW_NUMBER)  
- String Functions (SUBSTRING, CHARINDEX, PARSENAME)  
- Self Joins  
- CASE Statements  
- Temporary Tables  
- Data Type Conversion  
- ALTER TABLE Operations  

---

## Final Result

A clean and structured housing dataset ready for:

- Data analysis  
- Data visualization  
- Reporting  
- Machine learning applications  
- Business insights  

---

## Dataset

Nashville Housing Dataset (public dataset commonly used for SQL data cleaning practice).

---

## Disclaimer

All SQL code in this project was written by the project author.  
Comments and documentation were refined for clarity and readability.

---

## Author
SHANKHADEEP
