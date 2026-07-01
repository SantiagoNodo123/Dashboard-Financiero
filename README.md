# Nodo Tech & Growth Finance Dashboard

Entregables:

- `index.html`: prototipo React + Tailwind autocontenido. Se abre directamente en el navegador o se despliega en GitHub Pages.
- `nodo_finance_schema.sql`: esquema relacional sugerido con vistas de métricas financieras y ROI.
- `nodo_finance_schema.json`: mapa lógico de entidades, métricas calculadas y reglas contables.

Notas de arquitectura:

- Las ventas se calculan desde `invoices` pagadas y no incluyen capital de socios o inversionistas.
- Las compras CAPEX financiadas viven en `fixed_assets` y abren una fila en `liabilities`.
- Los pagos de deuda se separan entre `principal_component` e `interest_component`; solo el interés impacta OPEX.
- El formulario de Marketing ROI calcula CPL, conversión y ROAS en la interfaz; las campañas con ROAS superior a 3.0 se resaltan en verde.

## Despliegue en GitHub Pages

Para ver el dashboard interactivo funcionando en vivo directamente en la web:
1. Ve a la pestaña **Settings** (Configuración) de tu repositorio en GitHub.
2. En el menú de la izquierda, haz clic en **Pages**.
3. En la sección **Build and deployment**, bajo **Source**, selecciona **Deploy from a branch**.
4. Bajo **Branch**, selecciona **main** y la carpeta `/ (root)`. Haz clic en **Save**.
5. Espera un minuto y tu dashboard estará disponible en: [https://SantiagoNodo123.github.io/Dashboard-Financiero/](https://SantiagoNodo123.github.io/Dashboard-Financiero/)

