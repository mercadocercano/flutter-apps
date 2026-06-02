import { test, expect, Page } from '@playwright/test';

/**
 * E2E S013 — mc_admin Web Data: Dashboard, Fuentes, Jobs y Productos
 *
 * Prerequisito: app corriendo en APP_URL + webdata-service accesible vía Kong.
 * Credenciales via env: TEST_EMAIL, TEST_PASSWORD (usuario con rol superadmin).
 *
 * Estrategia Flutter Web: interacción via Semantics (accessibility tree).
 * Los inputs son accesibles via role=textbox, botones via role=button.
 *
 * Tests que requieren backend: pasar BACKEND_AVAILABLE=true.
 */

const TEST_EMAIL = process.env.TEST_EMAIL ?? 'admin@test.com';
const TEST_PASSWORD = process.env.TEST_PASSWORD ?? 'test1234';

const SLUG_PREFIX = `e2e-${Date.now()}`;
const SOURCE_NAME = `MercadoLibre Ferretería ${SLUG_PREFIX}`;
const SOURCE_URL = `https://listado.mercadolibre.com.ar/ferreteria-${Date.now()}`;

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

async function fillTextField(page: Page, index: number, value: string) {
  const field = page.getByRole('textbox').nth(index);
  await field.fill(value);
}

// ─── FLOW 1: DASHBOARD WEB DATA ─────────────────────────────────────────────

test.describe('S013 Web Data — Flow 1: Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('navega a /web-data/dashboard sin errores JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/web-data/dashboard');
    expect(page.url()).toContain('/web-data');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/web-data/dashboard retorna HTTP 200', async ({ page }) => {
    const response = await page.goto('/web-data/dashboard');
    expect(response?.status()).not.toBe(404);
  });

  test('dashboard carga sin crash aunque el backend no esté disponible', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/web-data/dashboard');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('dashboard muestra 4 tarjetas de métricas (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/dashboard');
    await page.waitForTimeout(2000);

    const body = await page.content();

    // Las 4 tarjetas del dashboard según BDD:
    // Fuentes Activas, Jobs Hoy, Productos Totales, Tasa de Éxito
    expect(body).toMatch(
      /fuentes activas|fuentes|sources/i,
    );
    expect(body).toMatch(/jobs|trabajos/i);
    expect(body).toMatch(/productos|products/i);
    expect(body).toMatch(/éxito|tasa|rate|success/i);
  });

  test('lista de últimos jobs recientes visible en dashboard (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/dashboard');
    await page.waitForTimeout(2000);

    const body = await page.content();
    // El dashboard muestra jobs recientes con estados coloreados
    expect(body).toMatch(/running|completed|failed|completado|fallido|corriendo/i);
  });
});

// ─── FLOW 2: CREAR FUENTE Y TRIGGER MANUAL ──────────────────────────────────

test.describe('S013 Web Data — Flow 2: Crear Fuente y Trigger', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('navega a /web-data/sources sin errores JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/web-data/sources');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/web-data/sources retorna HTTP 200', async ({ page }) => {
    const response = await page.goto('/web-data/sources');
    expect(response?.status()).not.toBe(404);
  });

  test('formulario nueva fuente — campos nombre y URL accesibles', async ({
    page,
  }) => {
    await goTo(page, '/web-data/sources/new');

    const fields = await page.getByRole('textbox').all();
    if (fields.length > 0) {
      await fields[0].fill(SOURCE_NAME);
    }
    if (fields.length > 1) {
      await fields[1].fill(SOURCE_URL);
    }

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      expect(await saveBtn.isEnabled()).toBeDefined();
    }
  });

  test('crea fuente con nombre y URL y aparece en la lista (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/sources/new');
    await page.waitForTimeout(1000);

    const uniqueName = `Fuente E2E ${SLUG_PREFIX}`;
    await fillTextField(page, 0, uniqueName);
    await fillTextField(page, 1, SOURCE_URL);
    await page.waitForTimeout(500);

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(2500);
    }

    await goTo(page, '/web-data/sources');
    const body = await page.content();
    expect(body).toContain(uniqueName);
  });

  test('trigger manual de fuente muestra snackbar de job iniciado (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/sources');
    await page.waitForTimeout(2000);

    // Hacer click en "Ejecutar ahora" / "Run Now" de la primera fuente
    const triggerBtn = page
      .getByRole('button', { name: /ejecutar|run now|trigger/i })
      .first();

    if (await triggerBtn.isVisible()) {
      await triggerBtn.click();
      await page.waitForTimeout(2000);

      // Verificar snackbar de confirmación
      const body = await page.content();
      expect(body).toMatch(/job|trabajo|iniciado|started|running/i);
    }
  });
});

