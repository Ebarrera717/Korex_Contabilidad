export interface RolePermissionsMatrix {
    modules: Record<string, boolean>;
    masters: Record<string, boolean>;
    actions: Record<string, boolean>;
}

export const ALL_MASTER_CODES: { code: string; label: string }[] = [
    { code: 'Company', label: 'Empresas' },
    { code: 'Account', label: 'Plan Único de Cuentas (PUC)' },
    { code: 'ThirdParty', label: 'Terceros' },
    { code: 'CostCenter', label: 'Centros de Costo' },
    { code: 'DocumentType', label: 'Tipos de Documento' },
    { code: 'Consecutive', label: 'Consecutivos' },
    { code: 'FiscalPeriod', label: 'Períodos Fiscales' },
    { code: 'TaxConcept', label: 'Impuestos y Retenciones' },
    { code: 'User', label: 'Usuarios' },
    { code: 'Role', label: 'Roles y Permisos' },
    { code: 'SystemParameter', label: 'Parámetros del Sistema' },
    { code: 'SystemLog', label: 'Auditoría y Logs' }
];

export const ACTION_PERMISSIONS: { key: string; label: string; group: string }[] = [
    // Comprobantes y Asientos
    { key: 'journal.create', label: 'Crear Comprobante Contable', group: 'Contabilidad' },
    { key: 'journal.edit', label: 'Editar Comprobante Borrador', group: 'Contabilidad' },
    { key: 'journal.post', label: 'Contabilizar Comprobante (Partida Doble)', group: 'Contabilidad' },
    { key: 'journal.annul', label: 'Anular Comprobante', group: 'Contabilidad' },
    { key: 'journal.reverse', label: 'Reversar Asiento Contable', group: 'Contabilidad' },
    { key: 'journal.print', label: 'Imprimir Comprobante', group: 'Contabilidad' },
    { key: 'journal.exportExcel', label: 'Exportar Comprobantes a Excel', group: 'Contabilidad' },

    // Períodos Contables
    { key: 'period.close', label: 'Cierre Mensual de Período', group: 'Cierres' },
    { key: 'period.annualClose', label: 'Cierre Anual del Ejercicio', group: 'Cierres' },
    { key: 'period.reopen', label: 'Reapertura Controlada de Período', group: 'Cierres' },

    // Reportes Contables y Financieros
    { key: 'reports.trialBalance', label: 'Consultar Balance de Prueba', group: 'Reportes' },
    { key: 'reports.generalLedger', label: 'Consultar Libro Mayor y Balances', group: 'Reportes' },
    { key: 'reports.journalBook', label: 'Consultar Libro Diario', group: 'Reportes' },
    { key: 'reports.accountAuxiliary', label: 'Consultar Auxiliar por Cuenta', group: 'Reportes' },
    { key: 'reports.thirdPartyAuxiliary', label: 'Consultar Auxiliar por Tercero', group: 'Reportes' },
    { key: 'reports.financialStatements', label: 'Estados Financieros (Balance y Resultados)', group: 'Reportes' },
    { key: 'reports.exportExcel', label: 'Exportar Reportes a Excel', group: 'Reportes' },
    { key: 'reports.exportPdf', label: 'Exportar Reportes a PDF', group: 'Reportes' }
];

export const DEFAULT_PERMISSIONS: RolePermissionsMatrix = {
    modules: {
        accounting: true,
        masters: true,
        periods: true,
        reports: true,
        treasury: true,
        receivables: true,
        payables: true,
        config: true,
        manual: true
    },
    masters: ALL_MASTER_CODES.reduce((acc, m) => ({ ...acc, [m.code]: true }), {}),
    actions: ACTION_PERMISSIONS.reduce((acc, a) => ({ ...acc, [a.key]: true }), {})
};

export function isSuperAdminRole(roleName?: string): boolean {
    if (!roleName) return false;
    return roleName.toUpperCase().includes('SUPERADMIN');
}

export function normalizeRolePermissions(rawPermissions?: any, roleName?: string): RolePermissionsMatrix {
    if (isSuperAdminRole(roleName)) {
        return DEFAULT_PERMISSIONS;
    }

    if (!rawPermissions || typeof rawPermissions !== 'object') {
        return DEFAULT_PERMISSIONS;
    }

    const modules = { ...DEFAULT_PERMISSIONS.modules, ...(rawPermissions.modules || {}) };
    const masters = { ...DEFAULT_PERMISSIONS.masters, ...(rawPermissions.masters || {}) };
    const actions = { ...DEFAULT_PERMISSIONS.actions, ...(rawPermissions.actions || {}) };

    return { modules, masters, actions };
}

export function hasPermission(
    permissions: RolePermissionsMatrix | any,
    type: 'module' | 'master' | 'action',
    key: string,
    roleName?: string
): boolean {
    if (isSuperAdminRole(roleName)) {
        return true;
    }
    const norm = normalizeRolePermissions(permissions, roleName);
    if (type === 'module') return norm.modules[key] ?? true;
    if (type === 'master') return norm.masters[key] ?? true;
    if (type === 'action') return norm.actions[key] ?? true;
    return true;
}
