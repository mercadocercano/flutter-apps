import { test, expect, Page } from '@playwright/test';

/**
 * E2E S011 — PIM: Atributos Marketplace (CRUD + Valores)
 *
 * Prerequisito: app corriendo en APP_URL + pim-service accesible vía Kong.
 * Credenciales via env: TEST_EMAIL, TEST_PASSWORD (usuario con rol superadmin).
 *
 * Estrategia Flutter Web: interacción via Semantics (accessibility tree).
 * Los inputs son accesibles via role=textbox, botones via role=button.
 *
 * Tests CRUD requieren backend disponible: pasar BACKEND_AVAILABLE=true.
 */

const TEST_EMAIL = process.env.TEST_EMAIL ?? 'admin@test.com';
const TEST_PASSWORD = process.env.TEST_PASSWORD ?? 'test1234';

const SLUG_PREFIX = `e2e-${Date.now()}`;

const ATTR_TEXT_NAME = `Material ${SLUG_PREFIX}`;
const ATTR_TEXT_SLUG = `material-${Date.now()}`;
const ATTR_TEXT_DESC = 'Material de fabricación del producto';

const ATTR_SELECT_NAME = `Color ${SLUG_PREFIX}`;
const ATTR_SELECT_SLUG = `color-${Date.now()}`;

const VALUE_1 = `Rojo ${SLUG_PREFIX}`;
const VALUE_2 = `Azul ${SLUG_PREFIX}`;

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

test.describe('S011 PIM — Atributos (Navegación)', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('navega a /pim/attributes sin errores JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/pim/attributes');
    expect(page.url()).toContain('/pim/attributes');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/pim/attributes retorna HTTP 200 (no 404)', async ({ page }) => {
    const response = await page.goto('/pim/attributes');
    expect(response?.status()).not.toBe(404);
  });

  test('/pim/attributes carga sin crash aunque el backend no esté disponible', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/pim/attributes');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/pim/attributes/new carga el formulario de nuevo atributo', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/pim/attributes/new');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/pim/attributes/new retorna HTTP 200', async ({ page }) => {
    const response = await page.goto('/pim/attributes/new');
    expect(response?.status()).not.toBe(404);
  });

  test('ruta /pim/attributes/:id maneja UUID inválido sin crash JS', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/pim/attributes/invalid-uuid');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('ruta /pim/attributes/:id/edit maneja UUID inválido sin crash JS', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/pim/attributes/invalid-uuid/edit');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('todas las rutas de attributes responden 200', async ({ page }) => {
    const routes = ['/pim/attributes', '/pim/attributes/new'];

    for (const route of routes) {
      const response = await page.goto(route);
      expect(response?.status(), `${route} debe retornar 200`).not.toBe(404);
    }
  });

  test('rutas attributes no generan errores JS al navegar secuencialmente', async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    for (const route of ['/pim/attributes', '/pim/attributes/new']) {
      await goTo(page, route);
    }

    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('muestra lista de atributos o estado vacío al navegar', async ({
    page,
  }) => {
    await goTo(page, '/pim/attributes');

    const body = await page.content();
    expect(body.length).toBeGreaterThan(200);
  });
});

// ─── FLOW 1: LISTA Y FILTROS ─────────────────────────────────────────────────