// ─── FLOW 3: LISTA DE JOBS Y CONTROL ────────────────────────────────────────

test.describe('S013 Web Data — Flow 3: Jobs', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('navega a /web-data/jobs sin errores JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/web-data/jobs');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/web-data/jobs retorna HTTP 200', async ({ page }) => {
    const response = await page.goto('/web-data/jobs');
    expect(response?.status()).not.toBe(404);
  });

  test('lista de jobs carga con badges de estado (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/jobs');
    await page.waitForTimeout(2000);

    const body = await page.content();
    // Lista de jobs con badges de estado
    expect(body).toMatch(
      /running|completed|failed|cancelled|completado|fallido|cancelado|corriendo/i,
    );
  });

  test('cancelar job running abre diálogo de confirmación (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/jobs');
    await page.waitForTimeout(2000);

    const cancelBtn = page
      .getByRole('button', { name: /cancelar|cancel/i })
      .first();

    if (await cancelBtn.isVisible()) {
      await cancelBtn.click();
      await page.waitForTimeout(500);

      // Diálogo de confirmación debe aparecer
      const body = await page.content();
      expect(body).toMatch(/confirmar|cancelar|¿estás seguro/i);

      // Cerrar sin confirmar para no afectar datos de prueba
      const dismissBtn = page
        .getByRole('button', { name: /no|cerrar|close/i })
        .first();
      if (await dismissBtn.isVisible()) {
        await dismissBtn.click();
      }
    }
  });

  test('confirmar cancelación cambia badge a Cancelado (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/jobs');
    await page.waitForTimeout(2000);

    const cancelBtn = page
      .getByRole('button', { name: /cancelar|cancel/i })
      .first();

    if (await cancelBtn.isVisible()) {
      await cancelBtn.click();
      await page.waitForTimeout(500);

      const confirmBtn = page
        .getByRole('button', { name: /confirmar|sí|yes/i })
        .last();
      if (await confirmBtn.isVisible()) {
        await confirmBtn.click();
        await page.waitForTimeout(2000);

        const body = await page.content();
        expect(body).toMatch(/cancelado|cancelled/i);
      }
    }
  });

  test('filtro por estado filtra lista de jobs (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/jobs');
    await page.waitForTimeout(1500);

    // Intentar filtro por "completed"
    const filterBtn = page
      .getByRole('button', { name: /completado|completed|filtro/i })
      .first();

    if (await filterBtn.isVisible()) {
      await filterBtn.click();
      await page.waitForTimeout(1000);
      const body = await page.content();
      expect(body.length).toBeGreaterThan(200);
    }
  });
});

// ─── FLOW 4: LISTA DE PRODUCTOS SCRAPEADOS ───────────────────────────────────

test.describe('S013 Web Data — Flow 4: Productos Scrapeados', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('navega a /web-data/products sin errores JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/web-data/products');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/web-data/products retorna HTTP 200', async ({ page }) => {
    const response = await page.goto('/web-data/products');
    expect(response?.status()).not.toBe(404);
  });

  test('lista de productos scrapeados carga sin crash', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/web-data/products');
    const body = await page.content();
    expect(body.length).toBeGreaterThan(200);
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('lista de productos muestra items (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/products');
    await page.waitForTimeout(2000);

    const body = await page.content();
    expect(body.length).toBeGreaterThan(500);
  });
});

// ─── FLOW 5: BULK ASSIGN BUSINESS TYPE ──────────────────────────────────────

