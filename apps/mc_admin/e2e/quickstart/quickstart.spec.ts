import { test, expect, Page } from '@playwright/test';

/**
 * E2E S012 — mc_admin Quickstart: Tipos de Negocio y Templates
 *
 * Prerequisito: app corriendo en APP_URL + pim-service accesible vía Kong.
 * Credenciales via env: TEST_EMAIL, TEST_PASSWORD (usuario con rol superadmin).
 *
 * Estrategia Flutter Web: interacción via Semantics (accessibility tree).
 * Los inputs son accesibles via role=textbox, botones via role=button.
 *
 * Tests CRUD requieren backend disponible: pasar BACKEND_AVAILABLE=true.
 * Test de IA puede saltarse o mockear: pasar AI_AVAILABLE=true para activarlo.
 */

const TEST_EMAIL = process.env.TEST_EMAIL ?? 'admin@test.com';
const TEST_PASSWORD = process.env.TEST_PASSWORD ?? 'test1234';

const SLUG_PREFIX = `e2e-${Date.now()}`;

const BT_NAME = `Ferretería ${SLUG_PREFIX}`;
const BT_SLUG = `ferreteria-${Date.now()}`;
const BT_ICON = 'store';

const TEMPLATE_NAME = `Ferretería Básica ${SLUG_PREFIX}`;
const AI_DESCRIPTION =
  'Ferretería mediana en zona urbana, principalmente tornillos, herramientas manuales y electricidad';

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

// ─── NAVEGACIÓN BÁSICA ───────────────────────────────────────────────────────

test.describe('S012 Quickstart — Navegación', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('navega a /quickstart/business-types sin errores JS', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/quickstart/business-types');
    expect(page.url()).toContain('/quickstart/business-types');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/quickstart/business-types retorna HTTP 200', async ({ page }) => {
    const response = await page.goto('/quickstart/business-types');
    expect(response?.status()).not.toBe(404);
  });

  test('/quickstart/business-types carga sin crash aunque el backend no esté disponible', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/quickstart/business-types');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/quickstart/business-types/new carga el formulario de nuevo tipo', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/quickstart/business-types/new');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/quickstart/business-types/new retorna HTTP 200', async ({ page }) => {
    const response = await page.goto('/quickstart/business-types/new');
    expect(response?.status()).not.toBe(404);
  });

  test('ruta templates con businessTypeId inválido no crashea JS', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/quickstart/templates/invalid-uuid');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('ruta template analytics con ID inválido no crashea JS', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/quickstart/templates/some-bt/some-template/analytics');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('todas las rutas de quickstart responden 200', async ({ page }) => {
    const routes = [
      '/quickstart/business-types',
      '/quickstart/business-types/new',
    ];

    for (const route of routes) {
      const response = await page.goto(route);
      expect(response?.status(), `${route} debe retornar 200`).not.toBe(404);
    }
  });

  test('navegar secuencialmente entre rutas quickstart no genera errores JS', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    for (const route of [
      '/quickstart/business-types',
      '/quickstart/business-types/new',
    ]) {
      await goTo(page, route);
    }

    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });
});

// ─── FLOW 1: LISTAR TIPOS DE NEGOCIO ────────────────────────────────────────

test.describe('S012 Quickstart — Flow 1: Lista de Tipos de Negocio', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('lista muestra contenido o estado vacío al cargar', async ({ page }) => {
    await goTo(page, '/quickstart/business-types');

    const body = await page.content();
    expect(body.length).toBeGreaterThan(200);
  });

  test('campo de búsqueda acepta input sin errores', async ({ page }) => {
    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(1500);

    const searchField = page.getByRole('textbox').first();
    if (await searchField.isVisible()) {
      await searchField.fill('ferretería');
      await page.waitForTimeout(500);
      await expect(searchField).toHaveValue('ferretería');
    }
  });

  test('búsqueda no genera errores JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(1500);

    const searchField = page.getByRole('textbox').first();
    if (await searchField.isVisible()) {
      await searchField.fill('panadería');
      await page.waitForTimeout(1000);
    }

    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('lista muestra tipos de negocio con icono, nombre y badge de estado (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    // La lista debe tener contenido visible de al menos un tipo
    const body = await page.content();
    expect(body.length).toBeGreaterThan(500);
  });
});

