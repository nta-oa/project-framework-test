export const tableHeader = [
  "INVOICED UNITS",
  "GROSS SALES",
  "TOTAL MINORATIONS",
  "CONSO NET SALES",
  "GROSS MARGIN",
];

export const columnArray = [
  {
    Header: "Country",
    accessor: "country",
  },
  {
    Header: "Value",
    accessor: "invoiceUnitsValue",
  },
  {
    Header: "% Evo",
    accessor: "invoiceUnitsEvo",
  },
  {
    Header: "Value",
    accessor: "grossSalesValue",
  },
  {
    Header: "% Evo",
    accessor: "grossSalesEvo",
  },
  {
    Header: "% Sales",
    accessor: "totalMinorationsValue",
  },
  {
    Header: "Δ vs LY",
    accessor: "totalMinorationsEvo",
  },
  {
    Header: "Value",
    accessor: "consoNetSales",
  },
  {
    Header: "% Evo",
    accessor: "consoNetSalesEvo",
  },
  {
    Header: "% Sales",
    accessor: "grossMarginSales",
  },
  {
    Header: "Δ vs LY",
    accessor: "grossMarginSalesEvo",
  },
];
