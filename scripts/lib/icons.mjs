import sharp from "sharp";
import potrace from "potrace";
import nunjucks from "nunjucks";
import fs from "node:fs/promises";
import path from "node:path";
import { promisify } from "node:util";
import { curry } from "ramda";

/*** Private  ***/

const FAVICON = [32, 57, 76, 96, 128, 192, 228];
const APPLE_TOUCH = [120, 152, 167, 180];
const PWA = [48, 72, 96, 128, 144, 152, 192, 384, 512];
const MASK = [512];
const PADDING = 0.3;

const MASK_BG = "#ffffff";

nunjucks.configure(path.resolve("scripts", "templates", "icons", "public"), {
  autoescape: true,
});

async function generatePngIcon(input, size) {
  const output = getIconOutput(size, "png");

  await sharp(input)
    .resize(size, size, {
      fit: sharp.fit.inside,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .ensureAlpha(0)
    .png({ palette: true })
    .toFile(output);

  return {
    src: filePathToHttpPath(output),
    sizes: size + "x" + size,
    type: "image/png",
  };
}

async function generateVector(input, size) {
  const output = getIconOutput(size, "svg");

  const pngBuffer = await sharp(input).resize(size, size).png().toBuffer();
  const svg = await promisify(potrace.trace)(pngBuffer);
  await fs.writeFile(output, svg);

  return {
    src: filePathToHttpPath(output),
    sizes: size + "x" + size,
    type: "image/svg+xml",
  };
}

async function trimLogo(logo) {
  return await sharp(logo).trim().toBuffer();
}

async function padLogo(logo) {
  const instance = sharp(logo);

  const { width } = await instance.metadata();

  if (!width) {
    throw new Error("image has no width");
  }

  return await instance
    .extend({
      left: Math.round(width * (PADDING / 2)),
      right: Math.round(width * (PADDING / 2)),
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .toBuffer();
}

async function toSquare(logo) {
  const instance = sharp(logo);

  const { width, height } = await instance.metadata();

  if (!width || !height) {
    throw new Error("image has no width or height");
  }

  let padding = {};

  if (width > height) {
    const pad = Math.round((width - height) / 2) + 1;
    padding = { top: pad, bottom: pad };
  } else if (width < height) {
    const pad = Math.round((height - width) / 2) + 1;
    padding = { right: pad, left: pad };
  }

  return await instance
    .extend({
      ...padding,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png({ palette: true })
    .toBuffer();
}

function getIconOutput(size, ext) {
  const outFolder = path.resolve("public", "icons");

  return path.join(outFolder, size + "x" + size + "." + ext);
}

function pwaToHtmlLink(rel, pwa) {
  return { href: pwa.src, rel, sizes: pwa.sizes, type: pwa.type };
}

function filePathToHttpPath(filePath) {
  let isInPublic = false;

  return (
    "/static/" +
    filePath
      .split("/")
      .reduce((acc, part) => {
        if (isInPublic) {
          acc.push(part);
        }

        if (part === "public") {
          isInPublic = true;
        }

        return acc;
      }, [])
      .join("/")
  );
}

function addColor(color) {
  return (item) => {
    item.color = color;

    return item;
  };
}

async function getLogo(uri) {
  if (uri.startsWith("http")) {
    const res = await fetch(uri);
    const arrayBuffer = await res.arrayBuffer();

    return Buffer.from(arrayBuffer);
  } else {
    return fs.readFile(uri);
  }
}

/*** PUBLIC API  ***/

export async function generateFavicons(logo) {
  const buffer = await getLogo(logo).then(trimLogo).then(toSquare);

  const icons = await Promise.all(FAVICON.map(curry(generatePngIcon)(buffer)));

  return icons.map(curry(pwaToHtmlLink)("icon"));
}

export async function generatePwaIcons(logo) {
  const buffer = await getLogo(logo)
    .then(trimLogo)
    .then(padLogo)
    .then(toSquare);

  return Promise.all(PWA.map(curry(generatePngIcon)(buffer)));
}

export async function generateAppletouchIcons(logo) {
  const buffer = await getLogo(logo)
    .then(trimLogo)
    .then(padLogo)
    .then(toSquare);

  const icons = await Promise.all(
    APPLE_TOUCH.map(curry(generatePngIcon)(buffer))
  );

  return icons.map(curry(pwaToHtmlLink)("apple-touch-icon"));
}

export async function generateMaskIcons(logo) {
  const buffer = await getLogo(logo)
    .then(trimLogo)
    .then(padLogo)
    .then(toSquare);

  const icons = await Promise.all(MASK.map(curry(generateVector)(buffer)));

  return icons.map(curry(pwaToHtmlLink)("mask-icon")).map(addColor(MASK_BG));
}

export async function generateWebManifest(icons) {
  const appConfig = await fs
    .readFile(path.resolve("package.json"))
    .then(JSON.parse);

  const manifestPath = path.resolve("public", "app.webmanifest");
  const manifestJSON = nunjucks.render("app.webmanifest.twig", {
    ...appConfig,
    icons,
  });

  return fs.writeFile(manifestPath, manifestJSON);
}

export async function generateIconsConfig(htmlLinks, baseUrl) {
  const icons = htmlLinks.map(({ href, ...rest }) => ({
    href: baseUrl + href,
    ...rest,
  }));

  return fs.writeFile(
    path.resolve("config", "icons.json"),
    JSON.stringify(icons, null, 2)
  );
}
