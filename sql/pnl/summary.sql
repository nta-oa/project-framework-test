SELECT
    SUM(Sold_Units) as totalSoldUnits,
    SUM(Sold_Units_Promo) as totalSoldUnitsPromo,
    SUM(Sold_Value_EUR_Promo) as totalSoldValueEURPromo,
    SUM(Sold_Value_LOC_Promo) as totalSoldValueLOCPromo,
    SUM(Sold_Value_EUR_Promo) / 4 as totalSalesEuro,
    SUM(Sold_Value_LOC_Promo) / 4 as totalSalesLoc,
    SUM(Sold_Value_LOC) as totalSoldValueLOC,
    SUM(Sold_Value_EUR) as totalSoldValueEUR,
    EXTRACT(YEAR FROM DATE_YMD) as Year,
    Country

FROM `{{ projectData }}.rgmgt_ds_c3_finance_eu_np_private.fact_sellout_product_interim`

WHERE true
{% if countries %}
    AND Country IN UNNEST(@countries)
{% endif %}

{% if axis %}
    AND Axis IN UNNEST(@axis)
{% endif %}
{% if subAxis %}
    AND SubAxis IN UNNEST(@subAxis)
{%endif%}
{% if metier %}
    AND Metier IN UNNEST(@metier)
{% endif %}

{% if period == "Year-to-date" %}
    AND (Year = @year OR Year = (@year - 1))
    AND ( EXTRACT(MONTH FROM DATE_YMD) < @month)
{% endif %}

{% if period == "Monthly" %}
    AND (Year = @year OR Year = (@year - 1))
    AND ( EXTRACT(MONTH FROM DATE_YMD) = @month)
{% endif %}

{% if period == "Annual" %}
    AND (Year = @year OR Year = (@year - 1))
{% endif %}

GROUP BY
        Year,
        Country

ORDER BY Country