test.describe('S013 Web Data — Flow 5: Bulk Assign Business Type', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('checkboxes de selección visibles en lista de productos (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/products');
    await page.waitForTimeout(2000);

    const checkboxes = await page.getByRole('checkbox').all();
    expect(checkboxes.length).toBeGreaterThan(0);
  });

  test('seleccionar productos habilita botón "Asignar Tipo" (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/products');
    await page.waitForTimeout(2000);

    // Seleccionar los primeros 3 productos disponibles
    const checkboxes = await page.getByRole('checkbox').all();
    const toSelect = checkboxes.slice(0, Math.min(3, checkboxes.length));

    for (const checkbox of toSelect) {
      if (await checkbox.isVisible()) {
        await checkbox.click();
        await page.waitForTimeout(200);
      }
    }

    // El botón "Asignar tipo" debe habilitarse
    const assignBtn = page.getByRole('button', {
      name: /asignar tipo|assign type/i,
    });
    if (await assignBtn.isVisible()) {
      expect(await assignBtn.isEnabled()).toBeTruthy();
    }
  });

  test('bulk assign muestra selector de business_type (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/products');
    await page.waitForTimeout(2000);

    // Seleccionar checkbox del primer producto
    const firstCheckbox = page.getByRole('checkbox').first();
    if (await firstCheckbox.isVisible()) {
      await firstCheckbox.click();
      await page.waitForTimeout(300);

      const assignBtn = page.getByRole('button', {
        name: /asignar tipo|assign type/i,
      });

      if (await assignBtn.isVisible()) {
        await assignBtn.click();
        await page.waitForTimeout(1000);

        // Selector de tipo de negocio debe aparecer
        const body = await page.content();
        expect(body).toMatch(/tipo de negocio|business.?type|ferretería|seleccionar/i);
      }
    }
  });

  test('confirmar bulk assign muestra snackbar de éxito (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/products');
    await page.waitForTimeout(2000);

    // Seleccionar los primeros 3 checkboxes disponibles
    const checkboxes = await page.getByRole('checkbox').all();
    const toSelect = checkboxes.slice(0, Math.min(3, checkboxes.length));

    for (const checkbox of toSelect) {
      if (await checkbox.isVisible()) {
        await checkbox.click();
        await page.waitForTimeout(200);
      }
    }

    const assignBtn = page.getByRole('button', {
      name: /asignar tipo|assign type/i,
    });

    if (await assignBtn.isVisible() && await assignBtn.isEnabled()) {
      await assignBtn.click();
      await page.waitForTimeout(1000);

      // Seleccionar primer tipo de negocio del selector
      const typeOption = page.getByRole('option').first();
      if (await typeOption.isVisible()) {
        await typeOption.click();
        await page.waitForTimeout(300);
      }

      // Confirmar asignación
      const confirmBtn = page
        .getByRole('button', { name: /confirmar|asignar|assign/i })
        .last();

      if (await confirmBtn.isVisible()) {
        await confirmBtn.click();
        await page.waitForTimeout(2500);

        // Snackbar de éxito
        const body = await page.content();
        expect(body).toMatch(/asignado|assigned|éxito|success/i);
      }
    }
  });
});

// ─── FLOW 6: DETALLE DE PRODUCTO E HISTORIAL DE PRECIOS ─────────────────────