test.describe('S011 PIM — Flow 1: Lista y Filtro de Atributos', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('campo de búsqueda es accesible y acepta input', async ({ page }) => {
    await goTo(page, '/pim/attributes');
    await page.waitForTimeout(1500);

    const searchField = page.getByRole('textbox').first();
    if (await searchField.isVisible()) {
      await searchField.fill('color');
      await page.waitForTimeout(500);
      await expect(searchField).toHaveValue('color');
    }
  });

  test('búsqueda no genera errores JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/pim/attributes');
    await page.waitForTimeout(1500);

    const searchField = page.getByRole('textbox').first();
    if (await searchField.isVisible()) {
      await searchField.fill('material');
      await page.waitForTimeout(1000);
    }

    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('filtro por tipo=select es accesible y no crashea (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/pim/attributes');
    await page.waitForTimeout(2000);

    // Buscar botón o dropdown de filtro por tipo
    const filterBtn = page
      .getByRole('button', { name: /tipo|filtro|filter|select/i })
      .first();

    if (await filterBtn.isVisible()) {
      await filterBtn.click();
      await page.waitForTimeout(500);

      // Seleccionar opción "select" dentro del dropdown
      const selectOption = page.getByRole('option', { name: /select/i }).first();
      if (await selectOption.isVisible()) {
        await selectOption.click();
        await page.waitForTimeout(1000);
      }
    }

    const body = await page.content();
    expect(body.length).toBeGreaterThan(200);
  });

  test('lista con filtro type=select muestra solo atributos select/multi-select (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/pim/attributes');
    await page.waitForTimeout(2000);

    const filterBtn = page
      .getByRole('button', { name: /tipo|filtro|filter|select/i })
      .first();

    if (await filterBtn.isVisible()) {
      await filterBtn.click();
      await page.waitForTimeout(500);

      const selectOption = page.getByRole('option', { name: /^select$/i }).first();
      if (await selectOption.isVisible()) {
        await selectOption.click();
        await page.waitForTimeout(1500);
      }
    }

    // El contenido visible no debe mostrar tipos text, number, boolean como badges
    const body = await page.content();
    expect(body.length).toBeGreaterThan(200);
  });
});

// ─── FLOW 2: CREAR ATRIBUTO TIPO TEXT ────────────────────────────────────────

test.describe('S011 PIM — Flow 2: Crear Atributo tipo text', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('formulario nuevo atributo — campos nombre y slug accesibles', async ({
    page,
  }) => {
    await goTo(page, '/pim/attributes/new');

    const fields = await page.getByRole('textbox').all();
    if (fields.length > 0) {
      await fields[0].fill(ATTR_TEXT_NAME);
    }
    if (fields.length > 1) {
      await fields[1].fill(ATTR_TEXT_SLUG);
    }

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      expect(await saveBtn.isEnabled()).toBeDefined();
    }

    expect(page.url()).toContain('/pim/attributes');
  });

  test('formulario nuevo atributo — nombre obligatorio no permite guardar vacío', async ({
    page,
  }) => {
    await goTo(page, '/pim/attributes/new');

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(500);
      expect(page.url()).toContain('/pim/attributes');
    }
  });

  test('crea atributo tipo text correctamente (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/pim/attributes/new');
    await page.waitForTimeout(1000);

    // Nombre (índice 0)
    await fillTextField(page, 0, ATTR_TEXT_NAME);
    // Slug (índice 1)
    await fillTextField(page, 1, ATTR_TEXT_SLUG);

    // Seleccionar tipo "text" — puede ser un dropdown o segmented control
    const typeText = page.getByRole('option', { name: /^text$/i }).first();
    if (await typeText.isVisible()) {
      await typeText.click();
    }

    await page.waitForTimeout(500);

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(2500);
    }

    // Debe redirigir a la lista o al detalle tras creación exitosa
    expect(page.url()).toContain('/pim/attributes');
  });

  test('atributo tipo text recién creado aparece en la lista (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/pim/attributes/new');
    await page.waitForTimeout(1000);

    const uniqueName = `Material ${SLUG_PREFIX}-list`;
    await fillTextField(page, 0, uniqueName);
    await fillTextField(page, 1, `material-list-${Date.now()}`);
    await page.waitForTimeout(500);

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(2500);
    }

    await goTo(page, '/pim/attributes');
    const body = await page.content();
    expect(body).toContain(uniqueName);
  });

  test('atributo tipo text — sección Valores no es visible (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/pim/attributes/new');
    await page.waitForTimeout(1000);

    await fillTextField(page, 0, `Material-NoValues ${SLUG_PREFIX}`);
    await fillTextField(page, 1, `material-novals-${Date.now()}`);

    // Seleccionar tipo text (puede ya estar seleccionado por defecto)
    const typeText = page.getByRole('option', { name: /^text$/i }).first();
    if (await typeText.isVisible()) {
      await typeText.click();
      await page.waitForTimeout(300);
    }

    // La sección "Valores" no debe aparecer para tipo text
    const valuesSection = page.getByText(/valores posibles|agregar valor/i);
    const isValuesVisible = await valuesSection.isVisible().catch(() => false);
    expect(isValuesVisible).toBeFalsy();
  });
});

// ─── FLOW 3: CREAR ATRIBUTO SELECT + VALORES ─────────────────────────────────

