'use client';

import React, { useState, useEffect } from 'react';
import {
  Receipt,
  Search,
  Plus,
  Edit2,
  Trash2,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  FileSpreadsheet,
  ArrowRightLeft,
  X,
  RefreshCw,
  Eye,
  Calendar,
  Layers,
  Sparkles
} from 'lucide-react';

interface JournalEntryLine {
  id?: string;
  accountId: string;
  accountCode?: string;
  accountName?: string;
  thirdPartyId?: string | null;
  thirdPartyName?: string | null;
  costCenterId?: string | null;
  description: string;
  debit: number;
  credit: number;
  baseAmount?: number | null;
}

interface JournalEntry {
  id: string;
  entryNumber: string;
  entryType: string;
  date: string;
  concept: string;
  status: 'DRAFT' | 'POSTED' | 'ANNULLED';
  totalDebit: number;
  totalCredit: number;
  lines?: JournalEntryLine[];
}

export default function JournalEntriesPage() {
  const [entries, setEntries] = useState<JournalEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [showModal, setShowModal] = useState(false);
  const [pucAccounts, setPucAccounts] = useState<any[]>([]);
  const [thirdParties, setThirdParties] = useState<any[]>([]);

  // Form State
  const [formData, setFormData] = useState<{
    entryType: string;
    date: string;
    concept: string;
    lines: {
      accountId: string;
      thirdPartyId: string;
      description: string;
      debit: number;
      credit: number;
      baseAmount: number;
    }[];
  }>({
    entryType: 'CC',
    date: new Date().toISOString().split('T')[0],
    concept: '',
    lines: [
      { accountId: '', thirdPartyId: '', description: '', debit: 0, credit: 0, baseAmount: 0 },
      { accountId: '', thirdPartyId: '', description: '', debit: 0, credit: 0, baseAmount: 0 }
    ]
  });

  const loadData = async () => {
    try {
      setLoading(true);
      const res = await fetch('/api/journal-entries');
      if (res.ok) {
        const json = await res.json();
        setEntries(json.data || json || []);
      }
    } catch (e) {
      console.error('Error cargando comprobantes:', e);
    } finally {
      setLoading(false);
    }
  };

  const loadBaseData = async () => {
    try {
      const [resPuc, resThird] = await Promise.all([
        fetch('/api/puc'),
        fetch('/api/third-parties')
      ]);
      if (resPuc.ok) {
        const json = await resPuc.json();
        setPucAccounts((json.data || json || []).filter((a: any) => a.isAuxiliary || a.code.length >= 6));
      }
      if (resThird.ok) {
        const json = await resThird.json();
        setThirdParties(json.data || json || []);
      }
    } catch (e) {
      console.error('Error cargando datos base:', e);
    }
  };

  useEffect(() => {
    loadData();
    loadBaseData();
  }, []);

  const totalDebit = formData.lines.reduce((acc, curr) => acc + (Number(curr.debit) || 0), 0);
  const totalCredit = formData.lines.reduce((acc, curr) => acc + (Number(curr.credit) || 0), 0);
  const difference = Math.abs(totalDebit - totalCredit);
  const isBalanced = difference < 0.01 && totalDebit > 0;

  const handleAddLine = () => {
    setFormData((prev) => ({
      ...prev,
      lines: [
        ...prev.lines,
        { accountId: '', thirdPartyId: '', description: prev.concept || '', debit: 0, credit: 0, baseAmount: 0 }
      ]
    }));
  };

  const handleRemoveLine = (index: number) => {
    if (formData.lines.length <= 2) {
      alert('Un comprobante contable debe tener al menos dos líneas (Partida Doble).');
      return;
    }
    setFormData((prev) => ({
      ...prev,
      lines: prev.lines.filter((_, i) => i !== index)
    }));
  };

  const handleLineChange = (index: number, field: string, value: any) => {
    setFormData((prev) => {
      const updatedLines = [...prev.lines];
      updatedLines[index] = { ...updatedLines[index], [field]: value };
      return { ...prev, lines: updatedLines };
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isBalanced) {
      alert(`El comprobante no cumple Partida Doble. Diferencia: $${difference.toLocaleString('es-CO')}`);
      return;
    }

    try {
      const res = await fetch('/api/journal-entries', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });

      if (res.ok) {
        setShowModal(false);
        loadData();
      } else {
        const err = await res.json();
        alert(`Error al crear comprobante: ${err.message || err.error || 'Verifique los datos'}`);
      }
    } catch (e) {
      alert('Error de conexión con el servidor');
    }
  };

  const handlePostEntry = async (id: string) => {
    if (!confirm('¿Desea asentar definitivamente este comprobante contable?')) return;
    try {
      const res = await fetch(`/api/journal-entries/${id}/post`, { method: 'POST' });
      if (res.ok) {
        loadData();
      } else {
        const err = await res.json();
        alert(`Error al asentar: ${err.message || err.error}`);
      }
    } catch (e) {
      alert('Error al procesar asentamiento');
    }
  };

  const handleAnnulEntry = async (id: string) => {
    const reason = prompt('Ingrese el motivo de anulación:');
    if (!reason) return;
    try {
      const res = await fetch(`/api/journal-entries/${id}/annul`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reason })
      });
      if (res.ok) {
        loadData();
      } else {
        const err = await res.json();
        alert(`Error al anular: ${err.message || err.error}`);
      }
    } catch (e) {
      alert('Error al procesar anulación');
    }
  };

  const filteredEntries = entries.filter((item) => {
    const matchesSearch =
      (item.entryNumber || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (item.concept || '').toLowerCase().includes(searchTerm.toLowerCase());

    if (!matchesSearch) return false;
    if (statusFilter === 'POSTED') return item.status === 'POSTED';
    if (statusFilter === 'DRAFT') return item.status === 'DRAFT';
    if (statusFilter === 'ANNULLED') return item.status === 'ANNULLED';
    return true;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
              <Receipt className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-slate-900">Comprobantes y Asientos Contables</h1>
              <p className="text-xs text-slate-500">Registro NIIF con validación estricta de Partida Doble (Σ Débitos = Σ Créditos)</p>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={loadData}
            className="p-2.5 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 transition-colors"
            title="Refrescar"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={() => setShowModal(true)}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-blue-600 text-white text-xs font-semibold hover:bg-blue-700 shadow-sm shadow-blue-500/20 transition-all"
          >
            <Plus className="w-4 h-4" />
            <span>+ Nuevo Comprobante</span>
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Total Comprobantes</p>
            <p className="text-2xl font-bold text-slate-900 mt-1">{entries.length}</p>
          </div>
          <div className="w-9 h-9 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
            <Receipt className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Asentados (Oficiales)</p>
            <p className="text-2xl font-bold text-emerald-600 mt-1">{entries.filter(e => e.status === 'POSTED').length}</p>
          </div>
          <div className="w-9 h-9 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
            <CheckCircle2 className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Borradores</p>
            <p className="text-2xl font-bold text-amber-600 mt-1">{entries.filter(e => e.status === 'DRAFT').length}</p>
          </div>
          <div className="w-9 h-9 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center font-bold">
            <AlertTriangle className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Anulados</p>
            <p className="text-2xl font-bold text-rose-600 mt-1">{entries.filter(e => e.status === 'ANNULLED').length}</p>
          </div>
          <div className="w-9 h-9 rounded-lg bg-rose-50 text-rose-600 flex items-center justify-center font-bold">
            <XCircle className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Filter and Search */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="relative flex-1 w-full">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Buscar por consecutivo, concepto, descripción..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-all"
          />
        </div>

        <div className="flex items-center gap-2 w-full md:w-auto">
          {['ALL', 'POSTED', 'DRAFT', 'ANNULLED'].map((status) => {
            const labels: Record<string, string> = {
              ALL: 'Todos',
              POSTED: 'Asentados',
              DRAFT: 'Borradores',
              ANNULLED: 'Anulados'
            };
            return (
              <button
                key={status}
                onClick={() => setStatusFilter(status)}
                className={`px-3.5 py-2 rounded-xl text-xs font-semibold transition-all ${
                  statusFilter === status
                    ? 'bg-blue-600 text-white shadow-sm'
                    : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border border-slate-200'
                }`}
              >
                {labels[status]}
              </button>
            );
          })}
        </div>
      </div>

      {/* Entries Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                <th className="py-3 px-4">Consecutivo</th>
                <th className="py-3 px-4">Tipo</th>
                <th className="py-3 px-4">Fecha</th>
                <th className="py-3 px-4">Concepto General</th>
                <th className="py-3 px-4 text-right">Total Débito</th>
                <th className="py-3 px-4 text-right">Total Crédito</th>
                <th className="py-3 px-4 text-center">Estado</th>
                <th className="py-3 px-4 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs text-slate-700">
              {filteredEntries.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-slate-400">
                    <Receipt className="w-10 h-10 mx-auto mb-2 text-slate-300" />
                    <p className="font-semibold">No se encontraron comprobantes registrados</p>
                    <p className="text-[11px] mt-0.5">Haz clic en "+ Nuevo Comprobante" para crear un asiento contable.</p>
                  </td>
                </tr>
              ) : (
                filteredEntries.map((item) => (
                  <tr key={item.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-3 px-4 font-mono font-bold text-slate-900">
                      {item.entryNumber}
                    </td>
                    <td className="py-3 px-4">
                      <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-100 text-slate-700">
                        {item.entryType}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-slate-600 font-mono">
                      {item.date ? new Date(item.date).toLocaleDateString('es-CO') : '-'}
                    </td>
                    <td className="py-3 px-4 font-medium text-slate-800 max-w-xs truncate">
                      {item.concept}
                    </td>
                    <td className="py-3 px-4 text-right font-mono font-bold text-slate-900">
                      ${Number(item.totalDebit || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
                    </td>
                    <td className="py-3 px-4 text-right font-mono font-bold text-slate-900">
                      ${Number(item.totalCredit || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
                    </td>
                    <td className="py-3 px-4 text-center">
                      <span
                        className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                          item.status === 'POSTED'
                            ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                            : item.status === 'DRAFT'
                            ? 'bg-amber-50 text-amber-700 border border-amber-200'
                            : 'bg-rose-50 text-rose-700 border border-rose-200'
                        }`}
                      >
                        {item.status === 'POSTED' ? 'Asentado' : item.status === 'DRAFT' ? 'Borrador' : 'Anulado'}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-right space-x-1">
                      {item.status === 'DRAFT' && (
                        <button
                          onClick={() => handlePostEntry(item.id)}
                          className="px-2 py-1 rounded-lg text-[11px] font-bold bg-emerald-600 text-white hover:bg-emerald-700 transition-colors shadow-sm"
                          title="Asentar Comprobante"
                        >
                          Asentar
                        </button>
                      )}
                      {item.status === 'POSTED' && (
                        <button
                          onClick={() => handleAnnulEntry(item.id)}
                          className="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 transition-colors"
                          title="Anular Comprobante"
                        >
                          <XCircle className="w-3.5 h-3.5" />
                        </button>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Crear Comprobante */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white w-full max-w-5xl rounded-2xl border border-slate-200 shadow-2xl overflow-hidden flex flex-col max-h-[92vh]">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-200 bg-slate-50">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
                  <Receipt className="w-4 h-4" />
                </div>
                <h3 className="text-base font-bold text-slate-900">Registrar Comprobante Contable</h3>
              </div>
              <button onClick={() => setShowModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-6">
              {/* Encabezado */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 bg-slate-50 p-4 rounded-xl border border-slate-200">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Tipo de Comprobante</label>
                  <select
                    value={formData.entryType}
                    onChange={(e) => setFormData({ ...formData, entryType: e.target.value })}
                    className="w-full px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs text-slate-900 focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="CC">CC - Comprobante Contable / Diario</option>
                    <option value="CI">CI - Recibo de Caja / Ingreso</option>
                    <option value="CE">CE - Comprobante de Egreso</option>
                    <option value="FV">FV - Factura de Venta</option>
                    <option value="FC">FC - Factura de Compra</option>
                    <option value="NC">NC - Nota Crédito</option>
                    <option value="ND">ND - Nota Débito</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Fecha Contable</label>
                  <input
                    type="date"
                    required
                    value={formData.date}
                    onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                    className="w-full px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs text-slate-900 focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Concepto General</label>
                  <input
                    type="text"
                    required
                    value={formData.concept}
                    onChange={(e) => setFormData({ ...formData, concept: e.target.value })}
                    placeholder="Ej. Causación de servicios de consultoría"
                    className="w-full px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs text-slate-900 focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              {/* Grid de Movimientos Contables */}
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <h4 className="text-xs font-bold text-slate-800 uppercase tracking-wider">Líneas de Movimiento Contable</h4>
                  <button
                    type="button"
                    onClick={handleAddLine}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-blue-50 text-blue-700 text-xs font-bold hover:bg-blue-100 transition-colors"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>+ Agregar Línea</span>
                  </button>
                </div>

                <div className="border border-slate-200 rounded-xl overflow-hidden">
                  <table className="w-full text-left border-collapse text-xs">
                    <thead>
                      <tr className="bg-slate-100 border-b border-slate-200 text-[11px] font-bold text-slate-600">
                        <th className="py-2.5 px-3 w-1/4">Cuenta PUC</th>
                        <th className="py-2.5 px-3 w-1/5">Tercero</th>
                        <th className="py-2.5 px-3">Detalle / Concepto</th>
                        <th className="py-2.5 px-3 w-28 text-right">Débito ($)</th>
                        <th className="py-2.5 px-3 w-28 text-right">Crédito ($)</th>
                        <th className="py-2.5 px-2 w-10 text-center"></th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 bg-white">
                      {formData.lines.map((line, idx) => (
                        <tr key={idx} className="hover:bg-slate-50/50">
                          <td className="p-2">
                            <select
                              required
                              value={line.accountId}
                              onChange={(e) => handleLineChange(idx, 'accountId', e.target.value)}
                              className="w-full p-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono text-slate-900"
                            >
                              <option value="">-- Seleccione Cuenta --</option>
                              {pucAccounts.map((acc) => (
                                <option key={acc.id} value={acc.id}>
                                  {acc.code} - {acc.name}
                                </option>
                              ))}
                            </select>
                          </td>
                          <td className="p-2">
                            <select
                              value={line.thirdPartyId}
                              onChange={(e) => handleLineChange(idx, 'thirdPartyId', e.target.value)}
                              className="w-full p-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs text-slate-900"
                            >
                              <option value="">-- Opcional Tercero --</option>
                              {thirdParties.map((tp) => (
                                <option key={tp.id} value={tp.id}>
                                  {tp.documentNumber} - {tp.businessName || `${tp.firstName || ''} ${tp.lastName || ''}`}
                                </option>
                              ))}
                            </select>
                          </td>
                          <td className="p-2">
                            <input
                              type="text"
                              value={line.description}
                              onChange={(e) => handleLineChange(idx, 'description', e.target.value)}
                              placeholder="Detalle del movimiento"
                              className="w-full p-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs text-slate-900"
                            />
                          </td>
                          <td className="p-2">
                            <input
                              type="number"
                              step="0.01"
                              min="0"
                              value={line.debit || ''}
                              onChange={(e) => {
                                const val = parseFloat(e.target.value) || 0;
                                handleLineChange(idx, 'debit', val);
                                if (val > 0) handleLineChange(idx, 'credit', 0);
                              }}
                              className="w-full p-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs text-right font-mono font-bold text-slate-900"
                            />
                          </td>
                          <td className="p-2">
                            <input
                              type="number"
                              step="0.01"
                              min="0"
                              value={line.credit || ''}
                              onChange={(e) => {
                                const val = parseFloat(e.target.value) || 0;
                                handleLineChange(idx, 'credit', val);
                                if (val > 0) handleLineChange(idx, 'debit', 0);
                              }}
                              className="w-full p-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs text-right font-mono font-bold text-slate-900"
                            />
                          </td>
                          <td className="p-2 text-center">
                            <button
                              type="button"
                              onClick={() => handleRemoveLine(idx)}
                              className="p-1 text-slate-400 hover:text-rose-600 rounded-lg"
                              title="Eliminar Línea"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Barra de Validación de Partida Doble */}
              <div className={`p-4 rounded-xl border flex flex-col sm:flex-row items-center justify-between gap-4 ${
                isBalanced
                  ? 'bg-emerald-50 border-emerald-200 text-emerald-800'
                  : 'bg-amber-50 border-amber-200 text-amber-900'
              }`}>
                <div className="flex items-center gap-3">
                  {isBalanced ? (
                    <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                  ) : (
                    <AlertTriangle className="w-5 h-5 text-amber-600" />
                  )}
                  <div>
                    <p className="text-xs font-bold">
                      {isBalanced ? '¡Partida Doble Cuadrada! El comprobante está listo para ser guardado.' : 'Partida Doble Descuadrada'}
                    </p>
                    <p className="text-[11px] opacity-80">
                      {isBalanced
                        ? 'La suma de los débitos coincide exactamente con la suma de los créditos.'
                        : `Existe una diferencia de $${difference.toLocaleString('es-CO', { minimumFractionDigits: 2 })} entre Débitos y Créditos.`}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-6 text-xs font-mono font-bold">
                  <div>
                    <span className="text-[10px] block opacity-70">TOTAL DÉBITO</span>
                    <span>${totalDebit.toLocaleString('es-CO', { minimumFractionDigits: 2 })}</span>
                  </div>
                  <div>
                    <span className="text-[10px] block opacity-70">TOTAL CRÉDITO</span>
                    <span>${totalCredit.toLocaleString('es-CO', { minimumFractionDigits: 2 })}</span>
                  </div>
                </div>
              </div>
            </form>

            <div className="px-6 py-4 bg-slate-50 border-t border-slate-200 flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setShowModal(false)}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-200/60 transition-colors"
              >
                Cancelar
              </button>
              <button
                onClick={handleSubmit}
                disabled={!isBalanced}
                className={`px-5 py-2 rounded-xl text-xs font-semibold text-white shadow-sm transition-all ${
                  isBalanced
                    ? 'bg-blue-600 hover:bg-blue-700 shadow-blue-500/20 cursor-pointer'
                    : 'bg-slate-400 cursor-not-allowed opacity-60'
                }`}
              >
                Guardar Comprobante
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
