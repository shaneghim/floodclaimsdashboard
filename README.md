# U.S. Flood Insurance Claims Dashboard: SQL Server and Power BI

This project analyzes every National Flood Insurance Program (NFIP) claim from 1978 to 2026, over 2.7 million claims. I trimmed FEMA's raw file in R, cleaned and summarized it in SQL Server, and built an interactive Power BI dashboard showing where flood losses happen, what drives them, and which storms cost the most.

[View the interactive dashboard](https://shaneghim.github.io/floodclaimsdashboard/) (opens in Power BI)

![Dashboard demo](images/demo.gif)

**Data**

I used FEMA's [NFIP Redacted Claims (v3)](https://www.fema.gov/openfema-data-page/nfip-redacted-claims-v3) dataset from OpenFEMA. It has 2,725,989 claims from January 1978 through September 2026, with 84 columns describing each claim's date, location, flood zone, building, damage, and payments. To compare years fairly, I accounted for inflation by adjusting every payment to 2025 dollars using the [Consumer Price Index](https://fred.stlouisfed.org/series/CPIAUCSL) from FRED.

**Method**

<ins>Trim in R</ins>

Since the raw file is over a gigabyte, I used R to keep 19 columns I needed out of 84, and saved them as a smaller CSV. Everything was kept as text so codes (like county code 06073) wouldn't lose their leading zeros. All cleaning and analysis happened in SQL.

<ins>Clean in SQL Server</ins>

I loaded the trimmed file into a staging table as text, then built a clean table with the correct data types using TRY_CAST, so a bad value becomes blank instead of stopping the import. There were 11,558 building payments written in scientific notation, which would have turned blank, so I converted them to float first, then decimal. Total paid adds the building, contents, and increased cost of compliance (ICC) payments. I treated missing payments as \$0 using COALESCE, since a blank payment means nothing was paid, but left missing damage amounts blank, since those are unknown. FRED’s 2025 annual CPI was missing because one month had no value, so I built the annual averages from monthly data instead, using the 11 available months for 2025. Finally, claims with no location (FEMA’s “UN” code, 16,442 claims) were labeled “Unknown.”

Two views feed Power BI: v_claims converts payments to 2025 dollars with a LEFT JOIN to CPI (to keep the 2026 claims) and groups flood zone and building codes with CASE. The view v_event_summary totals each storm by name and year, since names like Irene repeat, and drops FEMA’s generic “Flooding” label.

<ins>Dashboard in Power BI</ins>

Power BI imports the two views. I added a date table connected to the claims and wrote DAX measures for totals, averages, and shares. CALCULATE handles the risk percentages, and TOPN finds each year's costliest storm for the chart tooltips. A year slicer is synced across the first three pages, and buttons move between pages.

**Dashboard**

<ins>Overview</ins>

![Overview page](images/overview.png)

Overview shows the total claims and payments, payments by year, and the top 10 states by total payments. The three orange bars are 2005 (Hurricane Katrina), 2012 (Sandy), and 2017 (Harvey). 2026 is left out of the yearly chart because claims are still being paid.

<ins>Map</ins>

![Map page](images/map.png)

Map visualizes the payments by state, with a table of every state/territory.

<ins>Risk</ins>

![Risk page](images/risk.png)

Risk reveals the claims and average payments by flood zone, building type, elevation, and whether the home was a primary residence or not.

<ins>Major events</ins>

![Major events page](images/events.png)

The major events page highlights the 15 costliest storms, and contains a scatter plot comparing how many properties each storm flooded with how much damage it did per property.

**Results**

| Measure | Result |
|----|---:|
| Total claims | 2,725,989 |
| Total paid (2025 dollars) | \$134.5 billion |
| Average paid per claim (2025 dollars) | \$49,355 |
| Costliest event | Hurricane Katrina (2005), \$26.5 billion |
| Share of payments from the top 3 events | 37.7% |

**Findings**

We see that flood losses are very concentrated. Louisiana, Texas, and Florida account for about 62% of all payments since 1978, and three storms (Katrina, Sandy, and Harvey) account for 37.7%, more than a third of the program's entire history.

About a quarter of the claims (25%) came from moderate to low-risk flood zones, outside the areas where flood insurance is usually required, and those claims averaged around \$46,000, close to the \$53,000 average in high-risk zones. Claims on elevated buildings averaged about 10% less than those on buildings that weren't elevated, and about half of all claims were on buildings that weren't a primary residence, such as second homes, rentals, and businesses. Residential buildings received 87% of all payments.

**Files**

- `FloodClaims.pbit`: the Power BI template (pages, visuals, measures, and data model, without the data, since it is too large to upload onto GitHub)
- `R/data_clean.R`: trims the raw FEMA file to the needed columns
- `sql/raw.sql`: checks the raw data
- `sql/clean.sql`: builds the clean claims and CPI tables
- `sql/view.sql`: builds the inflation-adjusted claims view and event summary
- `images/`: dashboard screenshots and demo GIF
- `README.md`: this page

<ins>To rerun it</ins>

1.  Download the [NFIP Redacted Claims (v3)](https://www.fema.gov/openfema-data-page/nfip-redacted-claims-v3) file from OpenFEMA, and the monthly [CPIAUCSL](https://fred.stlouisfed.org/series/CPIAUCSL) series from FRED starting in 1970.
2.  Run `R/data_clean.R` to create the trimmed CSV.
3.  In SQL Server, create a database called `FloodClaims`, then use Import Flat File to load the trimmed claims as `raw_claims` (every column as `nvarchar(255)`) and the CPI file as `raw_cpi_monthly`.
4.  Run the SQL scripts in order: `raw.sql`, `clean.sql`, `03_view.sql`.
5.  Open `FloodClaims.pbit` in Power BI Desktop and connect to your SQL Server.

**Limitations**

This project only uses claims, not policies, so it shows where losses happened but not how likely a flood claim is for a given home. Generally, a state with more policies will naturally have more claims. I adjusted for inflation with CPI, which tracks general prices, not construction costs, so older claims may be undervalued in today’s dollars. FEMA's event names aren't always consistent, and claims not tied to a named storm are grouped under a generic label. The 2026 numbers are incomplete, since recent claims are still bei

**What's next**

We could add FEMA's NFIP policies dataset to compare claims to the number of policies, showing losses per policy instead of just totals. We could also add a county-level map, and look at how the NFIP's 2021 pricing change (with Risk Rating 2.0) relates to where losses happen.