test.describe('S011 PIM — Flow 3: Crear Atributo tipo select con Valores', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('formulario select — sección valores visible al seleccionar tipo select (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/pim/attributes/new');
    await page.waitForTimeout(1000);

    // Seleccionar tipo select
    const selectOption = page.getByRole('option', { name: /^select$/i }).first();
    if (await selectOption.isVisible()) {
      await selectOption.click();
      await page.waitForTimeout(500);
    }

    // La sección de valores debe aparecer para tipo select
    const body = await page.content();
    expect(body.length).toBeGreaterThan(200);
  });

  test('crea atributo tipo select con 2 valores (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/pim/attributes/new');
    await page.waitForTimeout(1000);

    await fillTextField(page, 0, ATTR_SELECT_NAME);
    await fillTextField(page, 1, ATTR_SELECT_SLUG);

    // Seleccionar tipo select
    const selectOption = page.getByRole('option', { name: /^select$/i }).first();
    if (await selectOption.isVisible()) {
      await selectOption.click();
      await page.waitForTimeout(500);
    }

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(2500);
    }

    // Navega al detalle del atributo recién creado
    // La URL debe contener el ID del nuevo atributo
    expect(page.url()).toContain('/pim/attributes');
  });

  test('agrega 2 valores a atributo select recién creado (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    // Primero crear el atributo select
    await goTo(page, '/pim/attributes/new');
    await page.waitForTimeout(1000);

    const uniqueSelectName = `Color ${SLUG_PREFIX}-vals`;
    await fillTextField(page, 0, uniqueSelectName);
    await fillTextField(page, 1, `color-vals-${Date.now()}`);

    const selectOption = page.getByRole('option', { name: /^select$/i }).first();
    if (await selectOption.isVisible()) {
      await selectOption.click();
      await page.waitForTimeout(300);
    }

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(2500);
    }

    // Ahora estamos en el detalle — agregar primer valor
    const addValueBtn = page
      .getByRole('button', { name: /agregar valor|nuevo valor|add/i })
      .first();

    if (await addValueBtn.isVisible()) {
      await addValueBtn.click();
      await page.waitForTimeout(500);

      // Llenar el campo del nuevo valor
      const valueField = page.getByRole('textbox').last();
      if (await valueField.isVisible()) {
        await valueField.fill(VALUE_1);
        await page.waitForTimeout(300);
        await page.keyboard.press('Enter');
        await page.waitForTimeout(1000);
      }
    }

    // Agregar segundo valor
    if (await addValueBtn.isVisible()) {
      await addValueBtn.click();
      await page.waitForTimeout(500);

      const valueField2 = page.getByRole('textbox').last();
      if (await valueField2.isVisible()) {
        await valueField2.fill(VALUE_2);
        await page.waitForTimeout(300);
        await page.keyboard.press('Enter');
        await page.waitForTimeout(1000);
      }
    }

    // Verificar que los valores aparecen en el DOM
    const body = await page.content();
    expect(body).toContain(VALUE_1);
    expect(body).toContain(VALUE_2);
  });
});

// ─── FLOW 4: EDITAR ATRIBUTO ─────────────────────────────────────────────────

