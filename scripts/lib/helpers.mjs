import fsP from "node:fs/promises";
import nunjucks from "nunjucks";

export function renderTemplate(src, params, dest) {
  const content = nunjucks.render(src, params);

  return fsP.writeFile(dest, content);
}
