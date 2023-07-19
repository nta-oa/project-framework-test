import { Th, Tr } from "@chakra-ui/react";

const SummarySubHeader = (
  <Tr>
    <Th></Th>
    <Th
      bg="table.header.bg"
      color="table.header.link"
      colSpan={2}
      marginX={5}
      textAlign="center"
    >
      Invoiced units
    </Th>
    <Th
      bg="table.header.bg"
      color="table.header.link"
      colSpan={2}
      marginX={5}
      textAlign="center"
    >
      Gross Sales
    </Th>
    <Th
      bg="table.header.bg"
      color="table.header.link"
      colSpan={2}
      marginX={5}
      textAlign="center"
    >
      Total Minorations
    </Th>
    <Th
      bg="table.header.bg"
      color="table.header.link"
      colSpan={2}
      marginX={5}
      textAlign="center"
    >
      Conso Net Sales
    </Th>
    <Th
      bg="table.header.bg"
      color="table.header.link"
      colSpan={2}
      marginX={5}
      textAlign="center"
    >
      Gross Margin
    </Th>
  </Tr>
);

export default SummarySubHeader;
