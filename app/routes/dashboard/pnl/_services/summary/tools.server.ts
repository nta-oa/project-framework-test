import numeral from "numeral";

import { CurrencyValues } from "~/types/pnl";
import type {
  ComputedValuesType,
  pnlDataType,
  PnlRawDataType,
  yearlyDataType,
  PnlSummaryDataType,
} from "~/types/pnl";

const groupDataByCountry = ({
  rawData,
  currentYear,
}: {
  rawData: PnlRawDataType[];
  currentYear: number;
}) => {
  return rawData.reduce((group, product) => {
    const { Country, Year, ...entry } = product;

    const currentEntry =
      currentYear === Year ? { currentYear: entry } : { lastYear: entry };

    group[Country as keyof pnlDataType] = Object.assign(
      currentEntry,
      group[Country as keyof pnlDataType] ?? {}
    );
    return group;
  }, {} as pnlDataType);
};
const getMinorations = ({
  cost,
  gross,
  promo,
}: {
  gross: number;
  cost: number;
  promo: number;
}): { totalMinorationsValue: number } => {
  const net = gross - cost;
  return {
    totalMinorationsValue: (net && promo) !== 0 ? (promo - net) / net : 0,
  };
};
const getNetGrossMargin = ({
  cost,
  gross,
}: {
  gross: number;
  cost: number;
}): {
  consoNetSales: number;
  grossMarginSales: number;
} => {
  return {
    consoNetSales: gross - cost,
    grossMarginSales: (gross && cost) !== 0 ? (gross - cost) / gross : 0,
  };
};

const getMetricsByCurrencyByYear = (
  currency: CurrencyValues,
  currentYearParams: yearlyDataType
): ComputedValuesType => {
  if (currency === CurrencyValues.euro) {
    return {
      invoiceUnitsValue: currentYearParams.totalSoldUnits || 0,
      grossSalesValue: currentYearParams.totalSoldValueEUR || 0,
      ...getMinorations({
        gross: currentYearParams.totalSoldValueEUR || 0,
        cost: currentYearParams.totalSalesEuro || 0,
        promo: currentYearParams.totalSoldValueEURPromo || 0,
      }),
      ...getNetGrossMargin({
        gross: currentYearParams.totalSoldValueEUR || 0,
        cost: currentYearParams.totalSalesEuro || 0,
      }),
    };
  } else {
    return {
      invoiceUnitsValue: currentYearParams.totalSoldUnits || 0,
      grossSalesValue: currentYearParams.totalSoldValueLOC || 0,
      ...getMinorations({
        gross: currentYearParams.totalSoldValueLOC || 0,
        cost: currentYearParams.totalSalesLoc || 0,
        promo: currentYearParams.totalSoldValueLOCPromo || 0,
      }),
      ...getNetGrossMargin({
        gross: currentYearParams.totalSoldValueLOC || 0,
        cost: currentYearParams.totalSalesLoc || 0,
      }),
    };
  }
};

const computeDataEvolutions = (
  currentYearValue: number,
  lastYearValue: number
): number => {
  currentYearValue = currentYearValue || 0;
  lastYearValue = lastYearValue || 0;
  return lastYearValue !== 0
    ? (currentYearValue - lastYearValue) / lastYearValue
    : 0;
};

const formatPnlSummaryData = (data: PnlSummaryDataType[]) => {
  return data.map((item) => ({
    country: item.country,
    invoiceUnitsValue: numeral(item.invoiceUnitsValue).format("0.0a"),
    grossSalesValue: numeral(item.grossSalesValue).format("0.0a"),
    totalMinorationsValue: numeral(item.totalMinorationsValue).format("0.00%"),
    consoNetSales: numeral(item.consoNetSales).format("0.0a"),
    grossMarginSales: numeral(item.grossMarginSales).format("0.00%"),
    invoiceUnitsEvo: numeral(item.invoiceUnitsEvo).format("0.00%"),
    grossSalesEvo: numeral(item.grossSalesEvo).format("0.00%"),
    totalMinorationsEvo:
      numeral(item.totalMinorationsEvo).format("0.00") + "pt",
    consoNetSalesEvo: numeral(item.consoNetSalesEvo).format("0.00%"),
    grossMarginSalesEvo:
      numeral(item.grossMarginSalesEvo).format("0.00") + "pt",
  }));
};

export {
  computeDataEvolutions,
  getMetricsByCurrencyByYear,
  groupDataByCountry,
  formatPnlSummaryData,
};