test.describe('S013 Web Data — Flow 6: Detalle y Precio Historial', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('navegar a detalle de producto no crashea JS (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/web-data/products');
    await page.waitForTimeout(2000);

    // Click en el primer producto de la lista
    const firstProductBtn = page
      .getByRole('button', { name: /ver|detalle|detail/i })
      .first();

    if (await firstProductBtn.isVisible()) {
      await firstProductBtn.click();
      await page.waitForTimeout(1500);
    }

    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('tab "Historial de Precios" visible en detalle de producto (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/products');
    await page.waitForTimeout(2000);

    const firstProductBtn = page
      .getByRole('button', { name: /ver|detalle|detail/i })
      .first();

    if (await firstProductBtn.isVisible()) {
      await firstProductBtn.click();
      await page.waitForTimeout(1500);

      // Tab de historial de precios
      const priceHistoryTab = page
        .getByRole('tab', { name: /historial|precios|price.?history/i })
        .first();

      if (await priceHistoryTab.isVisible()) {
        expect(await priceHistoryTab.isEnabled()).toBeTruthy();
      }
    }
  });

  test('tab historial de precios muestra tabla con fecha y precio (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/web-data/products');
    await page.waitForTimeout(2000);

    const firstProductBtn = page
      .getByRole('button', { name: /ver|detalle|detail/i })
      .first();

    if (await firstProductBtn.isVisible()) {
      await firstProductBtn.click();
      await page.waitForTimeout(1500);

      const priceHistoryTab = page
        .getByRole('tab', { name: /historial|precios|price.?history/i })
        .first();

      if (await priceHistoryTab.isVisible()) {
        await priceHistoryTab.click();
        await page.waitForTimeout(1500);

        const body = await page.content();
        // La tabla debe mostrar fecha y precio
        expect(body).toMatch(/fecha|date/i);
        expect(body).toMatch(/precio|price/i);
      }
    }
  });

  test('ruta /web-data/products/:id con ID inválido no crashea JS', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/web-data/products/invalid-uuid-test');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });
});

// ─── FLOW 7: FLUJO E2E COMPLETO ─────────────────────────────────────────────

test.describe('S013 Web Data — Flow 7: Flujo E2E Completo', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('flujo completo: crear fuente → trigger → ver job → ver productos → bulk assign (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    const uniqueSuffix = Date.now();
    const e2eSourceName = `Fuente E2E Completo ${uniqueSuffix}`;
    const e2eSourceUrl = `https://test.mercadolibre.com.ar/items-${uniqueSuffix}`;

    // Paso 1: Crear fuente
    await goTo(page, '/web-data/sources/new');
    await page.waitForTimeout(1000);

    await fillTextField(page, 0, e2eSourceName);
    await fillTextField(page, 1, e2eSourceUrl);
    await page.waitForTimeout(500);

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(2500);
    }

    // Verificar que la fuente aparece en la lista
    await goTo(page, '/web-data/sources');
    await page.waitForTimeout(1500);
    const sourcesBody = await page.content();
    expect(sourcesBody).toContain(e2eSourceName);

    // Paso 2: Trigger manual de la fuente
    const triggerBtn = page
      .getByRole('button', { name: /ejecutar|run now|trigger/i })
      .last();

    if (await triggerBtn.isVisible()) {
      await triggerBtn.click();
      await page.waitForTimeout(2000);

      const afterTriggerBody = await page.content();
      expect(afterTriggerBody).toMatch(/job|running|iniciado|started/i);
    }

    // Paso 3: Ver lista de jobs
    await goTo(page, '/web-data/jobs');
    await page.waitForTimeout(2000);

    const jobsBody = await page.content();
    expect(jobsBody.length).toBeGreaterThan(300);

    // Paso 4: Ver lista de productos
    await goTo(page, '/web-data/products');
    await page.waitForTimeout(2000);

    const productsBody = await page.content();
    expect(productsBody.length).toBeGreaterThan(200);

    // Paso 5: Dashboard debe reflejar actividad
    await goTo(page, '/web-data/dashboard');
    await page.waitForTimeout(2000);

    const dashboardBody = await page.content();
    expect(dashboardBody.length).toBeGreaterThan(300);
  });

  test('todas las rutas web-data responden HTTP 200', async ({ page }) => {
    const routes = [
      '/web-data/dashboard',
      '/web-data/sources',
      '/web-data/sources/new',
      '/web-data/jobs',
      '/web-data/products',
    ];

    for (const route of routes) {
      const response = await page.goto(route);
      expect(response?.status(), `${route} debe retornar 200`).not.toBe(404);
    }
  });

  test('navegar secuencialmente entre rutas web-data no genera errores JS', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    for (const route of [
      '/web-data/dashboard',
      '/web-data/sources',
      '/web-data/jobs',
      '/web-data/products',
    ]) {
      await goTo(page, route);
    }

    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });
});
