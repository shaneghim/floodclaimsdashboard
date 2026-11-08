USE FloodClaims;
GO

--build the clean claims and cpi tables--

--create our claims table, drop if it already exists--
DROP TABLE IF EXISTS claims;

--TRY_CAST to convert data types--
--CASE WHEN for TRUE/FALSE--
--COALESCE to return the first non-NULL value to turn a NULL payment into 0, so we dont lose--
--any payment from paid_building, paid_contents, paid_icc--
--ALTER TABLE with AS computes a new column (paid_total)--
SELECT TRY_CAST(id AS bigint) AS claim_id,
       TRY_CAST(dateOfLoss AS date) AS date_of_loss,
       TRY_CAST(yearOfLoss AS int) AS year_of_loss, state, countyCode AS county_code, ratedFloodZone AS flood_zone,
       TRY_CAST(occupancyType AS int) AS occupancy_type,
CASE primaryResidenceIndicator WHEN 'TRUE' THEN 1 WHEN 'FALSE' THEN 0 END AS primary_residence,
CASE elevatedBuildingIndicator WHEN 'TRUE' THEN 1 WHEN 'FALSE' THEN 0 END AS elevated_building,
       TRY_CAST(TRY_CAST(waterDepth AS float) AS decimal(10,2)) AS water_depth, floodEvent AS flood_event, causeOfDamage AS cause_of_damage,
       TRY_CAST(TRY_CAST(buildingDamageAmount AS float) AS decimal(18,2)) AS building_damage,
       TRY_CAST(TRY_CAST(contentsDamageAmount AS float) AS decimal(18,2)) AS contents_damage,
       COALESCE(TRY_CAST(TRY_CAST(netBuildingPaymentAmount AS float) AS decimal(18,2)), 0) AS paid_building,
       COALESCE(TRY_CAST(TRY_CAST(netContentsPaymentAmount AS float) AS decimal(18,2)), 0) AS paid_contents,
       COALESCE(TRY_CAST(TRY_CAST(netIccPaymentAmount AS float) AS decimal(18,2)), 0) AS paid_icc,
       TRY_CAST(TRY_CAST(totalBuildingInsuranceCoverage AS float) AS decimal(18,2)) AS building_coverage,
       TRY_CAST(policyCount AS int) AS policy_count
INTO claims
FROM raw_claims;
ALTER TABLE claims
ADD paid_total AS (paid_building + paid_contents + paid_icc);
GO

--check the cleaned table
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN date_of_loss IS NULL THEN 1 ELSE 0 END) AS bad_dates,
    SUM(CASE WHEN building_damage IS NULL THEN 1 ELSE 0 END) AS missing_damage,
    SUM(paid_total) AS total_paid_nominal,
    MIN(date_of_loss) AS first_loss,
    MAX(date_of_loss) AS last_loss
FROM claims;

--clean the cpi, drop if it already exists--
--we build the annual from monthly data since 2025's annual average is missing--
DROP TABLE IF EXISTS cpi;

SELECT
    YEAR(TRY_CAST(observation_date AS date)) AS cpi_year,
    AVG(TRY_CAST(CPIAUCSL AS float)) AS cpi,
    COUNT(TRY_CAST(CPIAUCSL AS float)) AS months_reported
INTO cpi
FROM raw_cpi_monthly
GROUP BY YEAR(TRY_CAST(observation_date AS date));
GO

SELECT * FROM cpi ORDER BY cpi_year DESC;
GO
