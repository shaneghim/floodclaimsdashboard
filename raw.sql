USE FloodClaims;
GO

--look at the raw data before cleaning--

SELECT COUNT(*)
FROM raw_claims;
SELECT TOP 10 *
FROM raw_claims

--ok everything looks good--
--we need to create a new table to organize each column into the correct data type for power bi--
--deal with missing values, and create a "total paid" column--
--check for problems--
SELECT COUNT(*) AS total_rows,
    SUM(CASE WHEN dateOfLoss IS NULL THEN 1 ELSE 0 END) AS missing_date,
    SUM(CASE WHEN state IS NULL THEN 1 ELSE 0 END) AS missing_state,
    SUM(CASE WHEN netBuildingPaymentAmount IS NULL THEN 1 ELSE 0 END) AS missing_building_payment,
    SUM(CASE WHEN netBuildingPaymentAmount LIKE '%e%' THEN 1 ELSE 0 END) AS sci_notation_building,
    MIN(yearOfLoss) AS first_year,
    MAX(yearOfLoss) AS last_year
FROM raw_claims;
