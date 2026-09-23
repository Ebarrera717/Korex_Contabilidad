'use client';

import React, { useState, useEffect } from 'react';
import {
  FileBarChart,
  Calendar,
  Download,
  Printer,
  RefreshCw,
  TrendingUp,
  TrendingDown,
  Layers,
  Scale,
  DollarSign,
  FileSpreadsheet
} from 'lucide-react';

export default function ReportsPage() {
  const [reportType, setReportType] = useState<'BALANCE_SHEET' | 'INCOME_STATEMENT' | 'TRIAL_BALANCE'>('BALANCE_SHEET');
  const [startDate, setStartDate] = useState('2026-01-01');
  const [endDate, setEndDate] = useState('2026-12-31');
  const [reportData, setReportData] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const loadReport = async () => {
    try {
      setLoading(true);
      let endpoint = '/api/reports/balance-sheet';
      if (reportType === 'INCOME_STATEMENT') endpoint = '/api/reports/income-statement';
      if (reportType === 'TRIAL_BALANCE') endpoint = '/api/reports/trial-balance';

      const url = `${endpoint}?startDate=${startDate}&endDate=${endDate}`;
      const res = await fetch(url);
      if (res.ok) {
        const json = await res.json();
        setReportData(json.data || json || null);
      }
    } catch (e) {
      console.error('Error cargando estado financiero:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadReport();
  }, [reportType]);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
              <FileBarChart className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-slate-900">Estados Financieros NIIF</h1>
              <p className="text-xs text-slate-500">Estado de Situación Financiera (Balance General), Estado de Resultados Integral y Balance de Prueba</p>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => window.print()}
            className="flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 text-xs font-semibold hover:bg-slate-50 transition-colors"
          >
            <Printer className="w-4 h-4" />
            <span>Imprimir</span>
          </button>
          <button
            onClick={loadReport}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-blue-600 text-white text-xs font-semibold hover:bg-blue-700 shadow-sm transition-all"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            <span>Generar Reporte</span>
          </button>
        </div>
      </div>

      {/* Report Controls & Selectors */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
        {/* Type Selector */}
        <div className="flex items-center gap-2 w-full md:w-auto">
          <button
            onClick={() => setReportType('BALANCE_SHEET')}
            className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
              reportType === 'BALANCE_SHEET'
                ? 'bg-blue-600 text-white shadow-sm'
                : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            Balance General
          </button>
          <button
            onClick={() => setReportType('INCOME_STATEMENT')}
            className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
              reportType === 'INCOME_STATEMENT'
                ? 'bg-blue-600 text-white shadow-sm'
                : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            Estado de Resultados (PyG)
          </button>
          <button
            onClick={() => setReportType('TRIAL_BALANCE')}
            className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
              reportType === 'TRIAL_BALANCE'
                ? 'bg-blue-600 text-white shadow-sm'
                : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            Balance de Prueba
          </button>
        </div>

        {/* Date Pickers */}
        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="flex items-center gap-2 bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs">
            <span className="text-slate-400 font-semibold">Desde:</span>
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="bg-transparent text-slate-800 font-mono focus:outline-none"
            />
          </div>
          <div className="flex items-center gap-2 bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs">
            <span className="text-slate-400 font-semibold">Hasta:</span>
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="bg-transparent text-slate-800 font-mono focus:outline-none"
            />
          </div>
        </div>
      </div>

      {/* Report Canvas */}
      <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm space-y-6">
        {/* Printable Header */}
        <div className="text-center pb-6 border-b border-slate-200 space-y-1">
          <h2 className="text-lg font-bold text-slate-900 uppercase tracking-wide">EMPRESA DEMO CONTABLE S.A.S.</h2>
          <p className="text-xs text-slate-500 font-mono">NIT: 900.123.456-8</p>
          <h3 className="text-sm font-bold text-blue-700 uppercase mt-2">
            {reportType === 'BALANCE_SHEET'
              ? 'ESTADO DE SITUACIÓN FINANCIERA (BALANCE GENERAL NIIF)'
              : reportType === 'INCOME_STATEMENT'
              ? 'ESTADO DE RESULTADOS INTEGRAL (P&G)'
              : 'BALANCE DE PRUEBA OFICIAL POR CUENTAS'}
          </h3>
          <p className="text-[11px] text-slate-400">
            Período: {new Date(startDate).toLocaleDateString('es-CO')} al {new Date(endDate).toLocaleDateString('es-CO')} • Cifras en Pesos Colombianos (COP)
          </p>
        </div>

        {/* Report Content */}
        {loading ? (
          <div className="py-16 text-center text-slate-400">
            <RefreshCw className="w-8 h-8 animate-spin mx-auto mb-2 text-blue-500" />
            <p className="text-xs font-semibold">Calculando saldos y consolidando estados financieros...</p>
          </div>
        ) : (
          <div className="space-y-6">
            {/* Balance Sheet View */}
            {reportType === 'BALANCE_SHEET' && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                {/* Activos */}
                <div className="space-y-4">
                  <div className="flex items-center justify-between pb-2 border-b-2 border-blue-600">
                    <h4 className="text-sm font-bold text-slate-900">1. ACTIVO</h4>
                    <span className="text-sm font-bold font-mono text-blue-700">
                      ${Number(reportData?.totalAssets || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
                    </span>
                  </div>
                  <div className="space-y-2 text-xs">
                    {(reportData?.assets || []).map((item: any, idx: number) => (
                      <div key={idx} className="flex items-center justify-between py-1 border-b border-slate-100">
                        <span className="text-slate-700">{item.code} - {item.name}</span>
                        <span className="font-mono font-bold text-slate-900">${Number(item.balance || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Pasivo + Patrimonio */}
                <div className="space-y-6">
                  {/* Pasivos */}
                  <div className="space-y-4">
                    <div className="flex items-center justify-between pb-2 border-b-2 border-indigo-600">
                      <h4 className="text-sm font-bold text-slate-900">2. PASIVO</h4>
                      <span className="text-sm font-bold font-mono text-indigo-700">
                        ${Number(reportData?.totalLiabilities || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
                      </span>
                    </div>
                    <div className="space-y-2 text-xs">
                      {(reportData?.liabilities || []).map((item: any, idx: number) => (
                        <div key={idx} className="flex items-center justify-between py-1 border-b border-slate-100">
                          <span className="text-slate-700">{item.code} - {item.name}</span>
                          <span className="font-mono font-bold text-slate-900">${Number(item.balance || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</span>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Patrimonio */}
                  <div className="space-y-4">
                    <div className="flex items-center justify-between pb-2 border-b-2 border-emerald-600">
                      <h4 className="text-sm font-bold text-slate-900">3. PATRIMONIO</h4>
                      <span className="text-sm font-bold font-mono text-emerald-700">
                        ${Number(reportData?.totalEquity || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
                      </span>
                    </div>
                    <div className="space-y-2 text-xs">
                      {(reportData?.equity || []).map((item: any, idx: number) => (
                        <div key={idx} className="flex items-center justify-between py-1 border-b border-slate-100">
                          <span className="text-slate-700">{item.code} - {item.name}</span>
                          <span className="font-mono font-bold text-slate-900">${Number(item.balance || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</span>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Ecuación Patrimonial */}
                  <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between">
                    <div>
                      <span className="text-[10px] font-bold text-slate-500 uppercase block">TOTAL PASIVO + PATRIMONIO</span>
                      <span className="text-base font-bold font-mono text-slate-900">
                        ${(Number(reportData?.totalLiabilities || 0) + Number(reportData?.totalEquity || 0)).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
                      </span>
                    </div>
                    <Scale className="w-5 h-5 text-emerald-600" />
                  </div>
                </div>
              </div>
            )}

            {/* Income Statement View */}
            {reportType === 'INCOME_STATEMENT' && (
              <div className="max-w-2xl mx-auto space-y-4">
                <div className="space-y-2 text-xs">
                  <div className="flex items-center justify-between py-2 border-b-2 border-emerald-600 text-sm font-bold">
                    <span>4. INGRESOS OPERACIONALES</span>
                    <span className="font-mono text-emerald-700">${Number(reportData?.totalIncome || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</span>
                  </div>
                  {(reportData?.incomeDetails || []).map((item: any, idx: number) => (
                    <div key={idx} className="flex items-center justify-between py-1 text-slate-600 pl-4">
                      <span>{item.code} - {item.name}</span>
                      <span className="font-mono font-medium">${Number(item.balance || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</span>
                    </div>
                  ))}

                  <div className="flex items-center justify-between py-2 border-b-2 border-rose-600 text-sm font-bold pt-4">
                    <span>5. GASTOS OPERACIONALES</span>
                    <span className="font-mono text-rose-700">${Number(reportData?.totalExpenses || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</span>
                  </div>
                  {(reportData?.expenseDetails || []).map((item: any, idx: number) => (
                    <div key={idx} className="flex items-center justify-between py-1 text-slate-600 pl-4">
                      <span>{item.code} - {item.name}</span>
                      <span className="font-mono font-medium">${Number(item.balance || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</span>
                    </div>
                  ))}

                  <div className="flex items-center justify-between py-2 border-b-2 border-amber-600 text-sm font-bold pt-4">
                    <span>6. COSTOS DE VENTAS / OPERACIÓN</span>
                    <span className="font-mono text-amber-700">${Number(reportData?.totalCosts || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</span>
                  </div>
                </div>

                {/* Utilidad Neta */}
                <div className="p-5 rounded-2xl bg-blue-50 border border-blue-200 flex items-center justify-between mt-6">
                  <div>
                    <span className="text-xs font-bold text-blue-900 uppercase block">UTILIDAD / (PÉRDIDA) DEL EJERCICIO</span>
                    <span className="text-2xl font-bold font-mono text-blue-700 mt-1 block">
                      ${Number(reportData?.netIncome || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
                    </span>
                  </div>
                  {Number(reportData?.netIncome || 0) >= 0 ? (
                    <TrendingUp className="w-8 h-8 text-emerald-600" />
                  ) : (
                    <TrendingDown className="w-8 h-8 text-rose-600" />
                  )}
                </div>
              </div>
            )}

            {/* Trial Balance View */}
            {reportType === 'TRIAL_BALANCE' && (
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse text-xs">
                  <thead>
                    <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-600">
                      <th className="py-2.5 px-3">Cuenta PUC</th>
                      <th className="py-2.5 px-3">Nombre de Cuenta</th>
                      <th className="py-2.5 px-3 text-right">Saldo Anterior ($)</th>
                      <th className="py-2.5 px-3 text-right">Débitos ($)</th>
                      <th className="py-2.5 px-3 text-right">Créditos ($)</th>
                      <th className="py-2.5 px-3 text-right">Nuevo Saldo ($)</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-mono">
                    {(reportData?.accounts || []).map((acc: any, idx: number) => (
                      <tr key={idx} className="hover:bg-slate-50">
                        <td className="py-2 px-3 font-bold text-slate-900">{acc.code}</td>
                        <td className="py-2 px-3 font-sans text-slate-700">{acc.name}</td>
                        <td className="py-2 px-3 text-right">${Number(acc.initialBalance || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</td>
                        <td className="py-2 px-3 text-right text-emerald-700">${Number(acc.debit || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</td>
                        <td className="py-2 px-3 text-right text-indigo-700">${Number(acc.credit || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</td>
                        <td className="py-2 px-3 text-right font-bold text-slate-900">${Number(acc.finalBalance || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
