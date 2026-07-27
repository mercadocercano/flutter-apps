# assets/images — fondo de login

El login usa `McLoginBackground` (del design system) con un **mapa procedural
placeholder**. Para usar la imagen final del mapa:

1. Generá el mapa **limpio, sin pines** (los pines son una capa Flutter animada).
   - Opción IA satelital o vectorial → ver prompts de Midjourney en el chat.
   - Opción Mapbox → static export del estilo custom en cobalto.
2. Exportá a **WebP**, < 300 KB, crop **9:16** (tablet POS), y guardalo acá como
   `login_map.webp`.
3. En `lib/features/auth/auth_screen.dart`, descomentá:
   ```dart
   mapImage: const AssetImage('assets/images/login_map.webp'),
   ```

El asset del pin de marca está en `marketing/assets/PinMC.png` si más adelante
querés reemplazar el `Icons.location_on` por el pin "MC".
