#!/usr/bin/env node
/**
 * CLI for driving Hat Finder in real Chrome via Playwright.
 *
 * Examples:
 *   node drive.mjs screenshot --out ../artifacts/home.png
 *   node drive.mjs snapshot
 *   node drive.mjs click "Search by Hat Type"
 *   node drive.mjs open --headed
 */
import { chromium } from '@playwright/test';
import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const DEFAULT_URL = process.env.BASE_URL ?? 'http://127.0.0.1:8080';
const FLUTTER_BOOT_MS = Number(process.env.FLUTTER_BOOT_MS ?? 8000);

function parseArgs(argv) {
  const positional = [];
  const flags = {};
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg.startsWith('--')) {
      const key = arg.slice(2);
      const next = argv[i + 1];
      if (next && !next.startsWith('--')) {
        flags[key] = next;
        i += 1;
      } else {
        flags[key] = true;
      }
    } else {
      positional.push(arg);
    }
  }
  return { positional, flags };
}

async function launchBrowser({ headed = false }) {
  const useSystemChrome = process.env.USE_SYSTEM_CHROME === '1';
  return chromium.launch({
    headless: !headed,
    ...(useSystemChrome ? { channel: 'chrome' } : {}),
  });
}

/** Flutter web hides semantics until the placeholder is activated. */
async function enableFlutterAccessibility(page) {
  await page.evaluate(() => {
    document.querySelector('[aria-label="Enable accessibility"]')?.click();
  });
  await page.waitForTimeout(1000);
}

async function waitForFlutter(page, { waitMs = FLUTTER_BOOT_MS } = {}) {
  await page.waitForFunction(
    () => document.title.toLowerCase().includes('moon ridge'),
    { timeout: 60_000 },
  );
  await page.waitForTimeout(waitMs);
  await enableFlutterAccessibility(page);
}

async function openPage(browser, url, options = {}) {
  const context = await browser.newContext({
    viewport: { width: 1440, height: 900 },
  });
  const page = await context.newPage();
  await page.goto(url, { waitUntil: 'networkidle', timeout: 60_000 });
  await waitForFlutter(page, options);
  return { context, page };
}

async function cmdScreenshot(flags) {
  const url = flags.url ?? DEFAULT_URL;
  const out = resolve(__dirname, flags.out ?? '../artifacts/playwright-screenshot.png');
  const browser = await launchBrowser({ headed: Boolean(flags.headed) });
  try {
    const { context, page } = await openPage(browser, url, {
      waitMs: Number(flags.wait ?? FLUTTER_BOOT_MS),
    });
    await mkdir(dirname(out), { recursive: true });
    await page.screenshot({
      path: out,
      fullPage: Boolean(flags.full),
    });
    console.log(out);
    await context.close();
  } finally {
    await browser.close();
  }
}

async function cmdSnapshot(flags) {
  const url = flags.url ?? DEFAULT_URL;
  const out = flags.out ? resolve(__dirname, flags.out) : null;
  const browser = await launchBrowser({ headed: false });
  try {
    const { context, page } = await openPage(browser, url);
    const snapshot = await page.accessibility.snapshot({ interestingOnly: false });
    const text = JSON.stringify(snapshot, null, 2);
    if (out) {
      await mkdir(dirname(out), { recursive: true });
      await writeFile(out, text, 'utf8');
      console.log(out);
    } else {
      console.log(text);
    }
    await context.close();
  } finally {
    await browser.close();
  }
}

async function cmdClick(flags, target) {
  if (!target) throw new Error('Usage: drive.mjs click "<label or selector>"');
  const url = flags.url ?? DEFAULT_URL;
  const browser = await launchBrowser({ headed: Boolean(flags.headed) });
  try {
    const { context, page } = await openPage(browser, url);
    const locator = target.startsWith('#') || target.startsWith('.')
      ? page.locator(target)
      : page.getByRole('button', { name: new RegExp(target, 'i') }).or(
          page.getByText(new RegExp(target, 'i')),
        );
    await locator.first().click({ timeout: 20_000 });
    await page.waitForTimeout(Number(flags.wait ?? 2000));
    if (flags.out) {
      const out = resolve(__dirname, flags.out);
      await mkdir(dirname(out), { recursive: true });
      await page.screenshot({ path: out, fullPage: Boolean(flags.full) });
      console.log(out);
    }
    await context.close();
  } finally {
    await browser.close();
  }
}

async function cmdOpen(flags) {
  const url = flags.url ?? DEFAULT_URL;
  const browser = await launchBrowser({ headed: true });
  const { context, page } = await openPage(browser, url);
  console.log(`Opened ${url} in Chrome. Press Ctrl+C to close.`);
  process.on('SIGINT', async () => {
    await context.close();
    await browser.close();
    process.exit(0);
  });
  await page.waitForTimeout(Number.MAX_SAFE_INTEGER);
}

async function main() {
  const { positional, flags } = parseArgs(process.argv.slice(2));
  const command = positional[0] ?? 'help';

  switch (command) {
    case 'screenshot':
      await cmdScreenshot(flags);
      break;
    case 'snapshot':
      await cmdSnapshot(flags);
      break;
    case 'click':
      await cmdClick(flags, positional[1]);
      break;
    case 'open':
      await cmdOpen(flags);
      break;
    default:
      console.log(`Hat Finder Playwright driver

Commands:
  screenshot [--out path] [--url url] [--headed] [--full] [--wait ms]
  snapshot   [--out path] [--url url]
  click      "<text>" [--url url] [--headed] [--out path]
  open       [--url url]   Keep a headed Chrome window open

Env:
  BASE_URL=http://127.0.0.1:8080
  FLUTTER_BOOT_MS=8000
  USE_SYSTEM_CHROME=1      Use installed Google Chrome instead of bundled Chromium
`);
  }
}

main().catch((err) => {
  console.error(err.message ?? err);
  process.exit(1);
});