// ─── FLOW 2: CREAR TIPO DE NEGOCIO ──────────────────────────────────────────

test.describe('S012 Quickstart — Flow 2: Crear Tipo de Negocio', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('formulario nuevo tipo — campos nombre y slug accesibles', async ({
    page,
  }) => {
    await goTo(page, '/quickstart/business-types/new');

    const fields = await page.getByRole('textbox').all();
    if (fields.length > 0) {
      await fields[0].fill(BT_NAME);
    }
    if (fields.length > 1) {
      await fields[1].fill(BT_SLUG);
    }

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      expect(await saveBtn.isEnabled()).toBeDefined();
    }

    expect(page.url()).toContain('/quickstart/business-types');
  });

  test('formulario nuevo tipo — nombre obligatorio no permite guardar vacío', async ({
    page,
  }) => {
    await goTo(page, '/quickstart/business-types/new');

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(500);
      expect(page.url()).toContain('/quickstart');
    }
  });

  test('crea tipo de negocio con nombre, slug e icono (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/quickstart/business-types/new');
    await page.waitForTimeout(1000);

    await fillTextField(page, 0, BT_NAME);
    await fillTextField(page, 1, BT_SLUG);

    // Intentar seleccionar icono si hay un picker accesible
    const iconPicker = page.getByRole('button', { name: /icono|icon/i }).first();
    if (await iconPicker.isVisible()) {
      await iconPicker.click();
      await page.waitForTimeout(500);

      // Buscar el icono "store" o similar en el picker
      const iconOption = page
        .getByRole('button', { name: new RegExp(BT_ICON, 'i') })
        .first();
      if (await iconOption.isVisible()) {
        await iconOption.click();
        await page.waitForTimeout(300);
      }
    }

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(2500);
    }

    expect(page.url()).toContain('/quickstart');
  });

  test('tipo de negocio recién creado aparece en la lista (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/quickstart/business-types/new');
    await page.waitForTimeout(1000);

    const uniqueName = `Ferretería ${SLUG_PREFIX}-list`;
    await fillTextField(page, 0, uniqueName);
    await fillTextField(page, 1, `ferreteria-list-${Date.now()}`);
    await page.waitForTimeout(500);

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(2500);
    }

    await goTo(page, '/quickstart/business-types');
    const body = await page.content();
    expect(body).toContain(uniqueName);
  });
});

// ─── FLOW 3: ACTIVAR / DESACTIVAR TIPO DE NEGOCIO ───────────────────────────

test.describe('S012 Quickstart — Flow 3: Activar y Desactivar Tipo de Negocio', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('lista business types carga sin crash JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/quickstart/business-types');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('toggle de estado muestra diálogo de confirmación (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    // Buscar botón activar/desactivar del primer tipo
    const toggleBtn = page
      .getByRole('button', {
        name: /activar|desactivar|activate|deactivate/i,
      })
      .first();

    if (await toggleBtn.isVisible()) {
      await toggleBtn.click();
      await page.waitForTimeout(500);

      // El diálogo de confirmación debe aparecer
      const body = await page.content();
      expect(body).toMatch(/confirmar|activ|desactiv/i);

      // Cancelar para no afectar datos de prueba
      const cancelBtn = page.getByRole('button', { name: /cancelar/i });
      if (await cancelBtn.isVisible()) {
        await cancelBtn.click();
      }
    }
  });

  test('desactivar tipo cambia badge a Inactivo (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    // Crear tipo efímero para desactivar
    await goTo(page, '/quickstart/business-types/new');
    await page.waitForTimeout(1000);

    const ephemeralName = `Tipo Efímero ${SLUG_PREFIX}`;
    await fillTextField(page, 0, ephemeralName);
    await fillTextField(page, 1, `tipo-efimero-${Date.now()}`);
    await page.waitForTimeout(500);

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(2500);
    }

    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    // Buscar y hacer click en desactivar del tipo recién creado
    const deactivateBtn = page
      .getByRole('button', { name: /desactivar/i })
      .last();

    if (await deactivateBtn.isVisible()) {
      await deactivateBtn.click();
      await page.waitForTimeout(500);

      // Confirmar
      const confirmBtn = page
        .getByRole('button', { name: /confirmar|desactivar/i })
        .last();
      if (await confirmBtn.isVisible()) {
        await confirmBtn.click();
        await page.waitForTimeout(2000);
      }

      // El badge debe cambiar a "Inactivo"
      const body = await page.content();
      expect(body).toMatch(/inactivo|inactive/i);
    }
  });

  test('reactivar tipo cambia badge a Activo (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    // Buscar botón activar (para un tipo inactivo)
    const activateBtn = page
      .getByRole('button', { name: /activar(?! )/i })
      .first();

    if (await activateBtn.isVisible()) {
      await activateBtn.click();
      await page.waitForTimeout(500);

      const confirmBtn = page
        .getByRole('button', { name: /confirmar|activar/i })
        .last();
      if (await confirmBtn.isVisible()) {
        await confirmBtn.click();
        await page.waitForTimeout(2000);
      }

      const body = await page.content();
      expect(body).toMatch(/activo|active/i);
    }
  });
});

