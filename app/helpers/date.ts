import { formatWithOptions, millisecondsToSeconds } from "date-fns/fp";
import { enUS, fr } from "date-fns/locale";
import { pipe } from "ramda";
import ms from "ms";

/**
 * A map of locale codes to locale objects.
 */
const locales: Record<string, Locale> = {
  en: enUS,
  fr,
};

/**
 * Formats a date string or Date object using the specified format string and locale.
 *
 * @param date - The date string or Date object to format.
 * @param formatStr - The format string to use.
 * @param [locale="en"] - The locale code to use. Defaults to "en".
 */
export const formatDate = (
  date: string | Date,
  formatStr: string,
  locale = "en"
): string => {
  const finalDate = typeof date === "string" ? new Date(date) : date;

  return formatWithOptions({ locale: locales[locale] }, formatStr)(finalDate);
};

/**
 * Converts a time string in milliseconds to seconds.
 *
 * @param {string} time - The time string ("1h" for 1 hour) to convert.
 * @returns {number} The time in seconds.
 * @example s("2m") // return 120
 *
 */
export const s = pipe(ms, millisecondsToSeconds);
