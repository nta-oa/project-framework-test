import { z } from "zod";
import { json } from "@remix-run/node";
import { Table } from "@c4e-lib/ui/";
import { useLoaderData } from "@remix-run/react";
import { Card, CardBody } from "@chakra-ui/react";

import type { RemixFunction } from "~/types/context";
import type { PnlParsedSummaryDataType } from "~/types/pnl";
import {
  PnlParsedSummaryDataSchema,
  CurrencyValues,
  pnlDataSchema,
} from "~/types/pnl";
import { columnArray } from "./data";
import { generatePnlSummaryTableData } from "./_services/summary/logic.server";
import SummarySubHeader from "./_components/summary-subheader";
import KpiValue from "./_components/kpi-value";

export const loader: RemixFunction = async ({
  context: { data, cache },
  request,
}) => {
  const cached = await cache.get(
    request.url,
    z.array(PnlParsedSummaryDataSchema)
  );

  if (cached) {
    return json(cached);
  } else {
    const [pnlData] = await Promise.all([
      data.query({
        queryName: "pnl/summary.sql",
        schema: pnlDataSchema,
        params: {
          year: 2023,
          period: "Yearly",
        },
      }),
    ]);

    const compiledPnlData = generatePnlSummaryTableData(
      { rawData: pnlData, currentYear: 2023 },
      { currency: CurrencyValues.euro }
    );

    await cache.set(
      request.url,
      compiledPnlData,
      "1d",
      z.array(PnlParsedSummaryDataSchema)
    );

    return json(compiledPnlData);
  }
};

export default function PnlSummary() {
  const data = useLoaderData<PnlParsedSummaryDataType[]>();

  const styledData = data.map(
    ({
      totalMinorationsEvo,
      grossMarginSalesEvo,
      invoiceUnitsEvo,
      grossSalesEvo,
      consoNetSalesEvo,
      ...rest
    }) => ({
      totalMinorationsEvo: <KpiValue type="pt" value={totalMinorationsEvo} />,
      grossMarginSalesEvo: <KpiValue type="pt" value={grossMarginSalesEvo} />,
      invoiceUnitsEvo: <KpiValue type="percent" value={grossMarginSalesEvo} />,
      grossSalesEvo: <KpiValue type="percent" value={grossSalesEvo} />,
      consoNetSalesEvo: <KpiValue type="percent" value={consoNetSalesEvo} />,
      ...rest,
    })
  );

  return (
    <Card>
      <CardBody overflow="auto">
        <Table
          data={styledData}
          columns={columnArray}
          subHeader={SummarySubHeader}
          style={{
            borderSpacing: "1px",
            borderCollapse: "separate",
          }}
        />
      </CardBody>
    </Card>
  );
}