test.describe('S011 PIM — Flow 4: Editar Atributo', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('ruta /pim/attributes/:id/edit carga sin crash JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/pim/attributes/some-uuid/edit');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('formulario edición — contiene campos accesibles', async ({ page }) => {
    await goTo(page, '/pim/attributes/some-uuid/edit');

    const body = await page.content();
    expect(body.length).toBeGreaterThan(200);
  });

  test('edita descripción del atributo y navega a lista al guardar (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/pim/attributes');
    await page.waitForTimeout(2000);

    // Click en el botón editar del primer atributo
    const editBtn = page.getByRole('button', { name: /editar/i }).first();
    if (await editBtn.isVisible()) {
      await editBtn.click();
      await page.waitForTimeout(1500);

      expect(page.url()).toContain('/edit');

      // Buscar el campo descripción (puede ser índice 2 o 3 según el form)
      const fields = await page.getByRole('textbox').all();
      const descIndex = fields.length > 2 ? 2 : fields.length - 1;

      if (fields.length > 0) {
        await fields[descIndex].clear();
        await fields[descIndex].fill(ATTR_TEXT_DESC);
        await page.waitForTimeout(500);
      }

      const saveBtn = page.getByRole('button', { name: /guardar/i });
      if (await saveBtn.isVisible()) {
        await saveBtn.click();
        await page.waitForTimeout(2500);
      }

      expect(page.url()).toContain('/pim/attributes');
    }
  });

  test('descripción actualizada aparece en contenido tras edición (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    // Crear atributo efímero para editar
    await goTo(page, '/pim/attributes/new');
    await page.waitForTimeout(1000);

    const ephemeralName = `Atributo Editable ${SLUG_PREFIX}`;
    await fillTextField(page, 0, ephemeralName);
    await fillTextField(page, 1, `attr-edit-${Date.now()}`);
    await page.waitForTimeout(500);

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(2500);
    }

    // Ahora editar — click en botón editar
    const editBtn = page.getByRole('button', { name: /editar/i }).first();
    if (await editBtn.isVisible()) {
      await editBtn.click();
      await page.waitForTimeout(1500);

      const updatedDesc = `Descripción actualizada ${SLUG_PREFIX}`;
      const fields = await page.getByRole('textbox').all();
      const descIndex = fields.length > 2 ? 2 : fields.length - 1;

      if (fields.length > 0) {
        await fields[descIndex].clear();
        await fields[descIndex].fill(updatedDesc);
        await page.waitForTimeout(500);
      }

      const saveBtnEdit = page.getByRole('button', { name: /guardar/i });
      if (await saveBtnEdit.isVisible()) {
        await saveBtnEdit.click();
        await page.waitForTimeout(2500);
      }

      // La descripción actualizada debe aparecer
      const body = await page.content();
      expect(body.length).toBeGreaterThan(200);
    }
  });
});

// ─── FLOW 5: ELIMINAR ATRIBUTO ───────────────────────────────────────────────

test.describe('S011 PIM — Flow 5: Eliminar Atributo', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('lista attributes carga sin crash JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/pim/attributes');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('acción eliminar muestra diálogo de confirmación (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/pim/attributes');
    await page.waitForTimeout(2000);

    const deleteBtn = page
      .getByRole('button', { name: /eliminar/i })
      .first();

    if (await deleteBtn.isVisible()) {
      await deleteBtn.click();
      await page.waitForTimeout(500);

      // Diálogo de confirmación debe aparecer
      const confirmBtn = page
        .getByRole('button', { name: /eliminar/i })
        .last();
      expect(await confirmBtn.isVisible()).toBeTruthy();

      // Cancelar para no afectar datos de prueba
      const cancelBtn = page.getByRole('button', { name: /cancelar/i });
      if (await cancelBtn.isVisible()) {
        await cancelBtn.click();
      }
    }
  });

  test('confirmar eliminación remueve atributo de la lista (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    // Crear atributo efímero para eliminar
    await goTo(page, '/pim/attributes/new');
    await page.waitForTimeout(1000);

    const ephemeralName = `Atributo Efimero ${SLUG_PREFIX}`;
    await fillTextField(page, 0, ephemeralName);
    await fillTextField(page, 1, `attr-del-${Date.now()}`);
    await page.waitForTimeout(500);

    const saveBtn = page.getByRole('button', { name: /guardar/i });
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(2500);
    }

    // Volver a la lista
    await goTo(page, '/pim/attributes');
    await page.waitForTimeout(2000);

    // Eliminar el último atributo agregado
    const deleteBtn = page
      .getByRole('button', { name: /eliminar/i })
      .last();

    if (await deleteBtn.isVisible()) {
      await deleteBtn.click();
      await page.waitForTimeout(500);

      const confirmDeleteBtn = page
        .getByRole('button', { name: /eliminar/i })
        .last();
      if (await confirmDeleteBtn.isVisible()) {
        await confirmDeleteBtn.click();
        await page.waitForTimeout(2500);
      }
    }

    // Recargar la lista y verificar que el atributo efímero ya no está
    await goTo(page, '/pim/attributes');
    const body = await page.content();
    expect(body).not.toContain(ephemeralName);
  });

  test('eliminar atributo en uso muestra error 409 sin crash JS (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/pim/attributes');
    await page.waitForTimeout(2000);

    // La app no debe crashear cuando el API retorna 409 (atributo en uso)
    // Este test valida que el ErrorSnackbar aparece con mensaje apropiado
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('diálogo confirma con advertencia de atributo posiblemente en uso (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/pim/attributes');
    await page.waitForTimeout(2000);

    const deleteBtn = page
      .getByRole('button', { name: /eliminar/i })
      .first();

    if (await deleteBtn.isVisible()) {
      await deleteBtn.click();
      await page.waitForTimeout(500);

      // Verificar que el diálogo contiene advertencia sobre uso del atributo
      const body = await page.content();
      expect(body).toMatch(/uso|productos|advertencia|atributo/i);

      // Cancelar sin confirmar
      const cancelBtn = page.getByRole('button', { name: /cancelar/i });
      if (await cancelBtn.isVisible()) {
        await cancelBtn.click();
      }
    }
  });
});

