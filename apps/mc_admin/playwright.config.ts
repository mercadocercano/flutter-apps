import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright config para mc_admin E2E.
 *
 * Prerequisito: `flutter build web --web-renderer html` en el directorio raíz,
 * luego servir `build/web` en el puerto 8888.
 *
 * Script de inicio rápido (en package.json):
 *   "e2e:serve": "npx serve build/web -p 8888 -s"
 *   "e2e:run":   "playwright test"
 *   "e2e":       "flutter build web && npm run e2e:serve & sleep 3 && playwright test"
 */
export default defineConfig({
  testDir: './e2e',
  timeout: 30_000,
  expect: { timeout: 5_000 },
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: 'html',

  use: {
    baseURL: process.env.APP_URL ?? 'http://localhost:8888',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
