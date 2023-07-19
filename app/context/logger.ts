/* eslint-disable no-console */
import type { Reducer } from "react";
import { useCallback } from "react";

const getCurrentTimeFormatted = () => {
  const currentTime = new Date();
  const hours = currentTime.getHours();
  const minutes = currentTime.getMinutes();
  const seconds = currentTime.getSeconds();
  const milliseconds = currentTime.getMilliseconds();
  return `${hours}:${minutes}:${seconds}.${milliseconds}`;
};

const logger = <S>(
  reducer: Reducer<S, any>,
  prefix = "Action",
  color = "lightgreen"
) => {
  // eslint-disable-next-line react-hooks/rules-of-hooks
  return useCallback(
    (state: S, action: any) => {
      const next = reducer(state, action);

      if (window.env.NODE_ENV === "development") {
        console.groupCollapsed(
          `%c${prefix}: %c${action.type} %cat ${getCurrentTimeFormatted()}`,
          `color: ${color}; font-weight: bold;`,
          "color: #00A7F7; font-weight: bold;",
          "color: lightblue; font-weight: lighter;"
        );
        console.log(
          "%cPrevious State:",
          "color: #9E9E9E; font-weight: 700;",
          state
        );
        console.log("%cAction:", "color: #00A7F7; font-weight: 700;", action);
        console.log("%cNext State:", "color: #47B04B; font-weight: 700;", next);
        console.groupEnd();
      }

      return next;
    },

    [color, prefix, reducer]
  );
};

export default logger;