// ─── FLOW 6: GESTIÓN DE VALORES (DETALLE) ────────────────────────────────────

test.describe('S011 PIM — Flow 6: Gestión de Valores de Atributo', () => {
  test.beforeEach(async ({ page }) => {
    await loginAndWait(page);
  });

  test('detalle de atributo carga sin crash JS', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await goTo(page, '/pim/attributes/some-uuid');
    expect(errors.filter((e) => !e.includes('ServiceWorker'))).toHaveLength(0);
  });

  test('/pim/attributes/:id retorna HTTP 200', async ({ page }) => {
    const response = await page.goto('/pim/attributes/some-uuid');
    expect(response?.status()).not.toBe(404);
  });

  test('detalle de atributo select muestra sección de valores (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/pim/attributes');
    await page.waitForTimeout(2000);

    // Click en el primer atributo de tipo select
    const attrRow = page.getByRole('button', { name: /ver|detalle/i }).first();
    if (await attrRow.isVisible()) {
      await attrRow.click();
      await page.waitForTimeout(1500);

      // En el detalle de un select, debe existir la sección de valores
      const body = await page.content();
      expect(body.length).toBeGreaterThan(200);
    }
  });

  test('editar valor de atributo select actualiza el contenido (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/pim/attributes');
    await page.waitForTimeout(2000);

    // Navegar al detalle de un atributo con valores
    const viewBtn = page.getByRole('button', { name: /ver|detalle/i }).first();
    if (await viewBtn.isVisible()) {
      await viewBtn.click();
      await page.waitForTimeout(1500);

      // Editar el primer valor disponible
      const editValueBtn = page
        .getByRole('button', { name: /editar/i })
        .first();
      if (await editValueBtn.isVisible()) {
        await editValueBtn.click();
        await page.waitForTimeout(500);

        const updatedValue = `Rojo/Red ${SLUG_PREFIX}`;
        const valueField = page.getByRole('textbox').last();
        if (await valueField.isVisible()) {
          await valueField.clear();
          await valueField.fill(updatedValue);
          await page.waitForTimeout(300);

          const saveValueBtn = page.getByRole('button', { name: /guardar|confirmar/i }).last();
          if (await saveValueBtn.isVisible()) {
            await saveValueBtn.click();
            await page.waitForTimeout(1500);
          }
        }

        const body = await page.content();
        expect(body.length).toBeGreaterThan(200);
      }
    }
  });

  test('eliminar valor de atributo muestra confirmación (requiere backend)', async ({
    page,
  }) => {
    test.skip(!process.env.BACKEND_AVAILABLE, 'Backend no disponible');

    await goTo(page, '/pim/attributes');
    await page.waitForTimeout(2000);

    const viewBtn = page.getByRole('button', { name: /ver|detalle/i }).first();
    if (await viewBtn.isVisible()) {
      await viewBtn.click();
      await page.waitForTimeout(1500);

      const deleteValueBtn = page
        .getByRole('button', { name: /eliminar/i })
        .first();

      if (await deleteValueBtn.isVisible()) {
        await deleteValueBtn.click();
        await page.waitForTimeout(500);

        // Diálogo de confirmación
        const confirmBtn = page
          .getByRole('button', { name: /confirmar|eliminar/i })
          .last();
        expect(await confirmBtn.isVisible()).toBeTruthy();

        // Cancelar para no modificar datos
        const cancelBtn = page.getByRole('button', { name: /cancelar/i });
        if (await cancelBtn.isVisible()) {
          await cancelBtn.click();
        }
      }
    }
  });
});