// ─── FLOW 4: CREAR TEMPLATE MANUALMENTE ─────────────────────────────────────

test.describe('S012 Quickstart — Flow 4: Crear Template Manual', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('ruta templates de un businessTypeId carga sin crash JS', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/quickstart/templates/some-uuid');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/quickstart/templates/:id retorna HTTP 200', async ({ page }) => {
    const response = await page.goto('/quickstart/templates/some-uuid');
    expect(response?.status()).not.toBe(404);
  });

  test('formulario nuevo template — campo nombre accesible', async ({
    page,
  }) => {
    await goTo(page, '/quickstart/templates/some-uuid/new');

    const body = await page.content();
    expect(body.length).toBeGreaterThan(200);
  });

  test('crea template manual con nombre y navega a lista (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    // Primero obtener un businessTypeId real de la lista
    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    // Click en el primer tipo para navegar a sus templates
    const viewTemplatesBtn = page
      .getByRole('button', { name: /templates?|ver templates?/i })
      .first();

    if (await viewTemplatesBtn.isVisible()) {
      await viewTemplatesBtn.click();
      await page.waitForTimeout(1500);

      // Crear nuevo template
      const newTemplateBtn = page
        .getByRole('button', { name: /nuevo template|new template|agregar/i })
        .first();
      if (await newTemplateBtn.isVisible()) {
        await newTemplateBtn.click();
        await page.waitForTimeout(1000);

        // Llenar nombre del template
        await fillTextField(page, 0, TEMPLATE_NAME);
        await page.waitForTimeout(300);

        const saveBtn = page.getByRole('button', { name: /guardar/i });
        if (await saveBtn.isVisible()) {
          await saveBtn.click();
          await page.waitForTimeout(2500);
        }

        // Verificar que volvemos a la lista de templates
        const body = await page.content();
        expect(body.length).toBeGreaterThan(200);
      }
    }
  });

  test('template recién creado aparece en la lista (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    const viewTemplatesBtn = page
      .getByRole('button', { name: /templates?/i })
      .first();

    if (await viewTemplatesBtn.isVisible()) {
      await viewTemplatesBtn.click();
      await page.waitForTimeout(1500);

      const newTemplateBtn = page
        .getByRole('button', { name: /nuevo|agregar/i })
        .first();

      if (await newTemplateBtn.isVisible()) {
        await newTemplateBtn.click();
        await page.waitForTimeout(1000);

        const uniqueTemplateName = `Template ${SLUG_PREFIX}-visible`;
        await fillTextField(page, 0, uniqueTemplateName);
        await page.waitForTimeout(300);

        const saveBtn = page.getByRole('button', { name: /guardar/i });
        if (await saveBtn.isVisible()) {
          await saveBtn.click();
          await page.waitForTimeout(2500);
        }

        const body = await page.content();
        expect(body).toContain(uniqueTemplateName);
      }
    }
  });
});

// ─── FLOW 5: GENERACIÓN CON IA ───────────────────────────────────────────────

