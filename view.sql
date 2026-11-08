USE FloodClaims;
GO

--inflation-adjusted claims view, checks, and event summary--

--build our view--
CREATE OR ALTER VIEW v_claims AS
SELECT c.claim_id, c.date_of_loss, c.year_of_loss,

--*fix here* UN (unknown) claims have no county, get rid of the blank row (femas's location is unassigned)--
CASE WHEN c.state = 'UN' OR c.state IS NULL THEN 'Unknown' ELSE c.state END AS state,
    c.county_code, c.flood_zone, c.occupancy_type, c.primary_residence, c.elevated_building,
    c.water_depth, c.flood_event, c.cause_of_damage, c.building_damage, c.contents_damage,
    c.paid_building, c.paid_contents, c.paid_icc, c.paid_total, c.building_coverage, c.policy_count,

--adjust for inflation--
c.paid_total * (base.cpi / COALESCE(y.cpi, base.cpi)) AS paid_total_2025,

--group flood zones into broader risk categories--
CASE WHEN c.flood_zone LIKE 'V%' THEN 'Coastal high risk (V)'
     WHEN c.flood_zone LIKE 'A%' THEN 'High risk (A)'
     WHEN c.flood_zone IN ('B', 'C') OR c.flood_zone LIKE 'X%' THEN 'Moderate to low risk (B, C, X)'
     WHEN c.flood_zone = 'D' THEN 'Undetermined (D)'
     ELSE 'Unknown'
     END AS flood_zone_group,

--group occupancy codes into residential vs. non-residential--
CASE WHEN c.occupancy_type IN (1, 2, 3, 11, 12, 13, 14, 15, 16) THEN 'Residential'
     WHEN c.occupancy_type IN (4, 6, 17, 18, 19) THEN 'Non-residential'
     ELSE 'Unknown'
     END AS occupancy_group,

--*fix*readable labels for the 1/0 columns for the charts--
CASE c.elevated_building WHEN 1 THEN 'Elevated' WHEN 0 THEN 'Not elevated' ELSE 'Unknown' END AS elevated_group,
CASE c.primary_residence WHEN 1 THEN 'Primary residence' WHEN 0 THEN 'Not primary' ELSE 'Unknown' END AS residence_group

--join each claim's year's CPI, left join so we dont drop 2026 claims--
--attach each 2025 CPI to every row as base.cpi to adjust for inflation--

FROM claims c
LEFT JOIN cpi y ON y.cpi_year = c.year_of_loss
CROSS JOIN (SELECT cpi FROM cpi WHERE cpi_year = 2025) base;
GO

--check the view--
SELECT
    COUNT(*) AS total_rows,
    SUM(paid_total) AS paid_nominal,
    SUM(paid_total_2025) AS paid_2025_dollars
FROM v_claims;


SELECT flood_zone_group, COUNT(*) AS claims
FROM v_claims
GROUP BY flood_zone_group
ORDER BY claims DESC;
GO

--summarize each named flood event in 2025 dollars--
CREATE OR ALTER VIEW v_event_summary AS
SELECT flood_event, year_of_loss AS event_year,
    CONCAT(flood_event, ' (', year_of_loss, ')') AS event_label,
    MIN(date_of_loss) AS first_loss_date,
    COUNT(*) AS claims,
    SUM(paid_total_2025) AS paid_2025,
    AVG(paid_total_2025) AS avg_paid_2025
FROM v_claims
WHERE flood_event IS NOT NULL
  AND flood_event <> 'Flooding'
GROUP BY flood_event, year_of_loss;
GO

SELECT TOP 10 * FROM v_event_summary ORDER BY paid_2025 DESC;

--check "unknown" flood_zone_group--
SELECT flood_zone,
COUNT(*) AS claims
FROM v_claims
WHERE flood_zone_group = 'Unknown'
GROUP BY flood_zone
ORDER BY claims DESC;
--only null, leave alone--

--check
   SELECT state, COUNT(*) AS claims FROM v_claims WHERE state = 'Unknown' GROUP BY state;