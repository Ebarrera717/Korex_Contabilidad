'use client';

import React, { useState, useEffect } from 'react';
import {
  ShoppingBag,
  Search,
  Plus,
  RefreshCw,
  Clock,
  CheckCircle2,
  AlertTriangle,
  FileText,
  DollarSign,
  X
} from 'lucide-react';

interface PayableInvoice {
  id: string;
  invoiceNumber: string;
  issueDate: string;
  dueDate: string;
  totalAmount: number;
  paidAmount: number;
  balance: number;
  status: 'ISSUED' | 'PAID' | 'PARTIAL' | 'ANNULLED';
  thirdPartyName?: string;
}

export default function PayablesPage() {
  const [invoices, setInvoices] = useState<PayableInvoice[]>([]);
  const [agingData, setAgingData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [activeTab, setActiveTab] = useState<'INVOICES' | 'AGING'>('INVOICES');
  const [showCrossModal, setShowCrossModal] = useState(false);
  const [selectedInvoice, setSelectedInvoice] = useState<PayableInvoice | null>(null);
  const [paymentAmount, setPaymentAmount] = useState('');

  const loadData = async () => {
    try {
      setLoading(true);
      const [resInv, resAging] = await Promise.all([
        fetch('/api/payables/invoices'),
        fetch('/api/payables/aging')
      ]);

      if (resInv.ok) {
        const json = await resInv.json();
        setInvoices(json.data || json || []);
      }
      if (resAging.ok) {
        const json = await resAging.json();
        setAgingData(json.data || json || null);
      }
    } catch (e) {
      console.error('Error cargando cuentas por pagar:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const totalPayables = invoices.reduce((acc, i) => acc + (Number(i.balance) || 0), 0);
  const totalPaid = invoices.reduce((acc, i) => acc + (Number(i.paidAmount) || 0), 0);

  const handleOpenCross = (inv: PayableInvoice) => {
    setSelectedInvoice(inv);
    setPaymentAmount(inv.balance.toString());
    setShowCrossModal(true);
  };

  const handleApplyCross = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedInvoice) return;
    try {
      const res = await fetch('/api/payables/cross', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          invoiceId: selectedInvoice.id,
          amount: parseFloat(paymentAmount) || 0,
          date: new Date().toISOString().split('T')[0]
        })
      });

      if (res.ok) {
        setShowCrossModal(false);
        loadData();
      } else {
        const err = await res.json();
        alert(`Error al aplicar pago a proveedor: ${err.message || err.error}`);
      }
    } catch (e) {
      alert('Error de conexión');
    }
  };

  const filteredInvoices = invoices.filter((inv) => {
    const num = (inv.invoiceNumber || '').toLowerCase();
    const tp = (inv.thirdPartyName || '').toLowerCase();
    return num.includes(searchTerm.toLowerCase()) || tp.includes(searchTerm.toLowerCase());
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-indigo-100 text-indigo-600 flex items-center justify-center font-bold">
              <ShoppingBag className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-slate-900">Proveedores y Cuentas por Pagar (CxP)</h1>
              <p className="text-xs text-slate-500">Control de facturas de compra, vencimientos, pagos a proveedores y retenciones NIIF</p>
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
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Saldo Total por Pagar</p>
            <p className="text-2xl font-bold text-indigo-700 mt-1 font-mono">
              ${totalPayables.toLocaleString('es-CO', { minimumFractionDigits: 2 })}
            </p>
            <p className="text-[11px] text-slate-400 mt-0.5">Grupo 22 - Proveedores Nacionales</p>
          </div>
          <div className="w-11 h-11 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold">
            <DollarSign className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Total Pagado / Girado</p>
            <p className="text-2xl font-bold text-emerald-600 mt-1 font-mono">
              ${totalPaid.toLocaleString('es-CO', { minimumFractionDigits: 2 })}
            </p>
            <p className="text-[11px] text-slate-400 mt-0.5">Egresos y giros aplicados</p>
          </div>
          <div className="w-11 h-11 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
            <CheckCircle2 className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Facturas Pendientes</p>
            <p className="text-2xl font-bold text-amber-600 mt-1 font-mono">
              {invoices.filter(i => i.balance > 0).length}
            </p>
            <p className="text-[11px] text-slate-400 mt-0.5">De un total de {invoices.length} causadas</p>
          </div>
          <div className="w-11 h-11 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center font-bold">
            <Clock className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-2 border-b border-slate-200 pb-2">
        <button
          onClick={() => setActiveTab('INVOICES')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            activeTab === 'INVOICES'
              ? 'bg-indigo-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          Facturas de Proveedores
        </button>
        <button
          onClick={() => setActiveTab('AGING')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            activeTab === 'AGING'
              ? 'bg-indigo-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          Matriz de Edades de Pasivos
        </button>
      </div>

      {/* Tab 1: Facturas */}
      {activeTab === 'INVOICES' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden space-y-4">
          <div className="p-4 border-b border-slate-100">
            <div className="relative">
              <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Buscar por número de factura o proveedor..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                  <th className="py-3 px-4">Factura</th>
                  <th className="py-3 px-4">Proveedor</th>
                  <th className="py-3 px-4">Emisión</th>
                  <th className="py-3 px-4">Vencimiento</th>
                  <th className="py-3 px-4 text-right">Total ($)</th>
                  <th className="py-3 px-4 text-right">Saldo Pendiente ($)</th>
                  <th className="py-3 px-4 text-center">Estado</th>
                  <th className="py-3 px-4 text-right">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs text-slate-700">
                {filteredInvoices.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="py-12 text-center text-slate-400">
                      <ShoppingBag className="w-10 h-10 mx-auto mb-2 text-slate-300" />
                      <p className="font-semibold">No se encontraron facturas registradas</p>
                    </td>
                  </tr>
                ) : (
                  filteredInvoices.map((inv) => (
                    <tr key={inv.id} className="hover:bg-slate-50/80">
                      <td className="py-3 px-4 font-mono font-bold text-slate-900">
                        {inv.invoiceNumber}
                      </td>
                      <td className="py-3 px-4 font-semibold text-slate-800">
                        {inv.thirdPartyName || 'Proveedor General'}
                      </td>
                      <td className="py-3 px-4 font-mono text-slate-600">
                        {inv.issueDate ? new Date(inv.issueDate).toLocaleDateString('es-CO') : '-'}
                      </td>
                      <td className="py-3 px-4 font-mono text-slate-600">
                        {inv.dueDate ? new Date(inv.dueDate).toLocaleDateString('es-CO') : '-'}
                      </td>
                      <td className="py-3 px-4 text-right font-mono font-bold text-slate-900">
                        ${Number(inv.totalAmount || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
                      </td>
                      <td className="py-3 px-4 text-right font-mono font-bold text-indigo-700">
                        ${Number(inv.balance || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
                      </td>
                      <td className="py-3 px-4 text-center">
                        <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                          inv.status === 'PAID'
                            ? 'bg-emerald-50 text-emerald-700'
                            : inv.status === 'PARTIAL'
                            ? 'bg-blue-50 text-blue-700'
                            : 'bg-amber-50 text-amber-700'
                        }`}>
                          {inv.status === 'PAID' ? 'Pagada' : inv.status === 'PARTIAL' ? 'Parcial' : 'Pendiente'}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-right">
                        {inv.balance > 0 && (
                          <button
                            onClick={() => handleOpenCross(inv)}
                            className="px-2.5 py-1 rounded-lg bg-indigo-600 text-white text-[11px] font-bold hover:bg-indigo-700 shadow-sm"
                          >
                            Pagar Factura
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
      )}

      {/* Tab 2: Matriz Edades */}
      {activeTab === 'AGING' && (
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-6">
          <h3 className="text-sm font-bold text-slate-900">Distribución de Pasivos por Edades de Vencimiento</h3>
          <div className="grid grid-cols-2 sm:grid-cols-5 gap-4">
            <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 text-center">
              <span className="text-[10px] font-bold text-slate-500 uppercase block">Corriente / Al Día</span>
              <span className="text-lg font-bold font-mono text-emerald-700 mt-1 block">
                ${Number(agingData?.current || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
              </span>
            </div>
            <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 text-center">
              <span className="text-[10px] font-bold text-slate-500 uppercase block">1 a 30 Días</span>
              <span className="text-lg font-bold font-mono text-blue-700 mt-1 block">
                ${Number(agingData?.days1_30 || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
              </span>
            </div>
            <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 text-center">
              <span className="text-[10px] font-bold text-slate-500 uppercase block">31 a 60 Días</span>
              <span className="text-lg font-bold font-mono text-amber-700 mt-1 block">
                ${Number(agingData?.days31_60 || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
              </span>
            </div>
            <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 text-center">
              <span className="text-[10px] font-bold text-slate-500 uppercase block">61 a 90 Días</span>
              <span className="text-lg font-bold font-mono text-orange-700 mt-1 block">
                ${Number(agingData?.days61_90 || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
              </span>
            </div>
            <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 text-center">
              <span className="text-[10px] font-bold text-slate-500 uppercase block">&gt; 90 Días</span>
              <span className="text-lg font-bold font-mono text-rose-700 mt-1 block">
                ${Number(agingData?.days90Plus || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
              </span>
            </div>
          </div>
        </div>
      )}

      {/* Modal Pago */}
      {showCrossModal && selectedInvoice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white w-full max-w-md rounded-2xl border border-slate-200 shadow-2xl p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-base font-bold text-slate-900">Registrar Pago a Proveedor</h3>
              <button onClick={() => setShowCrossModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="bg-indigo-50 p-3 rounded-xl text-xs space-y-1">
              <p><span className="font-bold">Factura:</span> {selectedInvoice.invoiceNumber}</p>
              <p><span className="font-bold">Saldo Pendiente:</span> ${selectedInvoice.balance.toLocaleString('es-CO')}</p>
            </div>

            <form onSubmit={handleApplyCross} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Monto a Pagar / Girar ($)</label>
                <input
                  type="number"
                  step="0.01"
                  max={selectedInvoice.balance}
                  required
                  value={paymentAmount}
                  onChange={(e) => setPaymentAmount(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-slate-900"
                />
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowCrossModal(false)}
                  className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-xl"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 text-xs font-semibold bg-indigo-600 text-white rounded-xl hover:bg-indigo-700 shadow-sm"
                >
                  Confirmar Pago
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
