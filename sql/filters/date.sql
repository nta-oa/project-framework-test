SELECT
  DISTINCT MONTH AS month,
  YEAR AS year
 FROM `{{ projectData }}.rgmgt_ds_c3_finance_eu_np.DIM_Date_Table`
ORDER BY year DESC, month DESC
