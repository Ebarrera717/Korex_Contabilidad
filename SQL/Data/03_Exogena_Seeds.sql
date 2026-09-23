-- ============================================================================
-- KOREX_CONTABILIDAD - SEMILLAS DE CONCEPTOS OFICIALES DE EXÓGENA DIAN
-- ============================================================================

INSERT INTO public."ExogenaConcept"("formatNumber", code, name, "isActive")
VALUES 
    -- Formato 1001: Pagos o Abonos en Cuenta y Retenciones Practicadas
    ('1001', '5001', 'Salarios, prestaciones sociales y demás pagos laborales', TRUE),
    ('1001', '5002', 'Honorarios', TRUE),
    ('1001', '5003', 'Comisiones', TRUE),
    ('1001', '5004', 'Servicios', TRUE),
    ('1001', '5005', 'Arrendamientos de bienes muebles e inmuebles', TRUE),
    ('1001', '5006', 'Intereses y rendimientos financieros', TRUE),
    ('1001', '5007', 'Compras de activos movibles (Inventarios / Mercancías)', TRUE),
    ('1001', '5008', 'Compras de activos fijos (Propiedad, planta y equipo)', TRUE),
    ('1001', '5010', 'Pagos o abonos en cuenta por seguros y reaseguros', TRUE),
    ('1001', '5016', 'Demás costos y deducciones no contemplados en otros conceptos', TRUE),

    -- Formato 1007: Ingresos Propios Recibidos
    ('1007', '4001', 'Ingresos brutos operacionales de actividades ordinarias', TRUE),
    ('1007', '4002', 'Ingresos brutos no operacionales (Financieros, diversos)', TRUE),
    ('1007', '4003', 'Ingresos por intereses y rendimientos financieros', TRUE),
    ('1007', '4004', 'Ingresos por dividendos y participaciones', TRUE),

    -- Formato 1008: Saldo de Cuentas por Cobrar a 31 de Diciembre
    ('1008', '1315', 'Cuentas por cobrar a clientes nacionales y del exterior', TRUE),
    ('1008', '1316', 'Cuentas por cobrar a socios y accionistas', TRUE),
    ('1008', '1317', 'Anticipos entregados a proveedores y contratistas', TRUE),
    ('1008', '1318', 'Otras cuentas por cobrar', TRUE),

    -- Formato 1009: Saldo de Cuentas por Pagar a 31 de Diciembre
    ('1009', '2201', 'Proveedores nacionales y del exterior', TRUE),
    ('1009', '2202', 'Obligaciones financieras con entidades bancarias', TRUE),
    ('1009', '2203', 'Cuentas por pagar a socios y accionistas', TRUE),
    ('1009', '2204', 'Anticipos recibidos de clientes', TRUE),
    ('1009', '2205', 'Otras cuentas por pagar y pasivos laborales', TRUE)
ON CONFLICT ("formatNumber", code) DO NOTHING;
