import type {
  PnlRawDataType,
  pnlDataType,
  yearlyDataType,
  PnlSummaryDataType,
  PnlParsedSummaryDataType,
  CurrencyValues,
} from "~/types/pnl";
import {
  computeDataEvolutions,
  formatPnlSummaryData,
  getMetricsByCurrencyByYear,
  groupDataByCountry,
} from "./tools.server";

const computeValuesWithEvolutions = ({
  currency,
  currentYear,
  lastYear,
}: {
  currency: CurrencyValues;
  currentYear: yearlyDataType;
  lastYear: yearlyDataType;
}): Omit<PnlSummaryDataType, "country"> => {
  const currentYearValues = getMetricsByCurrencyByYear(currency, currentYear);
  const lastYearValues = getMetricsByCurrencyByYear(currency, lastYear);
  return {
    ...currentYearValues,
    invoiceUnitsEvo: computeDataEvolutions(
      currentYearValues.invoiceUnitsValue,
      lastYearValues.invoiceUnitsValue
    ),
    grossSalesEvo: computeDataEvolutions(
      currentYearValues.grossSalesValue,
      lastYearValues.grossSalesValue
    ),
    totalMinorationsEvo: computeDataEvolutions(
      currentYearValues.totalMinorationsValue,
      lastYearValues.totalMinorationsValue
    ),
    consoNetSalesEvo: computeDataEvolutions(
      currentYearValues.consoNetSales,
      lastYearValues.consoNetSales
    ),
    grossMarginSalesEvo: computeDataEvolutions(
      currentYearValues.grossMarginSales,
      lastYearValues.grossMarginSales
    ),
  };
};

export const generatePnlSummaryTableData = (
  data: {
    rawData: PnlRawDataType[];
    currentYear: number;
  },
  filters: { currency: CurrencyValues }
): PnlParsedSummaryDataType[] => {
  const groupedData = groupDataByCountry(data);
  const pnLData: PnlSummaryDataType[] = Object.keys(groupedData).reduce(
    (acc: PnlSummaryDataType[], key: string) => {
      const currentEntry = groupedData[key as keyof pnlDataType];
      if (
        currentEntry.currentYear !== undefined &&
        currentEntry.lastYear !== undefined
      ) {
        acc.push({
          country: key,
          ...computeValuesWithEvolutions({
            currency: filters.currency,
            currentYear: currentEntry.currentYear,
            lastYear: currentEntry.lastYear,
          }),
        });
      }
      return acc;
    },
    []
  );
  return formatPnlSummaryData(pnLData);
};
