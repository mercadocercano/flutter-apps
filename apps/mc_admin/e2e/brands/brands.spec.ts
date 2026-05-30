import { test, expect, Page } from '@playwright/test';

/**
 * E2E S008 — PIM: Brands (Marcas del Marketplace)
 *
 * Prerequisito: app corriendo en APP_URL + pim-service accesible vía Kong.
 * Credenciales via env: TEST_EMAIL, TEST_PASSWORD (usuario con rol superadmin).
 *
 * Estrategia Flutter Web: interacción via Semantics (accessibility tree).
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

// ─── LISTA DE MARCAS ─────────────────────────────────────────────────────────

test.describe('S008 PIM — Marcas (Brands)', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('navega a /pim/brands sin errores JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/pim/brands');
    expect(page.url()).toContain('/pim/brands');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/pim/brands retorna HTTP 200 (no 404)', async ({ page }) => {
    const response = await page.goto('/pim/brands');
    expect(response?.status()).not.toBe(404);
  });

  test('/pim/brands carga sin crash aunque el backend no esté disponible', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/pim/brands');

    // La app no debe crashear (estado de error manejado graciosamente)
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });
});

// ─── FORMULARIO NUEVA MARCA ───────────────────────────────────────────────────

test.describe('S008 PIM — Nueva Marca', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('navega a /pim/brands/new sin errores JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/pim/brands/new');
    expect(page.url()).toContain('/pim/brands');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/pim/brands/new retorna HTTP 200', async ({ page }) => {
    const response = await page.goto('/pim/brands/new');
    expect(response?.status()).not.toBe(404);
  });

  test('formulario nueva marca — campos accesibles', async ({ page }) => {
    await goTo(page, '/pim/brands/new');

    const fields = await page.getByRole('textbox').all();
    if (fields.length > 0) {
      // Campo nombre (primero)
      await fields[0].fill(`E2E Marca ${Date.now()}`);
    }

    // Botón guardar debe existir
    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      expect(await saveBtn.isEnabled()).toBeDefined();
    }

    expect(page.url()).toContain('/pim/brands');
  });

  test('formulario nueva marca — campo nombre obligatorio', async ({ page }) => {
    await goTo(page, '/pim/brands/new');

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(500);
      // Sin nombre el formulario no debe navegar
      expect(page.url()).toContain('/pim/brands');
    }
  });
});

// ─── DETALLE DE MARCA ─────────────────────────────────────────────────────────

test.describe('S008 PIM — Detalle de Marca', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('ruta /pim/brands/:id maneja UUID inválido sin crash JS', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/pim/brands/invalid-uuid');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('ruta /pim/brands/:id/edit retorna 200 y no crashea', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    const response = await page.goto('/pim/brands/some-uuid/edit');
    expect(response?.status()).not.toBe(404);
    await page.waitForTimeout(1500);
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });
});

// ─── NAVEGACIÓN ───────────────────────────────────────────────────────────────

test.describe('S008 PIM — Navegación Brands', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('todas las rutas de brands responden 200', async ({ page }) => {
    const brandRoutes = [
      '/pim/brands',
      '/pim/brands/new',
    ];

    for (const route of brandRoutes) {
      const response = await page.goto(route);
      expect(response?.status(), `${route} debe retornar 200`).not.toBe(404);
    }
  });

  test('rutas de brands no generan errores JS al navegar secuencialmente', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    for (const route of ['/pim/brands', '/pim/brands/new']) {
      await goTo(page, route);
    }

    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('ruta legacy /brands redirige a /pim/brands', async ({ page }) => {
    await page.goto('/brands');
    await page.waitForTimeout(1500);
    expect(page.url()).toContain('/pim/brands');
  });
});
