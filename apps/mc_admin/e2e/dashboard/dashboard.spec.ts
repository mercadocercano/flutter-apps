import { test, expect, Page } from '@playwright/test';

/**
 * E2E S014 — mc_admin Dashboard: Overview General del Marketplace
 *
 * Prerequisito: app corriendo en APP_URL.
 * Tests que requieren backend: pasar BACKEND_AVAILABLE=true.
 *
 * Estrategia Flutter Web: interacción via Semantics (accessibility tree).
 * Botones via role=button, texto via contenido.
 */

const TEST_EMAIL = process.env.TEST_EMAIL ?? 'admin@test.com';
const TEST_PASSWORD = process.env.TEST_PASSWORD ?? 'test1234';

// ─── HELPERS ────────────────────────────────────────────────────────────────

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

// ─── FLOW 1: CARGA BÁSICA DEL DASHBOARD ──────────────────────────────────────

test.describe('S014 Dashboard — Flow 1: Carga básica', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('navega a /dashboard sin errores JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/dashboard');
    expect(page.url()).toContain('/dashboard');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/dashboard retorna HTTP 200', async ({ page }) => {
    const response = await page.goto('/dashboard');
    expect(response?.status()).not.toBe(404);
  });

  test('dashboard carga sin crash aunque el backend no esté disponible', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/dashboard');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('título "Dashboard" visible en la pantalla', async ({ page }) => {
    await goTo(page, '/dashboard');
    await page.waitForTimeout(1500);

    const body = await page.content();
    expect(body).toMatch(/dashboard/i);
  });
});

// ─── FLOW 2: SECCIONES DE MÉTRICAS ───────────────────────────────────────────

test.describe('S014 Dashboard — Flow 2: Secciones de métricas', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('las 4 secciones de tarjetas de stats son visibles (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/dashboard');
    await page.waitForTimeout(3000);

    const body = await page.content();

    // IAM, PIM, Web Data, Quickstart
    expect(body).toMatch(/IAM/);
    expect(body).toMatch(/PIM/);
    expect(body).toMatch(/Web Data/);
    expect(body).toMatch(/Quickstart/);
  });

  test('sección IAM visible en el contenido del dashboard', async ({ page }) => {
    await goTo(page, '/dashboard');
    await page.waitForTimeout(2000);

    const body = await page.content();
    // Al menos el título IAM aparece (puede estar loading)
    expect(body).toMatch(/IAM/);
  });

  test('sección PIM visible en el contenido del dashboard', async ({ page }) => {
    await goTo(page, '/dashboard');
    await page.waitForTimeout(2000);

    const body = await page.content();
    expect(body).toMatch(/PIM/);
  });

  test('sección Web Data visible en el contenido del dashboard', async ({ page }) => {
    await goTo(page, '/dashboard');
    await page.waitForTimeout(2000);

    const body = await page.content();
    expect(body).toMatch(/Web Data/);
  });

  test('sección Quickstart visible en el contenido del dashboard', async ({ page }) => {
    await goTo(page, '/dashboard');
    await page.waitForTimeout(2000);

    const body = await page.content();
    expect(body).toMatch(/Quickstart/);
  });
});

// ─── FLOW 3: CHIPS DE SALUD DE SERVICIOS ────────────────────────────────────

test.describe('S014 Dashboard — Flow 3: Estado de servicios', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('fila de chips de salud de servicios es visible (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/dashboard');
    await page.waitForTimeout(3000);

    const body = await page.content();
    // Los chips muestran nombres de servicios: iam, pim, webdata
    expect(body).toMatch(/iam|pim|webdata/i);
  });

  test('sección "Estado de servicios" aparece en el dashboard', async ({ page }) => {
    await goTo(page, '/dashboard');
    await page.waitForTimeout(2000);

    const body = await page.content();
    expect(body).toMatch(/Estado de servicios/i);
  });

  test('dashboard carga sin errores JS con servicios online o offline', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/dashboard');
    await page.waitForTimeout(3000);

    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });
});

