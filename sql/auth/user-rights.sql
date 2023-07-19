SELECT
  UPN AS email,
  COUNTRIES_CODES AS countries,
  DIVISIONS_CODES AS divisions,
  ZONES_CODES AS zones,
FROM `{{ projectData }}.rgmgt_ds_c3_finance_eu_np_identities.identities_rgmgt_flatten_v2`
WHERE true
  AND LOWER(UPN) = LOWER(@email)
