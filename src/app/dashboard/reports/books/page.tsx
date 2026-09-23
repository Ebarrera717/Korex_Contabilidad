'use client';

import React, { useState, useEffect } from 'react';
import {
  FileText,
  Calendar,
  Download,
  Printer,
  RefreshCw,
  Search,
  BookOpen,
  Filter
} from 'lucide-react';

export default function OfficialBooksPage() {
  const [bookType, setBookType] = useState<'AUXILIARY' | 'GENERAL_LEDGER' | 'JOURNAL_BOOK'>('AUXILIARY');
  const [startDate, setStartDate] = useState('2026-01-01');
  const [endDate, setEndDate] = useState('2026-12-31');
  const [accountCode, setAccountCode] = useState('');
  const [bookData, setBookData] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const loadBook = async () => {
    try {
      setLoading(true);
      let endpoint = '/api/reports/auxiliary-book';
      if (bookType === 'GENERAL_LEDGER') endpoint = '/api/reports/general-ledger';
      if (bookType === 'JOURNAL_BOOK') endpoint = '/api/reports/journal-book';

      const queryParams = new URLSearchParams({
        startDate,
        endDate,
        ...(accountCode ? { accountCode } : {})
      });

      const res = await fetch(`${endpoint}?${queryParams.toString()}`);
      if (res.ok) {
        const json = await res.json();
        setBookData(json.data || json || null);
      }
    } catch (e) {
      console.error('Error cargando libro oficial:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadBook();
  }, [bookType]);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
              <FileText className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-slate-900">Libros Oficiales de Contabilidad</h1>
              <p className="text-xs text-slate-500">Libro Diario Columnario, Libro Mayor y Balances, y Libro Auxiliar por Cuentas y Terceros</p>
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
            onClick={loadBook}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-blue-600 text-white text-xs font-semibold hover:bg-blue-700 shadow-sm transition-all"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            <span>Consultar Libro</span>
          </button>
        </div>
      </div>

      {/* Selectors */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-2 w-full md:w-auto">
          <button
            onClick={() => setBookType('AUXILIARY')}
            className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
              bookType === 'AUXILIARY'
                ? 'bg-blue-600 text-white shadow-sm'
                : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            Libro Auxiliar
          </button>
          <button
            onClick={() => setBookType('GENERAL_LEDGER')}
            className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
              bookType === 'GENERAL_LEDGER'
                ? 'bg-blue-600 text-white shadow-sm'
                : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            Mayor y Balances
          </button>
          <button
            onClick={() => setBookType('JOURNAL_BOOK')}
            className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
              bookType === 'JOURNAL_BOOK'
                ? 'bg-blue-600 text-white shadow-sm'
                : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            Libro Diario
          </button>
        </div>

        <div className="flex items-center gap-3 w-full md:w-auto">
          {bookType === 'AUXILIARY' && (
            <input
              type="text"
              placeholder="Filtrar por Cuenta (Ej. 1105)"
              value={accountCode}
              onChange={(e) => setAccountCode(e.target.value)}
              className="px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono focus:outline-none"
            />
          )}
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

      {/* Book Output */}
      <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm space-y-6">
        <div className="text-center pb-6 border-b border-slate-200 space-y-1">
          <h2 className="text-lg font-bold text-slate-900 uppercase">EMPRESA DEMO CONTABLE S.A.S.</h2>
          <p className="text-xs text-slate-500 font-mono">NIT: 900.123.456-8</p>
          <h3 className="text-sm font-bold text-blue-700 uppercase mt-2">
            {bookType === 'AUXILIARY'
              ? 'LIBRO AUXILIAR DE CONTABILIDAD'
              : bookType === 'GENERAL_LEDGER'
              ? 'LIBRO MAYOR Y BALANCES'
              : 'LIBRO DIARIO COLUMNARIO'}
          </h3>
          <p className="text-[11px] text-slate-400">
            Período: {new Date(startDate).toLocaleDateString('es-CO')} al {new Date(endDate).toLocaleDateString('es-CO')}
          </p>
        </div>

        {loading ? (
          <div className="py-16 text-center text-slate-400">
            <RefreshCw className="w-8 h-8 animate-spin mx-auto mb-2 text-blue-500" />
            <p className="text-xs font-semibold">Generando registros del libro contable...</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-600 uppercase">
                  <th className="py-2.5 px-3">Fecha</th>
                  <th className="py-2.5 px-3">Comprobante</th>
                  <th className="py-2.5 px-3">Cuenta PUC</th>
                  <th className="py-2.5 px-3">Tercero</th>
                  <th className="py-2.5 px-3">Concepto / Detalle</th>
                  <th className="py-2.5 px-3 text-right">Débito ($)</th>
                  <th className="py-2.5 px-3 text-right">Crédito ($)</th>
                  <th className="py-2.5 px-3 text-right">Saldo ($)</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-mono">
                {(bookData?.records || bookData?.lines || []).length === 0 ? (
                  <tr>
                    <td colSpan={8} className="py-12 text-center text-slate-400 font-sans">
                      <BookOpen className="w-8 h-8 mx-auto mb-2 text-slate-300" />
                      <p>No se registran movimientos para el período o cuenta seleccionada</p>
                    </td>
                  </tr>
                ) : (
                  (bookData?.records || bookData?.lines || []).map((item: any, idx: number) => (
                    <tr key={idx} className="hover:bg-slate-50">
                      <td className="py-2 px-3 text-slate-600">{item.date ? new Date(item.date).toLocaleDateString('es-CO') : '-'}</td>
                      <td className="py-2 px-3 font-bold text-slate-900">{item.entryNumber}</td>
                      <td className="py-2 px-3 font-bold text-blue-700">{item.accountCode}</td>
                      <td className="py-2 px-3 font-sans text-slate-700">{item.thirdPartyName || '-'}</td>
                      <td className="py-2 px-3 font-sans text-slate-600 max-w-xs truncate">{item.description}</td>
                      <td className="py-2 px-3 text-right text-emerald-700">${Number(item.debit || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</td>
                      <td className="py-2 px-3 text-right text-indigo-700">${Number(item.credit || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</td>
                      <td className="py-2 px-3 text-right font-bold text-slate-900">${Number(item.runningBalance || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