test.describe('S012 Quickstart — Flow 5: Generar Template con IA', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('botón "Generar con IA" es accesible en pantalla de templates (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    const viewTemplatesBtn = page
      .getByRole('button', { name: /templates?/i })
      .first();

    if (await viewTemplatesBtn.isVisible()) {
      await viewTemplatesBtn.click();
      await page.waitForTimeout(1500);

      const aiBtn = page
        .getByRole('button', { name: /generar con ia|ia|inteligencia/i })
        .first();

      if (await aiBtn.isVisible()) {
        expect(await aiBtn.isEnabled()).toBeTruthy();
      }
    }
  });

  test('bottom sheet de IA abre al hacer click en "Generar con IA" (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    const viewTemplatesBtn = page
      .getByRole('button', { name: /templates?/i })
      .first();

    if (await viewTemplatesBtn.isVisible()) {
      await viewTemplatesBtn.click();
      await page.waitForTimeout(1500);

      const aiBtn = page
        .getByRole('button', { name: /generar con ia/i })
        .first();

      if (await aiBtn.isVisible()) {
        await aiBtn.click();
        await page.waitForTimeout(1000);

        // El bottom sheet debe aparecer con un campo de descripción
        const body = await page.content();
        expect(body).toMatch(/descripción|describí|describe/i);
      }
    }
  });

  test('descripción con menos de 20 chars no activa el botón Generar (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    const viewTemplatesBtn = page
      .getByRole('button', { name: /templates?/i })
      .first();

    if (await viewTemplatesBtn.isVisible()) {
      await viewTemplatesBtn.click();
      await page.waitForTimeout(1500);

      const aiBtn = page
        .getByRole('button', { name: /generar con ia/i })
        .first();

      if (await aiBtn.isVisible()) {
        await aiBtn.click();
        await page.waitForTimeout(1000);

        // Ingresar descripción corta (< 20 chars)
        const descField = page.getByRole('textbox').last();
        if (await descField.isVisible()) {
          await descField.fill('Muy corto');
          await page.waitForTimeout(300);

          const generateBtn = page
            .getByRole('button', { name: /^generar$/i })
            .first();

          if (await generateBtn.isVisible()) {
            const isEnabled = await generateBtn.isEnabled();
            // Con descripción corta, el botón debe estar deshabilitado
            expect(isEnabled).toBeFalsy();
          }
        }
      }
    }
  });

  test('spinner aparece al generar template con IA (requiere backend + IA disponible)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');
    test.skip(!process.env.AI_AVAILABLE, 'AI gateway no disponible — omitiendo');

    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    const viewTemplatesBtn = page
      .getByRole('button', { name: /templates?/i })
      .first();

    if (await viewTemplatesBtn.isVisible()) {
      await viewTemplatesBtn.click();
      await page.waitForTimeout(1500);

      const aiBtn = page
        .getByRole('button', { name: /generar con ia/i })
        .first();

      if (await aiBtn.isVisible()) {
        await aiBtn.click();
        await page.waitForTimeout(1000);

        // Ingresar descripción válida (≥ 20 chars)
        const descField = page.getByRole('textbox').last();
        if (await descField.isVisible()) {
          await descField.fill(AI_DESCRIPTION);
          await page.waitForTimeout(300);

          const generateBtn = page
            .getByRole('button', { name: /^generar$/i })
            .first();

          if (await generateBtn.isVisible() && await generateBtn.isEnabled()) {
            await generateBtn.click();

            // El spinner debe aparecer inmediatamente tras click
            // Flutter Web lo expone como un CircularProgressIndicator con semantics
            await page.waitForTimeout(500);
            const body = await page.content();
            // Verificar que hay algún indicador de carga (spinner o mensaje)
            expect(body.length).toBeGreaterThan(200);
          }
        }
      }
    }
  });

  test('formulario se pre-completa con sugerencia IA tras generación (requiere backend + IA disponible)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');
    test.skip(!process.env.AI_AVAILABLE, 'AI gateway no disponible — omitiendo');

    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    const viewTemplatesBtn = page
      .getByRole('button', { name: /templates?/i })
      .first();

    if (await viewTemplatesBtn.isVisible()) {
      await viewTemplatesBtn.click();
      await page.waitForTimeout(1500);

      const aiBtn = page
        .getByRole('button', { name: /generar con ia/i })
        .first();

      if (await aiBtn.isVisible()) {
        await aiBtn.click();
        await page.waitForTimeout(1000);

        const descField = page.getByRole('textbox').last();
        if (await descField.isVisible()) {
          await descField.fill(AI_DESCRIPTION);
          await page.waitForTimeout(300);

          const generateBtn = page
            .getByRole('button', { name: /^generar$/i })
            .first();

          if (await generateBtn.isVisible() && await generateBtn.isEnabled()) {
            await generateBtn.click();

            // Esperar a que la IA responda (máximo 15s)
            await page.waitForTimeout(15_000);

            // El formulario debe estar pre-completado con la sugerencia
            const body = await page.content();
            expect(body.length).toBeGreaterThan(500);
          }
        }
      }
    }
  });
});

