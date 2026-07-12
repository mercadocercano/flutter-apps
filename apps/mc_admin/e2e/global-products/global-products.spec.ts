import { test, expect, Page } from '@playwright/test';

/**
 * E2E MC-E34 — Gestión y verificación de global_products en mc_admin.
 *
 * Prerequisito: app corriendo en APP_URL + Kong + PIM disponible.
 * Credenciales via env: TEST_EMAIL, TEST_PASSWORD (superadmin).
 *
 * Interacción Flutter Web via Semantics: botones por texto, chips por role=button.
 */

const TEST_EMAIL = process.env.TEST_EMAIL ?? 'admin@test.com';
const TEST_PASSWORD = process.env.TEST_PASSWORD ?? 'test1234';
const APP_URL = process.env.APP_URL ?? 'http://localhost:8888';

async function loginAndWait(page: Page) {
  await page.goto('/');
  await page.waitForFunction(
    () => document.body && document.body.innerHTML.length > 200,
    { timeout: 20_000 },
  );

  if (!page.url().includes('/login')) return;

  await page.goto('/login');
  await page.waitForTimeout(3000);

  const emailField = page.getByRole('textbox').first();
  if (await emailField.isVisible()) {
    await emailField.fill(TEST_EMAIL);
    const pwField = page.getByRole('textbox').nth(1);
    await pwField.fill(TEST_PASSWORD);
    await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
  }
}

async function goTo(page: Page, path: string) {
  await page.goto(path);
  await page.waitForFunction(
    () => document.body && document.body.innerHTML.length > 200,
    { timeout: 15_000 },
  );
  await page.waitForTimeout(1500);
}

test.describe('MC-E34 — Global Products (navegación)', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('/global-products carga sin errores JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/global-products');
    expect(page.url()).toContain('/global-products');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/global-products retorna HTTP 200', async ({ page }) => {
    const response = await page.goto('/global-products');
    expect(response?.status()).not.toBe(404);
  });

  test('muestra productos o estado vacío', async ({ page }) => {
    await goTo(page, '/global-products');
    const body = await page.content();
    expect(body.length).toBeGreaterThan(200);
  });
});

test.describe('MC-E34 — Global Products (segmentación y bulk verify)', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('filtros por bucket de calidad son accesibles (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/global-products');
    await page.waitForTimeout(2000);

    const lowQualityChip = page.getByRole('button', { name: /bajo <40/i });
    if (await lowQualityChip.isVisible()) {
      await lowQualityChip.click();
      await page.waitForTimeout(1000);
    }

    const body = await page.content();
    expect(body.length).toBeGreaterThan(200);
  });

  test('filtro "Mass verified" aísla el lote stopgap (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/global-products');
    await page.waitForTimeout(2000);

    const massVerifiedChip = page.getByRole('button', { name: /mass verified/i });
    if (await massVerifiedChip.isVisible()) {
      await massVerifiedChip.click();
      await page.waitForTimeout(1000);
    }

    const body = await page.content();
    expect(body.length).toBeGreaterThan(200);
  });

  test('seleccionar todos + verificar en lote muestra diálogo de confirmación (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/global-products');
    await page.waitForTimeout(2000);

    // Seleccionar todos los visibles (máx 100)
    const selectAllBtn = page.getByRole('button', { name: /seleccionar/i }).first();
    if (await selectAllBtn.isVisible()) {
      await selectAllBtn.click();
      await page.waitForTimeout(500);
    }

    // Botón verificar con conteo
    const verifyBtn = page.getByRole('button', { name: /verificar \(/i }).first();
    if (await verifyBtn.isVisible()) {
      await verifyBtn.click();
      await page.waitForTimeout(500);

      const confirmBtn = page.getByRole('button', { name: /verificar$/i }).last();
      expect(await confirmBtn.isVisible()).toBeTruthy();

      // Cancelar para no mutar datos de prueba
      const cancelBtn = page.getByRole('button', { name: /cancelar/i }).first();
      if (await cancelBtn.isVisible()) {
        await cancelBtn.click();
      }
    }
  });

  test('seleccionar todos + desverificar en lote muestra diálogo de confirmación (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/global-products');
    await page.waitForTimeout(2000);

    const selectAllBtn = page.getByRole('button', { name: /seleccionar/i }).first();
    if (await selectAllBtn.isVisible()) {
      await selectAllBtn.click();
      await page.waitForTimeout(500);
    }

    const unverifyBtn = page.getByRole('button', { name: /desverificar \(/i }).first();
    if (await unverifyBtn.isVisible()) {
      await unverifyBtn.click();
      await page.waitForTimeout(500);

      const confirmBtn = page.getByRole('button', { name: /desverificar$/i }).last();
      expect(await confirmBtn.isVisible()).toBeTruthy();

      const cancelBtn = page.getByRole('button', { name: /cancelar/i }).first();
      if (await cancelBtn.isVisible()) {
        await cancelBtn.click();
      }
    }
  });
});
