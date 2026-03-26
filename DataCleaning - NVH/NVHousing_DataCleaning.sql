/* 
DATA CLEANING USING SQL QUERIES
PROJECT: NASHVILLE HOUSING DATA
Goal: Prepare raw housing data for analysis by fixing formats, filling missing values,
splitting columns, standardizing fields, and removing duplicates.
*/

-- =========================================================
-- CREATE DATABASE
-- Create a dedicated database for the project (safe practice)
-- =========================================================
DROP DATABASE IF EXISTS ProjectNVH
CREATE DATABASE ProjectNVH


-- =========================================================
-- IMPORT DATA FROM LOCAL FILE (Excel)
-- Manual Import Steps in SSMS:
-- Database > Tasks > Import Data
-- Select Excel source → Choose file → Use OLE DB Provider
-- Select worksheet → Finish import
-- =========================================================


-- =========================================================
-- CHECK IMPORTED DATA
-- Quick look to confirm data loaded correctly
-- =========================================================
SELECT *
FROM ProjectNVH..NVHousing


-- =========================================================
-- STANDARDIZE DATE FORMAT
-- Goal: Convert SaleDate from DATETIME to DATE (remove time)
-- =========================================================

-- Preview conversion without changing data
SELECT
    nv.SaleDate,
    CONVERT(Date, SaleDate) AS SDV
FROM ProjectNVH..NVHousing nv

-- Attempt direct update
UPDATE NVHousing
SET SaleDate = CONVERT(Date, SaleDate)

-- Verify result
SELECT SaleDate FROM NVHousing 

-- If direct conversion fails, create a new column


-- Add new column with correct type
ALTER TABLE NVHousing
ADD SaleDateConv DATE

-- Populate new column with converted values
UPDATE NVHousing
SET SaleDateConv = CONVERT(Date, SaleDate)

-- Verify conversion
SELECT SaleDate, SaleDateConv FROM NVHousing 


/* ----------------------------------------------------------- */ 
/* TESTING DATA CHANGES USING A TEMP TABLE */

-- Create temporary table for experimentation (safe testing)
DROP TABLE IF EXISTS #temp_table
CREATE TABLE #temp_table 
(
    ParcelID NVARCHAR(255), 
    LandUse NVARCHAR(255), 
    SaleDate DATETIME
)

-- Copy sample data
INSERT INTO #temp_table 
SELECT ParcelID, LandUse, SaleDate
FROM NVHousing

-- Review temp data
SELECT *
FROM #temp_table

-- Add corrected date column
ALTER TABLE #temp_table
ADD SaleDateConv DATE

-- Fill new column with converted values
UPDATE #temp_table
SET SaleDateConv = CONVERT(DATE, SaleDate)

-- Remove old incorrect column
ALTER TABLE #temp_table
DROP COLUMN SaleDate

-- Rename corrected column to original name
EXEC tempdb..sp_rename 
    '#temp_table.SaleDateConv', 
    'SaleDate', 
    'COLUMN';


/*  -------------------------------------------------------  */
/* POPULATE MISSING PROPERTY ADDRESS VALUES */

-- Identify rows where PropertyAddress is NULL
SELECT * 
FROM NVHousing
WHERE PropertyAddress IS NULL

-- Sort by ParcelID to inspect related records
SELECT * 
FROM NVHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

-- Self-join to find matching records with same ParcelID
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NVHousing a
JOIN NVHousing b
    ON a.ParcelID = b.ParcelID 
    AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Preview corrected values using ISNULL
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
       ISNULL(a.PropertyAddress, b.PropertyAddress) AS CorrectedAddress
FROM NVHousing a
JOIN NVHousing b
    ON a.ParcelID = b.ParcelID 
    AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Update main table with available address values
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NVHousing a
JOIN NVHousing b
    ON a.ParcelID = b.ParcelID 
    AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


/*-----------------------------------------------------------------------------------------*/
-- SPLIT PROPERTY ADDRESS INTO SEPARATE COLUMNS (Address, City)

-- Inspect address format
SELECT PropertyAddress 
FROM NVHousing

-- Extract Address and City using SUBSTRING + CHARINDEX
SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM NVHousing

-- Add new columns
ALTER TABLE NVHousing
ADD Address NVARCHAR(255)

ALTER TABLE NVHousing
ADD City NVARCHAR(255)

-- Populate new columns
UPDATE NVHousing
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

UPDATE NVHousing
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

-- Verify results
SELECT *
FROM NVHousing


-- =========================================================
-- SPLIT OWNER ADDRESS INTO Address, City, State
-- =========================================================

SELECT OwnerAddress
FROM NVHousing

-- Use PARSENAME trick after replacing commas with dots
SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) AS Address,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) AS City,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) AS State
FROM NVHousing

-- Rename original column to preserve raw data
EXEC ProjectNVH..sp_rename 
    'NVHousing.OwnerAddress', 
    'OwnerFullAddress', 
    'COLUMN';

-- Add new structured columns
ALTER TABLE NVHousing
ADD OwnerAddress NVARCHAR(255)

ALTER TABLE NVHousing
ADD OwnerCity NVARCHAR(255)

ALTER TABLE NVHousing
ADD OwnerState NVARCHAR(255)

-- Populate structured columns
UPDATE NVHousing
SET OwnerAddress = PARSENAME(REPLACE(OwnerFullAddress, ',', '.'),3)

UPDATE NVHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerFullAddress, ',', '.'),2)

UPDATE NVHousing
SET OwnerState = PARSENAME(REPLACE(OwnerFullAddress, ',', '.'),1)

-- Verify results
SELECT *
FROM NVHousing


/* ---------------------------------------------------------------------------------------------- */
-- STANDARDIZE SoldAsVacant FIELD (Y/N → Yes/No)

-- Check distribution
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NVHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- Preview transformation
SELECT SoldAsVacant,
CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END AS Correction
FROM NVHousing
ORDER BY 1

-- Apply update
UPDATE NVHousing
SET SoldAsVacant = 
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END


/* ------------------------------------------------------------------------------ */
-- REMOVE DUPLICATE RECORDS

-- Review data before deletion
SELECT *
FROM NVHousing;

-- Identify duplicates using ROW_NUMBER
WITH RemoveDups AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
            ORDER BY UniqueID
        ) AS Row_Num
    FROM NVHousing
)
SELECT *
FROM RemoveDups

-- Delete duplicates (keep first record only)
;WITH RemoveDups AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
            ORDER BY UniqueID
        ) AS Row_Num
    FROM NVHousing
)
DELETE
FROM RemoveDups
WHERE Row_Num > 1


/* -------------------------------------------------------------- */
-- REMOVE UNUSED COLUMNS

-- Inspect table before deletion
SELECT *
FROM NVHousing;

SELECT OwnerFullAddress, TaxDistrict, PropertyAddress, SaleDate
FROM NVHousing;

-- Drop columns no longer needed
ALTER TABLE NVHousing
DROP COLUMN OwnerFullAddress, TaxDistrict, PropertyAddress, SaleDate

--- DONE ---
