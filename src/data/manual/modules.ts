export interface ManualSubmodule {
    id: string;
    title: string;
    description: string;
    technicalDetails?: string[];
    rules?: string[];
}

export interface ManualModule {
    id: string;
    title: string;
    description: string;
    icon: string;
    submodules: ManualSubmodule[];
}

export const MANUAL_MODULES: ManualModule[] = [
    {
        id: 'fundacion',
        title: 'Fundación y Arquitectura del Sistema',
        description: 'Estructura base, seguridad, conectividad multibase y reglas maestras de operación.',
        icon: 'ShieldCheck',
        submodules: [
            {
                id: 'seguridad-cifrado',
                title: 'Seguridad y Cifrado de Credenciales',
                description: 'Protección de contraseñas mediante Bcrypt y cifrado AES-256-CBC para cadenas de conexión.',
                technicalDetails: [
                    'Algoritmo AES-256-CBC con vector de inicialización de 16 bytes.',
                    'Formato de almacenamiento seguro: ENC(iv:ciphertext).',
                    'Enmascaramiento automático de datos sensibles en trazas y logs.'
                ],
                rules: [
                    'El archivo .env nunca debe contener claves en texto plano.',
                    'Los actualizadores tienen prohibido sobrescribir el archivo .env.'
                ]
            },
            {
                id: 'partida-doble',
                title: 'Principio de Partida Doble',
                description: 'Garantía matemática de balance en todos los comprobantes contables registrados.',
                technicalDetails: [
                    'Validación estricta Débitos = Créditos a nivel de Stored Procedure.',
                    'Uso de precisión numérica DECIMAL(18,4).'
                ],
                rules: [
                    'No se permite asentar ni contabilizar comprobantes descuadrados.'
                ]
            }
        ]
    },
    {
        id: 'maestros-contables',
        title: 'Maestros Contables Principales',
        description: 'Administración del PUC colombiano, Terceros con DV, Centros de Costo, Bancos, Tipos de Documentos y Consecutivos.',
        icon: 'BookOpen',
        submodules: [
            {
                id: 'empresa',
                title: 'Empresas y Parámetros Tributarios',
                description: 'Configuración de razón social, NIT, responsabilidades DIAN y régimen fiscal.',
                technicalDetails: [
                    'Procedimiento transaccional spCompanyGuardar.',
                    'Función de consulta fnCompanyListar.'
                ]
            },
            {
                id: 'puc',
                title: 'Plan Único de Cuentas (PUC)',
                description: 'Estructura jerárquica de cuentas (Clase, Grupo, Cuenta, Subcuenta, Auxiliar).',
                technicalDetails: [
                    'Control de niveles (1 al 5) y naturaleza (Débito / Crédito).',
                    'Procedimiento spPucGuardar con inferencia automática de cuenta padre.',
                    'Endpoint /api/puc/tree para visualización jerárquica en árbol.'
                ],
                rules: [
                    'Solo las cuentas de último nivel pueden marcarse como cuentas de movimiento.',
                    'Una cuenta padre no puede recibir movimientos directos si tiene subcuentas hijas.'
                ]
            },
            {
                id: 'terceros',
                title: 'Maestro Único de Terceros con DV',
                description: 'Gestión unificada de Clientes, Proveedores, Empleados, Socios y cálculo algorítmico de DV.',
                technicalDetails: [
                    'Cálculo de Dígito de Verificación DIAN Módulo 11 (src/lib/dian-utils.ts).',
                    'Procedimiento spThirdPartyGuardar y función fnThirdPartyListar.',
                    'Endpoint /api/third-parties/dv para cálculo instantáneo.'
                ]
            },
            {
                id: 'centros-costo',
                title: 'Centros de Costo',
                description: 'Estructura analítica de costos y gastos por departamentos o proyectos.',
                technicalDetails: [
                    'Procedimiento spCostCenterGuardar y función fnCostCenterListar.'
                ]
            },
            {
                id: 'bancos',
                title: 'Bancos y Cuentas Bancarias',
                description: 'Entidades financieras colombianas y cuentas asociadas al PUC.',
                technicalDetails: [
                    'Procedimiento spBankGuardar y función fnBankListar.'
                ]
            },
            {
                id: 'impuestos',
                title: 'Impuestos y Retenciones',
                description: 'Parametrización de IVA, Retefuente, ReteICA, ReteIVA y Autorretenciones con cuentas contables.',
                technicalDetails: [
                    'Procedimiento spTaxConceptGuardar y función fnTaxConceptListar.'
                ]
            },
            {
                id: 'documentos-consecutivos',
                title: 'Tipos de Documento y Consecutivos',
                description: 'Catálogo de comprobantes contables y numeración secuencial por año fiscal.',
                technicalDetails: [
                    'Procedimientos spDocumentTypeGuardar y spConsecutiveGuardar.',
                    'Garantía de numeración secuencial sin saltos.'
                ]
            }
        ]
    },
    {
        id: 'contabilidad-general',
        title: 'Núcleo Contable y Comprobantes (Fase 3)',
        description: 'Emisión de comprobantes, motor de contabilización con partida doble, reversiones y cierres fiscales.',
        icon: 'Receipt',
        submodules: [
            {
                id: 'comprobantes',
                title: 'Comprobantes Contables (Diario / Asientos)',
                description: 'Creación, edición en borrador y asignación de numeración secuencial continua.',
                technicalDetails: [
                    'Procedimiento spComprobanteGuardar con soporte de asientos en JSON.',
                    'Funciones fnComprobanteListar y fnComprobanteDetalle.'
                ]
            },
            {
                id: 'contabilizacion',
                title: 'Motor de Contabilización (Partida Doble)',
                description: 'Asentamiento formal con validación estricta de balance débito = crédito, cuentas de movimiento, terceros y períodos abiertos.',
                technicalDetails: [
                    'Procedimiento spComprobanteContabilizar con 5 capas de validación.',
                    'Transición de estado a POSTED con fecha y usuario de asentamiento.'
                ],
                rules: [
                    'Todo comprobante contabilizado debe cumplir Débitos = Créditos.',
                    'No se puede contabilizar en cuentas padre sin permiso de movimiento.',
                    'No se puede contabilizar en períodos fiscales cerrados.'
                ]
            },
            {
                id: 'reversiones-anulaciones',
                title: 'Reversiones y Anulaciones',
                description: 'Generación de asientos contables inversos automáticos y anulación justificada.',
                technicalDetails: [
                    'Procedimiento spComprobanteReversar (genera asiento inverso AJ en estado POSTED).',
                    'Procedimiento spComprobanteAnular (cambia estado a ANNULLED con motivo).'
                ]
            },
            {
                id: 'periodos-cierre-anual',
                title: 'Períodos Fiscales y Cierre Anual',
                description: 'Control de aperturas y cierres mensuales, y cancelación de cuentas de resultado (4, 5, 6, 7 contra 36) con comprobante CZ.',
                technicalDetails: [
                    'Procedimientos spPeriodoCerrar, spPeriodoReabrir y spCierreAnual.',
                    'Función fnPeriodoListar con métricas de comprobantes por mes.'
                ]
            }
        ]
    },
    {
        id: 'tesoreria-bancos',
        title: 'Gestión de Tesorería y Bancos (Fase 4)',
        description: 'Administración de cajas generales/menores, recibos de caja (CI), comprobantes de egreso (CE), transferencias internas (CC) y conciliación bancaria.',
        icon: 'Wallet',
        submodules: [
            {
                id: 'cajas-flujo',
                title: 'Administración de Cajas y Arqueos',
                description: 'Creación y control de cajas principales y cajas menores asignadas a responsables con cuenta contable PUC asociada.',
                technicalDetails: [
                    'Procedimiento spCajaGuardar con control de topes y responsables.',
                    'Función fnCajaListar con saldo en tiempo real.'
                ]
            },
            {
                id: 'ingresos-recibos-caja',
                title: 'Recibos de Caja / Ingresos de Tesorería (CI)',
                description: 'Registro de recaudos de clientes o ingresos varios con afectación automática a caja o banco y generación simétrica del comprobante contable CI.',
                technicalDetails: [
                    'Procedimiento spTesoreriaIngresoCrear con generación y contabilización automática de JournalEntry.',
                    'Soporte multiforma de pago (Efectivo, Transferencia, Cheque, Tarjeta).'
                ],
                rules: [
                    'Todo ingreso de tesorería genera de forma síncrona su asiento contable balanceado (Partida Doble).'
                ]
            },
            {
                id: 'egresos-pagos',
                title: 'Comprobantes de Egreso / Pagos (CE)',
                description: 'Desembolsos a proveedores o gastos varios con desglose y retención en la fuente automática, generando el comprobante contable CE.',
                technicalDetails: [
                    'Procedimiento spTesoreriaEgresoCrear con cálculo automático de retenciones y contrapartida bancaria.',
                    'Validación estricta de fondos y cuentas de movimiento.'
                ]
            },
            {
                id: 'transferencias-internas',
                title: 'Transferencias entre Cuentas y Cajas (CC)',
                description: 'Traslado seguro de fondos entre cuentas bancarias y cajas con comprobante de diario CC equilibrado.',
                technicalDetails: [
                    'Procedimiento spTesoreriaTransferenciaCrear con débito a destino y crédito a origen en una única transacción.'
                ]
            },
            {
                id: 'conciliacion-bancaria',
                title: 'Conciliación Bancaria Automática',
                description: 'Cálculo y cotejo de saldos en libros contables vs. extractos bancarios, identificando partidas conciliatorias (cheques en tránsito, consignaciones no acreditadas, notas débito/crédito).',
                technicalDetails: [
                    'Procedimiento spConciliacionBancariaCalcular y spConciliacionBancariaCerrar.',
                    'Función fnConciliacionBancariaConsultar con detalle de partidas conciliatorias y estado del período.'
                ],
                rules: [
                    'Una conciliación no puede cerrarse si existe diferencia no justificada entre el saldo ajustado de libros y el saldo de extracto.'
                ]
            }
        ]
    },
    {
        id: 'cartera-proveedores',
        title: 'Cartera y Proveedores (CxC / CxP) (Fase 5)',
        description: 'Gestión de facturas de venta y compra a crédito/contado, amortización por cuotas, análisis de edades, cruces de pagos, anticipos y notas débito/crédito.',
        icon: 'CreditCard',
        submodules: [
            {
                id: 'facturas-venta-cxc',
                title: 'Facturación de Venta y Cuentas por Cobrar (FV)',
                description: 'Emisión de facturas comerciales a clientes con cálculo de IVA y retenciones, tabla de vencimientos por cuotas y asiento automático de partida doble.',
                technicalDetails: [
                    'Procedimiento spFacturaVentaCrear y spFacturaVentaAnular.',
                    'Función fnFacturasVentaListar con filtros por cliente y estado.'
                ],
                rules: [
                    'Toda factura de venta genera en la misma transacción su comprobante contable FV balanceado.',
                    'No se puede anular una factura si ya cuenta con recaudos o abonos aplicados.'
                ]
            },
            {
                id: 'facturas-compra-cxp',
                title: 'Facturación de Compra y Cuentas por Pagar (FC)',
                description: 'Causación de facturas de compras y servicios a proveedores, cálculo de IVA descontable y Retefuente, con cuotas de vencimiento.',
                technicalDetails: [
                    'Procedimiento spFacturaCompraCrear y spFacturaCompraAnular.',
                    'Función fnFacturasCompraListar con correlativo interno y número físico.'
                ]
            },
            {
                id: 'cruces-recaudos-pagos',
                title: 'Cruces de Cartera y Aplicación de Pagos',
                description: 'Amortización de saldos de facturas mediante Recibos de Caja (CI), Comprobantes de Egreso (CE), Anticipos o Notas Crédito/Débito.',
                technicalDetails: [
                    'Procedimientos spCarteraReciboCruzar y spProveedorEgresoCruzar.',
                    'Actualización atómica de saldo en cuotas e invoice general (PAID / PARTIAL).'
                ]
            },
            {
                id: 'notas-credito-debito',
                title: 'Notas Crédito y Débito (NC / ND)',
                description: 'Emisión de notas por devoluciones, descuentos comerciales, correcciones o mayores valores cobrados/pagados con comprobante y cruce opcional automático.',
                technicalDetails: [
                    'Procedimiento spNotaCarteraCrear con soporte de NC_CLIENTE, ND_CLIENTE, NC_PROVEEDOR, ND_PROVEEDOR.',
                    'Función fnNotasCarteraListar.'
                ]
            },
            {
                id: 'edades-cartera-proveedores',
                title: 'Análisis de Edades y Saldos de Terceros',
                description: 'Matriz analítica de vencimientos clasificada en intervalos (Corriente, 1-30, 31-60, 61-90 y +90 días) para clientes y proveedores.',
                technicalDetails: [
                    'Funciones fnCarteraEdades, fnProveedoresEdades, fnCarteraSaldoTercero, fnProveedoresSaldoTercero.',
                    'Endpoints /api/receivables/aging y /api/payables/aging.'
                ]
            },
            {
                id: 'anticipos-terceros',
                title: 'Anticipos de Clientes y Proveedores',
                description: 'Registro, control de saldo y trazabilidad de anticipos recibidos o entregados antes de la emisión de la factura definitiva.',
                technicalDetails: [
                    'Procedimiento spAnticipoRegistrar y función fnAnticiposListar.',
                    'Endpoint /api/advances.'
                ]
            }
        ]
    },
    {
        id: 'activos-fijos-depreciacion',
        title: 'Activos Fijos y Depreciaciones (Fase 6)',
        description: 'Gestión de bienes de uso, vidas útiles bajo NIIF/Fiscal, motor mensual de depreciación lineal, mejoras capitalizables y enajenaciones/bajas.',
        icon: 'Building2',
        submodules: [
            {
                id: 'catalogo-categorias-activos',
                title: 'Categorías y Alta de Activos Fijos',
                description: 'Definición de grupos de activos (Edificaciones, Maquinaria, Cómputo, Vehículos) vinculados a cuentas PUC de Activo (15xx), Depreciación Acumulada (1592xx) y Gasto (5160xx).',
                technicalDetails: [
                    'Procedimientos spActivoFijoCategoriaGuardar y spActivoFijoGuardar.',
                    'Fórmula de cuota mensual: (Costo de Adquisición - Valor Residual) / Vida Útil en meses.',
                    'Función fnActivosFijosListar con filtros por categoría, centro de costo y responsable.'
                ]
            },
            {
                id: 'motor-depreciacion-mensual',
                title: 'Motor de Depreciación Periódica (DP)',
                description: 'Cálculo masivo de la cuota mensual de depreciación para todos los activos operativos, generando automáticamente el comprobante contable DP con balance estricto.',
                technicalDetails: [
                    'Procedimiento spActivoFijoDepreciarPeriodo con validación de período fiscal abierto.',
                    'Actualización atómica de depreciación acumulada y valor neto en libros.',
                    'Asignación automática del estado FULLY_DEPRECIATED al completar la vida útil.'
                ],
                rules: [
                    'La cuota de depreciación periódica no puede superar el costo neto amortizable.',
                    'No se puede depreciar un período más de una vez ni ejecutar en períodos fiscales cerrados.'
                ]
            },
            {
                id: 'mejoras-adiciones-capitalizables',
                title: 'Mejoras y Adiciones Capitalizables',
                description: 'Inversiones que incrementan la vida útil o el valor del activo, con recálculo dinámico de la cuota de depreciación futura.',
                technicalDetails: [
                    'Procedimiento spActivoFijoMejoraRegistrar con generación de comprobante de diario.'
                ]
            },
            {
                id: 'bajas-enajenaciones-activos',
                title: 'Bajas, Enajenaciones y Ventas de Activos',
                description: 'Retiro o venta de activos fijos, con cancelación del costo histórico y de la depreciación acumulada, y liquidación de utilidad o pérdida contable.',
                technicalDetails: [
                    'Procedimiento spActivoFijoBajaRegistrar.',
                    'Afectación a cuentas de Utilidad en Venta (424515) o Pérdida en Retiro (531015).'
                ]
            },
            {
                id: 'cuadro-resumen-activos',
                title: 'Cuadro Resumen e Historial de Depreciación',
                description: 'Reporte consolidado por categoría con costo histórico total, depreciación acumulada y valor neto en libros, e historial cronológico de cuotas.',
                technicalDetails: [
                    'Funciones fnActivosFijosCuadroResumen y fnActivoFijoHistorialDepreciacion.',
                    'Endpoints /api/fixed-assets/summary y /api/fixed-assets/[id].'
                ]
            }
        ]
    },
    {
        id: 'reportes-libros-dian',
        title: 'Reportes Financieros, Libros Oficiales e Impuestos DIAN (Fase 7)',
        description: 'Estados financieros bajo NIIF, libros oficiales de contabilidad, declaraciones tributarias (IVA 300 / Retefuente 350) y medios magnéticos de Información Exógena DIAN (1001, 1007, 1008, 1009).',
        icon: 'FileBarChart',
        submodules: [
            {
                id: 'estados-financieros-niif',
                title: 'Estados Financieros NIIF (Balance y PyG)',
                description: 'Generación del Balance General Clasificado y Estado de Resultados (Pérdidas y Ganancias) con cálculo dinámico de la utilidad del ejercicio y verificación estricta de la ecuación contable: Activo = Pasivo + Patrimonio + Utilidad.',
                technicalDetails: [
                    'Funciones fnReporteBalanceGeneral y fnReporteEstadoResultados.',
                    'Endpoints /api/reports/balance-sheet y /api/reports/income-statement.',
                    'Agrupación jerárquica por clases (1: Activo, 2: Pasivo, 3: Patrimonio, 4: Ingresos, 5: Gastos, 6: Costos).'
                ],
                rules: [
                    'El Balance General debe cumplir siempre la ecuación patrimonial de balance antes y después del cierre fiscal.',
                    'El cálculo de márgenes operativos y utilidad neta se deriva estrictamente de los comprobantes asentados (POSTED).'
                ]
            },
            {
                id: 'libros-oficiales-contabilidad',
                title: 'Libros Oficiales de Contabilidad',
                description: 'Reportes de auditoría y libros de registro legal: Balance de Prueba de sumas y saldos, Libro Auxiliar por cuenta y tercero, Libro Diario cronológico y Libro Mayor y Balances.',
                technicalDetails: [
                    'Funciones fnReporteBalancePrueba, fnReporteLibroAuxiliar, fnReporteLibroDiario y fnReporteLibroMayor.',
                    'Endpoints /api/reports/trial-balance, /api/reports/auxiliary-book, /api/reports/journal-book y /api/reports/general-ledger.',
                    'Totalización matemática obligatoria con validación de sumas iguales (Débitos = Créditos).'
                ]
            },
            {
                id: 'declaraciones-tributarias-dian',
                title: 'Declaraciones Tributarias (Formularios 300 y 350)',
                description: 'Liquidación de la Declaración Bimestral de IVA (Formulario 300) y Declaración Mensual de Retención en la Fuente (Formulario 350) con discriminación de bases gravables, tarifas y valores retenidos.',
                technicalDetails: [
                    'Funciones fnReporteDeclaracionIva y fnReporteDeclaracionRetefuente.',
                    'Endpoints /api/taxes/vat-declaration y /api/taxes/withholding-declaration.',
                    'Clasificación por tipo de impuesto (IVA_GENERADO, IVA_DESCONTABLE, RETEFUENTE_COMPRAS, RETEFUENTE_SERVICIOS, etc.).'
                ]
            },
            {
                id: 'informacion-exogena-dian',
                title: 'Información Exógena DIAN (Formatos 1001, 1007, 1008, 1009)',
                description: 'Generación y exportación de medios magnéticos para la DIAN con mapeo automático de conceptos tributarios y discriminación por tercero con NIT y Dígito de Verificación.',
                technicalDetails: [
                    'Formato 1001: Pagos o abonos en cuenta y retenciones practicadas (conceptos 5001-5016).',
                    'Formato 1007: Ingresos propios recibidos en el año fiscal (conceptos 4001-4004).',
                    'Formato 1008: Cuentas por cobrar a 31 de diciembre (conceptos 1315-1318).',
                    'Formato 1009: Cuentas por pagar a 31 de diciembre (conceptos 2201-2205).',
                    'Funciones fnGenerarFormatoExogena1001, fnGenerarFormatoExogena1007, fnGenerarFormatoExogena1008, fnGenerarFormatoExogena1009.',
                    'Endpoints /api/exogena/formats/1001, 1007, 1008, 1009.'
                ],
            }
        ]
    },
    {
        id: 'integraciones-interfaces-datos',
        title: 'Integraciones e Interfaces de Datos (Fase 8)',
        description: 'Mecanismos de ingesta y exportación masiva en Excel, CSV, JSON y XML para el Prevalidador DIAN, junto con webhooks y auditoría de transacciones con sistemas externos (ERP, Nómina, Facturación).',
        icon: 'ArrowLeftRight',
        submodules: [
            {
                id: 'plantillas-mapeo-datos',
                title: 'Plantillas y Mapeo Dinámico de Columnas',
                description: 'Administración de plantillas oficiales para la carga estructurada de datos, con normalización automática de encabezados personalizados.',
                technicalDetails: [
                    'Modelo DataInterfaceTemplate con esquema mappingConfig en JSONB.',
                    'Librería src/lib/excel-importer.ts con funciones de mapeo y parseo CSV.',
                    'Endpoint /api/interfaces/templates para consulta y configuración.'
                ]
            },
            {
                id: 'ingesta-masiva-lote',
                title: 'Importación Masiva en Lote (PUC, Terceros y Comprobantes)',
                description: 'Procesamiento masivo de catálogos y transacciones contables con validación de niveles jerárquicos, cálculo de Dígito de Verificación Módulo 11 y balance estricto Débito = Crédito.',
                technicalDetails: [
                    'Procedimiento spBatchImportPuc: Inferencia automática de cuentas padre y tipo de movimiento.',
                    'Procedimiento spBatchImportThirdParties: Cálculo algorítmico de DV para NITs.',
                    'Procedimiento spBatchImportComprobantes: Ingesta de asientos con partida doble y contabilización opcional.',
                    'Endpoints /api/interfaces/import/puc, /api/interfaces/import/third-parties, /api/interfaces/import/journal-entries.',
                    'Registro y seguimiento de estados (PENDING, PROCESSING, COMPLETED, FAILED) en BatchImportJob.'
                ],
                rules: [
                    'Ningún comprobante del lote puede ser asentado si presenta diferencias entre débitos y créditos.',
                    'Los errores individuales dentro de un lote no interrumpen el procesamiento de las filas válidas y se detallan en el reporte de job.'
                ]
            },
            {
                id: 'exportacion-xml-dian',
                title: 'Exportación XML para Prevalidador DIAN',
                description: 'Generación y descarga de archivos XML estructurados bajo las especificaciones técnicas de la DIAN para Medios Magnéticos (Formatos 1001, 1007, 1008, 1009).',
                technicalDetails: [
                    'Librería src/lib/xml-exogena-builder.ts con cabeceras XML ISO-8859-1 oficiales.',
                    'Endpoint /api/interfaces/export/exogena-xml con descarga directa de archivos adjuntos.'
                ]
            },
            {
                id: 'webhooks-transacciones-externas',
                title: 'Webhooks y Conectores con Sistemas Externos',
                description: 'Recepción asíncrona de eventos contables desde ERPs, sistemas de punto de venta (POS) y nómina electrónica, con cifrado AES-256 de credenciales y auditoría de telemetría.',
                technicalDetails: [
                    'Procedimiento spIntegrationTransactionRegistrar con generación de código ITX-YYYYMMDD-XXXX.',
                    'Funciones fnIntegrationEndpointsListar y fnIntegrationTransactionsListar.',
                    'Endpoints /api/interfaces/external/webhook, /api/interfaces/external/endpoints y /api/interfaces/external/transactions.'
                ],
            }
        ]
    },
    {
        id: 'empaquetado-instaladores-servicios',
        title: 'Empaquetado, Instaladores y Servicios de Windows (Fase 9)',
        description: 'Arquitectura de distribución autónoma, instaladores y actualizadores Inno Setup con protección inviolable del .env, generadores batch y servicio de Windows.',
        icon: 'Package',
        submodules: [
            {
                id: 'separacion-instaladores-multibase',
                title: 'Separación de Instaladores y Actualizadores Multibase',
                description: 'Generación independiente y autónoma de paquetes para PostgreSQL (GenerarSetup.bat / GenerarActualizador.bat) y SQL Server (GenerarSetupSqlServer.bat / GenerarActualizadorSqlServer.bat).',
                technicalDetails: [
                    'Scripts Inno Setup: deploy/installer.iss, deploy/updater.iss, deploy/installer_sqlserver.iss, deploy/updater_sqlserver.iss.',
                    'Compresión LZMA2 Ultra64 con asistente gráfico en español.',
                    'Ejecutables generados en el directorio dist/.'
                ],
                rules: [
                    'Ningún instalador o actualizador de PostgreSQL debe contener referencias o scripts de SQL Server y viceversa.'
                ]
            },
            {
                id: 'proteccion-inviolable-env',
                title: 'Protección Inviolable del Archivo de Configuración (.env)',
                description: 'Directivas estrictas que garantizan que las credenciales de base de datos, contraseñas de red y parámetros de licenciamiento nunca sean sobrescritos en actualizaciones de clientes.',
                technicalDetails: [
                    'Instaladores (Setup): Flags onlyifdoesntexist y uninsneveruninstall.',
                    'Actualizadores (Updater): Exclusión estricta de .env en la directiva [Files].'
                ],
                rules: [
                    'Está estrictamente prohibido que un actualizador sobrescriba, modifique o borre el archivo .env en producción.'
                ]
            },
            {
                id: 'consolidados-ddl-actualizador',
                title: 'Consolidación Automatizada de Scripts DDL (Actualizador.sql)',
                description: 'Generación incremental de scripts de base de datos sin destrucción de datos existentes mediante gen_schema_json.js.',
                technicalDetails: [
                    'Script deploy/gen_schema_json.js con extracción ordenada de Tablas, Semillas, Funciones y Procedimientos.',
                    'Generación de deploy/Actualizador.sql (PostgreSQL) y deploy/ActualizadorSERVER.sql (SQL Server).',
                    'Emisión de métricas en deploy/schema_metadata.json.'
                ]
            },
            {
                id: 'servicio-windows-fallback',
                title: 'Servicio de Windows y Estrategia de Fallback',
                description: 'Ejecución en segundo plano como servicio del sistema operativo (KorexContabilidadService) con inicio automático al arrancar el servidor.',
            }
        ]
    },
    {
        id: 'certificacion-calidad-entrega',
        title: 'Certificación de Calidad y Entrega (Fase 10)',
        description: 'Protocolo de pruebas automatizadas continuas, suite integral de validación en 7 capas y certificación de producción para Colombia.',
        icon: 'Award',
        submodules: [
            {
                id: 'banco-pruebas-automatizado',
                title: 'Banco de Pruebas Automatizado (Fases 2 a 9)',
                description: 'Ejecución integral de todas las suites unitarias y funcionales del sistema mediante scripts/run_all_tests.js con 100% de tasa de aprobación.',
                technicalDetails: [
                    'Suites ejecutadas: test_phase2_masters.js, test_phase3_accounting.js, test_phase4_treasury.js, test_phase5_receivables_payables.js, test_phase6_fixed_assets.js, test_phase7_reports_dian.js, test_phase8_integrations.js, test_phase9_packaging.js.',
                    'Cobertura completa de reglas contables, partida doble, cálculo de DV y medios magnéticos.'
                ]
            },
            {
                id: 'suite-integral-7-capas',
                title: 'Suite de Verificación Integral de 7 Capas',
                description: 'Verificación continua de la arquitectura del software mediante scripts/validate_full_suite.js.',
                technicalDetails: [
                    'Capa 1: 23 Skills de Arquitectura y Buenas Prácticas.',
                    'Capa 2: Reglas Maestras e Independencia Total en .agents/AGENTS.md.',
                    'Capa 3: 43 Modelos Relacionales en prisma/schema.prisma.',
                    'Capa 4: 10 Librerías de Núcleo en src/lib/.',
                    'Capa 5: 40 Procedimientos Almacenados en SQL/Procedure/.',
                    'Capa 6: 41 Funciones SQL de Consulta y Cálculo en SQL/Function/.',
                    'Capa 7: 64 Endpoints REST API operativos en src/app/api/.'
                ]
            },
            {
                id: 'garantia-aislamiento-multibase',
                title: 'Garantía de Aislamiento y Compatibilidad Multibase',
                description: 'Independencia total del proyecto Korex_Contabilidad respecto a sistemas externos y compatibilidad nativa dual en PostgreSQL y SQL Server.',
                technicalDetails: [
                    'Base de datos PostgreSQL: Korex_contabilidad_pg.',
                    'Base de datos SQL Server: Korex_Contabilidad_sql.',
                    'Cero interferencia con AgenciasNew u otros entornos.'
                ]
            }
        ]
    }
];



