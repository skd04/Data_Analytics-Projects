/* 
DATA CLEANING USING SQL QUEIRES
DATA: NASHVILLE HOUSING BROKING
*/

-- CREATE DATABASE
DROP DATABASE IF EXISTS ProjectNVH
CREATE DATABASE ProjectNVH

-- IMPORT DATA FROM LOCAL
 -- Click On DB > Tasks > Import Data
 -- Next > Seleect Microsoft excel & Browse  Excel File > Next> MS OLE DB Provider for SQL Server>
 -- Next > Tick the Sheet > Next> Next > Finish

-- CHECK THE IMPORTED DATA
SELECT *
FROM ProjectNVH..NVHousing

-- STANDARDIZE DATE FORMAT
SELECT
	nv.SaleDate,
	CONVERT(Date, SaleDate) SDV
FROM ProjectNVH..NVHousing nv

UPDATE NVHousing
SET SaleDate = CONVERT(Date, SaleDate)

-- Check if works or not
SELECT SaleDate FROM NVHousing 

-- This not working. So we try another way by adding new column 

-- Add new column
ALTER TABLE NVHousing
ADD SaleDateConv DATE

-- Update and input the saledate data with proper format.
UPDATE NVHousing
SET SaleDateConv = CONVERT(Date, SaleDate)

-- Check if works or not
SELECT SaleDate, SaleDateConv FROM NVHousing 


/* ----------------------------------------------------------- */ 
/* TESTING: TABLE DATA CHANGING USING TEMP TABLE */

-- Create the temp table.
DROP TABLE IF EXISTS #temp_table
CREATE TABLE #temp_table 
(
ParcelID NVARCHAR(255), 
LandUse NVARCHAR(255), 
SaleDate DATETIME
)
INSERT INTO #temp_table 
SELECT ParcelID, LandUse, SaleDate
FROM NVHousing

-- Check the data
SELECT *
FROM #temp_table

-- Add new column with correct format of SaleDate
ALTER TABLE #temp_table
ADD SaleDateConv DATE
-- Input data to the new blank column
UPDATE #temp_table
SET SaleDateConv = CONVERT(DATE, SaleDate)

-- Delete the incorrect format column
ALTER TABLE #temp_table
DROP COLUMN SaleDate

-- Rename the new column
EXEC tempdb..sp_rename 
    '#temp_table.SaleDateConv', 
    'SaleDate', 
    'COLUMN';

/*  -------------------------------------------------------  */

/* POPULATE THE PROPERTY ADDRESS */

-- Check the Property Address Column with NULL value.
SELECT * 
FROM NVHousing
WHERE PropertyAddress IS NULL

-- Sort the data according to ParcelID
SELECT * 
FROM NVHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

-- JOIN the table with itself to equalize the property address based on ParcelID
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NVHousing a
JOIN NVHousing b
    ON a.ParcelID = b.ParcelID 
    AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Create new column where we replace the Null values with available values
-- This is for checking which we are going to replace
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
, ISNULL(a.PropertyAddress, -- This one for select NULL value column.
         b.PropertyAddress -- This one for the extract value from.
         ) AS CorrectedAddress
FROM NVHousing a
JOIN NVHousing b
    ON a.ParcelID = b.ParcelID 
    AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Update in the main table 
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NVHousing a
JOIN NVHousing b
    ON a.ParcelID = b.ParcelID 
    AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Check it works correctly or not from the above query we have on above.

/*-----------------------------------------------------------------------------------------*/

-- BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (Address, City, State)

-- Analyse the Address format 
SELECT PropertyAddress 
FROM NVHousing

-- Separate things using SUBSTRING
SELECT
SUBSTRING(PropertyAddress, 1,CHARINDEX(',', PropertyAddress)-1) Address -- CHARINDEX is CharacterIndx which counts the characterindex no.
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) City -- LEN is for Count lenngth.
FROM NVHousing

-- Because we cannot change the existed whole column data or the data type, so we are going to add two new columns
ALTER TABLE NVHousing
ADD Address NVARCHAR(255)

ALTER TABLE NVHousing
ADD City NVARCHAR(255)

-- UPDATE THE DATA ON THE NEW COLUMN
UPDATE NVHousing
SET Address = SUBSTRING(PropertyAddress, 1,CHARINDEX(',', PropertyAddress)-1)

UPDATE NVHousing
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

-- CHECK IS IT WORKS...
SELECT *
FROM NVHousing


-- Now working for OwnwAddress
SELECT OwnerAddress
FROM NVHousing

-- Use Parse Name for separation
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) Address-- Because it's calculated backwards as first
, PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) City
, PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) State
FROM NVHousing

-- CHANGE THE COLUMN NAME
EXEC ProjectNVH..sp_rename 
    'NVHousing.OwnerAddress', 
    'OwnerFullAddress', 
    'COLUMN';

-- Because we cannot change the existed whole column data or the data type, so we are going to add two new columns
ALTER TABLE NVHousing
ADD OwnerAddress NVARCHAR(255)

ALTER TABLE NVHousing
ADD OwnerCity NVARCHAR(255)

ALTER TABLE NVHousing
ADD OwnerState NVARCHAR(255)

-- UPDATE THE DATA ON THE NEW COLUMN
UPDATE NVHousing
SET OwnerAddress = PARSENAME(REPLACE(OwnerFullAddress, ',', '.'),3)

UPDATE NVHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerFullAddress, ',', '.'),2)

UPDATE NVHousing
SET OwnerState = PARSENAME(REPLACE(OwnerFullAddress, ',', '.'),1)

-- Check if its work 
SELECT *
FROM NVHousing

/* ---------------------------------------------------------------------------------------------- */

-- CHANGE Y & N to YES and NO "Solid as Vacant" Field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NVHousing
GROUP BY SoldAsVacant
ORDER BY 2
-- CHECK HOW MUCH they have.

-- USE CASE for the correction and Check 
SELECT SoldAsVacant,
CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END AS Correction
FROM NVHousing
ORDER BY 1

-- UPdate the data
UPDATE NVHousing
SET SoldAsVacant = 
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END

/* ------------------------------------------------------------------------------ */

/* REMOVE DUPLICATES */

-- CHECK THE DATA ANAD DONE THE PARTITION BY USING THE UNIQUE STUFF
SELECT *
FROM NVHousing;

-- USING CTE
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
--WHERE Row_Num > 1
--ORDER BY PropertyAddress

-- DELETE THE DUPLICATE DATA
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
--ORDER BY PropertyAddress

/* -------------------------------------------------------------- */

-- DELETE UNUSED COLUMN 

-- CHECKING PURPOSE
SELECT *
FROM NVHousing;

-- CHECK BEFORE DELETE
SELECT OwnerFullAddress, TaxDistrict, PropertyAddress, SaleDate
FROM NVHousing;

-- DELETE THE COLUMNS
ALTER TABLE NVHousing
DROP COLUMN OwnerFullAddress, TaxDistrict, PropertyAddress, SaleDate
