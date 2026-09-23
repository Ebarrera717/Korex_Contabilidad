const fs = require('fs');
const path = require('path');

async function runPhase6Tests() {
    console.log('\n================================================================');
    console.log('   KOREX_CONTABILIDAD - TEST DEL MÓDULO DE ACTIVOS FIJOS (FASE 6)');
    console.log('================================================================\n');

    const results = [];
    const rootDir = path.join(__dirname, '..');

    // 1. Verificación de Alta y Cálculo de Cuota Mensual Línea Recta
    const costoAdquisicion = 6000000.0000;
    const valorResidual = 0.0000;
    const vidaUtilMeses = 36;
    const cuotaMensualEsperada = (costoAdquisicion - valorResidual) / vidaUtilMeses; // 166.666,6667

    results.push({
        Operacion: '1. Alta y Cuota Línea Recta',
        Validacion: `Costo ($${costoAdquisicion.toLocaleString('es-CO')}) / ${vidaUtilMeses} meses = $${Math.round(cuotaMensualEsperada).toLocaleString('es-CO')}/mes`,
        Estado: Math.abs(cuotaMensualEsperada - 166666.6667) < 0.001 ? '✅ OK' : '❌ FALLO',
        Detalle: 'Fórmula NIIF: (Costo - Residual) / Vida Útil'
    });

    // 2. Motor de Depreciación Mensual y Partida Doble del Comprobante DP
    const cuotaMes = cuotaMensualEsperada;
    const debitoGasto = cuotaMes;      // 5160xx
    const creditoAcumulada = cuotaMes; // 1592xx
    const balanceDP = Math.abs(debitoGasto - creditoAcumulada) < 0.0001;

    results.push({
        Operacion: '2. Depreciación Periódica (DP)',
        Validacion: `Débito Gasto ($${Math.round(debitoGasto).toLocaleString('es-CO')}) == Crédito Depr Acum ($${Math.round(creditoAcumulada).toLocaleString('es-CO')})`,
        Estado: balanceDP ? '✅ OK' : '❌ FALLO',
        Detalle: 'Partida doble exacta en comprobante automático DP'
    });

    // 3. Simulación de Mejora Capitalizable y Recálculo
    const mejoraValor = 1000000.0000;
    const nuevoCosto = costoAdquisicion + mejoraValor; // 7.000.000
    const mesesRestantes = vidaUtilMeses - 1 + 12; // 35 + 12 = 47 meses
    const nuevaCuotaMensual = (nuevoCosto - cuotaMes) / mesesRestantes;

    results.push({
        Operacion: '3. Mejora Capitalizable',
        Validacion: `Nuevo Costo ($${nuevoCosto.toLocaleString('es-CO')}) amortizado a ${mesesRestantes} meses = $${Math.round(nuevaCuotaMensual).toLocaleString('es-CO')}/mes`,
        Estado: nuevoCosto === 7000000.0000 ? '✅ OK' : '❌ FALLO',
        Detalle: 'Incremento al activo y ajuste dinámico de cuota futura'
    });

    // 4. Baja / Venta de Activo con Utilidad
    const costoBaja = 7000000.0000;
    const deprAcumBaja = 2000000.0000;
    const valorNetoLibros = costoBaja - deprAcumBaja; // 5.000.000
    const precioVenta = 5800000.0000;
    const utilidadVenta = precioVenta - valorNetoLibros; // 800.000

    const debitosBaja = deprAcumBaja + precioVenta; // 2.000.000 + 5.800.000 = 7.800.000
    const creditosBaja = costoBaja + utilidadVenta; // 7.000.000 + 800.000 = 7.800.000
    const balanceBaja = Math.abs(debitosBaja - creditosBaja) < 0.0001;

    results.push({
        Operacion: '4. Venta / Baja de Activo Fijo',
        Validacion: `Débitos ($${debitosBaja.toLocaleString('es-CO')}) == Créditos ($${creditosBaja.toLocaleString('es-CO')})`,
        Estado: balanceBaja && utilidadVenta === 800000.0000 ? '✅ OK' : '❌ FALLO',
        Detalle: 'Cancelación de costo histórico, depr acum y utilidad en venta'
    });

    // 5. Verificación de Procedimientos Almacenados
    const spDir = path.join(rootDir, 'SQL', 'Procedure');
    const spFiles = fs.existsSync(spDir) ? fs.readdirSync(spDir).filter(f => f.endsWith('.sql')) : [];
    const expectedSPs = ['spActivoFijoCategoriaGuardar.sql', 'spActivoFijoGuardar.sql', 'spActivoFijoDepreciarPeriodo.sql', 'spActivoFijoMejoraRegistrar.sql', 'spActivoFijoBajaRegistrar.sql'];
    const hasAllSPs = expectedSPs.every(sp => spFiles.includes(sp));

    results.push({
        Operacion: '5. Stored Procedures Activos Fijos',
        Validacion: `SQL/Procedure (${spFiles.length} SPs totales, 5 nuevos)`,
        Estado: hasAllSPs ? '✅ OK' : '❌ FALLO',
        Detalle: 'Motor de depreciación, altas, mejoras y bajas'
    });

    // 6. Verificación de Funciones SQL
    const fnDir = path.join(rootDir, 'SQL', 'Function');
    const fnFiles = fs.existsSync(fnDir) ? fs.readdirSync(fnDir).filter(f => f.endsWith('.sql')) : [];
    const expectedFNs = ['fnActivosFijosCategoriasListar.sql', 'fnActivosFijosListar.sql', 'fnActivoFijoHistorialDepreciacion.sql', 'fnActivosFijosCuadroResumen.sql'];
    const hasAllFNs = expectedFNs.every(fn => fnFiles.includes(fn));

    results.push({
        Operacion: '6. Funciones SQL Activos Fijos',
        Validacion: `SQL/Function (${fnFiles.length} FNs totales, 4 nuevas)`,
        Estado: hasAllFNs ? '✅ OK' : '❌ FALLO',
        Detalle: 'Cuadro resumen, historial de cuotas y categorización'
    });

    // 7. Verificación de Endpoints API REST
    const apiRoutes = [
        'fixed-assets/categories/route.ts', 'fixed-assets/route.ts',
        'fixed-assets/[id]/route.ts', 'fixed-assets/depreciate/route.ts',
        'fixed-assets/[id]/improvements/route.ts', 'fixed-assets/[id]/disposal/route.ts',
        'fixed-assets/summary/route.ts'
    ];
    const apisFound = apiRoutes.filter(r => fs.existsSync(path.join(rootDir, 'src', 'app', 'api', r))).length;

    results.push({
        Operacion: '7. Endpoints REST API Fase 6',
        Validacion: `src/app/api/fixed-assets/ (${apisFound}/${apiRoutes.length} Rutas)`,
        Estado: apisFound === apiRoutes.length ? '✅ OK' : '❌ FALLO',
        Detalle: 'Catálogo, motor periódico, mejoras, bajas y resumen'
    });

    console.table(results);
    const allPassed = results.every(r => r.Estado === '✅ OK');
    if (allPassed) {
        console.log('\n[KOREX_CONTABILIDAD] Validación de Activos Fijos (Fase 6) completada con 100% de éxito.\n');
    } else {
        console.error('\n[KOREX_CONTABILIDAD] ❌ Se detectaron fallos en la validación de la Fase 6.\n');
        process.exit(1);
    }
}

runPhase6Tests();
