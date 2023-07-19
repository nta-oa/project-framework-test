SELECT
  DISTINCT COUNTRY_CODE AS countryCode,
  COUNTRY AS country,
  REGION_CODE AS zoneCode,
  REGION AS zone
FROM `{{ projectData }}.rgmgt_ds_c3_finance_eu_np.geographic_hierarchy_dim_v4`
WHERE true
  AND REGION_CODE IN UNNEST(@regions)
  AND COUNTRY_CODE IN UNNEST(@countries)
