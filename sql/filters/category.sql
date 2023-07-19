SELECT
  DISTINCT Axis AS axis,
  Sub_Axis AS subAxis,
  Metier AS metier,
  Sub_Metier AS subMetier

FROM `{{ projectData }}.rgmgt_ds_c3_finance_eu_np.plp_dim_sellin_product_hierarchy_productlevel_v1`

WHERE true
{% if divisions %}
  AND Division IN UNNEST(@divisions)
{% endif %}
