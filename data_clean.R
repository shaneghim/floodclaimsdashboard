library(arrow)
library(readr)
library(dplyr)

keep <- c("id", "dateOfLoss", "yearOfLoss", "state", "countyCode", "ratedFloodZone",
          "occupancyType", "primaryResidenceIndicator", "elevatedBuildingIndicator",
          "waterDepth", "floodEvent", "causeOfDamage", "buildingDamageAmount",
          "contentsDamageAmount", "netBuildingPaymentAmount", "netContentsPaymentAmount",
          "netIccPaymentAmount", "totalBuildingInsuranceCoverage", "policyCount")


claims <- read_parquet("C:/Users/ghims/Downloads/floodclaims_sql/NfipClaimsV3.parquet", 
col_select = all_of(keep)) %>%
mutate(across(everything(), as.character))

nrow(claims)
head(claims)
