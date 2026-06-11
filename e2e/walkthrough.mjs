#!/usr/bin/env node
/**
 * Deep-dive GUI walkthrough of Hat Finder in real Chrome via Playwright.
 *
 * Captures screenshots of every screen at multiple viewport widths so we can
 * review spacing, alignment, and layout. Flutter renders to canvas, so we
 * enable the semantics tree and drive the UI by accessible label / text.
 *
 *   BASE_URL=http://127.0.0.1:8081 node walkthrough.mjs
 */
import { chromium } from '@playwright/test';
import { mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const BASE_URL = process.env.BASE_URL ?? 'http://127.0.0.1:8081';
const OUT_ROOT = resolve(__dirname, '../artifacts/walkthrough');
const BOOT_MS = Number(process.env.FLUTTER_BOOT_MS ?? 9000);

const VIEWPORTS = [
  { name: 'desktop', width: 1440, height: 900 },
  { name: 'laptop', width: 1180, height: 800 },
  { name: 'mobile', width: 390, height: 844 },
];

function log(...args) {
  console.log('[walkthrough]', ...args);
}

async function enableA11y(page) {
  await page.evaluate(() => {
    document.querySelector('[aria-label="Enable accessibility"]')?.click();
  });
  await page.waitForTimeout(800);
}

async function boot(page) {
  await page.goto(BASE_URL, { waitUntil: 'networkidle', timeout: 60_000 });
  await page.waitForFunction(() => !document.getElementById('boot-loader'), {
    timeout: 90_000,
  });
  await page.waitForFunction(
    () => document.title.toLowerCase().includes('moon ridge'),
    { timeout: 60_000 },
  );
  await page.waitForTimeout(BOOT_MS);
  await enableA11y(page);
}

async function shot(page, dir, name) {
  const out = resolve(OUT_ROOT, dir, `${name}.png`);
  await mkdir(dirname(out), { recursive: true });
  await page.screenshot({ path: out });
  log('shot', `${dir}/${name}.png`);
}

/** Click by accessible name (button role first, then any text). Resilient. */
async function tap(page, pattern, { timeout = 12_000 } = {}) {
  const rx = new RegExp(pattern, 'i');
  const byRole = page.getByRole('button', { name: rx }).first();
  try {
    await byRole.waitFor({ state: 'visible', timeout: 3000 });
    await byRole.click({ timeout });
    await page.waitForTimeout(900);
    return true;
  } catch {
    // fall through
  }
  try {
    const byText = page.getByText(rx).first();
    await byText.click({ timeout });
    await page.waitForTimeout(900);
    return true;
  } catch (err) {
    log('  ! could not tap', pattern, '-', err.message.split('\n')[0]);
    return false;
  }
}

async function run() {
  const browser = await chromium.launch({
    headless: true,
    channel: process.env.USE_SYSTEM_CHROME === '1' ? 'chrome' : undefined,
  });

  for (const vp of VIEWPORTS) {
    log('=== viewport', vp.name, `${vp.width}x${vp.height} ===`);
    const context = await browser.newContext({
      viewport: { width: vp.width, height: vp.height },
      deviceScaleFactor: 1,
    });
    const page = await context.newPage();
    try {
      await boot(page);
      await shot(page, vp.name, '00-home');

      // ── Find Hats wizard ── (carousel uses SELECT THIS …, grid uses card label)
      if (await tap(page, 'search by hat type')) {
        await page.waitForTimeout(1200);
        await shot(page, vp.name, '01-wizard-hat-type');

        if (await tap(page, 'select this type|^felt$')) {
          await page.waitForTimeout(900);
          await shot(page, vp.name, '02-wizard-style');

          if (await tap(page, 'select this style|^western$')) {
            await page.waitForTimeout(1000);
            await shot(page, vp.name, '03-wizard-crown');

            if (await tap(page, 'select this crown')) {
              await page.waitForTimeout(1000);
              await shot(page, vp.name, '04-wizard-brim');

              if (await tap(page, 'select this brim|find hats')) {
                await page.waitForTimeout(2500);
                await shot(page, vp.name, '05-results');
              }
            }
          }
        }
      }

      // ── Head Shape quiz ──
      await boot(page);
      if (await tap(page, 'learn your head shape')) {
        await page.waitForTimeout(1000);
        await shot(page, vp.name, '06-headshape-q1');
        if (await tap(page, 'forehead')) {
          await shot(page, vp.name, '07-headshape-q2');
          if (await tap(page, 'rocks|stable')) {
            await shot(page, vp.name, '08-headshape-q3');
            if (await tap(page, 'size up|usually works')) {
              await page.waitForTimeout(800);
              await shot(page, vp.name, '09-headshape-result');
            }
          }
        }
      }
    } catch (err) {
      log('viewport', vp.name, 'error:', err.message.split('\n')[0]);
    } finally {
      await context.close();
    }
  }

  await browser.close();
  log('done. screenshots in', OUT_ROOT);
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