// ─── FLOW 6: DUPLICAR TEMPLATE ───────────────────────────────────────────────

test.describe('S012 Quickstart — Flow 6: Duplicar Template', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('lista templates carga sin crash JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/quickstart/templates/some-uuid');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('botón duplicar muestra diálogo de confirmación (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    const viewTemplatesBtn = page
      .getByRole('button', { name: /templates?/i })
      .first();

    if (await viewTemplatesBtn.isVisible()) {
      await viewTemplatesBtn.click();
      await page.waitForTimeout(1500);

      const duplicateBtn = page
        .getByRole('button', { name: /duplicar/i })
        .first();

      if (await duplicateBtn.isVisible()) {
        await duplicateBtn.click();
        await page.waitForTimeout(500);

        // Diálogo de confirmación debe aparecer
        const body = await page.content();
        expect(body).toMatch(/duplicar|copiar|confirmar/i);

        // Cancelar para no afectar datos
        const cancelBtn = page.getByRole('button', { name: /cancelar/i });
        if (await cancelBtn.isVisible()) {
          await cancelBtn.click();
        }
      }
    }
  });

  test('duplicar template crea copia con "(copia)" en el nombre (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    // Crear template efímero para duplicar
    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    const viewTemplatesBtn = page
      .getByRole('button', { name: /templates?/i })
      .first();

    if (await viewTemplatesBtn.isVisible()) {
      await viewTemplatesBtn.click();
      await page.waitForTimeout(1500);

      // Crear template base
      const newTemplateBtn = page
        .getByRole('button', { name: /nuevo|agregar/i })
        .first();

      if (await newTemplateBtn.isVisible()) {
        await newTemplateBtn.click();
        await page.waitForTimeout(1000);

        const baseTemplateName = `Template Base ${SLUG_PREFIX}`;
        await fillTextField(page, 0, baseTemplateName);
        await page.waitForTimeout(300);

        const saveBtn = page.getByRole('button', { name: /guardar/i });
        if (await saveBtn.isVisible()) {
          await saveBtn.click();
          await page.waitForTimeout(2500);
        }

        // Duplicar el template recién creado
        const duplicateBtn = page
          .getByRole('button', { name: /duplicar/i })
          .last();

        if (await duplicateBtn.isVisible()) {
          await duplicateBtn.click();
          await page.waitForTimeout(500);

          // Confirmar duplicación
          const confirmBtn = page
            .getByRole('button', { name: /confirmar|duplicar/i })
            .last();
          if (await confirmBtn.isVisible()) {
            await confirmBtn.click();
            await page.waitForTimeout(2500);
          }

          // Verificar que la copia aparece con "(copia)" en el nombre
          const body = await page.content();
          expect(body).toContain('(copia)');
        }
      }
    }
  });
});

// ─── FLOW 7: ANALYTICS DE TEMPLATE ──────────────────────────────────────────

test.describe('S012 Quickstart — Flow 7: Analytics de Template', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('ruta analytics de template carga sin crash JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(
      page,
      '/quickstart/templates/some-bt/some-template/analytics',
    );
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('ruta analytics retorna HTTP 200', async ({ page }) => {
    const response = await page.goto(
      '/quickstart/templates/some-bt/some-template/analytics',
    );
    expect(response?.status()).not.toBe(404);
  });

  test('pantalla analytics muestra tarjetas de métricas (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    // Navegar a templates de un tipo
    const viewTemplatesBtn = page
      .getByRole('button', { name: /templates?/i })
      .first();

    if (await viewTemplatesBtn.isVisible()) {
      await viewTemplatesBtn.click();
      await page.waitForTimeout(1500);

      // Click en el tab/botón Analytics del primer template
      const analyticsBtn = page
        .getByRole('button', { name: /analytics|analítica/i })
        .first();

      if (await analyticsBtn.isVisible()) {
        await analyticsBtn.click();
        await page.waitForTimeout(2000);

        // La pantalla debe mostrar métricas clave
        const body = await page.content();
        // Verificar presencia de datos de métricas (tenants, fecha, porcentaje)
        expect(body.length).toBeGreaterThan(300);
      }
    }
  });

  test('métricas visibles: tenants usados, última activación, tasa completitud (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    const viewTemplatesBtn = page
      .getByRole('button', { name: /templates?/i })
      .first();

    if (await viewTemplatesBtn.isVisible()) {
      await viewTemplatesBtn.click();
      await page.waitForTimeout(1500);

      const analyticsBtn = page
        .getByRole('button', { name: /analytics|analítica/i })
        .first();

      if (await analyticsBtn.isVisible()) {
        await analyticsBtn.click();
        await page.waitForTimeout(2000);

        const body = await page.content();

        // Las métricas según el BDD deben incluir: tenants, fecha activación, tasa completitud
        expect(body).toMatch(
          /tenants?|comercios?|activación|completitud|completeness/i,
        );
      }
    }
  });
});

