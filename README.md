# Nodo Tech & Growth Finance Dashboard

Entregables:

- `nodo-finance-dashboard.html`: prototipo React + Tailwind autocontenido. Se abre directamente en el navegador.
- `nodo_finance_schema.sql`: esquema relacional sugerido con vistas de métricas financieras y ROI.
- `nodo_finance_schema.json`: mapa lógico de entidades, métricas calculadas y reglas contables.

Notas de arquitectura:

- Las ventas se calculan desde `invoices` pagadas y no incluyen capital de socios o inversionistas.
- Las compras CAPEX financiadas viven en `fixed_assets` y abren una fila en `liabilities`.
- Los pagos de deuda se separan entre `principal_component` e `interest_component`; solo el interés impacta OPEX.
- El formulario de Marketing ROI calcula CPL, conversión y ROAS en la interfaz; las campañas con ROAS superior a 3.0 se resaltan en verde.
