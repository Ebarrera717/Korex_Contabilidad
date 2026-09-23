'use client';

import React, { useState, useEffect } from 'react';
import {
  Landmark,
  Search,
  Plus,
  ArrowDownLeft,
  ArrowUpRight,
  CreditCard,
  Wallet,
  RefreshCw,
  CheckCircle2,
  AlertCircle,
  FileCheck,
  X,
  Building2,
  Calendar,
  Layers
} from 'lucide-react';

interface CashBox {
  id: string;
  code: string;
  name: string;
  type: 'CASH' | 'BANK';
  bankName?: string | null;
  accountNumber?: string | null;
  currency: string;
  currentBalance: number;
  isActive: boolean;
}

interface TreasuryMovement {
  id: string;
  movementType: 'INCOME' | 'EXPENSE' | 'TRANSFER';
  date: string;
  amount: number;
  concept: string;
  reference?: string | null;
  isReconciled: boolean;
  cashBoxName?: string;
  thirdPartyName?: string;
}

export default function TreasuryPage() {
  const [cashBoxes, setCashBoxes] = useState<CashBox[]>([]);
  const [movements, setMovements] = useState<TreasuryMovement[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [activeTab, setActiveTab] = useState<'BOXES' | 'MOVEMENTS' | 'RECONCILIATION'>('BOXES');
  const [showModal, setShowModal] = useState(false);

  // Form State
  const [formData, setFormData] = useState({
    cashBoxId: '',
    movementType: 'INCOME',
    date: new Date().toISOString().split('T')[0],
    amount: '',
    concept: '',
    reference: '',
    thirdPartyId: '',
    contraAccountId: ''
  });

  const loadData = async () => {
    try {
      setLoading(true);
      const [resBoxes, resMovs] = await Promise.all([
        fetch('/api/treasury/cash-boxes'),
        fetch('/api/treasury/movements')
      ]);

      if (resBoxes.ok) {
        const json = await resBoxes.json();
        setCashBoxes(json.data || json || []);
      }
      if (resMovs.ok) {
        const json = await resMovs.json();
        setMovements(json.data || json || []);
      }
    } catch (e) {
      console.error('Error cargando tesorería:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const totalBankBalance = cashBoxes
    .filter(b => b.type === 'BANK')
    .reduce((acc, b) => acc + (Number(b.currentBalance) || 0), 0);

  const totalCashBalance = cashBoxes
    .filter(b => b.type === 'CASH')
    .reduce((acc, b) => acc + (Number(b.currentBalance) || 0), 0);

  const handleCreateMovement = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await fetch('/api/treasury/movements', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...formData,
          amount: parseFloat(formData.amount) || 0
        })
      });

      if (res.ok) {
        setShowModal(false);
        loadData();
      } else {
        const err = await res.json();
        alert(`Error al registrar movimiento: ${err.message || err.error}`);
      }
    } catch (e) {
      alert('Error de conexión');
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
              <Landmark className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-slate-900">Tesorería y Gestión Bancaria</h1>
              <p className="text-xs text-slate-500">Cajas menores, cuentas bancarias, recaudos, giros y conciliación bancaria NIIF</p>
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
            <span>+ Movimiento de Tesorería</span>
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Disponibilidad en Bancos</p>
            <p className="text-2xl font-bold text-blue-700 mt-1 font-mono">
              ${totalBankBalance.toLocaleString('es-CO', { minimumFractionDigits: 2 })}
            </p>
            <p className="text-[11px] text-slate-400 mt-0.5">{cashBoxes.filter(b => b.type === 'BANK').length} Cuentas Bancarias</p>
          </div>
          <div className="w-11 h-11 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
            <Landmark className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Efectivo en Cajas</p>
            <p className="text-2xl font-bold text-emerald-700 mt-1 font-mono">
              ${totalCashBalance.toLocaleString('es-CO', { minimumFractionDigits: 2 })}
            </p>
            <p className="text-[11px] text-slate-400 mt-0.5">{cashBoxes.filter(b => b.type === 'CASH').length} Cajas Menores/Generales</p>
          </div>
          <div className="w-11 h-11 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
            <Wallet className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Total Liquidez Disponible</p>
            <p className="text-2xl font-bold text-slate-900 mt-1 font-mono">
              ${(totalBankBalance + totalCashBalance).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
            </p>
            <p className="text-[11px] text-slate-400 mt-0.5">Grupo 11 - Efectivo y Equivalentes</p>
          </div>
          <div className="w-11 h-11 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center font-bold">
            <CreditCard className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-2 border-b border-slate-200 pb-2">
        <button
          onClick={() => setActiveTab('BOXES')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            activeTab === 'BOXES'
              ? 'bg-blue-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          Cuentas y Cajas Registradas
        </button>
        <button
          onClick={() => setActiveTab('MOVEMENTS')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            activeTab === 'MOVEMENTS'
              ? 'bg-blue-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          Historial de Movimientos
        </button>
        <button
          onClick={() => setActiveTab('RECONCILIATION')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            activeTab === 'RECONCILIATION'
              ? 'bg-blue-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          Conciliación Bancaria NIIF
        </button>
      </div>

      {/* Tab 1: Cuentas y Cajas */}
      {activeTab === 'BOXES' && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {cashBoxes.map((box) => (
            <div key={box.id} className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-4">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center font-bold ${
                    box.type === 'BANK' ? 'bg-blue-50 text-blue-600' : 'bg-emerald-50 text-emerald-600'
                  }`}>
                    {box.type === 'BANK' ? <Landmark className="w-5 h-5" /> : <Wallet className="w-5 h-5" />}
                  </div>
                  <div>
                    <h3 className="text-sm font-bold text-slate-900">{box.name}</h3>
                    <p className="text-[11px] text-slate-500 font-mono">{box.code} {box.bankName ? `• ${box.bankName}` : ''}</p>
                  </div>
                </div>
                <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                  box.isActive ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'
                }`}>
                  {box.isActive ? 'Activo' : 'Inactivo'}
                </span>
              </div>

              {box.accountNumber && (
                <div className="bg-slate-50 p-2.5 rounded-xl border border-slate-100 text-xs">
                  <span className="text-[10px] text-slate-400 block font-semibold">NÚMERO DE CUENTA</span>
                  <span className="font-mono font-bold text-slate-800">{box.accountNumber}</span>
                </div>
              )}

              <div className="pt-2 border-t border-slate-100 flex items-center justify-between">
                <span className="text-xs text-slate-500">Saldo en Libros</span>
                <span className="text-base font-bold font-mono text-slate-900">
                  ${Number(box.currentBalance || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Tab 2: Movimientos */}
      {activeTab === 'MOVEMENTS' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                  <th className="py-3 px-4">Fecha</th>
                  <th className="py-3 px-4">Tipo</th>
                  <th className="py-3 px-4">Caja / Banco</th>
                  <th className="py-3 px-4">Concepto / Referencia</th>
                  <th className="py-3 px-4 text-right">Monto ($)</th>
                  <th className="py-3 px-4 text-center">Conciliado</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs text-slate-700">
                {movements.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-12 text-center text-slate-400">
                      <Landmark className="w-10 h-10 mx-auto mb-2 text-slate-300" />
                      <p className="font-semibold">No se registran movimientos de tesorería</p>
                    </td>
                  </tr>
                ) : (
                  movements.map((mov) => (
                    <tr key={mov.id} className="hover:bg-slate-50/80">
                      <td className="py-3 px-4 font-mono text-slate-600">
                        {mov.date ? new Date(mov.date).toLocaleDateString('es-CO') : '-'}
                      </td>
                      <td className="py-3 px-4">
                        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold ${
                          mov.movementType === 'INCOME'
                            ? 'bg-emerald-50 text-emerald-700'
                            : mov.movementType === 'EXPENSE'
                            ? 'bg-rose-50 text-rose-700'
                            : 'bg-blue-50 text-blue-700'
                        }`}>
                          {mov.movementType === 'INCOME' ? <ArrowDownLeft className="w-3 h-3" /> : <ArrowUpRight className="w-3 h-3" />}
                          {mov.movementType === 'INCOME' ? 'Ingreso (CI)' : mov.movementType === 'EXPENSE' ? 'Egreso (CE)' : 'Transferencia'}
                        </span>
                      </td>
                      <td className="py-3 px-4 font-semibold text-slate-800">
                        {mov.cashBoxName || 'Caja General'}
                      </td>
                      <td className="py-3 px-4 text-slate-600">
                        <p className="font-medium text-slate-900">{mov.concept}</p>
                        {mov.reference && <p className="text-[11px] text-slate-400 font-mono">Ref: {mov.reference}</p>}
                      </td>
                      <td className={`py-3 px-4 text-right font-mono font-bold ${
                        mov.movementType === 'INCOME' ? 'text-emerald-600' : 'text-slate-900'
                      }`}>
                        {mov.movementType === 'INCOME' ? '+' : '-'}${Number(mov.amount || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
                      </td>
                      <td className="py-3 px-4 text-center">
                        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold ${
                          mov.isReconciled ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'
                        }`}>
                          {mov.isReconciled ? 'Conciliado' : 'Pendiente'}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Tab 3: Conciliación */}
      {activeTab === 'RECONCILIATION' && (
        <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm text-center space-y-4">
          <div className="w-12 h-12 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center mx-auto">
            <FileCheck className="w-6 h-6" />
          </div>
          <h3 className="text-base font-bold text-slate-900">Módulo de Conciliación Bancaria Automática</h3>
          <p className="text-xs text-slate-500 max-w-md mx-auto">
            Cargue su extracto bancario en formato Excel/CSV para cruzar automáticamente los movimientos en libros contra los movimientos bancarios reales.
          </p>
          <div className="flex justify-center gap-3">
            <button className="px-4 py-2 bg-blue-600 text-white rounded-xl text-xs font-semibold hover:bg-blue-700 shadow-sm">
              Cargar Extracto Bancario
            </button>
            <button className="px-4 py-2 bg-slate-100 text-slate-700 rounded-xl text-xs font-semibold hover:bg-slate-200">
              Generar Informe de Partidas Conciliatorias
            </button>
          </div>
        </div>
      )}

      {/* Modal Nuevo Movimiento */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white w-full max-w-lg rounded-2xl border border-slate-200 shadow-2xl overflow-hidden flex flex-col">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-200 bg-slate-50">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
                  <Landmark className="w-4 h-4" />
                </div>
                <h3 className="text-base font-bold text-slate-900">Registrar Movimiento de Tesorería</h3>
              </div>
              <button onClick={() => setShowModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateMovement} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Caja / Cuenta Bancaria</label>
                <select
                  required
                  value={formData.cashBoxId}
                  onChange={(e) => setFormData({ ...formData, cashBoxId: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">-- Seleccione Caja o Banco --</option>
                  {cashBoxes.map((b) => (
                    <option key={b.id} value={b.id}>
                      {b.name} ({b.type === 'BANK' ? 'Banco' : 'Caja'})
                    </option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Tipo de Movimiento</label>
                  <select
                    value={formData.movementType}
                    onChange={(e) => setFormData({ ...formData, movementType: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="INCOME">Ingreso / Recibo de Caja (CI)</option>
                    <option value="EXPENSE">Egreso / Pago (CE)</option>
                    <option value="TRANSFER">Transferencia entre Cuentas</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Fecha</label>
                  <input
                    type="date"
                    required
                    value={formData.date}
                    onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Valor / Monto ($)</label>
                <input
                  type="number"
                  step="0.01"
                  min="0.01"
                  required
                  placeholder="0.00"
                  value={formData.amount}
                  onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Concepto / Motivo</label>
                <input
                  type="text"
                  required
                  placeholder="Ej. Recaudo factura de venta FV-102"
                  value={formData.concept}
                  onChange={(e) => setFormData({ ...formData, concept: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Número de Referencia / Comprobante</label>
                <input
                  type="text"
                  placeholder="Ej. TR-998823"
                  value={formData.reference}
                  onChange={(e) => setFormData({ ...formData, reference: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="pt-4 flex items-center justify-end gap-3 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-100 transition-colors"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl text-xs font-semibold bg-blue-600 text-white hover:bg-blue-700 shadow-sm shadow-blue-500/20 transition-all"
                >
                  Registrar Movimiento
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
