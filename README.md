# flutter-apps

Monorepo Flutter del ecosistema [mercado-cercano](https://github.com/mercadocercano): tres aplicaciones de cliente sobre una base de dominio compartida, organizadas como **Dart workspace** con [Melos](https://melos.invertase.dev) y **Clean Architecture (hexagonal) + DDD**.

```
Dart workspace (melos) · 3 apps · 5 packages · BLoC/Cubit
```

## Apps

| App | Para quién | Qué es |
|-----|-----------|--------|
| **mc_consumer** | Compradores | Marketplace — comprá en los comercios de tu barrio. |
| **mc_pos** | Comercios | Punto de venta para el mostrador, con integración de hardware. |
| **mc_admin** | Operación del marketplace | Panel de administración de comercios y catálogo. |

Las tres comparten dominio, casos de uso e infraestructura: la lógica de negocio se escribe **una vez** y cada app consume lo que necesita.

## Estructura

```
packages/
  mc_domain          Bounded contexts, entities, value objects, business rules.
                     Puro Dart, sin dependencias de Flutter.
  mc_application     Use cases y ports (interfaces). Orquesta dominio sin
                     conocer infraestructura.
  mc_infrastructure  Adapters de infra — HTTP (Dio), storage, auth, sync engine.
  mc_design_system   Tokens, theme y widgets compartidos.
  mc_hardware        Ports y adapters de hardware comercial — balanza,
                     impresora térmica, scanner.
apps/
  mc_consumer · mc_pos · mc_admin
```

La dependencia apunta siempre hacia adentro: `apps → application → domain`. La infraestructura y el hardware entran como **adapters** detrás de puertos, de modo que el dominio no conoce ni el cliente HTTP ni el modelo de impresora. `mc_domain` es Dart puro y testeable sin Flutter.

### Hardware (mc_pos)

El POS habla con periféricos físicos —balanza, impresora térmica, scanner de código de barras— a través de puertos en `mc_hardware`. La app depende de la interfaz, no del driver: cambiar de modelo de impresora es cambiar un adapter.

## Desarrollo

Requiere Flutter (canal stable) y Melos.

```bash
dart pub global activate melos
melos bootstrap        # resuelve el workspace completo
melos run analyze      # dart analyze en todos los packages
melos run test         # tests donde exista test/
melos run format       # formato
```

## Build web

Las apps se buildean a **web estática** vía Docker —`Dockerfile.web` corre el SDK de Flutter sobre Linux para evitar el requisito de macOS 14+ del host— y se sirven con nginx (`nginx-flutter.conf`, cache largo para assets versionados, revalidación del shell). Targets: `consumer`, `pos`, `admin`.

```bash
# Ejemplo: build de la app consumer apuntando al gateway Kong
docker build -f Dockerfile.web --target consumer \
  --build-arg API_BASE_URL=http://localhost:8000 -t mc-consumer-web .
```

`mc_consumer`/`mc_pos` leen `API_BASE_URL`; `mc_admin` lee `KONG_BASE_URL`. Todo el tráfico de cliente pasa por el API Gateway (Kong) del ecosistema.

---

Parte del ecosistema [mercado-cercano](https://github.com/mercadocercano) · Licencia MIT
