'use client';

import React from 'react';
import Link from 'next/link';
import {
  TrendingUp,
  TrendingDown,
  DollarSign,
  ShieldCheck,
  Receipt,
  Landmark,
  CreditCard,
  ShoppingBag,
  FileBarChart,
  Percent,
  Plus,
  ArrowUpRight,
  ArrowDownRight,
  Clock,
  CheckCircle2,
  AlertCircle
} from 'lucide-react';

export default function DashboardPage() {
  const metrics = [
    { title: 'Total Activos', value: '$ 152.400.000', change: '+12.4%', isPositive: true, sub: 'Bancos, Cajas, Inversiones, CxC' },
    { title: 'Total Pasivos', value: '$ 42.150.000', change: '-3.2%', isPositive: true, sub: 'Proveedores, Impuestos por pagar' },
    { title: 'Patrimonio Neto', value: '$ 110.250.000', change: '+8.1%', isPositive: true, sub: 'Capital social + Reservas' },
    { title: 'Utilidad Neta del Año', value: '$ 32.800.000', change: '+15.3%', isPositive: true, sub: 'Ingresos ($65M) - Gastos/Costos' },
  ];

  const quickActions = [
    { label: 'Nuevo Comprobante (CC)', desc: 'Asiento contable directo con partida doble', href: '/dashboard/journal-entries?new=true', icon: Receipt, color: 'bg-blue-500' },
    { label: 'Recibo de Caja (CI)', desc: 'Ingreso a caja o bancos con recaudo de clientes', href: '/dashboard/treasury?type=CI', icon: Landmark, color: 'bg-emerald-500' },
    { label: 'Comprobante Egreso (CE)', desc: 'Pago a proveedores con retención en la fuente', href: '/dashboard/treasury?type=CE', icon: ShoppingBag, color: 'bg-amber-500' },
    { label: 'Estados Financieros NIIF', desc: 'Balance General, PyG y Balance de Prueba', href: '/dashboard/reports', icon: FileBarChart, color: 'bg-indigo-500' },
    { label: 'Medios Magnéticos DIAN', desc: 'Formatos 1001, 1007, 1008 y 1009 en XML', href: '/dashboard/taxes', icon: Percent, color: 'bg-purple-500' },
    { label: 'Plan de Cuentas PUC', desc: 'Consulta y administración del catálogo de 5 niveles', href: '/dashboard/puc', icon: DollarSign, color: 'bg-rose-500' },
  ];

  const recentEntries = [
    { number: 'CC-2026-000001', date: '2026-09-23', concept: 'Aporte de Capital Inicial y Apertura de Cuentas', debit: '$ 50.000.000', credit: '$ 50.000.000', status: 'POSTED' },
    { number: 'CI-2026-000001', date: '2026-09-23', concept: 'Recaudo Factura de Venta FV-001 Cliente ABC', debit: '$ 12.500.000', credit: '$ 12.500.000', status: 'POSTED' },
    { number: 'CE-2026-000001', date: '2026-09-22', concept: 'Pago a Proveedor Nacional con Retefuente 2.5%', debit: '$ 8.200.000', credit: '$ 8.200.000', status: 'POSTED' },
    { number: 'FV-2026-000001', date: '2026-09-22', concept: 'Venta de Servicios de Consultoría Contable', debit: '$ 10.000.000', credit: '$ 10.000.000', status: 'POSTED' },
    { number: 'DP-2026-000001', date: '2026-09-21', concept: 'Depreciación Lineal Activos Fijos Período Mensual', debit: '$ 1.250.000', credit: '$ 1.250.000', status: 'POSTED' },
  ];

  return (
    <div className="space-y-8">
      
      {/* Bienvenida y Estado del Sistema */}
      <div className="bg-gradient-to-r from-blue-900 via-indigo-900 to-slate-900 rounded-2xl p-6 sm:p-8 text-white shadow-xl relative overflow-hidden">
        <div className="relative z-10 max-w-2xl">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-500/20 text-blue-300 text-xs font-semibold mb-3 border border-blue-400/30">
            <ShieldCheck className="w-4 h-4 text-emerald-400" />
            <span>Sistema Operacional Certificado al 100%</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">Tablero de Control Contable</h1>
          <p className="text-sm text-slate-300 mt-2 leading-relaxed">
            Bienvenido a <strong>Korex Contabilidad</strong>. Todas las reglas de partida doble, módulos tributarios DIAN, libros oficiales NIIF y conciliación bancaria se encuentran sincronizados.
          </p>
        </div>
      </div>

      {/* Tarjetas de Métricas Financieras */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {metrics.map((m, idx) => (
          <div key={idx} className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">{m.title}</span>
              <span className={`inline-flex items-center text-xs font-bold px-2 py-0.5 rounded-full ${m.isPositive ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700'}`}>
                {m.change}
              </span>
            </div>
            <p className="text-2xl font-bold text-slate-900 mt-2 tracking-tight">{m.value}</p>
            <p className="text-[11px] text-slate-400 mt-1 truncate">{m.sub}</p>
          </div>
        ))}
      </div>

      {/* Accesos Rápidos Operacionales */}
      <div>
        <h3 className="text-sm font-bold text-slate-800 uppercase tracking-wider mb-4">Acciones Rápidas</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {quickActions.map((action, idx) => {
            const Icon = action.icon;
            return (
              <Link
                key={idx}
                href={action.href}
                className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm hover:border-blue-300 hover:shadow-md transition-all flex items-start gap-4 group"
              >
                <div className={`w-10 h-10 rounded-xl ${action.color} text-white flex items-center justify-center flex-shrink-0 shadow-md group-hover:scale-105 transition-transform`}>
                  <Icon className="w-5 h-5" />
                </div>
                <div className="flex-1 min-w-0">
                  <h4 className="text-sm font-bold text-slate-800 group-hover:text-blue-600 transition-colors">{action.label}</h4>
                  <p className="text-xs text-slate-500 mt-0.5 line-clamp-2">{action.desc}</p>
                </div>
              </Link>
            );
          })}
        </div>
      </div>

      {/* Tabla de Últimos Comprobantes */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="p-5 border-b border-slate-100 flex items-center justify-between">
          <div>
            <h3 className="text-sm font-bold text-slate-900">Últimos Comprobantes Registrados</h3>
            <p className="text-xs text-slate-500 mt-0.5">Asientos contables y transacciones con partida doble</p>
          </div>
          <Link
            href="/dashboard/journal-entries"
            className="text-xs font-semibold text-blue-600 hover:text-blue-700 flex items-center gap-1"
          >
            <span>Ver Todos</span>
            <ArrowUpRight className="w-3.5 h-3.5" />
          </Link>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50/80 text-slate-600 uppercase font-semibold border-b border-slate-100">
              <tr>
                <th className="py-3 px-4">Comprobante</th>
                <th className="py-3 px-4">Fecha</th>
                <th className="py-3 px-4">Concepto</th>
                <th className="py-3 px-4 text-right">Débitos</th>
                <th className="py-3 px-4 text-right">Créditos</th>
                <th className="py-3 px-4 text-center">Estado</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {recentEntries.map((entry, idx) => (
                <tr key={idx} className="hover:bg-slate-50/60 transition-colors">
                  <td className="py-3 px-4 font-mono font-semibold text-blue-600">{entry.number}</td>
                  <td className="py-3 px-4 text-slate-500">{entry.date}</td>
                  <td className="py-3 px-4 font-medium max-w-xs truncate">{entry.concept}</td>
                  <td className="py-3 px-4 text-right font-mono">{entry.debit}</td>
                  <td className="py-3 px-4 text-right font-mono">{entry.credit}</td>
                  <td className="py-3 px-4 text-center">
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                      <CheckCircle2 className="w-3 h-3" />
                      <span>Asentado</span>
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

    </div>
  );
}
