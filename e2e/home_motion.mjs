#!/usr/bin/env node
/**
 * Diagnose jerky motion on the laptop home page.
 * Captures idle frames (hero carousel) and small scroll gestures (header hide).
 */
import { chromium } from '@playwright/test';
import { mkdir, writeFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const BASE_URL = process.env.BASE_URL ?? 'http://127.0.0.1:8081';
const OUT = resolve(__dirname, '../artifacts/home-motion');
const VIEWPORT = { width: 1180, height: 800 };

async function boot(page) {
  await page.goto(BASE_URL, { waitUntil: 'networkidle', timeout: 60_000 });
  await page.waitForFunction(() => !document.getElementById('boot-loader'), {
    timeout: 90_000,
  });
  await page.waitForFunction(
    () => document.title.toLowerCase().includes('moon ridge'),
    { timeout: 60_000 },
  );
  // Skip splash for returning-user timing (~1.6s) + settle
  await page.waitForTimeout(4500);
  await page.evaluate(() => {
    document.querySelector('[aria-label="Enable accessibility"]')?.click();
  });
  await page.waitForTimeout(800);
  await page.getByRole('button', { name: /search by hat type/i }).first().waitFor({
    state: 'visible',
    timeout: 30_000,
  });
}

async function shot(page, name) {
  const path = resolve(OUT, `${name}.png`);
  await page.screenshot({ path });
  console.log('shot', name);
}

async function measureLayout(page, label) {
  return page.evaluate((lbl) => {
    const canvas = document.querySelector('flt-glass-pane') ?? document.body;
    const rect = canvas.getBoundingClientRect();
    return {
      label: lbl,
      scrollY: window.scrollY,
      bodyScrollHeight: document.body.scrollHeight,
      canvasTop: rect.top,
      canvasHeight: rect.height,
      viewportH: window.innerHeight,
    };
  }, label);
}

async function run() {
  await mkdir(OUT, { recursive: true });
  const browser = await chromium.launch({ headless: true, channel: 'chrome' });
  const context = await browser.newContext({ viewport: VIEWPORT });
  const page = await context.newPage();

  await boot(page);
  await shot(page, '00-home-settled');

  const hasChrome = async () =>
    page.getByText(/back to moon ridge/i).first().isVisible().catch(() => false);

  const chromeBefore = await hasChrome();
  console.log('chrome visible before wheel:', chromeBefore);

  const idleSamples = [];
  for (let i = 0; i < 8; i += 1) {
    await page.waitForTimeout(750);
    idleSamples.push(await measureLayout(page, `idle-${i}`));
  }
  await shot(page, '01-after-idle-6s');

  // Small trackpad-like wheel nudges on center of page (hero area)
  const samples = [await measureLayout(page, 'before-scroll')];
  for (let i = 0; i < 6; i += 1) {
    await page.mouse.move(VIEWPORT.width / 2, VIEWPORT.height / 2);
    await page.mouse.wheel(0, 40);
    await page.waitForTimeout(120);
    samples.push(await measureLayout(page, `wheel-down-${i}`));
  }
  await shot(page, '02-after-wheel-down');
  const chromeAfterWheelDown = await hasChrome();
  console.log('chrome visible after wheel down:', chromeAfterWheelDown);

  await page.waitForTimeout(400);
  for (let i = 0; i < 4; i += 1) {
    await page.mouse.wheel(0, -40);
    await page.waitForTimeout(120);
    samples.push(await measureLayout(page, `wheel-up-${i}`));
  }
  await shot(page, '03-after-wheel-up');

  // Scroll inside actions panel (right side)
  await page.mouse.move(VIEWPORT.width * 0.75, VIEWPORT.height * 0.55);
  for (let i = 0; i < 8; i += 1) {
    await page.mouse.wheel(0, 60);
    await page.waitForTimeout(100);
    samples.push(await measureLayout(page, `actions-scroll-${i}`));
  }
  await shot(page, '04-actions-panel-scroll');

  await writeFile(
    resolve(OUT, 'layout-samples.json'),
    JSON.stringify({ viewport: VIEWPORT, idleSamples, scrollSamples: samples }, null, 2),
  );

  // Flag large canvasTop jumps (layout reflow from header hide)
  const tops = samples.map((s) => s.canvasTop);
  const maxJump = Math.max(...tops.map((t, i) => (i ? Math.abs(t - tops[i - 1]) : 0)));
  console.log('max canvasTop jump between wheel samples:', maxJump.toFixed(2), 'px');
  if (maxJump > 2) {
    console.log('LIKELY ISSUE: header hide/show is reflowing layout (canvas shifted)');
  }

  const idleTops = idleSamples.map((s) => s.canvasTop);
  const idleJump = Math.max(
    ...idleTops.map((t, i) => (i ? Math.abs(t - idleTops[i - 1]) : 0)),
  );
  console.log('max canvasTop jump during idle (carousel):', idleJump.toFixed(2), 'px');

  if (!chromeBefore || !chromeAfterWheelDown) {
    console.log('LIKELY ISSUE: home page chrome collapsed on wheel (layout jump)');
  } else {
    console.log('OK: home chrome stayed visible through wheel gestures');
  }

  await context.close();
  await browser.close();
  console.log('done', OUT);
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