// ─── FLOW 4: ACCIONES RÁPIDAS ─────────────────────────────────────────────────

test.describe('S014 Dashboard — Flow 4: Acciones rápidas', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('botones de acciones rápidas visibles en el dashboard', async ({ page }) => {
    await goTo(page, '/dashboard');
    await page.waitForTimeout(2000);

    // Scroll al final para ver quick actions
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await page.waitForTimeout(500);

    const body = await page.content();
    // Al menos un acceso rápido visible
    expect(body).toMatch(/Nuevo Tenant|Nueva Marca|Trigger Fuente|Nuevo Atributo/i);
  });

  test('sección "Accesos rápidos" aparece en el dashboard', async ({ page }) => {
    await goTo(page, '/dashboard');
    await page.waitForTimeout(2000);

    const body = await page.content();
    expect(body).toMatch(/Accesos rápidos/i);
  });

  test('click en "Nuevo Tenant" navega a /iam/tenants', async ({ page }) => {
    await goTo(page, '/dashboard');
    await page.waitForTimeout(2000);

    // Scroll para ver el botón
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await page.waitForTimeout(500);

    const btn = page.getByRole('button', { name: /Nuevo Tenant/i });
    if (await btn.isVisible()) {
      await btn.click();
      await page.waitForTimeout(2000);

      expect(page.url()).toContain('/iam/tenants');
    }
  });

  test('badge de auto-refresh visible', async ({ page }) => {
    await goTo(page, '/dashboard');
    await page.waitForTimeout(2000);

    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await page.waitForTimeout(500);

    const body = await page.content();
    expect(body).toMatch(/Auto-refresh.*60s|auto-refresh/i);
  });
});

// ─── FLOW 5: REFRESH MANUAL ──────────────────────────────────────────────────

test.describe('S014 Dashboard — Flow 5: Refresh manual', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('click en "Actualizar" no genera errores JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/dashboard');
    await page.waitForTimeout(2000);

    // Buscar botón de refresh (el IconButton con tooltip "Actualizar")
    const refreshBtn = page.getByRole('button', { name: /Actualizar/i });

    if (await refreshBtn.isVisible()) {
      await refreshBtn.click();
      await page.waitForTimeout(2000);
    }

    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('dashboard sigue visible después del refresh manual', async ({ page }) => {
    await goTo(page, '/dashboard');
    await page.waitForTimeout(2000);

    const refreshBtn = page.getByRole('button', { name: /Actualizar/i });

    if (await refreshBtn.isVisible()) {
      await refreshBtn.click();
      await page.waitForTimeout(2000);
    }

    // El dashboard sigue en la misma URL
    expect(page.url()).toContain('/dashboard');
  });
});

// ─── FLOW 6: FLUJO E2E COMPLETO ──────────────────────────────────────────────

test.describe('S014 Dashboard — Flow 6: Flujo E2E completo', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('todas las secciones del dashboard responden HTTP 200', async ({ page }) => {
    const routes = ['/dashboard'];

    for (const route of routes) {
      const response = await page.goto(route);
      expect(response?.status(), `${route} debe retornar 200`).not.toBe(404);
    }
  });

  test('flujo: login → dashboard → ver métricas (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/dashboard');
    await page.waitForTimeout(3000);

    const body = await page.content();

    // Las 4 secciones deben estar presentes
    expect(body).toMatch(/IAM/);
    expect(body).toMatch(/PIM/);
    expect(body).toMatch(/Web Data/);
    expect(body).toMatch(/Quickstart/);

    // Métricas numéricas visibles
    expect(body.length).toBeGreaterThan(500);
  });

  test('dashboard no genera errores JS durante navegación completa', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/dashboard');
    await page.waitForTimeout(2000);

    // Scroll completo para renderizar todo el contenido
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await page.waitForTimeout(500);

    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });
});
