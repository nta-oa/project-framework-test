import { z } from "zod";

export const pnlDataSchema = z.object({
  totalSoldUnits: z.number().nullable(),
  totalSoldUnitsPromo: z.number().nullable(),
  totalSoldValueEURPromo: z.number().nullable(),
  totalSoldValueLOCPromo: z.number().nullable(),
  totalSalesEuro: z.number().nullable(),
  totalSalesLoc: z.number().nullable(),
  totalSoldValueLOC: z.number().nullable(),
  totalSoldValueEUR: z.number().nullable(),
  Year: z.number(),
  Country: z.string(),
});

export const PnlParsedSummaryDataSchema = z.object({
  country: z.string(),
  invoiceUnitsValue: z.string(),
  grossSalesValue: z.string(),
  totalMinorationsValue: z.string(),
  consoNetSales: z.string(),
  grossMarginSales: z.string(),
  invoiceUnitsEvo: z.string(),
  grossSalesEvo: z.string(),
  totalMinorationsEvo: z.string(),
  consoNetSalesEvo: z.string(),
  grossMarginSalesEvo: z.string(),
});

export type PnlParsedSummaryDataType = z.infer<
  typeof PnlParsedSummaryDataSchema
>;
export type PnlSummaryDataType = {
  country: string;
  invoiceUnitsValue: number;
  grossSalesValue: number;
  totalMinorationsValue: number;
  consoNetSales: number;
  grossMarginSales: number;
  invoiceUnitsEvo: number;
  grossSalesEvo: number;
  totalMinorationsEvo: number;
  consoNetSalesEvo: number;
  grossMarginSalesEvo: number;
};
export type ComputedValuesType = Omit<
  PnlSummaryDataType,
  | "country"
  | "invoiceUnitsEvo"
  | "grossSalesEvo"
  | "totalMinorationsEvo"
  | "consoNetSalesEvo"
  | "grossMarginSalesEvo"
>;

export type PnlRawDataType = z.infer<typeof pnlDataSchema>;

export type yearlyDataType = Omit<PnlRawDataType, "Year" | "Country">;

export type pnlDataType = {
  data: {
    currentYear: yearlyDataType;
    lastYear: yearlyDataType;
  };
};

export type DataArrayType = {
  country: string;
  invoiceUnitsValue: number;
  invoiceUnitsEvo: number;
  grossSalesValue: number;
  grossSalesEvo: number;
  totalMinorationsValue: number;
  totalMinorationsEvo: number;
  consoNetSales: number;
  consoNetSalesEvo: number;
  grossMarginSales: number;
  grossMarginSalesEvo: number;
};

export enum CurrencyValues {
  euro = "euro",
  loc = "locale",
}
