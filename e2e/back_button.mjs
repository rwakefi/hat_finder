#!/usr/bin/env node
/**
 * Quick check of the discrete top-left back button on the wizard.
 *   BASE_URL=http://127.0.0.1:8081 USE_SYSTEM_CHROME=1 node back_button.mjs
 */
import { chromium } from '@playwright/test';
import { mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const BASE_URL = process.env.BASE_URL ?? 'http://127.0.0.1:8081';
const OUT = resolve(__dirname, '../artifacts/back-button');
const BOOT_MS = Number(process.env.FLUTTER_BOOT_MS ?? 9000);

const VIEWPORTS = [
  { name: 'laptop', width: 1180, height: 800 },
  { name: 'desktop', width: 1440, height: 900 },
];

async function enableA11y(page) {
  await page.evaluate(() => {
    document.querySelector('[aria-label="Enable accessibility"]')?.click();
  });
  await page.waitForTimeout(800);
}

async function boot(page) {
  await page.goto(BASE_URL, { waitUntil: 'networkidle', timeout: 60_000 });
  await page.waitForFunction(() => !document.getElementById('boot-loader'), { timeout: 90_000 });
  await page.waitForFunction(() => document.title.toLowerCase().includes('moon ridge'), { timeout: 60_000 });
  await page.waitForTimeout(BOOT_MS);
  await enableA11y(page);
}

async function tap(page, pattern) {
  const rx = new RegExp(pattern, 'i');
  try {
    const byRole = page.getByRole('button', { name: rx }).first();
    await byRole.waitFor({ state: 'visible', timeout: 3000 });
    await byRole.click({ timeout: 8000 });
    await page.waitForTimeout(900);
    return true;
  } catch {}
  try {
    await page.getByText(rx).first().click({ timeout: 6000 });
    await page.waitForTimeout(900);
    return true;
  } catch (e) {
    console.log('  ! could not tap', pattern);
    return false;
  }
}

async function shot(page, name) {
  const out = resolve(OUT, `${name}.png`);
  await mkdir(dirname(out), { recursive: true });
  await page.screenshot({ path: out });
  console.log('shot', name);
}

const browser = await chromium.launch({
  headless: true,
  channel: process.env.USE_SYSTEM_CHROME === '1' ? 'chrome' : undefined,
});
for (const vp of VIEWPORTS) {
  const context = await browser.newContext({ viewport: vp, deviceScaleFactor: 1 });
  const page = await context.newPage();
  try {
    await boot(page);
    await tap(page, 'search by hat type');
    await page.waitForTimeout(1000);
    await shot(page, `${vp.name}-step1`);
    await tap(page, 'select this type|^felt$');
    await page.waitForTimeout(900);
    await shot(page, `${vp.name}-step2`);
    // Tap the back button via its semantics label.
    await tap(page, '^back$');
    await page.waitForTimeout(900);
    await shot(page, `${vp.name}-after-back`);
  } catch (e) {
    console.log(vp.name, 'error', e.message.split('\n')[0]);
  } finally {
    await context.close();
  }
}
await browser.close();
console.log('done', OUT);