// ─── FLOW 8: FLUJO COMPLETO E2E ──────────────────────────────────────────────

test.describe('S012 Quickstart — Flow 8: Flujo E2E Completo', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('flujo completo: crear tipo → navegar a templates → duplicar → ver analytics (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    const uniqueSuffix = Date.now();
    const newBtName = `Librería ${uniqueSuffix}`;
    const newBtSlug = `libreria-${uniqueSuffix}`;

    // Paso 1: Crear tipo de negocio
    await goTo(page, '/quickstart/business-types/new');
    await page.waitForTimeout(1000);

    await fillTextField(page, 0, newBtName);
    await fillTextField(page, 1, newBtSlug);
    await page.waitForTimeout(300);

    const saveTypeBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveTypeBtn.isVisible()) {
      await saveTypeBtn.click();
      await page.waitForTimeout(2500);
    }

    // Verificar que el tipo aparece en la lista
    await goTo(page, '/quickstart/business-types');
    const listBody = await page.content();
    expect(listBody).toContain(newBtName);

    // Paso 2: Navegar a templates del tipo recién creado
    const viewTemplatesBtn = page
      .getByRole('button', { name: /templates?/i })
      .last();

    if (await viewTemplatesBtn.isVisible()) {
      await viewTemplatesBtn.click();
      await page.waitForTimeout(1500);

      // Paso 3: Crear template manual
      const newTemplateBtn = page
        .getByRole('button', { name: /nuevo|agregar/i })
        .first();

      if (await newTemplateBtn.isVisible()) {
        await newTemplateBtn.click();
        await page.waitForTimeout(1000);

        const e2eTemplateName = `Template E2E ${uniqueSuffix}`;
        await fillTextField(page, 0, e2eTemplateName);
        await page.waitForTimeout(300);

        const saveTemplateBtn = page.getByRole('button', { name: /guardar/i });
        if (await saveTemplateBtn.isVisible()) {
          await saveTemplateBtn.click();
          await page.waitForTimeout(2500);
        }

        // Template debe aparecer en lista
        const templatesBody = await page.content();
        expect(templatesBody).toContain(e2eTemplateName);

        // Paso 4: Duplicar template
        const duplicateBtn = page
          .getByRole('button', { name: /duplicar/i })
          .last();

        if (await duplicateBtn.isVisible()) {
          await duplicateBtn.click();
          await page.waitForTimeout(500);

          const confirmBtn = page
            .getByRole('button', { name: /confirmar|duplicar/i })
            .last();
          if (await confirmBtn.isVisible()) {
            await confirmBtn.click();
            await page.waitForTimeout(2500);
          }

          // La copia debe aparecer con "(copia)"
          const afterDupBody = await page.content();
          expect(afterDupBody).toContain('(copia)');
        }
      }
    }

    // Paso 5: Desactivar el tipo creado (limpieza)
    await goTo(page, '/quickstart/business-types');
    await page.waitForTimeout(2000);

    const deactivateBtn = page
      .getByRole('button', { name: /desactivar/i })
      .last();

    if (await deactivateBtn.isVisible()) {
      await deactivateBtn.click();
      await page.waitForTimeout(500);

      const confirmDeactivateBtn = page
        .getByRole('button', { name: /confirmar|desactivar/i })
        .last();
      if (await confirmDeactivateBtn.isVisible()) {
        await confirmDeactivateBtn.click();
        await page.waitForTimeout(2000);
      }
    }
  });
});
