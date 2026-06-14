#!/usr/bin/env node
import { chromium } from '@playwright/test';
import { mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const BASE_URL = process.env.BASE_URL ?? 'http://127.0.0.1:8081';
const OUT = resolve(__dirname, '../artifacts/spacing');
const BOOT_MS = Number(process.env.FLUTTER_BOOT_MS ?? 9000);

const VIEWPORTS = [
  { name: 'laptop', width: 1180, height: 800 },
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
    const b = page.getByRole('button', { name: rx }).first();
    await b.waitFor({ state: 'visible', timeout: 3000 });
    await b.click({ timeout: 8000 });
    await page.waitForTimeout(900);
    return true;
  } catch {}
  try { await page.getByText(rx).first().click({ timeout: 6000 }); await page.waitForTimeout(900); return true; } catch { return false; }
}
async function navVisible(page) {
  try { return await page.getByText(/back to moon ridge/i).first().isVisible(); } catch { return false; }
}
async function shot(page, name) {
  const out = resolve(OUT, `${name}.png`);
  await mkdir(dirname(out), { recursive: true });
  await page.screenshot({ path: out });
  console.log('shot', name, 'nav=', await navVisible(page));
}

const browser = await chromium.launch({ headless: true, channel: process.env.USE_SYSTEM_CHROME === '1' ? 'chrome' : undefined });
for (const vp of VIEWPORTS) {
  const context = await browser.newContext({ viewport: vp, deviceScaleFactor: 1 });
  const page = await context.newPage();
  try {
    await boot(page);
    await tap(page, 'search by hat type');
    await page.waitForTimeout(1000);
    await shot(page, `${vp.name}-1-hat-type`);
    await tap(page, 'select this type|^felt$');
    await page.waitForTimeout(900);
    await shot(page, `${vp.name}-2-style`);
    await tap(page, 'select this style|^western$');
    await page.waitForTimeout(1000);
    await shot(page, `${vp.name}-3-crown`);
    await tap(page, 'select this crown');
    await page.waitForTimeout(1000);
    await shot(page, `${vp.name}-4-brim`);
  } catch (e) { console.log(vp.name, 'error', e.message.split('\n')[0]); }
  finally { await context.close(); }
}
await browser.close();
console.log('done', OUT);
