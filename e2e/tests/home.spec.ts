import { test, expect, type Page } from '@playwright/test';

async function prepareFlutter(page: Page, path = '/') {
  await page.goto(path, { waitUntil: 'networkidle', timeout: 60_000 });
  await page.waitForFunction(
    () => !document.getElementById('boot-loader'),
    { timeout: 90_000 },
  );
  await page.waitForFunction(
    () => document.title.toLowerCase().includes('moon ridge'),
    { timeout: 60_000 },
  );
  await page.waitForTimeout(8000);
  await page.evaluate(() => {
    document.querySelector('[aria-label="Enable accessibility"]')?.click();
  });
  await page.waitForTimeout(1000);
}

async function waitForHome(page: Page) {
  await expect(
    page.getByRole('button', { name: /search by hat type/i }).first(),
  ).toBeVisible({ timeout: 30_000 });
}

test('home screen loads from local dev server', async ({ page }) => {
  await prepareFlutter(page);
  await waitForHome(page);
  await expect(page.getByRole('button', { name: /learn your head shape/i }).first()).toBeVisible();
});

test('search by hat type opens the wizard', async ({ page }) => {
  await prepareFlutter(page);
  await waitForHome(page);
  await page.getByRole('button', { name: /search by hat type/i }).click();
  await expect(page.getByText(/material|felt|straw|ballcap/i).first()).toBeVisible({
    timeout: 30_000,
  });
});

test('embed mode fills the viewport without store chrome', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  await prepareFlutter(page, '/?embed=1');
  await waitForHome(page);
  await expect(page.getByText(/back to moon ridge/i)).toHaveCount(0);
});

test('standalone desktop uses store chrome without side letterbox', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  await prepareFlutter(page);
  await expect(page.getByText(/moon ridge/i).first()).toBeVisible();
  await waitForHome(page);
});
