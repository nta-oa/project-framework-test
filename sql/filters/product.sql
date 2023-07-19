-- noinspection SqlNoDataSourceInspectionForFile

SELECT
    DISTINCT Signature AS signature,
    Brand_Name AS brand,
    Sub_Brand AS subBrand,
    Product_Name AS productName

FROM `itg-rgmgt-gbl-ww-np.rgmgt_ds_c3_finance_eu_np.plp_dim_sellin_product_hierarchy_productlevel_v1`
