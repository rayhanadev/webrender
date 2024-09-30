import Elysia, { t } from "elysia";
import puppeteer from "puppeteer";

const { PUPPETEER_EXECUTABLE_PATH, RUNNING_IN_DOCKER } = process.env;
const puppeteerArgs = RUNNING_IN_DOCKER
  ? ["--no-sandbox", "--disable-setuid-sandbox"]
  : [];

const app = new Elysia();

app.get("/", (ctx) => {
  return "Hello World!";
});

app.get(
  "/api/render",
  async (ctx) => {
    const { url, fullPage } = ctx.query;

    const browser = await puppeteer.launch({
      args: puppeteerArgs,
      executablePath: PUPPETEER_EXECUTABLE_PATH ?? undefined,
    });

    const page = await browser.newPage();
    await page.goto(url);

    const image = await page.screenshot({
      fullPage: fullPage === "1",
    });

    await browser.close();

    ctx.set.headers = {
      "Content-Type": "image/png",
      "Content-Length": image.length.toString(),
      "Cache-Control": "max-age=604800",
    };
    return image;
  },
  { query: t.Object({ url: t.String(), fullPage: t.Optional(t.String()) }) }
);

app.listen(3000);
